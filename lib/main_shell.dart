import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'pages/dashboard.dart';
import 'pages/rooms.dart';
import 'pages/students.dart';
import 'pages/fees.dart';
import 'pages/attendance.dart';
import 'pages/complaints.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0;
  bool _isWarden = true;

  final List<Map<String, dynamic>> _navItems = [
    {'title': 'Dashboard', 'icon': Icons.dashboard_outlined},
    {'title': 'Rooms', 'icon': Icons.bed_outlined},
    {'title': 'Students', 'icon': Icons.people_outline},
    {'title': 'Fees', 'icon': Icons.payments_outlined},
    {'title': 'Attendance', 'icon': Icons.how_to_reg_outlined},
    {'title': 'Complaints', 'icon': Icons.report_problem_outlined},
  ];

  Widget _getPage(int index) {
    switch (index) {
      case 0: return DashboardPage(isWarden: _isWarden);
      case 1: return RoomsPage(isWarden: _isWarden);
      case 2: return StudentsPage(isWarden: _isWarden);
      case 3: return const FeesPage();
      case 4: return const AttendancePage();
      case 5: return ComplaintsPage(isWarden: _isWarden);
      default: return DashboardPage(isWarden: _isWarden);
    }
  }

  // Logout Function
  Future<void> _handleLogout() async {
    try {
      await FirebaseAuth.instance.signOut();
      // No need for Navigator.push here because AuthGate in main.dart 
      // is listening to authStateChanges and will handle the UI swap.
    } catch (e) {
      debugPrint("Logout Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_navItems[_selectedIndex]['title'], 
          style: const TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: ChoiceChip(
              label: Text(_isWarden ? 'Warden' : 'Student'),
              selected: true,
              onSelected: (_) => setState(() => _isWarden = !_isWarden),
            ),
          ),
        ],
      ),
      drawer: Drawer(
        child: Column(
          children: [
            const UserAccountsDrawerHeader(
              decoration: BoxDecoration(color: Color(0xFF312E81)),
              accountName: Text("Hostel Manager"),
              accountEmail: Text("admin@hostelpro.com"),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.person, color: Color(0xFF312E81)),
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.zero,
                itemCount: _navItems.length,
                itemBuilder: (context, index) => ListTile(
                  leading: Icon(
                    _navItems[index]['icon'],
                    color: _selectedIndex == index ? const Color(0xFF4F46E5) : null,
                  ),
                  title: Text(
                    _navItems[index]['title'],
                    style: TextStyle(
                      fontWeight: _selectedIndex == index ? FontWeight.bold : FontWeight.normal,
                      color: _selectedIndex == index ? const Color(0xFF4F46E5) : null,
                    ),
                  ),
                  selected: _selectedIndex == index,
                  onTap: () {
                    setState(() => _selectedIndex = index);
                    Navigator.pop(context);
                  },
                ),
              ),
            ),
            const Divider(),
            // The Logout Feature
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text(
                "Logout", 
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)
              ),
              onTap: () {
                // Close drawer before logging out
                Navigator.pop(context);
                _handleLogout();
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
      body: _getPage(_selectedIndex),
    );
  }
}