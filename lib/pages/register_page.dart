import 'dart:io';
import 'package:Laovista/api_service.dart';
import 'package:Laovista/pages/login_page.dart';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import 'package:shared_preferences/shared_preferences.dart';

class RegisterPage extends StatefulWidget {
  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();

  final _firstName = TextEditingController();
  final _middleName = TextEditingController();
  final _lastName = TextEditingController();
  final _suffix = TextEditingController();
  final _birthdate = TextEditingController();
  final _email = TextEditingController();
   final _phone = TextEditingController(text: "09");
  final _zone = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();
final _otherProof = TextEditingController();

  final FocusNode zoneFocus = FocusNode();
  final FocusNode passwordFocus = FocusNode();
  final FocusNode confirmPasswordFocus = FocusNode();
  final FocusNode phoneFocus = FocusNode();

  String? gender;
  String? civilStatus;
  int? barangayId;
  int age = 0;

  String? voterStatus;
  String? proofType;

  bool isPasswordVisible = false;
  bool isConfirmVisible = false;
  bool categoryExpanded = false;
  bool isLoading = false;

  List<Map<String, dynamic>> barangays = [];
  List<String> selectedCategories = [];

 final Map<String, String> categoryOptions = {
  "PWD": "Person with Disability",
  "Senior": "Senior Citizen",
  "Indigenous": "Indigenous People",
  "SingleParent": "Single Parent",
};

  final List<String> proofOptions = [
    "School ID",
    "National ID",
    "Passport",
    "Driver’s License",
    "Voter’s ID",
    "Other"
  ];

  XFile? _proofFile;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    fetchBarangays();
  }

  void fetchBarangays() async {
    try {
      final data = await _apiService.getBarangays();
      setState(() => barangays = List<Map<String, dynamic>>.from(data));
    } catch (e) {
      print('Barangay fetch error: $e');
    }
  }

