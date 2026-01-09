import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class WardenRequestsScreen extends StatelessWidget {
  const WardenRequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Requests'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('requests')
            .where('status', isEqualTo: 'pending')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;
          // Sort client-side to avoid compound index requirement
          docs.sort((a, b) {
            final t1 = a['createdAt'] as Timestamp?;
            final t2 = b['createdAt'] as Timestamp?;
            if (t1 == null) return -1;
            if (t2 == null) return 1;
            return t2.compareTo(t1); // Descending
          });

          if (docs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text("No pending requests",
                      style: TextStyle(color: Colors.grey, fontSize: 16)),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            separatorBuilder: (ctx, i) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final request = docs[index];
              final data = request.data() as Map<String, dynamic>;

              return _buildRequestCard(context, request, data);
            },
          );
        },
      ),
    );
  }

  Widget _buildRequestCard(
      BuildContext context, DocumentSnapshot doc, Map<String, dynamic> data) {
    final type =
        data['requestType'] == 'change' ? "Room Change" : "New Allotment";
    final color = data['requestType'] == 'change' ? Colors.orange : Colors.blue;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: color.withValues(alpha: 0.5)),
                  ),
                  child: Text(
                    type,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                Text(
                  _formatDate(data['createdAt']),
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              data['studentName'] ?? 'Unknown Student',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Text(
              "Roll: ${data['rollNo']} • Current: ${data['currentRoom']}",
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
            ),
            const Divider(height: 24),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Preferred Type",
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      Text(
                        (data['preferredType'] ?? 'Any')
                            .toString()
                            .toUpperCase(),
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Reason",
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      Text(
                        data['reason'] ?? 'No reason provided',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _updateStatus(context, doc, 'rejected'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                    ),
                    child: const Text("Reject"),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _updateStatus(context, doc, 'approved'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text("Approve"),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(Timestamp? timestamp) {
    if (timestamp == null) return 'Just now';
    final date = timestamp.toDate();
    return "${date.day}/${date.month} ${date.hour}:${date.minute.toString().padLeft(2, '0')}";
  }

  Future<void> _updateStatus(
      BuildContext context, DocumentSnapshot doc, String status) async {
    try {
      await doc.reference.update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Request $status')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }
}
