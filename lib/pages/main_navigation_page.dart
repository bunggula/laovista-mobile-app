import 'package:Laovista/pages/ConcernListPage.dart';
import 'package:Laovista/pages/RequestDocumentsPage.dart';
import 'package:Laovista/pages/barangay_post_page.dart';
import 'package:Laovista/pages/edit_profile_page.dart';
import 'package:Laovista/pages/historypage.dart';
import 'package:Laovista/pages/profile.dart';
import 'package:flutter/material.dart';

import 'package:shared_preferences/shared_preferences.dart';


import 'home_page.dart';

class MainNavigationPage extends StatefulWidget {
  final int barangayId;
  final int initialTabIndex; 
  const MainNavigationPage({Key? key, required this.barangayId,this.initialTabIndex = 0,}) : super(key: key);

  @override
  _MainNavigationPageState createState() => _MainNavigationPageState();
}

class _MainNavigationPageState extends State<MainNavigationPage> {
  int _selectedIndex = 0;
  List<Widget> _pages = [];

  String? _token;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialTabIndex;
    _loadTokenAndInitPages();
  }

Future<void> _loadTokenAndInitPages() async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString(kAuthTokenKey) ?? '';

  if (token.isEmpty) {
    print("❌ No token found in SharedPreferences");
    // Optional: redirect to login if needed
  } else {
    print("✅ Token loaded: $token");
  }

  setState(() {
    _token = token;
    _pages = [
      HomePage(barangayId: widget.barangayId),
      BarangayPostPage(barangayId: widget.barangayId),
      RequestDocumentsPage(barangayId: widget.barangayId, token: token),
      ListOfConcernPage(barangayId: widget.barangayId),
      Historypage(barangayId: widget.barangayId),
      Profile(barangayId: widget.barangayId),
    ];
    _isLoading = false;
  });
}


  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

 @override
Widget build(BuildContext context) {
  if (_isLoading) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(
          color: Color(0xFF1565C0),
          strokeWidth: 3,
        ),
      ),
    );
  }

  return Scaffold(
    body: _pages[_selectedIndex],
    bottomNavigationBar: Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 6,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: const Color(0xFF1565C0), // Barangay Blue
        unselectedItemColor: Colors.grey,
        selectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 12,
        ),
        showUnselectedLabels: true,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.event_outlined),
            activeIcon: Icon(Icons.location_city),
            label: 'Events',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_outlined),
            activeIcon: Icon(Icons.account_balance),
            label: 'Services',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.report_problem_outlined),
            activeIcon: Icon(Icons.report_problem),
            label: 'Concern',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet_outlined),
            activeIcon: Icon(Icons.account_balance_wallet),
            label: 'Transactions',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    ),
  );
}
}