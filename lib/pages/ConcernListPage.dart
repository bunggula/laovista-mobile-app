import 'dart:convert';

import 'package:Laovista/api_service.dart';
import 'package:Laovista/config.dart';
import 'package:Laovista/pages/concernpage.dart';
import 'package:Laovista/pages/custom_header.dart';
import 'package:Laovista/pages/faq_page.dart';
import 'package:Laovista/pages/models/faq.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';



class ListOfConcernPage extends StatefulWidget {
  final int barangayId;

  const ListOfConcernPage({Key? key, required this.barangayId})
      : super(key: key);

  @override
  State<ListOfConcernPage> createState() => _ListOfConcernPageState();
}

class _ListOfConcernPageState extends State<ListOfConcernPage> {
  late Future<List<dynamic>> _futureConcerns;
  List<dynamic> faqItems = []; 
  @override
  void initState() {
    super.initState();
    _fetchConcerns();
    fetchFaq(); 
  }

  void _fetchConcerns() {
    _futureConcerns = ApiService().getUserConcerns();
  }
Future<void> fetchFaq() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token') ?? '';
    debugPrint('🔐 Token for FAQ request: $token');

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

        debugPrint('📝 FAQ fetched: ${faqItems.length} items');
      } else {
        debugPrint('❌ Failed to fetch FAQ: ${response.statusCode}');
        debugPrint('📦 Response body: ${response.body}');
      }
    } catch (e) {
      debugPrint('❌ Error fetching FAQ: $e');
    }
  }
  Future<void> _refreshConcerns() async {
    setState(() {
      _fetchConcerns();
    });
    await _futureConcerns;
  }

  String _formatDate(String isoString) {
    try {
      final dateTime = DateTime.parse(isoString).toLocal();
      return DateFormat('MMMM d, y • h:mm a').format(dateTime);
    } catch (e) {
      return isoString;
    }
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'on going':
        return Colors.blue;
      case 'resolved':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  void _showFullscreenImage(String imageUrl) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.black.withOpacity(0.9),
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                panEnabled: true,
                minScale: 0.5,
                maxScale: 3.0,
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) =>
                      const Text("❌ Could not load image.",
                          style: TextStyle(color: Colors.white)),
                ),
              ),
            ),
            Positioned(
              top: 40,
              right: 20,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const CircleAvatar(
                  backgroundColor: Colors.white54,
                  child: Icon(Icons.close, color: Colors.black),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final statuses = ['pending', 'on going', 'resolved'];
    final statusLabels = {
      'pending': 'Pending',
      'on going': 'On Going',
      'resolved': 'Resolved',
    };


   return Scaffold(
  backgroundColor: Colors.transparent, // Let gradient show through

  // Single body using Stack
  body: Stack(
    children: [
      // Gradient background + Concerns list
      Container(
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
        child: Column(
          children: [
            const CustomHeader(title: "Concerns"),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _refreshConcerns,
                displacement: 80,
                color: const Color(0xFF1565C0),
                child: FutureBuilder<List<dynamic>>(
                  future: _futureConcerns,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      return Center(child: Text("❌ Error: ${snapshot.error}"));
                    } else if (snapshot.data!.isEmpty) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(20.0),
                          child: Text(
                            "No concerns have been submitted yet.",
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.black54,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      );
                    }

                    final concerns = snapshot.data!;
                    return ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      itemCount: concerns.length,
                      itemBuilder: (context, index) {
                        final c = concerns[index];
                        final currentStatus = c['status'].toLowerCase();
                        int currentIndex = statuses.indexOf(currentStatus);
                        if (currentIndex == -1) currentIndex = 0;

                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20)),
                          elevation: 4,
                          shadowColor: Colors.black26,
                          color: Colors.white,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Title
                                Text(
                                  c['title'] ?? 'No Title',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1565C0),
                                  ),
                                ),
                                const SizedBox(height: 12),

                              // Description
Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    const Text(
      "Description:",
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600, // semi-bold for label
        color: Colors.black87,
        height: 1.4,
      ),
    ),
    const SizedBox(height: 4),
    Text(
      c['description'] ?? 'No Description',
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: Colors.black87,
        height: 1.5,
      ),
    ),
  ],
),
const SizedBox(height: 12),

// Location
Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    const Text(
      "Location:",
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Colors.black87,
        height: 1.4,
      ),
    ),
    const SizedBox(height: 4),
    Text(
      "Zone: ${c['zone'] ?? 'N/A'}",
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: Colors.black87,
        height: 1.4,
      ),
    ),
    Text(
      "Street/Landmark: ${c['street'] ?? 'N/A'}",
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: Colors.black87,
        height: 1.4,
      ),
    ),
  ],
),
const SizedBox(height: 12),



                                // Timeline
                                Row(
                                  children: List.generate(statuses.length * 2 - 1, (i) {
                                    if (i % 2 == 0) {
                                      int statusIdx = i ~/ 2;
                                      bool isDone = statusIdx <= currentIndex;
                                      return Expanded(
                                        child: Column(
                                          children: [
                                            CircleAvatar(
                                              radius: 10,
                                              backgroundColor: isDone
                                                  ? _statusColor(statuses[statusIdx])
                                                  : Colors.grey[300],
                                              child: isDone
                                                  ? const Icon(Icons.check,
                                                      size: 14,
                                                      color: Colors.white)
                                                  : null,
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              statusLabels[statuses[statusIdx]]!,
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: _statusColor(statuses[statusIdx]),
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    } else {
                                      return Expanded(
                                        child: Container(
                                          height: 2,
                                          color: (i ~/ 2) < currentIndex
                                              ? _statusColor(statuses[i ~/ 2])
                                              : Colors.grey[300],
                                        ),
                                      );
                                    }
                                  }),
                                ),
                                const SizedBox(height: 12),

                                // Date
                              Row(
  children: [
    const SizedBox(width: 4),
    Text(
      "Date: ${_formatDate(c['created_at'])}",
      style: TextStyle(
        fontSize: 14,               // konting pataas para mas readable
        color: Colors.black87,       // darker for better contrast
        fontWeight: FontWeight.w500, // medyo bold for emphasis
        height: 1.4,                 // line height for spacing
      ),
    ),
  ],
),


                                // Image
                                if (c['image_path'] != null) ...[
                                  const SizedBox(height: 12),
                                  GestureDetector(
                                    onTap: () => _showFullscreenImage(
                                        "${AppConfig.storageBaseUrl}/${c['image_path']}"),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.network(
                                        "${AppConfig.storageBaseUrl}/${c['image_path']}",
                                        height: 120,
                                        width: double.infinity,
                                        fit: BoxFit.contain,
                                        errorBuilder: (context, error, stackTrace) =>
                                            Container(
                                          height: 140,
                                          color: Colors.grey[200],
                                          alignment: Alignment.center,
                                          child: const Icon(Icons.broken_image,
                                              size: 40, color: Colors.grey),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),

      // FAQ Button (bottom-left)
      Positioned(
        left: 16,
        bottom: 32,
        child: GestureDetector(
          onTap: () {
            FaqChatModal.show(context, faqItems);
          },
          child: Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: Colors.orange,
              shape: BoxShape.circle,
              boxShadow: const [
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

  // Floating Action Button (Add Concern)
  floatingActionButton: FloatingActionButton(
    onPressed: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => Concernpage(barangayId: widget.barangayId),
        ),
      ).then((_) => _refreshConcerns());
    },
    backgroundColor: const Color(0xFF1565C0),
    child: const Icon(Icons.add, size: 30, color: Colors.white),
    tooltip: 'Add New Concern',
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
  ),
);
  }
}