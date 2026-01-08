import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants.dart';

class ComplaintsPage extends StatelessWidget {
  final bool isWarden;
  const ComplaintsPage({super.key, required this.isWarden});

  @override
  Widget build(BuildContext context) {
    final compRef = FirebaseFirestore.instance
        .collection('artifacts')
        .doc(appId)
        .collection('public')
        .doc('data')
        .collection('complaints');

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: !isWarden ? FloatingActionButton(
        onPressed: () {},
        backgroundColor: Colors.redAccent,
        child: const Icon(Icons.add_comment, color: Colors.white),
      ) : null,
      body: StreamBuilder<QuerySnapshot>(
        stream: compRef.snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snapshot.data!.docs;

          if (docs.isEmpty) return const Center(child: Text("No complaints found."));

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              return Card(
                elevation: 0,
                color: Colors.white,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.grey.shade100),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(data['category'] ?? 'General', 
                            style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12)),
                          Text(data['status'] ?? 'Pending', 
                            style: const TextStyle(fontSize: 10, color: Colors.grey)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(data['subject'] ?? 'No Subject', 
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text(data['description'] ?? '', 
                        style: const TextStyle(color: Colors.grey, fontSize: 13)),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}