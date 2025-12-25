import 'dart:convert';
import 'dart:io';
import 'package:Laovista/config.dart';
import 'package:Laovista/pages/models/announcement.dart';
import 'package:Laovista/pages/models/document_history.dart';
import 'package:Laovista/pages/models/event.dart';
import 'package:Laovista/pages/models/faq.dart';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';

import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'pages/models/format.dart';

class ApiService {
  static const String baseUrl = AppConfig.apiBaseUrl; 

Future<Map<String, dynamic>> loginResident(String email, String password) async {
  final url = Uri.parse('$baseUrl/login');
  print("🔌 Trying to login to $url with email=$email"); // debug

  final response = await http.post(
    url,
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'email': email, 'password': password}),
  );

  print("📡 Response Status: ${response.statusCode}");
  print("📩 Response Body: ${response.body}");

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    print("✅ Login success, token: ${data['token']}");
    if (data.containsKey('token')) {
      return data;
    } else {
      throw Exception('Token not found in response');
    }
  } else if (response.statusCode == 403) {
    print("❌ Account not approved response detected");
    throw Exception('Account not approved');
  } else if (response.statusCode == 423) {
    print("❌ Account archived response detected");
    throw Exception('Account archived');
  } else if (response.statusCode == 422) {
    final error = jsonDecode(response.body);
    print("⚠️ Validation error: $error");
    throw Exception(error['message'] ?? 'Validation error');
  } else if (response.statusCode == 401) {
    print("❌ Invalid credentials");
    throw Exception('Invalid credentials');
  } else {
    print("🚨 Unexpected error: Code=${response.statusCode}, Body=${response.body}");
    throw Exception('Login failed. Code: ${response.statusCode}');
  }
}


  Future<Map<String, dynamic>> registerResident(Map<String, dynamic> formData) async {
    final url = Uri.parse('$baseUrl/register');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(formData),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else if (response.statusCode == 422) {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Validation error');
    } else {
      throw Exception('Registration failed: ${response.statusCode}');
    }
  }

  Future<List<dynamic>> getBarangays() async {
    final url = Uri.parse('$baseUrl/barangays');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load barangays');
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    print("📨 [DEBUG] Sending password reset email to: $email");
    print("🌐 [DEBUG] Endpoint: $baseUrl/forgot-password");

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/forgot-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );

      print("📩 [DEBUG] Response Status: ${response.statusCode}");
      print("📨 [DEBUG] Response Body: ${response.body}");

      if (response.statusCode == 200) {
        print("✅ [SUCCESS] Reset link sent successfully!");
      } else {
        final error = jsonDecode(response.body);
        print("❌ [FAILED] Reset link request failed: ${error['message'] ?? response.body}");
        throw Exception(error['message'] ?? 'Failed to send reset link');
      }
    } catch (e) {
      print("💥 [ERROR] Exception while sending reset link: $e");
      rethrow;
    }
  }

  /// 🔹 Reset Password
  Future<void> resetPassword({
    required String email,
    required String token,
    required String password,
    required String passwordConfirmation,
  }) async {
    print("🔁 [DEBUG] Sending password reset request...");
    print("📧 [DEBUG] Email: $email");
    print("🔑 [DEBUG] Token: $token");
    print("🔐 [DEBUG] New Password: $password");
    print("🌐 [DEBUG] Endpoint: $baseUrl/reset-password");

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/reset-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'token': token,
          'password': password,
          'password_confirmation': passwordConfirmation,
        }),
      );

      print("📩 [DEBUG] Response Status: ${response.statusCode}");
      print("📨 [DEBUG] Response Body: ${response.body}");

      if (response.statusCode == 200) {
        print("✅ [SUCCESS] Password reset successfully!");
      } else {
        final error = jsonDecode(response.body);
        print("❌ [FAILED] Password reset failed: ${error['message'] ?? response.body}");
        throw Exception(error['message'] ?? 'Password reset failed');
      }
    } catch (e) {
      print("💥 [ERROR] Exception while resetting password: $e");
      rethrow;
    }
  }

