import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// Ensure this matches your project constants for appId
import '../constants.dart';

class RoomsPage extends StatelessWidget {
  final bool isWarden;
  const RoomsPage({super.key, required this.isWarden});

  @override
  Widget build(BuildContext context) {
    // Reference to the rooms collection following the specific path structure
    final CollectionReference roomsRef = FirebaseFirestore.instance
        .collection('artifacts')
        .doc(appId)
        .collection('public')
        .doc('data')
        .collection('rooms');

    return Scaffold(
      backgroundColor: Colors.transparent,
      
      // Floating Action Button to add rooms (Warden only)
      floatingActionButton: isWarden ? FloatingActionButton(
        onPressed: () => _showAddRoomDialog(context, roomsRef),
        backgroundColor: const Color(0xFF4F46E5),
        child: const Icon(Icons.add, color: Colors.white),
      ) : null,

      body: StreamBuilder<QuerySnapshot>(
        stream: roomsRef.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text("Error loading room data."));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return const Center(child: Text("No rooms available. Add one to get started."));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final String roomId = docs[index].id;
              final int occupied = data['occupied'] ?? 0;
              final int capacity = data['capacity'] ?? 2;
              final String roomNumber = data['number'] ?? 'N/A';
              
              // Calculate occupancy percentage for the progress bar
              double occupancyRate = occupied / capacity;
              if (occupancyRate > 1.0) occupancyRate = 1.0;

              return Card(
                elevation: 0,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.grey.shade100),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4F46E5).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.bed_outlined, color: Color(0xFF4F46E5)),
                    ),
                    title: Text(
                      "Room $roomNumber",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("${data['type'] ?? 'Standard'} • $capacity Beds"),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(
                            value: occupancyRate,
                            backgroundColor: Colors.grey.shade100,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              occupied >= capacity ? Colors.red : const Color(0xFF10B981)
                            ),
                          ),
                        ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              "$occupied/$capacity",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: occupied >= capacity ? Colors.red : Colors.grey.shade700,
                              ),
                            ),
                            const Text("Beds filled", style: TextStyle(fontSize: 10, color: Colors.grey)),
                          ],
                        ),
                        if (isWarden) ...[
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                            onPressed: () => _confirmDeletion(context, roomsRef, roomId, roomNumber),
                          ),
                        ]
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  // --- Delete Confirmation Logic ---
  void _confirmDeletion(BuildContext context, CollectionReference ref, String id, String number) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Room"),
        content: Text("Are you sure you want to remove Room $number? This will remove the room from inventory."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              try {
                await ref.doc(id).delete();
                if (context.mounted) Navigator.pop(context);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Room $number removed successfully")),
                  );
                }
              } catch (e) {
                debugPrint("Delete room error: $e");
              }
            },
            child: const Text("Delete", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // --- Add Room Logic ---
  void _showAddRoomDialog(BuildContext context, CollectionReference ref) {
    final numberController = TextEditingController();
    final capacityController = TextEditingController(text: "2");
    String selectedType = 'Standard';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text("New Room Configuration", style: TextStyle(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: numberController,
                  decoration: const InputDecoration(labelText: "Room Number", border: OutlineInputBorder()),
                  keyboardType: TextInputType.text,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedType,
                  decoration: const InputDecoration(labelText: "Room Type", border: OutlineInputBorder()),
                  items: ['Standard', 'Deluxe', 'AC Suite'].map((type) {
                    return DropdownMenuItem(value: type, child: Text(type));
                  }).toList(),
                  onChanged: (val) => setModalState(() => selectedType = val!),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: capacityController,
                  decoration: const InputDecoration(labelText: "Total Bed Capacity", border: OutlineInputBorder()),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4F46E5), foregroundColor: Colors.white),
              onPressed: () async {
                if (numberController.text.isNotEmpty) {
                  try {
                    await ref.add({
                      'number': numberController.text.trim(),
                      'type': selectedType,
                      'capacity': int.tryParse(capacityController.text) ?? 2,
                      'occupied': 0,
                      'createdAt': FieldValue.serverTimestamp(),
                    });
                    if (context.mounted) Navigator.pop(context);
                  } catch (e) {
                    debugPrint("Add room error: $e");
                  }
                }
              },
              child: const Text("Create Room"),
            ),
          ],
        ),
      ),
    );
  }
}