import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants.dart';

class DashboardPage extends StatelessWidget {
  final bool isWarden;
  const DashboardPage({super.key, required this.isWarden});

  @override
  Widget build(BuildContext context) {
    // Reference to the database collections
    final baseRef = FirebaseFirestore.instance
        .collection('artifacts')
        .doc(appId)
        .collection('public')
        .doc('data');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Status Overview",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.2,
            children: [
              // Real-time Room Count
              StreamBuilder<QuerySnapshot>(
                stream: baseRef.collection('rooms').snapshots(),
                builder: (context, snapshot) {
                  String count = snapshot.hasData ? snapshot.data!.docs.length.toString() : "...";
                  return _statCard("Total Rooms", count, Icons.bed, Colors.blue);
                },
              ),
              // Real-time Student Count
              StreamBuilder<QuerySnapshot>(
                stream: baseRef.collection('students').snapshots(),
                builder: (context, snapshot) {
                  String count = snapshot.hasData ? snapshot.data!.docs.length.toString() : "...";
                  return _statCard("Residents", count, Icons.group, Colors.indigo);
                },
              ),
              // Real-time Complaint Count
              StreamBuilder<QuerySnapshot>(
                stream: baseRef.collection('complaints').snapshots(),
                builder: (context, snapshot) {
                  int pending = snapshot.hasData 
                      ? snapshot.data!.docs.where((doc) => doc['status'] != 'Resolved').length 
                      : 0;
                  return _statCard("Active Issues", pending.toString(), Icons.warning_amber, Colors.orange);
                },
              ),
              // Example Fee Status (Static for now, or could be calculated)
              _statCard("Fee Status", "85%", Icons.check_circle, Colors.green),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          Text(
            label,
            style: const TextStyle(color: Colors.grey, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}