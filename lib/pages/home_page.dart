import 'dart:convert';
import 'package:Laovista/config.dart';
import 'package:Laovista/notification_service.dart';
import 'package:Laovista/pages/ConcernListPage.dart';
import 'package:Laovista/pages/RequestDocumentsPage.dart';
import 'package:Laovista/pages/barangay_post_page.dart';
import 'package:Laovista/pages/concernpage.dart';
import 'package:Laovista/pages/edit_profile_page.dart';
import 'package:Laovista/pages/faq_page.dart';
import 'package:Laovista/pages/historypage.dart';
import 'package:Laovista/pages/main_navigation_page.dart';
import 'package:Laovista/pages/models/announcement.dart';
import 'package:Laovista/pages/notifications_page.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api_service.dart';
import 'custom_header.dart';

class HomePage extends StatefulWidget {
  final int barangayId;

  const HomePage({required this.barangayId, Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ApiService _apiService = ApiService();

  Future<List<Announcement>>? _announcementsFuture;
  Future<List<dynamic>>? _eventsFuture;

  String currentUserRole = 'resident';
  String? userName;

  int newAnnouncementCount = 0;
  int newEventCount = 0;

  // ✅ new counts
  int rejectedRequests = 0;
  int pendingRequests = 0;
  int completedRequests = 0;
  int totalConcerns = 0;

  List<int> _currentImageIndexes = [];
  List<bool> _isExpandedList = [];
List<dynamic> faqItems = [];

  @override
  void initState() {
    super.initState();
    _initialize();
      fetchFaq();
  }

  Future<void> _initialize() async {
    await _loadUserRole();
    await _loadStats();
    _loadAnnouncements();
    await _checkNewEvents();
    _loadEvents();
  }
Future<void> fetchFaq() async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('auth_token') ?? '';

  final url = Uri.parse('${AppConfig.apiBaseUrl}/faqs'); 
  try {
    final response = await http.get(
      url,
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      final List data = decoded['data'] ?? decoded;
      setState(() {
        faqItems = data;
      });
      print('📝 FAQs fetched: ${faqItems.length}');
    } else {
      print('❌ Failed to fetch FAQ: ${response.statusCode}');
    }
  } catch (e) {
    print('❌ Error fetching FAQ: $e');
  }
}
 Future<void> _loadUserRole() async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('auth_token');

  if (token == null) return;

  try {
    final profile = await ApiService().fetchProfile(token);
    print('🔥 Profile fetched: $profile'); // 🔹 check keys

    // Build the display name safely
    final firstName = profile['first_name'] ?? '';
    
    setState(() {
      userName = firstName;
      currentUserRole = 'resident'; // API wala pang role, default lang
    });
  } catch (e) {
    print('❌ Error loading profile: $e');
  }
}


Future<void> _loadStats() async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString(kAuthTokenKey);
  print('Token: $token'); // 🔹 check token

  if (token == null) {
    print('No token found!');
    return;
  }