Future<List<Announcement>> fetchAnnouncements({int? barangayId, String? role}) async {
  final uri = Uri.parse('$baseUrl/announcements').replace(
    queryParameters: {
      'barangay_id': barangayId?.toString() ?? '',
      'role': role ?? '',
    },
  );

  print('📡 Fetching announcements from: $uri');
  final response = await http.get(uri);
  print('📦 Raw response: ${response.body}');

  if (response.statusCode == 200) {
    final List data = jsonDecode(response.body);

    print('✅ Total announcements received (after backend filter): ${data.length}');

    final now = DateTime.now();
    print('🕒 Current time: $now');

    for (var item in data) {
      final date = item['date'];
      final time = item['time'];

      // Combine date + time into DateTime for checking
      DateTime? eventDateTime;
      try {
        eventDateTime = DateTime.parse('$date $time');
      } catch (e) {
        print('⚠️ Failed to parse date/time for ${item['title']}: $e');
      }

      if (eventDateTime != null) {
        final isPast = eventDateTime.isBefore(now);
        print(
          '🔍 Announcement: "${item['title']}" '
          '| DateTime: $eventDateTime '
          '| ${isPast ? '⛔ PAST (should be hidden)' : '✅ UPCOMING/ACTIVE'}'
        );
      } else {
        print('❓ Skipping invalid date for ${item['title']}');
      }
    }

    return data.map((json) => Announcement.fromJson(json)).toList();
  } else {
    print('❌ Failed with status: ${response.statusCode}');
    throw Exception('Failed to load announcements');
  }
}


Future<List<Event>> fetchEvents({required int barangayId}) async {
  final uri = Uri.parse('$baseUrl/events').replace(
    queryParameters: {'barangay_id': barangayId.toString()},
  );

  print('🌐 Fetching Events for Barangay ID: $barangayId');
  print('📡 GET $uri');

  final response = await http.get(uri);

  print('📡 EVENTS STATUS: ${response.statusCode}');
  print('📦 EVENTS BODY RAW: ${response.body}');

  if (response.statusCode == 200) {
    final List<dynamic> data = json.decode(response.body);

    print('✅ TOTAL EVENTS RECEIVED: ${data.length}');
    if (data.isEmpty) print('⚠️ No events found.');

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    print('🕒 Current Date: ${DateFormat('yyyy-MM-dd').format(now)}');

    for (var i = 0; i < data.length; i++) {
      final event = data[i];
      final eventDateStr = event['date'];
      DateTime? eventDate;

      try {
        eventDate = DateTime.parse(eventDateStr);
      } catch (e) {
        print('⚠️ Invalid date format for event "${event['title']}": $eventDateStr');
      }

      final isUpcoming = eventDate != null && !eventDate.isBefore(today);

      print(
        '📅 EVENT #${i + 1} → '
        'Title: ${event['title']} | '
        'Date: ${event['date']} | '
        'Time: ${event['time']} | '
        'Venue: ${event['venue']} | '
        'Barangay ID: ${event['barangay_id']} | '
        '${isUpcoming ? '✅ UPCOMING' : '⛔ PAST EVENT'}',
      );

      // Debug each image path
      if (event['images'] != null && event['images'] is List) {
        for (var img in event['images']) {
          if (img is Map && img.containsKey('path')) {
            print('   🖼 IMAGE PATH: ${img['path']}');
          } else {
            print('   ⚠️ Unknown image format: $img');
          }
        }
      } else {
        print('   ⚠️ No images found for this event');
      }
    }

    // Map to Event objects
    final events = data.map((json) => Event.fromJson(json)).toList();

    // Filter events: today or future only
    final filteredEvents = events.where((event) {
      try {
        final eventDate = DateTime.parse(event.date);
        return !eventDate.isBefore(today); // today o future
      } catch (_) {
        return false;
      }
    }).toList();

    print('🎯 FINAL EVENTS DISPLAYED: ${filteredEvents.length}');
    return filteredEvents;
  } else {
    print('❌ Failed to load events. Status code: ${response.statusCode}');
    throw Exception('Failed to load events');
  }
}




Future<List<dynamic>> fetchBarangayDocuments(int barangayId, String token) async {
  final url = Uri.parse('$baseUrl/resident/documents?barangay_id=$barangayId');

  print('📡 Fetching barangay documents from: $url');
  print('🛡️ Using token: $token');

  try {
    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    print('📌 Response status: ${response.statusCode}');
    print('📦 Response body: ${response.body}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      print('✅ Parsed ${data.length} documents');
      return data;
    } else {
      print('❌ Failed to fetch documents. Status code: ${response.statusCode}');
      throw Exception('Failed to fetch documents: ${response.statusCode}');
    }
  } catch (e) {
    print('🚨 Error fetching documents: $e');
    rethrow;
  }
}


