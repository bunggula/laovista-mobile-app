import 'dart:convert';
import 'package:Laovista/api_service.dart';
import 'package:Laovista/pages/ChangePasswordPage.dart';
import 'package:Laovista/pages/PrivacyPolicyPage.dart';
import 'package:Laovista/pages/forgot_password_page.dart';
import 'package:Laovista/pages/main_navigation_page.dart';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String kAuthTokenKey = 'auth_token';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final ApiService _apiService = ApiService();

  bool _loading = false;
  bool _obscurePassword = true;

  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  late Animation<double> _logoScaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _slideAnimation = Tween<double>(begin: 30, end: 0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _logoScaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    try {
      final response = await _apiService.loginResident(
        _email.text.trim(),
        _password.text.trim(),
      );

      final token = response['token'];
      final user = response['user'];

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(kAuthTokenKey, token);
      await prefs.setString('profile', jsonEncode(user));
      await prefs.setBool('isLoggedIn', true);

      final mustChangePassword = (user['must_change_password'] == 1 || user['must_change_password'] == true);

      if (!mounted) return;

      if (mustChangePassword) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ChangePasswordPage(token: token, forceChange: true),
          ),
        );
      } else {
        final int barangayId = user['barangay_id'];
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => MainNavigationPage(barangayId: barangayId),
          ),
        );
      }
    } catch (e) {
      _handleLoginError(e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  void _handleLoginError(String errorMessage) {
    String message;
    errorMessage = errorMessage.replaceAll('Exception: ', '');

    if (errorMessage.contains("Account archived")) {
      message = "This account has been archived. Please report to your barangay to reactivate it.";
    } else if (errorMessage.contains("Account not approved")) {
      message = "Account not approved yet.";
    } else if (errorMessage.contains("Invalid credentials")) {
      message = "Invalid email or password.";
    } else if (errorMessage.contains("SocketException")) {
      message = "Cannot connect to server. Check your network or API URL.";
    } else if (errorMessage.contains("TimeoutException")) {
      message = "Connection timed out. Server may be offline.";
    } else {
      message = "Login failed. $errorMessage";
    }

    AwesomeDialog(
      context: context,
      dialogType: DialogType.error,
      animType: AnimType.scale,
      dialogBorderRadius: BorderRadius.circular(16),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      title: "Login Failed",
      desc: message,
      titleTextStyle: const TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: Colors.redAccent,
      ),
      descTextStyle: const TextStyle(
        fontSize: 16,
        color: Colors.black87,
      ),
      btnOkText: "OK",
      btnOkColor: Colors.redAccent,
      btnOkOnPress: () {},
      useRootNavigator: true,
    ).show();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmall = size.width < 380;

    return Scaffold(
      backgroundColor: Colors.blue[700],
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: Opacity(
                opacity: 0.05,
                child: Image.asset('assets/logo.png', fit: BoxFit.cover),
              ),
            ),
            SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: Column(
                children: [
                  SizedBox(height: isSmall ? 20 : 40),

                  // ✅ Responsive logo
                  ScaleTransition(
                    scale: _logoScaleAnimation,
                    child: Center(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(100),
                        child: Container(
                          padding: EdgeInsets.all(isSmall ? 14 : 20),
                          color: Colors.white,
                          child: Image.asset(
                            'assets/logo.png',
                            height: isSmall ? 80 : 100,
                            width: isSmall ? 80 : 100,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Column(
                      children: [
                        Text(
                          "LAOVISTA",
                          style: TextStyle(
                            fontSize: isSmall ? 20 : 24,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Virtual Information System for Municipality of Laoac",
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: AnimatedBuilder(
                      animation: _slideAnimation,
                      builder: (context, child) {
                        return Transform.translate(
                          offset: Offset(0, _slideAnimation.value),
                          child: child,
                        );
                      },
                      child: Center(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: size.width > 600 ? 400 : double.infinity,
                          ),
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
                                  children: [
                                    TextFormField(
                                      controller: _email,
                                      keyboardType: TextInputType.emailAddress,
                                      decoration: const InputDecoration(labelText: "Email"),
                                      validator: (val) => val == null || val.isEmpty
                                          ? "Email is required"
                                          : null,
                                    ),
                                    const SizedBox(height: 12),
                                    TextFormField(
                                      controller: _password,
                                      obscureText: _obscurePassword,
                                      decoration: InputDecoration(
                                        labelText: "Password",
                                        suffixIcon: IconButton(
                                          icon: Icon(
                                            _obscurePassword
                                                ? Icons.visibility
                                                : Icons.visibility_off,
                                          ),
                                          onPressed: () {
                                            setState(() => _obscurePassword = !_obscurePassword);
                                          },
                                        ),
                                      ),
                                      validator: (val) => val == null || val.isEmpty
                                          ? "Password is required"
                                          : null,
                                    ),
                                    const SizedBox(height: 10),
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: TextButton(
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => ForgotPasswordPage(),
                                            ),
                                          );
                                        },
                                        child: Text(
                                          "Forgot Password?",
                                          style: TextStyle(color: Colors.blue[700],fontSize: 16),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    _loading
                                        ? const CircularProgressIndicator(color: Colors.white)
                                        : SizedBox(
                                            width: double.infinity,
                                            child: ElevatedButton(
                                              onPressed: _login,
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.blue[700],
                                                padding: const EdgeInsets.symmetric(
                                                    vertical: 14, horizontal: 20),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(10),
                                                ),
                                              ),
                                              child: const Text(
                                                "Login",
                                                style: TextStyle(
                                                  fontSize: 18,
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

                  const SizedBox(height: 20),

                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: TextButton(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => PrivacyPolicyPage()),
                        );
                      },
                      child: Text(
                        "I don't have an account? Register",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                        ),
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
  }
}
