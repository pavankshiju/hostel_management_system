import 'package:flutter/material.dart';
import 'package:hostel_2/screens/student/room_request_screen.dart';
import 'package:hostel_2/screens/student/fee_screen.dart';
import 'package:hostel_2/screens/student/complaints_screen.dart';

class StudentMainScreen extends StatefulWidget {
  final String studentId;
  final Map<String, dynamic> studentData;

  const StudentMainScreen(
      {super.key, required this.studentId, required this.studentData});

  @override
  State<StudentMainScreen> createState() => _StudentMainScreenState();
}

class _StudentMainScreenState extends State<StudentMainScreen> {
  int _selectedIndex = 0;

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      RoomRequestScreen(
        studentId: widget.studentId,
        studentData: widget.studentData,
      ),
      const FeeScreen(),
      const ComplaintsScreen(),
    ];
  }

  final List<String> _titles = [
    "Requests",
    "Fee & Payments",
    "Complaints",
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_selectedIndex]),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
            },
          ),
        ],
      ),
      body: _screens[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) =>
            setState(() => _selectedIndex = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.bed_outlined),
            selectedIcon: Icon(Icons.bed),
            label: 'Requests',
          ),
          NavigationDestination(
            icon: Icon(Icons.payment_outlined),
            selectedIcon: Icon(Icons.payment),
            label: 'Fees',
          ),
          NavigationDestination(
            icon: Icon(Icons.support_agent_outlined),
            selectedIcon: Icon(Icons.support_agent),
            label: 'Complaints',
          ),
        ],
      ),
    );
  }
}
