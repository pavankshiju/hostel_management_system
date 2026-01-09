import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ComplaintsScreen extends StatelessWidget {
  const ComplaintsScreen({super.key});

  Future<void> _addComplaint(
      BuildContext context, String subject, String description) async {
    try {
      await FirebaseFirestore.instance.collection('complaints').add({
        'subject': subject,
        'description': description,
        'status': 'Pending',
        'createdAt': FieldValue.serverTimestamp(),
      });
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Complaint registered successfully!')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('complaints')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Something went wrong'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return const Center(
              child: Text(
                'No complaints found.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;

              String dateStr = 'Just now';
              if (data['createdAt'] != null) {
                final DateTime dt = (data['createdAt'] as Timestamp).toDate();
                dateStr =
                    "${dt.year}-${dt.month}-${dt.day} ${dt.hour}:${dt.minute}";
              }

              final status = data['status'] ?? 'Pending';
              final color = status == 'Resolved' ? Colors.green : Colors.orange;

              return _buildComplaintItem(
                id: "#C-${docs[index].id.substring(0, 4).toUpperCase()}",
                subject: data['subject'] ?? 'No Subject',
                description: data['description'] ?? '',
                status: status,
                date: dateStr,
                color: color,
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          final subjectController = TextEditingController();
          final descController = TextEditingController();
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text("New Complaint"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: subjectController,
                    decoration: const InputDecoration(
                      labelText: "Subject",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: descController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: "Description",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (subjectController.text.isNotEmpty &&
                        descController.text.isNotEmpty) {
                      _addComplaint(
                          context, subjectController.text, descController.text);
                      Navigator.pop(context);
                    }
                  },
                  child: const Text("Submit"),
                ),
              ],
            ),
          );
        },
        label: const Text("File Complaint"),
        icon: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildComplaintItem({
    required String id,
    required String subject,
    required String description,
    required String status,
    required String date,
    required Color color,
  }) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  id,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade500,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              subject,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E293B),
              ),
            ),
            if (description.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
            const SizedBox(height: 8),
            Text(
              date,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
