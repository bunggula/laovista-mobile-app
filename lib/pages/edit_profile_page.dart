import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:awesome_dialog/awesome_dialog.dart';

import '../config.dart';

const String kAuthTokenKey = 'auth_token';
const String baseUrl = AppConfig.apiBaseUrl;

class EditProfilePage extends StatefulWidget {
  final Map<String, dynamic> profile;

  const EditProfilePage({Key? key, required this.profile}) : super(key: key);

  @override
  _EditProfilePageState createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  late final TextEditingController _firstNameController;
  late final TextEditingController _middleNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _ageController;
  late final TextEditingController _zoneController;

  String? _gender;
  String? _birthdate;
  String? _civilStatus;
  String? _voterStatus;
  List<String> _categories = [];

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _firstNameController =
        TextEditingController(text: widget.profile['first_name'] ?? '');
    _middleNameController =
        TextEditingController(text: widget.profile['middle_name'] ?? '');
    _lastNameController =
        TextEditingController(text: widget.profile['last_name'] ?? '');
    _emailController =
        TextEditingController(text: widget.profile['email'] ?? '');
    _phoneController =
        TextEditingController(text: widget.profile['phone'] ?? '');
    _ageController =
        TextEditingController(text: widget.profile['age']?.toString() ?? '');
    _zoneController =
        TextEditingController(text: widget.profile['zone']?.toString() ?? '');
    _gender = widget.profile['gender'];
    _birthdate = widget.profile['birthdate'];
    _civilStatus = widget.profile['civil_status'];
    _voterStatus = widget.profile['voter'] ?? 'No';

    final profileCategories = widget.profile['category'];
    if (profileCategories is String && profileCategories.isNotEmpty) {
      _categories =
          profileCategories.split(',').map((e) => e.trim()).toList();
    }