Future<Map<String, dynamic>> getDocumentFields({
  required String token,
  required String documentId,
}) async {
  final url = Uri.parse('$baseUrl/documents/$documentId/fields');
  print('📡 GET Request URL: $url');
  print('🛡️ Token: $token');

  final response = await http.get(
    url,
    headers: {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    },
  );

  print('📌 Response Status: ${response.statusCode}');
  print('📦 Response Body: ${response.body}');

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    print('✅ Parsed Data: $data');
    print('🔹 Full API Response: ${response.body}');
    return data;
  } else {
    print('❌ Error: Failed to load document fields');
    throw Exception('Failed to load document fields');
  }
  
}



Future<Map<String, dynamic>> getProfile(String token) async {
  final url = Uri.parse('$baseUrl/resident/profile');
  final response = await http.get(
    url,
    headers: {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    },
  );

  if (response.statusCode == 200) {
    return jsonDecode(response.body);
  } else {
    throw Exception('Failed to fetch profile');
  }
}
Future<http.Response> submitDocumentRequest({
  required String token,
  required int barangayId,
  required String title,
  Map<String, dynamic>? fields,
  String? templateKey,
  String? purpose,
  String? price,
   bool isCustomPurpose = false,
  bool force = false, // ✅ optional flag
}) async {
  final url = Uri.parse('$baseUrl/document-requests');

  final body = {
    'barangay_id': barangayId,
    'title': title,
    if (templateKey != null) 'template_key': templateKey,
    if (fields != null) 'form_data': fields,
    if (purpose != null) 'purpose': purpose,
    if (price != null) 'price': price,
        'is_custom_purpose': isCustomPurpose, 
    if (force) 'force': true, // ✅ only add if true
  };

  print('📤 Sending Document Request...');
  print('🌐 URL: $url');
  print('🛡️ Token: $token');
  print('📝 Request Body: ${jsonEncode(body)}');
  print('💡 isCustomPurpose value: $isCustomPurpose');

  final response = await http.post(
    url,
    headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    },
    body: jsonEncode(body),
  );

  print('✅ Response Status: ${response.statusCode}');
  print('📦 Response Body: ${response.body}');

  return response;
}

Future<bool> checkDuplicate({
  required String token,
  required int residentId,
  required String documentType,
}) async {
  final url = Uri.parse(
      '$baseUrl/document-requests/check-duplicate?resident_id=$residentId&document_type=$documentType');

  print('📤 Checking duplicate...');
  print('🌐 URL: $url');
  print('🛡️ Token: $token');

  final response = await http.get(
    url,
    headers: {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    },
  );

  print('✅ Response Status: ${response.statusCode}');
  print('📦 Response Body: ${response.body}');

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    return data['has_duplicate'] ?? false;
  } else {
    throw Exception('Failed to check duplicate (${response.statusCode})');
  }
}


Future<Map<String, dynamic>> fetchProfile(String token) async {
  final url = Uri.parse('$baseUrl/resident/profile'); // correct endpoint
  try {
    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    print('📡 GET URL: $url');
    print('✅ Status: ${response.statusCode}');
    print('📦 Response: ${response.body}');

    if (response.statusCode == 200) {
      return jsonDecode(response.body); // returns the profile map
    } else {
      throw Exception('Failed to load profile: ${response.body}');
    }
  } catch (e) {
    print('🚨 Error fetching profile: $e');
    throw Exception('Error: $e');
  }
}

Future<List<DocumentHistory>> fetchDocumentHistory(String token) async {
  final url = Uri.parse('$baseUrl/document-requests/history');
  
  print('📥 Fetching document history from: $url');
  print('🪪 Using token: $token');

  try {
    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    print("📡 API response status: ${response.statusCode}");
    print("📄 API response body: ${response.body}");

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      print('🧐 Decoded type: ${decoded.runtimeType}');
      print('🧐 Decoded content: $decoded');

      // Determine if it's a list or a map with 'data'
      final List data;
      if (decoded is List) {
        data = decoded;
      } else if (decoded is Map && decoded.containsKey('data') && decoded['data'] is List) {
        data = decoded['data'];
      } else {
        print('⚠️ Unexpected API response format');
        data = [];
      }

      print("✅ Parsed data length: ${data.length}");
      if (data.isEmpty) print("⚠️ Document history is empty!");

      final historyList = data.map((item) {
        print("🔄 Mapping item: $item");
        try {
          final doc = DocumentHistory.fromJson(item);
          print("   ✅ Mapped DocumentHistory: ${doc.referenceCode}, Status: ${doc.status}");
          return doc;
        } catch (e) {
          print("❌ Failed to map item: $e");
          return null;
        }
      }).whereType<DocumentHistory>().toList();

      print("🎯 Total mapped DocumentHistory items: ${historyList.length}");
      return historyList;
    } else {
      print("❌ Failed to fetch history. Status: ${response.statusCode}");
      print("❗ Body: ${response.body}");
      throw Exception('Failed to load document history: ${response.body}');
    }
  } catch (e) {
    print("🚨 Exception during fetchDocumentHistory: $e");
    rethrow;
  }
}



