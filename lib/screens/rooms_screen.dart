import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RoomsScreen extends StatelessWidget {
  final CollectionReference roomsRef;

  const RoomsScreen({super.key, required this.roomsRef});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rooms & Occupancy'),
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
        onPressed: () => _showAddRoomDialog(context),
        label: const Text('Add Room'),
        icon: const Icon(Icons.add),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: roomsRef.snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return const Center(child: Text('No rooms configured yet.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 12),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final room = docs[index];
              final int occupied = room['bedsOccupied'];
              final int capacity = room['capacity'];
              final double progress = occupied / capacity;
              final bool isFull = occupied >= capacity;

              return Card(
                elevation: 0,
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Room ${room['number']}',
                                style: const TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                room['type'],
                                style: TextStyle(
                                    color: Colors.blue.shade700,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline,
                                color: Colors.redAccent),
                            onPressed: () => _handleDeleteRoom(context, room),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Occupancy',
                              style:
                                  TextStyle(color: Colors.grey, fontSize: 13)),
                          Text(
                            '$occupied / $capacity Beds',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isFull ? Colors.red : Colors.blueGrey,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 8,
                          backgroundColor: Colors.grey.shade100,
                          color: isFull
                              ? Colors.red
                              : (progress > 0.8 ? Colors.orange : Colors.blue),
                        ),
                      ),
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

  void _showAddRoomDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final numberController = TextEditingController();
    final capacityController = TextEditingController();
    String selectedType = 'Dorm (4 beds)';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add New Room'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: numberController,
                  decoration: const InputDecoration(
                    labelText: 'Room Number',
                    hintText: 'e.g. 101, A-1',
                  ),
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: capacityController,
                  decoration: const InputDecoration(labelText: 'Capacity'),
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Required';
                    if (int.tryParse(v) == null) return 'Must be a number';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: selectedType,
                  decoration: const InputDecoration(labelText: 'Room Type'),
                  items: const [
                    DropdownMenuItem(value: 'Single', child: Text('Single')),
                    DropdownMenuItem(value: 'Double', child: Text('Double')),
                    DropdownMenuItem(
                        value: 'Dorm (4 beds)', child: Text('Dorm (4 beds)')),
                    DropdownMenuItem(
                        value: 'Dorm (6 beds)', child: Text('Dorm (6 beds)')),
                  ],
                  onChanged: (v) {
                    setState(() {
                      selectedType = v!;
                    });
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  _addRoom(context, numberController.text,
                      int.parse(capacityController.text), selectedType);
                  Navigator.pop(ctx);
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addRoom(
      BuildContext context, String number, int capacity, String type) async {
    try {
      await roomsRef.add({
        'number': number,
        'capacity': capacity,
        'bedsOccupied': 0,
        'type': type,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding room: $e')),
        );
      }
    }
  }

  void _handleDeleteRoom(BuildContext context, DocumentSnapshot room) {
    if (room['bedsOccupied'] > 0) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Cannot Delete'),
          content: const Text(
              'This room has students assigned to it. Remove students first.'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx), child: const Text('OK')),
          ],
        ),
      );
      return;
    }
    room.reference.delete();
  }
}
