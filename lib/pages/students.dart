import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// Ensure this matches your project constants for appId
import '../constants.dart';

class StudentsPage extends StatelessWidget {
  final bool isWarden;
  const StudentsPage({super.key, required this.isWarden});

  @override
  Widget build(BuildContext context) {
    final firestore = FirebaseFirestore.instance;
    
    // Path for Students
    final CollectionReference studentsRef = firestore
        .collection('artifacts')
        .doc(appId)
        .collection('public')
        .doc('data')
        .collection('students');

    // Path for Rooms (needed to update occupancy)
    final CollectionReference roomsRef = firestore
        .collection('artifacts')
        .doc(appId)
        .collection('public')
        .doc('data')
        .collection('rooms');

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: isWarden ? FloatingActionButton(
        onPressed: () => _showAddStudentDialog(context, studentsRef, roomsRef),
        backgroundColor: const Color(0xFF4F46E5),
        child: const Icon(Icons.person_add_alt_1, color: Colors.white),
      ) : null,
      body: StreamBuilder<QuerySnapshot>(
        stream: studentsRef.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return const Center(child: Text("Error loading records."));
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          
          final docs = snapshot.data!.docs;
          if (docs.isEmpty) return const Center(child: Text("No students registered."));

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final String docId = docs[index].id;

              return Card(
                elevation: 0,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.grey.shade100),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFF4F46E5).withOpacity(0.1),
                    child: const Icon(Icons.person, color: Color(0xFF4F46E5)),
                  ),
                  title: Text(data['name'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text("${data['dept']} • Room ${data['roomNo']}"),
                  trailing: isWarden ? IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                    onPressed: () => _confirmDelete(context, studentsRef, roomsRef, docId, data),
                  ) : null,
                ),
              );
            },
          );
        },
      ),
    );
  }

  // --- Logic to sync occupancy on Delete ---
  void _confirmDelete(BuildContext context, CollectionReference sRef, CollectionReference rRef, String id, Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Remove Student"),
        content: Text("Delete records for ${data['name']}? This will free up a bed in Room ${data['roomNo']}."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              try {
                // 1. Delete Student
                await sRef.doc(id).delete();
                
                // 2. Decrement Room Occupancy
                final roomQuery = await rRef.where('number', isEqualTo: data['roomNo']).get();
                if (roomQuery.docs.isNotEmpty) {
                  await rRef.doc(roomQuery.docs.first.id).update({
                    'occupied': FieldValue.increment(-1)
                  });
                }
                
                if (context.mounted) Navigator.pop(context);
              } catch (e) {
                debugPrint("Delete error: $e");
              }
            },
            child: const Text("Delete", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // --- Logic to sync occupancy on Add ---
  void _showAddStudentDialog(BuildContext context, CollectionReference sRef, CollectionReference rRef) {
    final nameController = TextEditingController();
    final deptController = TextEditingController();
    final roomNoController = TextEditingController();
    String roomType = 'Standard';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text("Register Student", style: TextStyle(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameController, decoration: const InputDecoration(labelText: "Full Name", border: OutlineInputBorder())),
                const SizedBox(height: 12),
                TextField(controller: deptController, decoration: const InputDecoration(labelText: "Department", border: OutlineInputBorder())),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: TextField(controller: roomNoController, decoration: const InputDecoration(labelText: "Room No", border: OutlineInputBorder()))),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: roomType,
                        decoration: const InputDecoration(labelText: "Type", border: OutlineInputBorder()),
                        items: ['Standard', 'Deluxe', 'AC Suite'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                        onChanged: (v) => setState(() => roomType = v!),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4F46E5), foregroundColor: Colors.white),
              onPressed: () async {
                final roomNo = roomNoController.text.trim();
                if (nameController.text.isNotEmpty && roomNo.isNotEmpty) {
                  try {
                    // 1. Add Student
                    await sRef.add({
                      'name': nameController.text.trim(),
                      'dept': deptController.text.trim(),
                      'roomNo': roomNo,
                      'roomType': roomType,
                      'status': 'Active',
                      'createdAt': FieldValue.serverTimestamp(),
                    });

                    // 2. Increment Room Occupancy
                    final roomQuery = await rRef.where('number', isEqualTo: roomNo).get();
                    if (roomQuery.docs.isNotEmpty) {
                      await rRef.doc(roomQuery.docs.first.id).update({
                        'occupied': FieldValue.increment(1)
                      });
                    }

                    if (context.mounted) Navigator.pop(context);
                  } catch (e) {
                    debugPrint("Add error: $e");
                  }
                }
              },
              child: const Text("Save Details"),
            ),
          ],
        ),
      ),
    );
  }
}