    final age = int.tryParse(widget.profile['age']?.toString() ?? '0') ?? 0;
    if (age > 60 && !_categories.contains('Senior Citizen')) {
      _categories.add('Senior Citizen');
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _middleNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _ageController.dispose();
    _zoneController.dispose();
    super.dispose();
  }

Future<void> _saveChanges() async {
  try {
    setState(() => _isSaving = true);

    // ✅ Basic validation (Categories are now optional)
    if (_firstNameController.text.isEmpty ||
        _lastNameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _phoneController.text.length != 11 ||
        _zoneController.text.isEmpty ||
        _gender == null ||
        _birthdate == null ||
        _civilStatus == null ||
        _voterStatus == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ Please complete all required fields.')),
      );
      setState(() => _isSaving = false);
      return;
    }

    // ✅ Get stored token
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(kAuthTokenKey);

    if (token == null || token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('🔒 You are not logged in.')),
      );
      setState(() => _isSaving = false);
      return;
    }

    final id = widget.profile['id'];

    // ✅ Prepare updated data (categories optional)
    final updatedProfile = {
      'first_name': _firstNameController.text,
      'middle_name': _middleNameController.text,
      'last_name': _lastNameController.text,
      'email': _emailController.text,
      'phone': _phoneController.text,
      'gender': _gender,
      'birthdate': _birthdate,
      'age': int.tryParse(_ageController.text) ?? 0,
      'civil_status': _civilStatus,
      'zone': _zoneController.text,
      'voter': _voterStatus,
      'category': _categories.isEmpty ? null : _categories.join(','), // ✅ optional
    };

    // ✅ Send request
    final response = await http.put(
      Uri.parse('$baseUrl/residents/$id'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode(updatedProfile),
    );

    // ✅ Handle response
    if (response.statusCode == 200) {
      final updated = jsonDecode(response.body)['resident'];
      await prefs.setString('profile', jsonEncode(updated));

      if (!mounted) return;
      setState(() => _isSaving = false);

      AwesomeDialog(
        context: context,
        dialogType: DialogType.success,
        animType: AnimType.scale,
        title: 'Success',
        desc: 'Profile updated successfully!',
        btnOkOnPress: () {
          Navigator.pop(context, updated);
        },
      ).show();
    } else {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Failed to update: ${response.body}')),
      );
    }
  } catch (e) {
    setState(() => _isSaving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('⚠️ An error occurred: $e')),
    );
  }
}

  int _calculateAge(DateTime birthDate) {
    final now = DateTime.now();
    int age = now.year - birthDate.year;
    if (now.month < birthDate.month ||
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    return age;
  }

 Widget _buildCategoryChecklist() {
  final age = int.tryParse(_ageController.text) ?? 0;
 final Map<String, String> categoryOptions = {
  "PWD": "Person with Disability",
  "Senior Citizen": "Senior Citizen",
  "Indigenous": "Indigenous People",
  "Solo Parent": "Single Parent",
};


  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'Categories *',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 8),
      ...categoryOptions.entries.map((entry) {
        final key = entry.key;      // internal value
        final display = entry.value; // user-friendly display
        final isSenior = key == 'Senior Citizen';
        bool isChecked = _categories.contains(key);
        bool isDisabled = false;

        if (isSenior) {
          if (age >= 60) {
            isChecked = true;
            isDisabled = false; // allow uncheck if needed
          } else {
            isChecked = false;
            isDisabled = true;  // lock if under 60
          }
        }

        return CheckboxListTile(
          title: Text(display),
          value: isChecked,
          onChanged: isDisabled
              ? null
              : (checked) {
                  setState(() {
                    if (checked == true) {
                      _categories.add(key);
                    } else {
                      _categories.remove(key);
                    }
                  });
                },
        );
      }).toList(),
    ],
  );
}


  @override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: Colors.transparent, // Let gradient show
    appBar: AppBar(
      title: const Text('Edit Profile'),
      backgroundColor: Colors.blue.shade700,
      foregroundColor: Colors.white,
      elevation: 0,
    ),
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
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 6,
          shadowColor: Colors.black26,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _sectionTitle('Personal Information'),
                _buildTextField('First Name *', _firstNameController),
                _buildTextField('Middle Name', _middleNameController),
                _buildTextField('Last Name *', _lastNameController),
                _buildTextField('Email *', _emailController,
                    keyboardType: TextInputType.emailAddress),
                _buildTextField('Phone (11 digits) *', _phoneController,
                    keyboardType: TextInputType.phone,
                    maxLength: 11,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly]),
                _buildTextField('Zone *', _zoneController,
                    keyboardType: TextInputType.number),
                const SizedBox(height: 16),
                _buildDropdownField(
                  label: 'Gender *',
                  value: _gender,
                  items: ['Male', 'Female'],
                  onChanged: (value) => setState(() => _gender = value),
                ),
                const SizedBox(height: 16),
                _buildBirthdateField(),
                const SizedBox(height: 16),
                _buildDropdownField(
                  label: 'Civil Status *',
                  value: _civilStatus,
                  items: ['Single', 'Married', 'Divorced', 'Widowed'],
                  onChanged: (value) => setState(() => _civilStatus = value),
                ),
                const SizedBox(height: 16),
               DropdownButtonFormField<String>(
  value: _voterStatus,
  decoration: InputDecoration(
    labelText: 'Voter Status *',
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    filled: true,
    fillColor: Colors.white,
  ),
  items: ['Yes', 'No'].map((val) {
    return DropdownMenuItem(
      value: val,
      child: Text(val == 'Yes' ? 'Registered' : 'Non-Registered'),
    );
  }).toList(),
  onChanged: (val) => setState(() => _voterStatus = val),
),

                const SizedBox(height: 16),
                _buildCategoryChecklist(),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _saveChanges,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade700,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      textStyle: const TextStyle(fontSize: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 5,
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                              strokeWidth: 3,
                            ),
                          )
                        : const Text('Save Changes'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}


  Widget _buildTextField(String label, TextEditingController controller,
      {TextInputType keyboardType = TextInputType.text,
      int? maxLength,
      List<TextInputFormatter>? inputFormatters}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        maxLength: maxLength,
        inputFormatters: inputFormatters,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Colors.white,
          counterText: '',
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.blueAccent, width: 2),
          ),
        ),
      ),
    );
  }

  Widget _buildDropdownField(
      {required String label,
      required String? value,
      required List<String> items,
      required Function(String?) onChanged}) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.white,
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.blueAccent, width: 2),
        ),
      ),
      items: items.map((item) {
        return DropdownMenuItem(value: item, child: Text(item));
      }).toList(),
      onChanged: onChanged,
    );
  }

Widget _buildBirthdateField() {
  String displayText = '';
  if (_birthdate != null && _birthdate!.isNotEmpty) {
    DateTime? dt = DateTime.tryParse(_birthdate!);
    if (dt != null) {
      displayText = DateFormat('MMMM d, yyyy').format(dt); // September 20, 1998
    }
  }

  return TextField(
    controller: TextEditingController(text: displayText),
    readOnly: true,
    decoration: InputDecoration(
      labelText: 'Birthdate *',
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      filled: true,
      fillColor: Colors.white,
      suffixIcon: const Icon(Icons.calendar_today),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.blueAccent, width: 2),
      ),
    ),
    onTap: () async {
      final picked = await showDatePicker(
        context: context,
        initialDate: DateTime.tryParse(_birthdate ?? '') ?? DateTime(2000),
        firstDate: DateTime(1900),
        lastDate: DateTime.now(),
      );
      if (picked != null) {
        final age = _calculateAge(picked);
        setState(() {
          _birthdate = picked.toIso8601String().split('T')[0]; // for backend
          _ageController.text = age.toString();
          if (age >= 60) {
            if (!_categories.contains('Senior Citizen')) {
              _categories.add('Senior Citizen');
            }
          } else {
            _categories.remove('Senior Citizen');
          }
        });
      }
    },
  );
}


  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 10),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: const TextStyle(
              fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
        ),
      ),
    );
  }
}
