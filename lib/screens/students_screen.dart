import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class StudentsScreen extends StatelessWidget {
  final CollectionReference roomsRef;
  final CollectionReference studentsRef;

  const StudentsScreen(
      {super.key, required this.roomsRef, required this.studentsRef});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Students Directory'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddStudentDialog(context),
        label: const Text('Register Student'),
        icon: const Icon(Icons.person_add),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: studentsRef.snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return const Center(child: Text('No students registered.'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            separatorBuilder: (ctx, i) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final student = docs[index];
              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: CircleAvatar(
                    backgroundColor: Colors.blue.shade50,
                    child: Text(
                      student['name'][0].toUpperCase(),
                      style: TextStyle(
                          color: Colors.blue.shade700,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                  title: Text(student['name'],
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(
                      'Roll: ${student['rollNo']} • Room ${student['roomNumber']}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.person_remove_outlined,
                        color: Colors.grey),
                    onPressed: () => _confirmRemoval(context, student),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showAddStudentDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final rollNoController = TextEditingController();
    String? selectedRoomId;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Register New Student'),
          content: SizedBox(
            width: double.maxFinite,
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Full Name'),
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: rollNoController,
                    decoration: const InputDecoration(labelText: 'Roll Number'),
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  StreamBuilder<QuerySnapshot>(
                    stream: roomsRef
                        .where('bedsOccupied', isLessThan: 999)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const LinearProgressIndicator();
                      }
                      final availableRooms = snapshot.data!.docs.where((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        final occupied = data['bedsOccupied'] ?? 0;
                        final capacity = data['capacity'] ?? 0;
                        return occupied < capacity;
                      }).toList();

                      if (availableRooms.isEmpty) {
                        return const Text(
                            'No active rooms with vacancies available.',
                            style: TextStyle(color: Colors.red));
                      }

                      return DropdownButtonFormField<String>(
                        decoration:
                            const InputDecoration(labelText: 'Assign Room'),
                        // ignore: deprecated_member_use
                        value: selectedRoomId,
                        items: availableRooms.map((room) {
                          return DropdownMenuItem(
                            value: room.id,
                            child: Text(
                                'Room ${room['number']} (${room['capacity'] - room['bedsOccupied']} free)'),
                          );
                        }).toList(),
                        onChanged: (v) {
                          setState(() {
                            selectedRoomId = v;
                          });
                        },
                        validator: (v) =>
                            v == null ? 'Please select a room' : null,
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate() &&
                    selectedRoomId != null) {
                  await _addStudentWithId(context, nameController.text,
                      rollNoController.text, selectedRoomId!);
                  if (context.mounted) Navigator.pop(ctx);
                }
              },
              child: const Text('Register'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addStudentWithId(
      BuildContext context, String name, String rollNo, String roomId) async {
    try {
      final roomDoc = await roomsRef.doc(roomId).get();
      if (!context.mounted) return;
      if (roomDoc.exists) {
        await _addStudent(context, name, rollNo, roomDoc);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to fetch room: $e')),
        );
      }
    }
  }

  Future<void> _addStudent(BuildContext context, String name, String rollNo,
      DocumentSnapshot room) async {
    try {
      final roomId = room.id;
      final roomNum = room['number'];

      final currentOccupied = room['bedsOccupied'] ?? 0;
      final capacity = room['capacity'] ?? 0;

      if (currentOccupied >= capacity) {
        throw Exception("Room is full!");
      }

      final batch = FirebaseFirestore.instance.batch();

      // Add student
      batch.set(studentsRef.doc(), {
        'name': name,
        'rollNo': rollNo,
        'roomId': roomId,
        'roomNumber': roomNum,
        'joinedAt': FieldValue.serverTimestamp(),
      });

      // Update room using increment (atomic)
      batch.update(room.reference, {
        'bedsOccupied': FieldValue.increment(1),
      });

      await batch.commit();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e')),
        );
      }
    }
  }

  void _confirmRemoval(BuildContext context, DocumentSnapshot student) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Student?'),
        content: Text(
            'Are you sure you want to remove ${student['name']}? This will free up a bed in Room ${student['roomNumber']}.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () {
              _removeStudent(student);
              Navigator.pop(ctx);
            },
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  Future<void> _removeStudent(DocumentSnapshot student) async {
    final String roomId = student['roomId'];

    // 1. Delete the student document
    await student.reference.delete();

    // 2. Decrement the bed count in the room atomically
    await roomsRef.doc(roomId).update({
      'bedsOccupied': FieldValue.increment(-1),
    });
  }
}
