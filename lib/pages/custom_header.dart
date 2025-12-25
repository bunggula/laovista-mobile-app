import 'package:flutter/material.dart';

class CustomHeader extends StatelessWidget {
  final String title;

  const CustomHeader({Key? key, required this.title}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 25, horizontal: 16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
  Color(0xFF1565C0), // deep blue
  Color(0xFF42A5F5), // lighter blue
],

          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          // --- Logo (pinaliit) ---
          ClipOval(
            child: Image.asset(
              'assets/logo.png',
              height: 45, // dati 70
              width: 45,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 14),

          // --- Title Text ---
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 26,
                color: Colors.white,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.8,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
