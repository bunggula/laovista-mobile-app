import 'dart:convert';
import 'dart:io';
import 'package:Laovista/api_service.dart';
import 'package:Laovista/config.dart';
import 'package:Laovista/pages/ChangePasswordPage.dart';
import 'package:Laovista/pages/custom_header.dart';
import 'package:Laovista/pages/faq_page.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'edit_profile_page.dart';
import 'login_page.dart';

class Profile extends StatefulWidget {
  final int barangayId;

  const Profile({Key? key, required this.barangayId}) : super(key: key);

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  Map<String, dynamic>? profile;
  List<dynamic> faqItems = [];
  File? _profileImage;
  final ImagePicker _picker = ImagePicker();
  String? barangayName; // ✅ holds fetched barangay name

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _loadBarangayName();
     fetchFaq(); // ✅ fetch barangay name
  }

  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    if (token == null || token.isEmpty) {
      debugPrint('❌ No token found.');
      return;
    }

    try {
      final api = ApiService();
      final profileData = await api.getProfile(token);
      debugPrint('✅ Profile fetched: $profileData');

      setState(() => profile = profileData);
      await prefs.setString('profile', jsonEncode(profileData));
    } catch (e) {
      debugPrint('❌ Failed to load profile: $e');
    }
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
  // ✅ Barangay name loader
  Future<void> _loadBarangayName() async {
    try {
      final barangays = await ApiService().getBarangays();
      final matched = barangays.firstWhere(
        (b) => b['id'] == widget.barangayId,
        orElse: () => null,
      );
      if (matched != null) {
        setState(() {
          barangayName = matched['name'];
        });
      }
    } catch (e) {
      debugPrint('❌ Failed to load barangay name: $e');
    }
  }

  void _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    debugPrint('👋 Logged out, cleared SharedPreferences');

    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => LoginPage()),
      (route) => false,
    );
  }

  void _navigateToEditProfile() async {
    if (profile == null) return;

    final updated = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditProfilePage(profile: profile!),
      ),
    );

    if (updated != null) {
      setState(() => profile = updated);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('profile', jsonEncode(updated));
      debugPrint('✏️ Profile updated and saved.');
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() => _profileImage = File(pickedFile.path));

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token != null && token.isNotEmpty) {
        try {
          final api = ApiService();
          final result = await api.uploadProfilePicture(
            token: token,
            file: pickedFile,
          );

          if (result['success'] == true) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('✅ Profile picture uploaded!')),
            );
            await _loadProfile();
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('❌ Upload failed: ${result['message']}')),
            );
          }
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('❌ Error uploading image: $e')),
          );
        }
      } else {
        debugPrint('❌ Token missing when uploading image.');
      }
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '—';
    try {
      final date = DateTime.parse(dateStr);
      const months = [
        'January',
        'February',
        'March',
        'April',
        'May',
        'June',
        'July',
        'August',
        'September',
        'October',
        'November',
        'December'
      ];
      String monthName = months[date.month - 1];
      return '$monthName ${date.day}, ${date.year}';
    } catch (e) {
      return dateStr;
    }
  }

 @override
