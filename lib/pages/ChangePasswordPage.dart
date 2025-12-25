import 'dart:convert';
import 'package:Laovista/api_service.dart';
import 'package:Laovista/pages/main_navigation_page.dart';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChangePasswordPage extends StatefulWidget {
  final String token;
  final bool forceChange; // true = walang old pass, false = kailangan old pass

  const ChangePasswordPage({
    Key? key,
    required this.token,
    this.forceChange = false,
  }) : super(key: key);

  @override
  _ChangePasswordPageState createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _oldPassword = TextEditingController();
  final _newPassword = TextEditingController();
  final _confirmPassword = TextEditingController();
  final ApiService _apiService = ApiService();

  bool _loading = false;
  bool _obscureOld = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  // -------------------- Password Strength --------------------
  int _passwordStrength = 0;

  void checkPasswordStrength(String password) {
    int strength = 0;
    if (password.length >= 8) strength++;
    if (RegExp(r'[A-Z]').hasMatch(password)) strength++;
    if (RegExp(r'[0-9]').hasMatch(password)) strength++;
    if (RegExp(r'[!@#\$&*~]').hasMatch(password)) strength++;
    setState(() => _passwordStrength = strength);
  }

  Color getStrengthColor() {
    switch (_passwordStrength) {
      case 0:
      case 1:
        return Colors.red;
      case 2:
        return Colors.orange;
      case 3:
      case 4:
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String getStrengthText() {
    switch (_passwordStrength) {
      case 0:
      case 1:
        return "Weak";
      case 2:
        return "Medium";
      case 3:
      case 4:
        return "Strong";
      default:
        return "";
    }
  }

  // -------------------- Change Password --------------------
  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) return;

    if (_newPassword.text != _confirmPassword.text) {
      AwesomeDialog(
        context: context,
        dialogType: DialogType.error,
        animType: AnimType.bottomSlide,
        title: "Error",
        desc: "Password and Confirm Password do not match",
        btnOkOnPress: () {},
      ).show();
      return;
    }

    setState(() => _loading = true);

    try {
      final response = widget.forceChange
          ? await _apiService.updatePassword(
              widget.token,
              _newPassword.text.trim(),
            )
          : await _apiService.updatePasswordWithOld(
              widget.token,
              _oldPassword.text.trim(),
              _newPassword.text.trim(),
            );

      if (response['message'] == 'Password updated successfully') {
        final prefs = await SharedPreferences.getInstance();
        final profile = await _apiService.getProfile(widget.token);
        await prefs.setString('profile', jsonEncode(profile));

        AwesomeDialog(
          context: context,
          dialogType: DialogType.success,
          animType: AnimType.scale,
          title: "Success",
          desc: "Password changed successfully!",
          btnOkOnPress: () {
            final int barangayId = profile['barangay_id'];
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => MainNavigationPage(barangayId: barangayId),
              ),
            );
          },
        ).show();
      } else {
        throw Exception(response['message'] ?? 'Password change failed');
      }
    } catch (e) {
      AwesomeDialog(
        context: context,
        dialogType: DialogType.error,
        animType: AnimType.bottomSlide,
        title: "Failed",
        desc: e.toString(),
        btnOkOnPress: () {},
      ).show();
    } finally {
      setState(() => _loading = false);
    }
  }

  // -------------------- Build Text Field --------------------
  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool obscureText,
    required VoidCallback toggleVisibility,
    Function(String)? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          decoration: InputDecoration(
            labelText: label,
            filled: true,
            fillColor: Colors.grey[50],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            suffixIcon: IconButton(
              icon: Icon(
                  obscureText ? Icons.visibility : Icons.visibility_off),
              onPressed: toggleVisibility,
            ),
          ),
          validator: (val) {
            if (val == null || val.isEmpty) return "$label is required";
            if (label == "New Password") {
              final regex = RegExp(
                  r'^(?=.*?[A-Z])(?=.*?[a-z])(?=.*?[0-9])(?=.*?[!@#\$&*~]).{8,}$');
              if (!regex.hasMatch(val)) {
                return "Weak password! 8+ chars, uppercase, number & special char";
              }
            }
            return null;
          },
          onChanged: onChanged,
        ),
        if (label == "New Password" && controller.text.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Row(
              children: [
                Expanded(
                  child: LinearProgressIndicator(
                    value: _passwordStrength / 4,
                    minHeight: 5,
                    backgroundColor: Colors.grey[300],
                    color: getStrengthColor(),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  getStrengthText(),
                  style: TextStyle(
                      color: getStrengthColor(), fontWeight: FontWeight.bold),
                )
              ],
            ),
          ),
      ],
    );
  }

  // -------------------- Build --------------------
 @override
Widget build(BuildContext context) {
  return Scaffold(
    // Remove backgroundColor here; we use a Container with gradient
    body: Container(
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
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 6,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (!widget.forceChange) ...[
                          _buildPasswordField(
                            controller: _oldPassword,
                            label: "Old Password",
                            obscureText: _obscureOld,
                            toggleVisibility: () {
                              setState(() => _obscureOld = !_obscureOld);
                            },
                          ),
                          const SizedBox(height: 16),
                        ],
                        _buildPasswordField(
                          controller: _newPassword,
                          label: "New Password",
                          obscureText: _obscureNew,
                          toggleVisibility: () {
                            setState(() => _obscureNew = !_obscureNew);
                          },
                          onChanged: (val) => checkPasswordStrength(val),
                        ),
                        const SizedBox(height: 16),
                        _buildPasswordField(
                          controller: _confirmPassword,
                          label: "Confirm Password",
                          obscureText: _obscureConfirm,
                          toggleVisibility: () {
                            setState(() => _obscureConfirm = !_obscureConfirm);
                          },
                        ),
                        const SizedBox(height: 24),
                        _loading
                            ? const CircularProgressIndicator()
                            : SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: _changePassword,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue[700],
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: const Text(
                                    "Change Password",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
    appBar: AppBar(
      title: const Text("Change Password"),
      backgroundColor: Colors.blue[700],
       foregroundColor: Colors.white,
      centerTitle: true,
      elevation: 0,
  
    ),
  );
}
}