void calculateAge(String birthDateStr) {
  print("RAW INPUT: '$birthDateStr'");  // DEBUG

  birthDateStr = birthDateStr.trim();
  print("TRIMMED INPUT: '$birthDateStr'"); // DEBUG

  DateTime birth;

  try {
    birth = DateFormat('yyyy-MM-dd').parseStrict(birthDateStr);
    print("PARSED DATE: $birth"); // DEBUG
  } catch (e) {
    print("PARSE ERROR: $e");
    return;
  }

  final today = DateTime.now();
  print("TODAY: $today"); // DEBUG

  int computedAge = today.year - birth.year;

  if (today.month < birth.month ||
      (today.month == birth.month && today.day < birth.day)) {
    computedAge--;
  }

  print("COMPUTED AGE: $computedAge"); // DEBUG

  setState(() {
    age = computedAge;

    if (age >= 60) {
      if (!selectedCategories.contains("Senior")) {
        selectedCategories.add("Senior");
      }
    } else {
      selectedCategories.remove("Senior");
    }
  });
}



  void pickProofOfResidency({required ImageSource source}) async {
    final pickedImage = await _picker.pickImage(source: source);
    if (pickedImage != null) {
      final file = File(pickedImage.path);
      final compressedBytes = await FlutterImageCompress.compressWithFile(
        file.absolute.path,
        quality: 70,
      );
      if (compressedBytes == null) {
        showMessage("Image compression failed.");
        return;
      }
      final compressedFile = File("${file.path}_compressed.jpg")..writeAsBytesSync(compressedBytes);
      if (await compressedFile.length() > 5 * 1024 * 1024) {
        showMessage("Compressed image is still too large. Try another image.");
        return;
      }
      setState(() => _proofFile = XFile(compressedFile.path));
    }
  }
  void _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    if (_password.text != _confirmPassword.text) {
      confirmPasswordFocus.requestFocus();
      showDialogBox("Password Error", "Passwords do not match.", Icons.error, Colors.red);
      return;
    }

    if (_zone.text.isEmpty) {
      zoneFocus.requestFocus();
      showDialogBox("Zone Required", "Zone is required.", Icons.error, Colors.red);
      return;
    }

    if (voterStatus == null) {
      showDialogBox("Voter Status", "Please select voter status.", Icons.error, Colors.red);
      return;
    }

    if (proofType == null) {
      showDialogBox("Proof Required", "Please select proof of residency type.", Icons.error, Colors.red);
      return;
    }

    if (_proofFile == null) {
      showDialogBox("Proof Missing", "Please upload proof of residency.", Icons.error, Colors.red);
      return;
    }

    // Map voterStatus to backend value
    final voterPayload = (voterStatus == "Registered") ? "Yes" : "No";

    final formData = {
      "first_name": _firstName.text,
      "middle_name": _middleName.text,
      "last_name": _lastName.text,
      "suffix": _suffix.text,
      "gender": gender,
      "birthdate": _birthdate.text,
      "age": age,
      "civil_status": civilStatus,
      "category": selectedCategories.join(','),
      "zone": _zone.text,
      "email": _email.text,
      "phone": _phone.text,
      "barangay_id": barangayId,
      "password": _password.text,
      "status": "pending",
      "voter": voterPayload, // ✅ send correct value
     "proof_type": proofType == "Other" ? _otherProof.text.trim() : proofType,
    };

    try {
      setState(() => isLoading = true);
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      final status = prefs.getString('status');

      if (status == 'approved') {
        showDialogBox(
          "Already Approved",
          "You are already approved. Registration is no longer allowed.",
          Icons.info,
          Colors.blue,
        );
        setState(() => isLoading = false);
        return;
      }

      final result = await _apiService.registerResidentWithProof(formData, _proofFile!, token);
      setState(() => isLoading = false);

   if (result['success'] == true) {
  AwesomeDialog(
    context: context,
    dialogType: DialogType.noHeader,
    animType: AnimType.bottomSlide,
    customHeader: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.green.withOpacity(0.1),
      ),
      child: const Icon(Icons.check_circle, color: Colors.green, size: 60),
    ),
    title: "Success!",
    desc: "Registration successful. Please wait for approval. You will be notified via email.",
    titleTextStyle: const TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.bold,
      color: Colors.black87,
    ),
    descTextStyle: const TextStyle(
      fontSize: 16,
      color: Colors.black54,
      height: 1.4,
    ),
    btnOkText: "Continue",
    btnOkColor: Colors.green,
    btnOkOnPress: () {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => LoginPage()));
    },
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
  ).show();

      } else {
        String message = "Registration failed.";
        if (result['errors'] != null && result['errors'] is Map) {
          final firstError = (result['errors'] as Map).values.first;
          if (firstError is List && firstError.isNotEmpty) message = firstError.first;
        } else if (result['message'] != null) {
          message = result['message'];
        }
        if (message.toLowerCase().contains("email") && message.toLowerCase().contains("taken")) {
          message = "This email is already registered. Please use another one.";
        }
        showDialogBox("Registration Failed", message, Icons.error, Colors.red);
      }
    } catch (e) {
      setState(() => isLoading = false);
      showDialogBox("Unexpected Error", "Error: ${e.toString()}", Icons.error, Colors.red);
    }
  }