Future<Map<String, dynamic>> registerResidentWithProof(
  Map<String, dynamic> data,
  XFile file,
  String token,
) async {
  try {
    final formData = FormData.fromMap({
      ...data.map((key, value) => MapEntry(key, value.toString())),
      'proof': await MultipartFile.fromFile(file.path, filename: file.name),
    });

    print("📤 Sending request to: $baseUrl/register-with-proof");
    print("📦 Form Data: ${formData.fields.map((e) => '${e.key}: ${e.value}').join(', ')}");
    print("📎 File Path: ${file.path}");

    final response = await Dio().post(
      '$baseUrl/register-with-proof',
      data: formData,
      options: Options(headers: {
        'Content-Type': 'multipart/form-data',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      }),
    );

    print("✅ Response Status: ${response.statusCode}");
    print("📨 Response Data: ${response.data}");

    if (response.statusCode == 200 || response.statusCode == 201) {
      return {'success': true, 'data': response.data};
    } else {
      return {'success': false, 'message': 'Registration failed with status code ${response.statusCode}'};
    }
  } on DioException catch (e) {
    print("🚨 DioException occurred");
    print("❌ Status Code: ${e.response?.statusCode}");
    print("❌ Response Data: ${e.response?.data}");

    if (e.response?.statusCode == 422 && e.response?.data != null) {
      return {
        'success': false,
        'validationErrors': e.response!.data['errors'],
        'message': e.response!.data['message'] ?? 'Validation failed',
      };
    }

    return {
      'success': false,
      'message': e.message ?? 'Unexpected Dio error',
    };
  } catch (e) {
    print("🛑 Unknown error: $e");
    return {
      'success': false,
      'message': 'Unexpected error: $e',
    };
  }
}

Future<Map<String, dynamic>> uploadProfilePicture({
  required String token,
  required XFile file,
}) async {
  try {
    final formData = FormData.fromMap({
      'image': await MultipartFile.fromFile(file.path, filename: file.name),
    });

    final response = await Dio().post(
      '$baseUrl/resident/upload-profile-picture',
      data: formData,
      options: Options(headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'multipart/form-data',
        'Accept': 'application/json',
      }),
    );

    print("📤 Upload Response Status: ${response.statusCode}");
    print("📦 Upload Response Data: ${response.data}");

    if (response.statusCode == 200 || response.statusCode == 201) {
      return {
        'success': true,
        'data': response.data,
      };
    } else {
      return {
        'success': false,
        'message': 'Upload failed with status ${response.statusCode}',
      };
    }
  } catch (e) {
    print("❌ Upload error: $e");
    return {
      'success': false,
      'message': 'Upload error: $e',
    };
  }
}
Future<Map<String, dynamic>> sendConcern({
  required String token,
  required int barangayId,
  required String title,
  required String description,
  required String zone,
  required String street,
  XFile? image,
}) async {
  var uri = Uri.parse('$baseUrl/concerns');

  print('🔁 Preparing request to $uri');
  print('📦 Data:');
  print(' - Barangay ID: $barangayId');
  print(' - Title: $title');
  print(' - Description: $description');
  print(' - Zone: $zone');
  print(' - Street: $street');
  if (image != null) print(' - Image: ${image.path}');

  var request = http.MultipartRequest('POST', uri)
    ..headers['Authorization'] = 'Bearer $token'
    ..headers['Accept'] = 'application/json' // ✅ Add this to avoid HTML response
    ..fields['barangay_id'] = barangayId.toString()
    ..fields['title'] = title
    ..fields['description'] = description
    ..fields['zone'] = zone
    ..fields['street'] = street;

  if (image != null) {
    final file = await http.MultipartFile.fromPath('image', image.path);
    request.files.add(file);
  }

  try {
    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    print('✅ Response Status: ${response.statusCode}');
    print('📥 Response Body: ${response.body}');

    return jsonDecode(response.body);
  } catch (e) {
    print('❌ Error sending concern: $e');
    rethrow;
  }
}
 Future<List<dynamic>> getUserConcerns() async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('auth_token');

  print('🔐 Token: $token');
  print('📡 Sending GET to: $baseUrl/user/concerns');

  final response = await http.get(
    Uri.parse('$baseUrl/user/concerns'),
    headers: {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    },
  );

  print('📥 Response Status: ${response.statusCode}');
  print('📦 Response Body: ${response.body}');

  if (response.statusCode == 200) {
    final data = json.decode(response.body);
    print('✅ Decoded Concerns: ${data['data']}');
    return data['data'];
  } else {
    print('❌ Failed to load concerns. Status: ${response.statusCode}');
    print('❗ Body: ${response.body}');
    throw Exception('❌ Failed to load concerns');
  }
}
Future<Map<String, dynamic>> getDocumentPurposes({
  required String token,
  required String documentId,
}) async {
  final url = Uri.parse('$baseUrl/documents/$documentId/purposes');
  print('📡 GET Purposes URL: $url');

  final response = await http.get(
    url,
    headers: {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    },
  );

  print('📌 Response Status: ${response.statusCode}');
  print('📦 Response Body: ${response.body}');

  if (response.statusCode == 200) {
    return jsonDecode(response.body);
  } else {
    throw Exception('Failed to load purposes');
  }
}

