import 'dart:convert';

import 'package:Laovista/pages/faq_page.dart';
import 'package:Laovista/pages/models/event.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../api_service.dart';
import '../config.dart';
import 'custom_header.dart';

class BarangayPostPage extends StatefulWidget {
  final int barangayId;

  const BarangayPostPage({required this.barangayId, Key? key}) : super(key: key);

  @override
  _BarangayPostPageState createState() => _BarangayPostPageState();
}

class _BarangayPostPageState extends State<BarangayPostPage> {
  final ApiService _apiService = ApiService();
  late Future<List<Event>> _eventsFuture;
  List<int> _currentImageIndexes = [];
  List<bool> _isExpandedList = [];
List<dynamic> faqItems = [];
  @override
  void initState() {
    super.initState();
    _loadEvents();
      fetchFaq();
  }

  void _loadEvents() {
    _eventsFuture = _apiService.fetchEvents(barangayId: widget.barangayId);
  }

  Future<void> _refreshEvents() async {
    setState(() {
      _loadEvents();
    });
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
@override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: Colors.transparent, // Let gradient show
    body: Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.blue.shade200, // top color
            Colors.blue.shade50,  // bottom color
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Stack(
        children: [
          Column(
            children: [
              CustomHeader(title: 'Barangay Events'),
              const SizedBox(height: 10),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _refreshEvents,
                  child: _buildEvents(),
                ),
              ),
            ],
          ),
          // ✅ Floating FAQ button
          Positioned(
            left: 16,
            bottom: 32,
            child: GestureDetector(
              onTap: () {
                FaqChatModal.show(context, faqItems); // Make sure faqItems is loaded
              },
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
    ),
  );
}



Widget _buildEvents() {
  return FutureBuilder<List<Event>>(
    future: _eventsFuture,
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Center(child: CircularProgressIndicator());
      }

      if (snapshot.hasError) {
        return const Center(
          child: Text(
            '⚠️ Failed to load posts',
            style: TextStyle(color: Colors.redAccent, fontSize: 16),
          ),
        );
      }

      final allEvents = snapshot.data ?? [];
      // 🔹 DEBUG: Print all events before filtering
for (var event in allEvents) {
  print('🌟 Event: ${event.title}, Status: ${event.status}, BarangayId: ${event.barangayId}, Date: ${event.date}');
}
      final filteredEvents = allEvents
          .where((event) =>
              event.status == 'approved' &&
              event.barangayId == widget.barangayId)
          .toList();

      if (filteredEvents.isEmpty) {
        return const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.event_busy, size: 60, color: Colors.grey),
              SizedBox(height: 12),
              Text(
                'No approved posts from your barangay',
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            ],
          ),
        );
      }

      // Ensure state lists match filtered length
      if (_currentImageIndexes.length != filteredEvents.length) {
        _currentImageIndexes = List<int>.filled(filteredEvents.length, 0);
      }
      if (_isExpandedList.length != filteredEvents.length) {
        _isExpandedList = List<bool>.filled(filteredEvents.length, false);
      }

      return ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 10),
        itemCount: filteredEvents.length,
        itemBuilder: (context, index) {
          final event = filteredEvents[index];

          final parsedDate = DateTime.tryParse(event.date);
          final formattedDate = parsedDate != null
              ? DateFormat('MMMM d, yyyy').format(parsedDate)
              : event.date;

          String formattedTime;
          try {
            final parsedTime = DateFormat('HH:mm:ss').parse(event.time);
            formattedTime = DateFormat('h:mm a').format(parsedTime);
          } catch (_) {
            formattedTime = event.time;
          }

          final postedDate = event.updatedDate != null
              ? DateTime.parse(event.updatedDate!)
              : DateTime.now();
          final isNew = postedDate.isAfter(DateTime.now().subtract(const Duration(days: 1)));

          final images = event.images;

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
          // Header: Title + NEW badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.event, color: Colors.blueAccent, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  event.title,
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
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 4),

          Text(
            'Approved on: ${DateFormat('MMMM d, yyyy').format(postedDate)}',
            style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w500),
          ),

          const SizedBox(height: 12),

          // Date & Time Box
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
                const Text(
                  'Date & Time',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blueAccent),
                ),
                Flexible(
                  child: Text(
                    '$formattedDate at $formattedTime',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black87),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Venue Box
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
                const Text(
                  'Venue',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1),
                ),
                const SizedBox(height: 6),
                Text(
                  event.venue,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black87),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Details Box
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
                const Text(
                  'Details',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1),
                ),
                const SizedBox(height: 6),
                Text(
                  event.details,
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
                    style: const TextStyle(fontSize: 14, color: Colors.blueAccent, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),

          // Images + pagination dots
          if (_isExpandedList[index] && images.isNotEmpty) ...[
            const SizedBox(height: 12),

            // IMAGE CAROUSEL
            SizedBox(
              height: 220,
              child: PageView.builder(
                itemCount: images.length,
                controller: PageController(viewportFraction: 0.9),
                onPageChanged: (imgIndex) {
                  setState(() => _currentImageIndexes[index] = imgIndex);
                },
                itemBuilder: (context, imgIndex) {
                  final imagePath = images[imgIndex];
                  final imageUrl = imagePath.startsWith('http')
                      ? imagePath
                      : "${AppConfig.storageBaseUrl}/$imagePath";

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

            const SizedBox(height: 10),

            // MANUAL PAGINATION DOTS
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
        // FULLSCREEN IMAGE DIALOG
        Dialog(
          backgroundColor: Colors.black.withOpacity(0.95),
          insetPadding: EdgeInsets.zero,
          child: GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: InteractiveViewer(
              child: Center(
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => const Icon(
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
            onTap: () => Navigator.of(context).pop(),
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

// InfoCard widget
class _InfoCard extends StatelessWidget {
  final String label;
  final String value;

  const _InfoCard({required this.label, required this.value, Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      constraints: const BoxConstraints(minWidth: 100),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(),
              style: const TextStyle(
                  fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(value,
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w500, color: Colors.black87)),
        ],
      ),
    );
  }
}
