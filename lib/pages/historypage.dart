import 'package:Laovista/config.dart';
import 'package:Laovista/pages/custom_header.dart';
import 'package:Laovista/pages/faq_page.dart';
import 'package:Laovista/pages/login_page.dart' show kAuthTokenKey;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';


class Historypage extends StatefulWidget {
  final int barangayId;
  final String? filter;

    const Historypage({Key? key, required this.barangayId, this.filter}) : super(key: key);

  @override
  _HistorypageState createState() => _HistorypageState();
}

class _HistorypageState extends State<Historypage> {
  List<dynamic> _history = [];
  bool _isLoading = true;
List<dynamic> faqItems = [];
  @override
  void initState() {
    super.initState();
    _fetchHistory();
      fetchFaq();
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
  Future<void> _fetchHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(kAuthTokenKey) ?? '';

    final url = Uri.parse('${AppConfig.apiBaseUrl}/document-requests/history');

    try {
      final response = await http.get(url, headers: {
        'Authorization': 'Bearer $token',
      });

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);

        setState(() {
          _history = data;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'approved':
        return Colors.green;
         case 'ready_for_pickup':
        return const Color.fromARGB(255, 196, 70, 238);
      case 'rejected':
        return Colors.red;
      case 'pending':
        return Colors.orange;
      case 'completed':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

Widget _buildHistoryCard(dynamic item) {
  // Check if rejected
  bool isRejected = item['status'] == 'rejected';

  // If rejected, override timeline to only show rejected
  List<String> statuses = isRejected
      ? ['rejected']
      : ['pending', 'approved', 'ready_for_pickup', 'completed'];

  String currentStatus = item['status'] ?? 'pending';
  int currentIndex = statuses.indexOf(currentStatus);
  if (currentIndex == -1) currentIndex = 0;

  return Card(
  margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),

    elevation: 4,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    shadowColor: Colors.black26,
    child: Padding(
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Document Title
          Text(
            item['document_type'] ?? 'Unknown Document',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1565C0),
            ),
          ),
          const SizedBox(height: 10),

          // Timeline Status Line
          Row(
            children: List.generate(statuses.length * 2 - 1, (index) {
              if (index % 2 == 0) {
                int statusIndex = index ~/ 2;
                bool isDone = statusIndex <= currentIndex;
                return Expanded(
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 10,
                        backgroundColor: isDone
                            ? _getStatusColor(statuses[statusIndex])
                            : Colors.grey[300],
                        child: isDone
                            ? const Icon(Icons.check, size: 13, color: Colors.white)
                            : null,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        statuses[statusIndex].replaceAll('_', ' ').toUpperCase(),
                        style: TextStyle(
                          fontSize: 8,
                          color: _getStatusColor(statuses[statusIndex]),
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              } else {
                return Expanded(
                  child: Container(
                    height: 2,
                    color: (index ~/ 2) < currentIndex
                        ? _getStatusColor(statuses[index ~/ 2])
                        : Colors.grey[300],
                  ),
                );
              }
            }),
          ),
          const SizedBox(height: 12),

          // Reference Code
          _infoRow("Reference Code", item['reference_code'] ?? 'N/A'),

          // Requested On
          _infoRow("Requested On", _formatDate(item['created_at'])),

          const SizedBox(height: 8),

          // Purpose + Price + Paid Badge
          if (!isRejected) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _infoRow(
                    "Purpose",
                    "${item['purpose'] ?? 'N/A'} (₱${item['price'] ?? '0.00'})",
                  ),
                ),
                
              ],
            ),
          ],

          const SizedBox(height: 8),

          // Rejection Reason if any
          if (isRejected)
            _infoRow(
              "Rejection Reason",
              item['rejection_reason'] ?? 'N/A',
              color: Colors.redAccent,
            ),
        ],
      ),
    ),
  );
}



String _formatDate(String? dateStr) {
  if (dateStr == null || dateStr.isEmpty) return 'Not available';

  try {
    // Parse and convert to local time
    DateTime dt = DateTime.parse(dateStr).toLocal();

    // Format the date
    return DateFormat('MMMM d, yyyy – h:mm a').format(dt); // ex: November 13, 2025 – 2:30 PM
  } catch (e) {
    // Fallback to original string if parsing fails
    return dateStr;
  }
}


  Widget _infoRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: Text(
              "$label:",
              style: TextStyle(
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,fontSize: 13
              ),
            ),
          ),
          Expanded(
            flex: 5,
            child: Text(
              value,
              style: TextStyle(
                color: color ?? Colors.black87,
                fontWeight: FontWeight.w600,fontSize: 13
              ),
            ),
          ),
        ],
      ),
    );
  }

@override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: Colors.transparent, // Let gradient show through
    // Conditional AppBar
   appBar: widget.filter == null
    ? null // We'll show CustomHeader inside the body
    : AppBar(
        backgroundColor: Colors.blue,
        title: Text(
          widget.filter == 'pending'
              ? "Pending Requests"
              : widget.filter == 'completed'
                  ? "Completed Requests"
                  : widget.filter == 'rejected'
                      ? "Rejected Requests"
                      : "Concerns",
          style: const TextStyle(color: Colors.white),
        ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
    body: Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.blue.shade200,
                Colors.blue.shade50,
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Column(
            children: [
              // Use CustomHeader only if filter is null
              if (widget.filter == null)
                const CustomHeader(title: "Transaction"),

              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _history.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(Icons.history, size: 60, color: Colors.grey),
                                SizedBox(height: 12),
                                Text(
                                  "No history found.",
                                  style: TextStyle(color: Colors.grey, fontSize: 16),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _fetchHistory,
                            color: const Color(0xFF1565C0),
                            displacement: 80,
                            child: Builder(
                              builder: (context) {
                                List<dynamic> filteredHistory = widget.filter == null
                                    ? _history
                                    : _history
                                        .where((h) => h['status'] == widget.filter)
                                        .toList();

                                return ListView.builder(
                                  physics: const AlwaysScrollableScrollPhysics(),
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 12, horizontal: 16),
                                  itemCount: filteredHistory.length,
                                  itemBuilder: (context, index) {
                                    return _buildHistoryCard(filteredHistory[index]);
                                  },
                                );
                              },
                            ),
                          ),
              ),
            ],
          ),
        ),

        // FAQ Button
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
  );
}
}