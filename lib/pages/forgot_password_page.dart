import 'dart:convert';

import 'package:Laovista/config.dart';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ForgotPasswordPage extends StatefulWidget {
  @override
  _ForgotPasswordPageState createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _emailController = TextEditingController();
  bool _loading = false;

Future<void> _sendResetLink() async {
  final email = _emailController.text.trim();

  print("📧 [DEBUG] Email entered: '$email'");

  if (email.isEmpty) {
    AwesomeDialog(
      context: context,
      dialogType: DialogType.warning,
      animType: AnimType.scale,
      title: 'Oops!',
      desc: 'Please enter your email',
      btnOkOnPress: () {},
    ).show();

    print("❌ [DEBUG] Email field is empty. Aborting request.");
    return;
  }

  setState(() => _loading = true);

  try {
    final url = Uri.parse('${AppConfig.apiBaseUrl}/forgot-password');
    print("🌐 [DEBUG] Sending POST request to: $url");

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email}),
    );

    print("📩 [DEBUG] Response Status Code: ${response.statusCode}");
    print("📨 [DEBUG] Response Body: ${response.body}");

    if (response.statusCode == 200) {
      AwesomeDialog(
        context: context,
        dialogType: DialogType.success,
        animType: AnimType.rightSlide,
        title: 'Success!',
        desc: 'Reset link sent to your email',
        btnOkOnPress: () => Navigator.pop(context),
      ).show();

      print("✅ [DEBUG] Reset link sent successfully!");
    } else {
      AwesomeDialog(
        context: context,
        dialogType: DialogType.error,
        animType: AnimType.rightSlide,
        title: 'Failed!',
        desc: 'Error: ${response.body}',
        btnOkOnPress: () {},
      ).show();

      print("❌ [DEBUG] Failed to send reset link. Status: ${response.statusCode}");
    }
  } catch (e, stackTrace) {
    AwesomeDialog(
      context: context,
      dialogType: DialogType.error,
      animType: AnimType.leftSlide,
      title: 'Error!',
      desc: e.toString(),
      btnOkOnPress: () {},
    ).show();

    print("🔥 [DEBUG] Exception occurred while sending request: $e");
    print("🧩 [DEBUG] Stack trace: $stackTrace");
  } finally {
    setState(() => _loading = false);
    print("🕓 [DEBUG] Request completed. Loading state reset to false.");
  }
}



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1565C0), Color(0xFF42A5F5)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
              child: Card(
                elevation: 10,
                color: Colors.white,
                shadowColor: Colors.black26,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // 🔹 Logo or Icon
                      const Icon(Icons.lock_reset_rounded,
                          size: 80, color: Color(0xFF1565C0)),
                      const SizedBox(height: 16),

                      // 🔹 Title
                      const Text(
                        "Forgot Password",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1565C0),
                        ),
                      ),
                      const SizedBox(height: 8),

                      const Text(
                        "Enter your registered email address and we’ll send you a link to reset your password.",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 15, color: Colors.black87, height: 1.4),
                      ),
                      const SizedBox(height: 24),

                      // 🔹 Email Field
                      TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: "Email Address",
                          prefixIcon: const Icon(Icons.email_outlined),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey[100],
                        ),
                      ),

                      const SizedBox(height: 30),

                      // 🔹 Submit Button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _loading ? null : _sendResetLink,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1565C0),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            elevation: 3,
                          ),
                          child: _loading
                              ? const SizedBox(
                                  height: 22,
                                  width: 22,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  "Send Reset Link",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // 🔹 Back to Login Button
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text(
                          "Back to Login",
                          style: TextStyle(
                            color: Color(0xFF1565C0),
                            fontWeight: FontWeight.w500,
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
    );
  }
}