  try {
    final history = await _apiService.fetchDocumentHistory(token);
    print('Fetched document history: $history'); // 🔹 check history raw

    final concerns = await _apiService.getUserConcerns();
    print('Fetched concerns: $concerns'); // 🔹 check concerns raw

   setState(() {
  pendingRequests = history.where((d) => d.status == 'pending').length;
  completedRequests = history.where((d) => d.status == 'completed').length;
  rejectedRequests = history.where((d) => d.status == 'rejected').length; // ✅ added
  totalConcerns = concerns.length;
});


    print('Pending: $pendingRequests, Completed: $completedRequests, Total Concerns: $totalConcerns');

  } catch (e) {
    print('Error loading stats: $e');
  }
}



  void _loadAnnouncements() {
    setState(() {
      _announcementsFuture = _apiService.fetchAnnouncements(
        barangayId: widget.barangayId,
        role: currentUserRole,
      );
    });
    _checkNewAnnouncements();
  }

  void _loadEvents() {
    setState(() {
      _eventsFuture = _apiService.fetchEvents(barangayId: widget.barangayId);
    });
  }

  Future<void> _checkNewAnnouncements() async {
    final prefs = await SharedPreferences.getInstance();
    final lastSeenString = prefs.getString('lastSeenAnnouncement');

    final announcements = await _apiService.fetchAnnouncements(
      barangayId: widget.barangayId,
      role: currentUserRole,
    );

    if (announcements.isEmpty) return;

    DateTime latest = announcements
        .map((a) => DateTime.parse(a.createdAt ?? a.date))
        .reduce((a, b) => a.isAfter(b) ? a : b);

    if (lastSeenString == null) {
      await prefs.setString('lastSeenAnnouncement', latest.toIso8601String());
      setState(() => newAnnouncementCount = 0);
      return;
    }

    DateTime lastSeen = DateTime.parse(lastSeenString);

    final newAnnouncements = announcements.where((a) {
      bool isForUser = false;
      if (a.target == 'all') {
        isForUser = true;
      } else if (a.target == 'specific' &&
          a.barangayId == widget.barangayId &&
          ((a.targetRole ?? '').isEmpty || a.targetRole == currentUserRole)) {
        isForUser = true;
      }
      if (!isForUser) return false;
      DateTime aCreated = DateTime.parse(a.createdAt ?? a.date);
      return aCreated.isAfter(lastSeen);
    }).toList();

    setState(() => newAnnouncementCount = newAnnouncements.length);

    if (newAnnouncements.isNotEmpty) {
      final latestAnnouncement = newAnnouncements.first;
      await NotificationService().showNotification(
        title: "New Announcement",
        body: latestAnnouncement.title,
      );
    }
  }

  Future<void> _checkNewEvents() async {
    final prefs = await SharedPreferences.getInstance();
    final lastSeenEventString = prefs.getString('lastSeenEvent');

    final events = await _apiService.fetchEvents(barangayId: widget.barangayId);
    final approvedEvents = events.where((e) => e.status == 'approved').toList();
    if (approvedEvents.isEmpty) return;

    DateTime latestApproved = approvedEvents
        .map((e) => DateTime.tryParse(e.updatedDate ?? e.date) ?? DateTime.now())
        .reduce((a, b) => a.isAfter(b) ? a : b);

    if (lastSeenEventString == null) {
      await prefs.setString('lastSeenEvent', latestApproved.toIso8601String());
      setState(() => newEventCount = 0);
      return;
    }

    DateTime lastSeen = DateTime.parse(lastSeenEventString);

    final newApproved = approvedEvents.where((e) {
      final approvedDate =
          DateTime.tryParse(e.updatedDate ?? e.date) ?? DateTime.now();
      return approvedDate.isAfter(lastSeen);
    }).toList();

    setState(() => newEventCount = newApproved.length);

    if (newApproved.isNotEmpty) {
      final latestEvent = newApproved.first;
      await NotificationService().showNotification(
        title: "New Event Approved!",
        body: latestEvent.title ?? "Check the new event in your barangay!",
      );
    }
  }

  Future<void> _refreshHome() async {
    await _loadStats();
    _loadAnnouncements();
    _loadEvents();
    await _checkNewEvents();
  }

  void _onBellTap() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      newAnnouncementCount = 0;
      newEventCount = 0;
    });

    final announcements = await _apiService.fetchAnnouncements(
      barangayId: widget.barangayId,
      role: currentUserRole,
    );

    if (announcements.isNotEmpty) {
      final latest = announcements
          .map((a) => DateTime.parse(a.createdAt ?? a.date))
          .reduce((a, b) => a.isAfter(b) ? a : b);
      prefs.setString('lastSeenAnnouncement', latest.toIso8601String());
    }

    final events = await _apiService.fetchEvents(barangayId: widget.barangayId);
    final approvedEvents = events.where((e) => e.status == 'approved').toList();

    if (approvedEvents.isNotEmpty) {
      final latestApproved = approvedEvents
          .map((e) => DateTime.tryParse(e.updatedDate ?? e.date) ?? DateTime.now())
          .reduce((a, b) => a.isAfter(b) ? a : b);
      prefs.setString('lastSeenEvent', latestApproved.toIso8601String());
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => NotificationsPage(
          announcements: announcements,
          events: approvedEvents,
        ),
      ),
    );
  }

