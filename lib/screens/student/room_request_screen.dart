import 'package:flutter/material.dart';

import 'package:cloud_firestore/cloud_firestore.dart';

class RoomRequestScreen extends StatefulWidget {
  final String studentId;
  final Map<String, dynamic> studentData;

  const RoomRequestScreen(
      {super.key, required this.studentId, required this.studentData});

  @override
  State<RoomRequestScreen> createState() => _RoomRequestScreenState();
}

class _RoomRequestScreenState extends State<RoomRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();

  String? _requestType;
  String? _preferredRoomType;
  bool _isLoading = false;

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await FirebaseFirestore.instance.collection('requests').add({
        'studentId': widget.studentId,
        'studentName': widget.studentData['name'],
        'rollNo': widget.studentData['rollNo'],
        'currentRoom': widget.studentData['roomNumber'] ?? 'Not Assigned',
        'requestType': _requestType,
        'preferredType': _preferredRoomType,
        'reason': _reasonController.text.trim(),
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Request submitted successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      _reasonController.clear();
      setState(() {
        _requestType = null;
        _preferredRoomType = null;
      });
      _formKey.currentState!.reset();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentRoom = widget.studentData['roomNumber'] ?? 'Not Assigned';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildInfoCard(
            title: "Current Allocation",
            content: "Room $currentRoom",
            icon: Icons.bed_outlined,
            color: Colors.blueAccent,
          ),
          const SizedBox(height: 24),
          const Text(
            "Request Change / New Allotment",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.grey.shade200),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: "Request Type",
                        border: OutlineInputBorder(),
                      ),
                      // 'value' is deprecated in DropdownButtonFormField, use initialValue
                      initialValue: _requestType,
                      items: const [
                        DropdownMenuItem(
                            value: "change", child: Text("Room Change")),
                        DropdownMenuItem(
                            value: "new", child: Text("New Allotment")),
                      ],
                      onChanged: (v) => setState(() => _requestType = v),
                      validator: (v) => v == null ? 'Please select type' : null,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: "Preferred Room Type",
                        border: OutlineInputBorder(),
                      ),
                      initialValue: _preferredRoomType,
                      items: const [
                        DropdownMenuItem(
                            value: "single", child: Text("Single")),
                        DropdownMenuItem(
                            value: "double", child: Text("Double")),
                        DropdownMenuItem(value: "quad", child: Text("Quad")),
                      ],
                      onChanged: (v) => setState(() => _preferredRoomType = v),
                      validator: (v) =>
                          v == null ? 'Please select preference' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _reasonController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: "Reason for Request",
                        border: OutlineInputBorder(),
                        alignLabelWithHint: true,
                      ),
                      validator: (v) =>
                          v!.isEmpty ? 'Please provide a reason' : null,
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _submitRequest,
                        icon: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2))
                            : const Icon(Icons.send),
                        label: Text(
                            _isLoading ? "Submitting..." : "Submit Request"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(
      {required String title,
      required String content,
      required IconData icon,
      required Color color}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                content,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
