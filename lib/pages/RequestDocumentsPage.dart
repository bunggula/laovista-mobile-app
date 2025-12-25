import 'package:Laovista/pages/faq_page.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import '../config.dart';
import 'fill_form_page.dart';
import 'custom_header.dart'; // ✅ Added import for your custom header

class RequestDocumentsPage extends StatefulWidget {
  final int barangayId;
  final String token;

  const RequestDocumentsPage({
    Key? key,
    required this.barangayId,
    required this.token,
  }) : super(key: key);

  @override
  State<RequestDocumentsPage> createState() => _RequestDocumentsPageState();
}

class _RequestDocumentsPageState extends State<RequestDocumentsPage> {
  List<dynamic> documents = [];
  bool isLoading = true;
  Map<String, String> userData = {};
  List<dynamic> faqItems = []; // For storing FAQ from API

  @override
  void initState() {
    super.initState();
    fetchAllData();
    fetchFaq(); // fetch FAQ on init
  }

  Future<void> fetchAllData() async {
    await fetchResidentProfile();
    await fetchBarangayName();
    await fetchBarangayOfficials();
    await fetchDocuments();
    setState(() => isLoading = false);
  }

  Future<void> fetchResidentProfile() async {
    final url = Uri.parse('${AppConfig.apiBaseUrl}/resident/profile');
    try {
      final response = await http.get(url, headers: {
        'Authorization': 'Bearer ${widget.token}',
        'Accept': 'application/json',
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        debugPrint('👤 Resident profile fetched: $data');

        userData = {
          'resident_id': data['id']?.toString() ?? '0',
          'first_name': data['first_name'] ?? '',
          'middle_name': data['middle_name'] ?? '',
          'last_name': data['last_name'] ?? '',
          'name':
              '${data['first_name']} ${data['middle_name']} ${data['last_name']}',
          'age': data['age']?.toString() ?? '',
          'birthdate': data['birthdate'] ?? '',
          'address': data['address'] ?? '',
          'civil_status': data['civil_status'] ?? '',
          'gender': data['gender'] ?? '',
          'email': data['email'] ?? '',
          'phone': data['phone'] ?? '',
          'barangay_id': data['barangay_id']?.toString() ?? '',
        };
      } else {
        debugPrint('❌ Failed to fetch profile. Status: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Error fetching profile: $e');
    }
  }

  Future<void> fetchBarangayName() async {
    final url = Uri.parse('${AppConfig.apiBaseUrl}/barangays');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        final barangay = data.firstWhere(
          (b) => b['id'].toString() == userData['barangay_id'],
          orElse: () => null,
        );
        if (barangay != null) {
          userData['barangay_name'] = barangay['name'];
          debugPrint('🏘️ Barangay name fetched: ${userData['barangay_name']}');
        }
      }
    } catch (e) {
      debugPrint('❌ Error fetching barangay name: $e');
    }
  }

  Future<void> fetchBarangayOfficials() async {
    final url = Uri.parse(
        '${AppConfig.apiBaseUrl}/barangay-officials/${userData['barangay_id']}');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        userData['captain'] = data['captain'] ?? '';
        userData['secretary'] = data['secretary'] ?? '';
        debugPrint(
            '🧑‍💼 Officials fetched: Captain=${userData['captain']}, Secretary=${userData['secretary']}');
      }
    } catch (e) {
      debugPrint('❌ Error fetching officials: $e');
    }
  }

  Future<void> fetchDocuments() async {
    final url = Uri.parse(
      '${AppConfig.apiBaseUrl}/resident/documents?barangay_id=${widget.barangayId}',
    );
    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer ${widget.token}',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          documents = jsonDecode(response.body);
        });
        debugPrint('📄 Documents fetched: ${documents.length} items');
      }
    } catch (e) {
      debugPrint('❌ Error fetching documents: $e');
    }
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




  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // --- Main Content ---
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade200, Colors.blue.shade50],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Column(
              children: [
                const CustomHeader(title: "Barangay Services"),
                Expanded(
                  child: isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : documents.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Icon(Icons.description_outlined,
                                      size: 64, color: Colors.grey),
                                  SizedBox(height: 15),
                                  Text(
                                    "No documents available",
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                              itemCount: documents.length,
                              itemBuilder: (context, index) {
                                final doc = documents[index];
                                return Card(
                                  margin: const EdgeInsets.symmetric(vertical: 10),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  elevation: 5,
                                  shadowColor: Colors.black26,
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        CircleAvatar(
                                          radius: 28,
                                          backgroundColor: Colors.blue.shade100,
                                          child: const Icon(
                                            Icons.file_copy_outlined,
                                            size: 28,
                                            color: Color(0xFF1565C0),
                                          ),
                                        ),
                                        const SizedBox(width: 15),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                doc['name'],
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 18,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              const Text(
                                                "Tap to request this document",
                                                style: TextStyle(color: Colors.black54),
                                              ),
                                              const SizedBox(height: 10),
                                              Align(
                                                alignment: Alignment.centerRight,
                                                child: ElevatedButton(
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: const Color(0xFF1565C0),
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius: BorderRadius.circular(10),
                                                    ),
                                                    padding: const EdgeInsets.symmetric(
                                                        horizontal: 20, vertical: 12),
                                                  ),
                                                  onPressed: () {
                                                    Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                        builder: (_) => FillFormPage(
                                                          title: doc['name'],
                                                          initialValues: userData,
                                                          token: widget.token,
                                                          barangayId: widget.barangayId,
                                                          documentId: doc['id'].toString(),
                                                        ),
                                                      ),
                                                    );
                                                  },
                                                  child: const Text(
                                                    "Request",
                                                    style: TextStyle(
                                                        fontSize: 16, color: Colors.white),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                ),
              ],
            ),
          ),

          // --- Floating FAQ Icon at Bottom Left ---
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
          )
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
