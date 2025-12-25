import 'package:Laovista/pages/login_page.dart';
import 'package:Laovista/pages/register_page.dart';
import 'package:flutter/material.dart';

class PrivacyPolicyPage extends StatefulWidget {
  const PrivacyPolicyPage({super.key});

  @override
  State<PrivacyPolicyPage> createState() => _PrivacyPolicyPageState();
}

class _PrivacyPolicyPageState extends State<PrivacyPolicyPage> {
  bool agreed = false; // ✅ default unchecked

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 360;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ✅ Header with Logo + Title
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Image.asset(
                    "assets/logo.png", // 🛑 Add municipal/barangay logo here
                    height: isSmallScreen ? 45 : 60,
                    width: isSmallScreen ? 45 : 60,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "Municipality of Laoac Privacy Policy",
                      style: TextStyle(
                        fontSize: isSmallScreen ? 17 : 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[900],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // ✅ Scrollable Policy Content
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: SingleChildScrollView(
                    child: Text(
                      """
In compliance with the **Data Privacy Act of 2012 (Republic Act 10173)**, the Municipality of Laoac, including its 22 Barangays, is committed to protecting the personal information of our residents.

**1. Collection of Information**  
We collect personal data such as name, address, contact number, age, and civil status solely for the purpose of official barangay and municipal records.

**2. Use of Information**  
The information you provide will be used only for:  
• Resident profiling and barangay services  
• Issuance of certifications and clearances  
• Municipal planning and development programs  
• Emergency response and disaster preparedness  

**3. Data Protection**  
All information will be stored securely and accessed only by authorized personnel. We employ administrative, physical, and technical safeguards to ensure the confidentiality and integrity of your data.

**4. Consent**  
By clicking **“I Accept”**, you give your consent to the collection and processing of your personal data in accordance with this Privacy Policy.

For questions or concerns, you may contact the Municipal Data Privacy Officer through your Barangay Hall.
                      """,
                      style: TextStyle(
                        fontSize: isSmallScreen ? 13.5 : 15,
                        height: 1.5,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // ✅ Agreement Checkbox
              Row(
                children: [
                  Checkbox(
                    value: agreed,
                    onChanged: (value) {
                      setState(() {
                        agreed = value ?? false;
                      });
                    },
                    activeColor: Colors.green,
                  ),
                  Expanded(
                    child: Text(
                      "I have read and agree to the Data Privacy Policy.",
                      style: TextStyle(
                        fontSize: isSmallScreen ? 13 : 14,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // ✅ Responsive Action Buttons
              Wrap(
                spacing: 10,
                runSpacing: 10,
                alignment: WrapAlignment.center,
                children: [
                  SizedBox(
                    width: size.width * 0.4,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 2,
                      ),
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => LoginPage()),
                        );
                      },
                      child: const Text(
                        "Decline",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: size.width * 0.4,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            agreed ? Colors.blue[700] : Colors.grey,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 2,
                      ),
                      onPressed: agreed
                          ? () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => RegisterPage()),
                              );
                            }
                          : null, // disabled if unchecked
                      child: const Text(
                        "I Accept",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
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
  }
}