Future<Map<String, dynamic>> updatePassword(String token, String newPassword) async {
  final url = Uri.parse('$baseUrl/resident/change-password');

  print('🔹 Sending password update request to: $url');
  print('🔹 Token: $token');
  print('🔹 New Password: $newPassword');

  final response = await http.post(
    url,
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    },
    body: jsonEncode({
      'new_password': newPassword,
      'new_password_confirmation': newPassword,
    }),
  );

  print('🔹 Response status: ${response.statusCode}');
  print('🔹 Response body: ${response.body}');

  if (response.statusCode == 200) {
    // ✅ Successful update
    final data = jsonDecode(response.body);
    print('✅ Password updated successfully');
    return data;
  } else if (response.statusCode == 422) {
    // ⚠ Validation error
    final error = jsonDecode(response.body);
    print('⚠️ Validation error: ${error['message'] ?? 'Unknown validation error'}');
    throw Exception(error['message'] ?? 'Validation error');
  } else {
    // ❌ Other errors
    throw Exception('Failed to change password: ${response.body}');
  }
}
Future<Map<String, dynamic>> updatePasswordWithOld(
  String token,
  String oldPassword,
  String newPassword,
) async {
  final url = Uri.parse('$baseUrl/resident/change-password-with-old');

  print('🔹 Sending password update (with old) request to: $url');
  print('🔹 Token: $token');
  print('🔹 Old Password: $oldPassword');
  print('🔹 New Password: $newPassword');

  final response = await http.post(
    url,
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    },
    body: jsonEncode({
      'old_password': oldPassword,
      'new_password': newPassword,
      'new_password_confirmation': newPassword,
    }),
  );

  print('🔹 Response status: ${response.statusCode}');
  print('🔹 Response body: ${response.body}');

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    print('✅ Password updated successfully (with old)');
    return data;
  } else if (response.statusCode == 422) {
    final error = jsonDecode(response.body);
    print('⚠️ Validation error: ${error['message'] ?? 'Unknown validation error'}');
    throw Exception(error['message'] ?? 'Validation error');
  } else {
    throw Exception('Failed to change password: ${response.body}');
  }
}
Future<List<Faq>> fetchFaqs(String token) async {
  print('🔐 Token being used for FAQ request: $token'); // ✅ Print token

  final url = Uri.parse('$baseUrl/faqs');
  print('📡 Fetching FAQs from: $url');

  final response = await http.get(
    url,
    headers: {
      'Accept': 'application/json',
      'Authorization': 'Bearer $token', // ✅ kailangan ito
    },
  );

  if (response.statusCode == 200) {
    final decoded = jsonDecode(response.body);
    final List data = decoded['data'] ?? [];
    print('✅ Total FAQs fetched: ${data.length}');
    return data.map((json) => Faq.fromJson(json)).toList();
  } else {
    print('❌ Failed to fetch FAQs: ${response.statusCode}');
    print('Response body: ${response.body}');
    throw Exception('Failed to load FAQs');
  }
}


}
