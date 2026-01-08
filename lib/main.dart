import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hostel_2/firebase_options.dart';

// Ensure these match your project name in pubspec.yaml (hostel_2)
import 'package:hostel_2/screens/login_selection_screen.dart';
import 'package:hostel_2/screens/dashboard_screen.dart';
import 'package:hostel_2/screens/rooms_screen.dart';
import 'package:hostel_2/screens/students_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // This MUST be called before any Firestore code
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint("Firebase init error (check your configuration): $e");
  }

  runApp(const DormFlowApp());
}

class DormFlowApp extends StatelessWidget {
  const DormFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DormFlow Pro',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
            color: Color(0xFF1E293B),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const LoginSelectionScreen(),
      },
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;
  final String appId = 'hostel-manager-001';

  late final CollectionReference<Map<String, dynamic>> roomsRef;
  late final CollectionReference<Map<String, dynamic>> studentsRef;
  bool _isReady = false;

  @override
  void initState() {
    super.initState();
    _setupFirestore();
  }

  void _setupFirestore() {
    try {
      // MANDATORY PATH STRUCTURE: /artifacts/{appId}/public/data/{collection}
      final base = FirebaseFirestore.instance
          .collection('artifacts')
          .doc(appId)
          .collection('public')
          .doc('data');

      roomsRef = base.collection('rooms');
      studentsRef = base.collection('students');

      setState(() {
        _isReady = true;
      });
    } catch (e) {
      debugPrint("Firestore Setup Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isReady) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final List<Widget> screens = [
      DashboardScreen(roomsRef: roomsRef, studentsRef: studentsRef),
      RoomsScreen(roomsRef: roomsRef),
      StudentsScreen(roomsRef: roomsRef, studentsRef: studentsRef),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) =>
            setState(() => _selectedIndex = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.door_front_door_outlined),
            selectedIcon: Icon(Icons.door_front_door),
            label: 'Rooms',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people),
            label: 'Students',
          ),
        ],
      ),
    );
  }
}