Widget build(BuildContext context) {
  if (profile == null) {
    return const Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(child: CircularProgressIndicator()),
    );
  }

 return Scaffold(
  backgroundColor: Colors.transparent,
  body: Stack(
    children: [
      // Existing gradient + content
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
            const CustomHeader(title: "My Profile"),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadProfile,
                color: const Color(0xFF1565C0),
                displacement: 70,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildProfileHeader(),
                      const SizedBox(height: 30),
                      _buildInfoCard(),
                      const SizedBox(height: 40),
                      _buildSettingsButton(),
                    ],
                  ),
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
            child: const Icon(Icons.help_outline, color: Colors.white, size: 20,),
          ),
        ),
      ),
    ],
  ),
);

}


  Widget _buildProfileHeader() {
    final rawUrl = profile?['profile_picture'];
    final profilePictureUrl = (rawUrl != null && rawUrl.isNotEmpty)
        ? '${AppConfig.base}/$rawUrl'
        : null;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              CircleAvatar(
                radius: 60,
                backgroundColor: Colors.grey[300],
                backgroundImage: _profileImage != null
                    ? FileImage(_profileImage!)
                    : (profilePictureUrl != null && profilePictureUrl.isNotEmpty
                        ? NetworkImage(profilePictureUrl) as ImageProvider
                        : null),
                child: (_profileImage == null &&
                        (profilePictureUrl == null || profilePictureUrl.isEmpty))
                    ? Icon(Icons.person, size: 60, color: Colors.grey[600])
                    : null,
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Material(
                  color: Colors.blue.shade700,
                  shape: const CircleBorder(),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(30),
                    onTap: _pickImage,
                    child: const Padding(
                      padding: EdgeInsets.all(8),
                      child:
                          Icon(Icons.camera_alt, color: Colors.white, size: 20),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '${profile!['first_name']} ${profile!['middle_name'] ?? ''} ${profile!['last_name']}'
                .replaceAll(RegExp(r'\s+'), ' ')
                .trim(),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1565C0),
              letterSpacing: 0.5,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 6),
          if (profile!['email'] != null &&
              profile!['email'].toString().isNotEmpty)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF1565C0).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                profile!['email'],
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF1565C0),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 6,
      shadowColor: Colors.blue.withOpacity(0.2),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.info_outline, color: Color(0xFF1565C0), size: 26),
                SizedBox(width: 8),
                Text(
                  "Basic Information",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1565C0),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            const Divider(height: 1, thickness: 1.2),
            const SizedBox(height: 18),
            _infoTile("Phone", profile!['phone']),
            const SizedBox(height: 12),
            _infoTile("Birthdate", _formatDate(profile!['birthdate'])),
            const SizedBox(height: 12),
            _infoTile("Gender", profile!['gender']),
            const SizedBox(height: 12),
            _infoTile("Civil Status", profile!['civil_status']),
            const SizedBox(height: 12),
             // 🏡 Barangay name (NEW)
          _infoTile("Barangay", barangayName ?? "—"),
          ],
        ),
      ),
    );
  }

  Widget _infoTile(String label, String? value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F7FB),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Color(0xFF1565C0),
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value == null || value.isEmpty ? '—' : value,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black87,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsButton() {
  return Align(
    alignment: Alignment.center,
    child: FractionallySizedBox(
      widthFactor: 0.5, // ✅ 50% ng screen width, automatic resize sa different devices
      child: ElevatedButton(
        onPressed: () {
         showModalBottomSheet(
  context: context,
  isScrollControlled: true, // ✅ allows the sheet to expand and scroll
  backgroundColor: Colors.transparent,
  shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
  ),
  builder: (_) => DraggableScrollableSheet(
    expand: false, // ✅ so it doesn't force full height
    initialChildSize: 0.35, // 35% of screen height initially
    minChildSize: 0.2,
    maxChildSize: 0.8,
    builder: (_, scrollController) => Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      child: SingleChildScrollView(
        controller: scrollController, // ✅ attach scroll controller
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _settingsCard(
              icon: Icons.edit,
              color: Colors.blue,
              label: "Edit Profile",
              onTap: () {
                Navigator.pop(context);
                _navigateToEditProfile();
              },
            ),
            _settingsCard(
              icon: Icons.lock,
              color: Colors.orange,
              label: "Change Password",
              onTap: () async {
                Navigator.pop(context);
                final prefs = await SharedPreferences.getInstance();
                final token = prefs.getString('auth_token');
                if (token != null && token.isNotEmpty) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChangePasswordPage(token: token),
                    ),
                  );
                }
              },
            ),
            _settingsCard(
              icon: Icons.logout,
              color: Colors.red,
              label: "Logout",
              onTap: () {
                Navigator.pop(context);
                _logout();
              },
            ),
          ],
        ),
      ),
    ),
  ),
);

        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue.shade700,
          foregroundColor: Colors.white,
          elevation: 6,
          shadowColor: Colors.black45,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min, // ✅ centers content without forcing full width
          children: [
            Icon(Icons.settings, size: 18),
            SizedBox(width: 8),
            Flexible(
              child: Text(
                "Settings",
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                overflow: TextOverflow.ellipsis, // ✅ ensures text won't overflow
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

Widget _settingsCard({
  required IconData icon,
  required Color color,
  required String label,
  required VoidCallback onTap,
}) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14), // ✅ flexible padding
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color,
            radius: 18, // ✅ slightly smaller for better fit
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
}