@override
Widget build(BuildContext context) {
  final totalNotif = newAnnouncementCount + newEventCount;

  return Scaffold(
    backgroundColor: Colors.transparent,
    body: Stack(
      children: [
        // 🌈 Background + List
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade200, Colors.blue.shade50],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: RefreshIndicator(
            onRefresh: _refreshHome,
            child: ListView(
              padding: EdgeInsets.only(bottom: 80), // give space for floating button
              children: [
                Stack(
                  children: [
                    const CustomHeader(title: 'Home'),
                    Positioned(
                      right: 16,
                      top: 40,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.notifications,
                                color: Colors.white, size: 28),
                            onPressed: _onBellTap,
                          ),
                          if (totalNotif > 0)
                            Positioned(
                              right: -2,
                              top: -2,
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.redAccent,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 1.5),
                                ),
                                child: Text(
                                  '$totalNotif',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                // 👋 Greeting
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Text(
                    'Good day, ${userName ?? "Resident"}!',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                // Stats cards
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        "Request Summary",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Padding(
  padding: const EdgeInsets.symmetric(horizontal: 16),
  child: SizedBox(
    width: double.infinity,
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: _statCard("Pending", pendingRequests, Colors.orange),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: _statCard("Completed", completedRequests, Colors.green),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: _statCard("Rejected", rejectedRequests, Colors.red),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: _statCard("Concerns", totalConcerns, Colors.blue),
        ),
      ],
    ),
  ),
),

                    const SizedBox(height: 15),
                  ],
                ),
                _upcomingEvents(),
                const SizedBox(height: 8),
                _announcementSection(),
              ],
            ),
          ),
        ),

        // 🟠 Floating FAQ Button at bottom-left
        Positioned(
          left: 16,
          bottom: 32,
          child: GestureDetector(
            onTap: () => FaqChatModal.show(context, faqItems),
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: Colors.orange,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 4,
                    offset: Offset(2, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.help_outline,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
Widget _statCard(String label, int count, Color color) {
  return GestureDetector(
    onTap: () {
      if (label == "Pending") {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => Historypage(
              barangayId: widget.barangayId,
              filter: 'pending',
            ),
          ),
        );
      } else if (label == "Completed") {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => Historypage(
              barangayId: widget.barangayId,
              filter: 'completed',
            ),
          ),
        );
        } else if (label == "Rejected") {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => Historypage(
        barangayId: widget.barangayId,
        filter: 'rejected',
      ),
    ),
  );

     } else if (label == "Concerns") {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => MainNavigationPage(
        barangayId: widget.barangayId,
        initialTabIndex: 3, // 🟢 open Concerns tab
      ),
    ),
  );
}

    },
    child: Column(
      children: [
        // 🔵 Bilog na lalagyan ng number
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withOpacity(0.1),
            border: Border.all(color: color, width: 3),
          ),
          child: Center(
            child: Text(
              '$count',
              style: TextStyle(
                color: color,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        // 🏷️ Label sa labas ng bilog
        SizedBox(
          width: 90,
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 10,
              color: Colors.black87,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    ),
  );
}

  Widget _upcomingEvents() {
    return FutureBuilder<List<dynamic>>(
      future: _eventsFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
              child: Padding(
            padding: EdgeInsets.all(8.0),
            child: Text("No upcoming events at the moment."),
          ));
        }

        final now = DateTime.now();
       final today = DateTime(now.year, now.month, now.day);

      // Filter approved events scheduled today or in the future
      final upcoming = snapshot.data!
          .where((e) {
            if (e.date == null) return false;
            final eventDate = DateTime.parse(e.date);
            return e.status == 'approved' && !eventDate.isBefore(today);
          })
          .toList();

      // Sort by date ascending
      upcoming.sort((a, b) {
        final dateA = DateTime.parse(a.date);
        final dateB = DateTime.parse(b.date);
        return dateA.compareTo(dateB);
      });

        final upcomingLimited = upcoming.take(3).toList();

      return Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Text(
        "Upcoming Barangay Events",
        style: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    ),
    const SizedBox(height: 8),
    SizedBox(
      height: 150,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: upcomingLimited.length,
        itemBuilder: (context, i) {
          final e = upcomingLimited[i];
          final date = DateFormat('MMM d').format(
              DateTime.tryParse(e.date ?? '') ?? DateTime.now());

          // Vibrant solid colors
          final colors = [
            Colors.orange.shade700,
            Colors.blue.shade700,
            Colors.green.shade700,
            Colors.purple.shade700,
          ];
          final color = colors[i % colors.length];

          return Container(
            width: 220,
            margin: const EdgeInsets.symmetric(horizontal: 10),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.4),
                  blurRadius: 8,
                  offset: const Offset(2, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.event, size: 18, color: Colors.white),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        e.title ?? "Barangay Event",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
            Expanded(
  child: SingleChildScrollView(
    child: Text(
      e.details ?? "No details available.",
      style: const TextStyle(
        fontFamily: 'Poppins',
        fontSize: 14,
        color: Colors.white70,
      ),
    ),
  ),
),




                        Text("Date: $date",
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            )),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _announcementSection() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: const [
              
              SizedBox(width: 8),
              Text("Upcoming Announcements",
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  )),
            ],
          ),
        ),
        _buildAnnouncements(),
      ],
    );
  }
  
  // Existing Announcement Builder (unaltered)
