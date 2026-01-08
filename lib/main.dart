import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
// Ensure the package name matches your pubspec.yaml 'name' field
import 'package:hostel_management_system/firebase_options.dart';
import 'package:hostel_management_system/login_page.dart';
import 'package:hostel_management_system/main_shell.dart';

void main() async {
  // Ensure Flutter engine is initialized before Firebase
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // Initialize Firebase with platform-specific options
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    runApp(const HostelApp());
  } catch (e) {
    // Fallback error screen if Firebase fails to initialize
    runApp(MaterialApp(
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Text(
              "Firebase Initialization Error:\n\n$e", 
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ),
      ),
    ));
  }
}

class HostelApp extends StatelessWidget {
  const HostelApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HostelPro Management',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4F46E5),
          primary: const Color(0xFF4F46E5),
        ),
        fontFamily: 'Inter',
      ),
      // AuthGate manages the navigation flow
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    // StreamBuilder monitors the user's login status in real-time
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // 1. While the app is determining the current auth state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // 2. If snapshot has data, the user is logged in
        if (snapshot.hasData) {
          return const MainShell();
        }

        // 3. If no user is logged in, show your updated LoginPage
        return const LoginPage();
      },
    );
  }
}