void showDialogBox(String title, String desc, IconData icon, Color color) {
  AwesomeDialog(
    context: context,
    dialogType: DialogType.noHeader,
    animType: AnimType.bottomSlide,
    customHeader: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withOpacity(0.1),
      ),
      child: Icon(icon, color: color, size: 60),
    ),
    title: title,
    desc: desc,
    titleTextStyle: const TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.bold,
      color: Colors.black87,
    ),
    descTextStyle: const TextStyle(
      fontSize: 16,
      color: Colors.black54,
      height: 1.4,
    ),
    btnOkText: "OK",
    btnOkColor: color,
    btnOkOnPress: () {},
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
  ).show();
}

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
void showPreviewDialog() {
  // Format the birthdate nicely
  String formattedBirthdate = "";
  if (_birthdate.text.isNotEmpty) {
    try {
      final birthDate = DateFormat('yyyy-MM-dd').parse(_birthdate.text);
      formattedBirthdate = DateFormat('EEEE, MMMM d, yyyy').format(birthDate);
    } catch (_) {
      formattedBirthdate = _birthdate.text;
    }
  }

  showDialog(
    context: context,
    builder: (context) {
      return Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Text(
                    "Confirm Your Details",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[800],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Personal Info
                _buildPreviewRow("Name", "${_firstName.text} ${_middleName.text} ${_lastName.text} ${_suffix.text}"),
                _buildPreviewRow("Gender", gender ?? ""),
                _buildPreviewRow("Birthdate", formattedBirthdate),
                _buildPreviewRow("Age", age.toString()),
                _buildPreviewRow("Civil Status", civilStatus ?? ""),
                _buildPreviewRow("Category", selectedCategories.join(", ")),
                const Divider(height: 24, thickness: 1.2),

                // Contact Info
                _buildPreviewRow("Email", _email.text),
                _buildPreviewRow("Phone", _phone.text),
                _buildPreviewRow("Zone", _zone.text),
                _buildPreviewRow("Barangay", barangayId != null ? barangays.firstWhere((b) => b['id'] == barangayId)['name'] : ""),
                _buildPreviewRow("Voter", voterStatus ?? ""),
                _buildPreviewRow("Proof Type", proofType == "Other" ? _otherProof.text : proofType ?? ""),
                const SizedBox(height: 12),

                // Proof of Residency Image
                if (_proofFile != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Proof of Residency:",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          File(_proofFile!.path),
                          width: double.infinity,
                          height: 200,
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),

                // Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.blue.shade700),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: () => Navigator.pop(context),
                        child: const Text(
                          "Edit",
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[700],
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                          _submitForm();
                        },
                    child: const Text(
  "Register",
  style: TextStyle(
    fontWeight: FontWeight.bold,
    color: Colors.white, 
                        ),
                        
                      ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

  Widget _buildPreviewRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("$label: ", style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
@override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: Colors.transparent, // make scaffold transparent
    body: SafeArea(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade200, Colors.blue.shade50], // match Barangay Services
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(5),
          child: Column(
            children: [
              const SizedBox(height: 20),

              // 🏛 Barangay Logo Section
              AnimatedContainer(
                duration: const Duration(milliseconds: 1),
                curve: Curves.easeOutBack,
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 55,
                      backgroundColor: Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Image.asset('assets/logo.png', width: 75),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      "Barangay Resident Registration",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1565C0),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
              // ...rest of your form remains the same

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Card(
                  color: Colors.white,
                  surfaceTintColor: Colors.white,
                  elevation: 8,
                  shadowColor: Colors.black26,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 28),
                    child: Form(
                      key: _formKey,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionHeader(Icons.person, "Personal Information"),
                          buildTextField(_firstName, "First Name *", textCapitalization: TextCapitalization.words),
                          buildTextField(_middleName, "Middle Name", textCapitalization: TextCapitalization.words),
                          buildTextField(_lastName, "Last Name *", textCapitalization: TextCapitalization.words),
                          buildTextField(_suffix, "Suffix"),
                          buildDropdown("Sex *", ["Male", "Female"], (val) => gender = val, gender),
                          buildDatePickerField(),
                          buildDropdown("Civil Status *", ["Single", "Married", "Widowed", "Separated"], (val) => civilStatus = val, civilStatus),
                          buildCategorySelector(),
                          const SizedBox(height: 16),
                          _buildSectionHeader(Icons.contact_mail, "Contact Information"),
                         buildTextField(
  _email,
  "Email *",
  inputType: TextInputType.emailAddress,
  validator: (val) {
    if (val == null || val.isEmpty) return "Email is required";
    // Strict Gmail validation
    final gmailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@gmail\.com$');
    if (!gmailRegex.hasMatch(val.trim().toLowerCase())) {
      return "Please enter a valid Gmail address (e.g., yourname@gmail.com)";
    }
    return null;
  },
),

                          buildTextField(_phone, "Phone *", inputType: TextInputType.phone, maxLength: 11, focusNode: phoneFocus, validator: (val) {
                            if (val == null || val.isEmpty) return "Phone is required";
                            if (!RegExp(r'^\d{11}$').hasMatch(val)) return "Phone must be 11 digits";
                            return null;
                          }),
                          buildTextField(_zone, "Zone *", inputType: TextInputType.number, focusNode: zoneFocus, validator: (val) {
                            if (val == null || val.isEmpty) return "Zone is required";
                            if (!RegExp(r'^\d+$').hasMatch(val)) return "Zone must be a number";
                            return null;
                          }),
                          buildDropdown(
                            "Barangay *",
                            barangays.map((b) => b['name'].toString()).toList(),
                            (val) {
                              final selected = barangays.firstWhere((b) => b['name'] == val);
                              barangayId = selected['id'];
                            },
                            barangayId != null
                                ? barangays.firstWhere((b) => b['id'] == barangayId)['name']
                                : null,
                          ),
                          buildDropdown("Voter *", ["Registered", "Non Registered"], (val) => voterStatus = val, voterStatus),
                          const SizedBox(height: 16),
                          // 🔐 Security Section
      _buildSectionHeader(Icons.lock, "Security"),

      // Password Field
      buildTextField(
        _password,
        "Password *",
        isPassword: true,
        focusNode: passwordFocus,
        validator: (val) {
          if (val == null || val.isEmpty) return "Password is required";
          if (val.length < 8) return "Password must be at least 8 characters";
          if (!RegExp(r'^(?=.*[A-Z])(?=.*[a-z])(?=.*\d)(?=.*[!@#\$&*~]).+$')
              .hasMatch(val)) {
            return "Must include uppercase, lowercase, number, and symbol";
          }
          return null;
        },
      ),

      // 👇 Live Password Strength Indicator
      ValueListenableBuilder<TextEditingValue>(
        valueListenable: _password,
        builder: (context, value, child) {
          final text = value.text;
          String strengthLabel = "";
          Color color = Colors.grey;

          if (text.isEmpty) {
            strengthLabel = "";
          } else if (text.length < 6) {
            strengthLabel = "Weak";
            color = Colors.red;
          } else if (RegExp(r'(?=.*[A-Z])(?=.*[a-z])(?=.*\d)').hasMatch(text)) {
            strengthLabel = "Medium";
            color = Colors.orange;
          }
          if (text.length >= 8 &&
              RegExp(r'(?=.*[A-Z])(?=.*[a-z])(?=.*\d)(?=.*[!@#\$&*~])')
                  .hasMatch(text)) {
            strengthLabel = "Strong";
            color = Colors.green;
          }

          return Padding(
            padding: const EdgeInsets.only(top: 6, left: 4),
            child: Text(
              strengthLabel.isEmpty
                  ? ""
                  : "Password Strength: $strengthLabel",
              style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          );
        },
      ),

      // Confirm Password
      buildTextField(
        _confirmPassword,
        "Confirm Password *",
        isPassword: true,
        focusNode: confirmPasswordFocus,
        validator: (val) {
          if (val == null || val.isEmpty) return "Please confirm your password";
          if (val != _password.text) return "Passwords do not match";
          return null;
        },
      ),
      const SizedBox(height: 16),

                          _buildSectionHeader(Icons.home, "Proof of Residency"),
                        buildDropdown(
  "Proof of Residency Type *",
  proofOptions,
  (val) {
    setState(() {
      proofType = val;
      if (val != "Other") _otherProof.clear(); // clear field pag hindi Other
    });
  },
  proofType,
),

// ✅ Lumalabas lang kapag "Other" ang napili
if (proofType == "Other")
  Padding(
    padding: const EdgeInsets.only(top: 8.0, bottom: 12.0),
    child: TextFormField(
      controller: _otherProof,
      decoration: InputDecoration(
        labelText: "Please specify other proof *",
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      validator: (val) {
        if (proofType == "Other" && (val == null || val.isEmpty)) {
          return "Please specify your proof of residency";
        }
        return null;
      },
    ),
  ),

                          const SizedBox(height: 10),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue[700],
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            icon: const Icon(Icons.upload_rounded),
                            label: const Text("Upload Proof of Residency"),
                            onPressed: () {
                              showModalBottomSheet(
                                context: context,
                                shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                                ),
                                builder: (context) => _buildPhotoPickerSheet(context),
                              );
                            },
                          ),
                          if (_proofFile != null) ...[
                            const SizedBox(height: 12),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.file(
                                File(_proofFile!.path),
                                height: 140,
                                width: double.infinity,
                                fit: BoxFit.contain,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Center(
                              child: Text(
                                "Selected Proof of Residency",
                                style: TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ),
                          ],
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            child:
                             ElevatedButton(
  onPressed: isLoading ? null : showPreviewDialog,
  style: ElevatedButton.styleFrom(
    backgroundColor: Colors.blue[700],
    padding: const EdgeInsets.symmetric(vertical: 14),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    elevation: 3,
  ),
  child: isLoading
      ? const SizedBox(
          height: 22,
          width: 22,
          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
        )
      : const Text(
          "Register",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
        ),
),

                          ),
                          const SizedBox(height: 10),
                          Center(
                            child: TextButton(
                              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => LoginPage())),
                              child: Text(
                                "Already have an account? Login",
                                style: TextStyle(color: Colors.blue[700], fontWeight: FontWeight.w500),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
/// helper widget for section headers with icons
Widget _buildSectionHeader(IconData icon, String title) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 10, top: 25),
    child: Row(
      children: [
        Icon(icon, color: Colors.blue[700], size: 22),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.blue[800],
          ),
        ),
        const Expanded(
          child: Divider(thickness: 1.2, indent: 10, endIndent: 0, color: Colors.blueGrey),
        ),
      ],
    ),
  );
}

/// helper for bottom sheet
Widget _buildPhotoPickerSheet(BuildContext context) {
  return Padding(
    padding: const EdgeInsets.all(8),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ListTile(
          leading: const Icon(Icons.photo_library_outlined, color: Colors.blue),
          title: const Text("Pick from Gallery"),
          onTap: () {
            Navigator.pop(context);
            pickProofOfResidency(source: ImageSource.gallery);
          },
        ),
        ListTile(
          leading: const Icon(Icons.camera_alt_outlined, color: Colors.blue),
          title: const Text("Use Camera"),
          onTap: () {
            Navigator.pop(context);
            pickProofOfResidency(source: ImageSource.camera);
          },
        ),
        const SizedBox(height: 10),
      ],
    ),
  );
}
  Widget buildSection(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blue[900])),
      ),
    );
  }

  Widget buildTextField(TextEditingController controller, String label,
      {bool isPassword = false,
      TextInputType inputType = TextInputType.text,
      int? maxLength,
      String? Function(String?)? validator,
      TextCapitalization textCapitalization = TextCapitalization.none,
      FocusNode? focusNode}) {
 return Padding(
  padding: const EdgeInsets.only(bottom: 12),
  child: TextFormField(
    controller: controller,
    focusNode: focusNode,
    obscureText: isPassword
        ? (label.contains("Confirm")
            ? !isConfirmVisible
            : !isPasswordVisible)
        : false,
    keyboardType: inputType,
    maxLength: maxLength,
    textCapitalization: textCapitalization,
    decoration: InputDecoration(
      labelText: label,
      counterText: "",
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      contentPadding: EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      errorMaxLines: 2, // ✅ FIX: allows error text to wrap to 2 lines
      suffixIcon: isPassword
          ? IconButton(
              icon: Icon(label.contains("Confirm")
                  ? (isConfirmVisible
                      ? Icons.visibility_off
                      : Icons.visibility)
                  : (isPasswordVisible
                      ? Icons.visibility_off
                      : Icons.visibility)),
              onPressed: () {
                setState(() {
                  if (label.contains("Confirm")) {
                    isConfirmVisible = !isConfirmVisible;
                  } else {
                    isPasswordVisible = !isPasswordVisible;
                  }
                });
              },
            )
          : null,
    ),
    validator: validator ??
        (val) {
          if (label.contains("*") &&
              (val == null || val.isEmpty)) {
            return "${label.replaceAll("*", "").trim()} is required";
          }
          if (label.toLowerCase().contains("password") &&
              val != null &&
              val.length < 6) {
            return "Password must be at least 6 characters";
          }
          return null;
        },
  ),
);

  }

  Widget buildDropdown(String label, List<String> options, Function(String?) onChanged, String? value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        value: value,
        items: options.map((o) => DropdownMenuItem(value: o, child: Text(o))).toList(),
        onChanged: (val) => setState(() => onChanged(val)),
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
        validator: label.contains("*") ? (val) => val == null || val.isEmpty ? "$label is required" : null : null,
      ),
    );
  }

 Widget buildDatePickerField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: _birthdate,
        readOnly: true,
        decoration: InputDecoration(
          labelText: 'Birthdate *',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
       onTap: () async {
  DateTime initialDate = DateTime(2000); // default

  // Kung may existing value, i-parse ito
  if (_birthdate.text.isNotEmpty) {
    initialDate = DateFormat('yyyy-MM-dd').parse(_birthdate.text);
  }

  final picked = await showDatePicker(
    context: context,
    initialDate: initialDate,
    firstDate: DateTime(1900),
    lastDate: DateTime.now(),
  );

  if (picked != null) {
    final formatted = DateFormat('yyyy-MM-dd').format(picked);
    _birthdate.text = formatted;
    calculateAge(formatted);
  }
},

        validator: (val) => val == null || val.isEmpty ? "Birthdate is required" : null,
      ),
    );
  }
  Widget buildCategorySelector() {
  return Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Category *",
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
        GestureDetector(
          onTap: () => setState(() => categoryExpanded = !categoryExpanded),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade400),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    selectedCategories.isEmpty
                        ? 'Select Category (optional)'
                        : selectedCategories.join(', '),
                  ),
                ),
                Icon(
                  categoryExpanded
                      ? Icons.arrow_drop_up
                      : Icons.arrow_drop_down,
                ),
              ],
            ),
          ),
        ),

        // 🔽 Category options
        if (categoryExpanded)
         ...categoryOptions.entries.map((entry) {
  final value = entry.key;      // internal value
  final display = entry.value;  // display text
  final isSenior = value == "Senior";
  final isSeniorDisabled = isSenior && age < 60;

  return CheckboxListTile(
    title: Text(
      display,
      style: TextStyle(
        color: isSeniorDisabled ? Colors.grey : Colors.black,
      ),
    ),
    value: selectedCategories.contains(value),
    onChanged: (isSenior && age >= 60)
        ? null // lock senior if age >= 60
        : isSeniorDisabled
            ? null // disable if age < 60
            : (val) {
                setState(() {
                  if (val == true) {
                    selectedCategories.add(value);
                  } else {
                    selectedCategories.remove(value);
                  }
                });
              },
    dense: true,
    controlAffinity: ListTileControlAffinity.leading,
    contentPadding: EdgeInsets.zero,
  );
}).toList(),

      ],
    ),
  );
}
}