Widget _buildAnnouncements() {
  if (_announcementsFuture == null) {
    return const Center(child: CircularProgressIndicator());
  }

  return FutureBuilder<List<Announcement>>(
    future: _announcementsFuture,
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Center(child: CircularProgressIndicator());
      }

      if (snapshot.hasError) {
        return const Center(
          child: Text(
            '⚠️ Failed to load announcements',
            style: TextStyle(color: Colors.redAccent, fontSize: 16),
          ),
        );
      }

      final allAnnouncements = snapshot.data ?? [];
      final filtered = allAnnouncements.where((a) {
        final role = a.targetRole ?? '';
        if (a.target == 'all') return true;
        if (a.target == 'specific' &&
            (role.isEmpty || role == currentUserRole) &&
            a.barangayId == widget.barangayId) return true;
        return false;
      }).toList();

      if (filtered.isEmpty) {
        return const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.announcement_outlined, size: 60, color: Color.fromARGB(255, 250, 246, 246)),
              SizedBox(height: 12),
              Text(
                'No announcements available',
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            ],
          ),
        );
      }

      // Ensure state lists match filtered length
      if (_currentImageIndexes.length != filtered.length) {
        _currentImageIndexes = List<int>.filled(filtered.length, 0);
      }
      if (_isExpandedList.length != filtered.length) {
        _isExpandedList = List<bool>.filled(filtered.length, false);
      }

      return ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(vertical: 10),
        itemCount: filtered.length,
        itemBuilder: (context, index) {
          final ann = filtered[index];
          final postedDate = DateTime.tryParse(ann.createdAt ?? '') ?? DateTime.now();
          final announcementDate = DateTime.tryParse(ann.date ?? '') ?? DateTime.now();
          final formattedPostedDate = DateFormat('MMMM d, yyyy').format(postedDate);
          final formattedAnnouncementDate = DateFormat('MMMM d, yyyy').format(announcementDate);

          String formattedTime;
          try {
            final parsedTime = DateFormat('HH:mm:ss').parse(ann.time ?? '00:00:00');
            formattedTime = DateFormat('h:mm a').format(parsedTime);
          } catch (_) {
            formattedTime = ann.time ?? '';
          }

          final isNew = postedDate.isAfter(DateTime.now().subtract(const Duration(days: 1)));
          final images = ann.images ?? [];

       return Container(
  width: double.infinity,
  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  child: Card(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    elevation: 4,
    shadowColor: Colors.black26,
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          
          // HEADER (Icon + title + NEW)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.announcement, color: Colors.blueAccent, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  ann.title ?? "Untitled Announcement",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueAccent,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
              ),
              if (isNew)
                Container(
                  margin: const EdgeInsets.only(left: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.redAccent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'NEW',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 6),

          Text(
            'Posted on: $formattedPostedDate',
            style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500
            ),
          ),

          const SizedBox(height: 12),

          // DATE & TIME BOX
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Date & Time',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blueAccent)),
                Flexible(
                  child: Text(
                    '$formattedAnnouncementDate at $formattedTime',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.black87),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // DETAILS BOX
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Details',
                    style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1)),
                const SizedBox(height: 6),
                Text(
                  ann.details ?? "No details available.",
                  maxLines: _isExpandedList[index] ? null : 3,
                  overflow: _isExpandedList[index] ? TextOverflow.visible : TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 14, height: 1.5, color: Colors.black87),
                ),

                const SizedBox(height: 8),

                GestureDetector(
                  onTap: () {
                    setState(() => _isExpandedList[index] = !_isExpandedList[index]);
                  },
                  child: Text(
                    _isExpandedList[index] ? 'See Less ▲' : 'See More ▼',
                    style: const TextStyle(
                        fontSize: 14,
                        color: Colors.blueAccent,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),

          // IMAGE + DOTS
          if (_isExpandedList[index] && images.isNotEmpty) ...[
            const SizedBox(height: 12),

            // CAROUSEL
            SizedBox(
              height: 220,
              child: PageView.builder(
                itemCount: images.length,
                controller: PageController(viewportFraction: 0.9),
                onPageChanged: (imgIndex) {
                  setState(() => _currentImageIndexes[index] = imgIndex);
                },
                itemBuilder: (context, imgIndex) {
                  final imageUrl = images[imgIndex];

                  return GestureDetector(
                    onTap: () => _showFullscreenImage(context, imageUrl),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: CachedNetworkImage(
                          imageUrl: imageUrl,
                          fit: BoxFit.contain,
                          placeholder: (context, url) => Container(
                            color: Colors.grey[300],
                            child: const Center(child: CircularProgressIndicator()),
                          ),
                          errorWidget: (context, url, error) =>
                              const Icon(Icons.broken_image, size: 60, color: Colors.grey),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 8),

            // PAGINATION DOTS (NO PACKAGE)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(images.length, (dotIndex) {
                bool isActive = _currentImageIndexes[index] == dotIndex;

                return AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: isActive ? 12 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: isActive ? Colors.blueAccent : Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(50),
                  ),
                );
              }),
            ),
          ],
        ],
      ),
    ),
  ),
);

        },
      );
    },
  );
}

 void _showFullscreenImage(BuildContext context, String imageUrl) {
  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (_) => Stack(
      children: [
        // IMAGE VIEWER DIALOG
        Dialog(
          backgroundColor: Colors.black.withOpacity(0.95),
          insetPadding: EdgeInsets.zero,
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: InteractiveViewer(
              child: Center(
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.contain,
                  placeholder: (context, url) => const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                  errorWidget: (context, url, error) => const Icon(
                    Icons.broken_image,
                    color: Colors.white,
                    size: 80,
                  ),
                ),
              ),
            ),
          ),
        ),

        // ❌ CLOSE BUTTON (TOP RIGHT)
        Positioned(
          top: 40,
          right: 20,
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close,
                color: Colors.white,
                size: 28,
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
}
