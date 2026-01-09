import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FeeSettingsScreen extends StatefulWidget {
  const FeeSettingsScreen({super.key});

  @override
  State<FeeSettingsScreen> createState() => _FeeSettingsScreenState();
}

class _FeeSettingsScreenState extends State<FeeSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _singleController = TextEditingController();
  final _doubleController = TextEditingController();
  final _quadController = TextEditingController();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFees();
  }

  Future<void> _loadFees() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('settings')
          .doc('fees')
          .get();

      if (doc.exists && mounted) {
        final data = doc.data()!;
        _singleController.text = (data['single'] ?? 0).toString();
        _doubleController.text = (data['double'] ?? 0).toString();
        _quadController.text = (data['quad'] ?? 0).toString();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading fees: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveFees() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        await FirebaseFirestore.instance
            .collection('settings')
            .doc('fees')
            .set({
          'single': double.parse(_singleController.text),
          'double': double.parse(_doubleController.text),
          'quad': double.parse(_quadController.text),
          'updatedAt': FieldValue.serverTimestamp(),
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Fee structure updated successfully!')),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error saving fees: $e')),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Manage Fee Structure")),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      "Set annual fees for each room type.",
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                    const SizedBox(height: 24),
                    _buildFeeField("Single Room Fee", _singleController),
                    const SizedBox(height: 16),
                    _buildFeeField("Double Room Fee", _doubleController),
                    const SizedBox(height: 16),
                    _buildFeeField("Quad Room Fee", _quadController),
                    const SizedBox(height: 32),
                    SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _saveFees,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text("Save Changes"),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildFeeField(String label, TextEditingController controller) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        prefixText: "\$ ",
        border: const OutlineInputBorder(),
        filled: true,
        fillColor: Colors.white,
      ),
      validator: (value) {
        if (value == null || value.isEmpty) return 'Please enter an amount';
        if (double.tryParse(value) == null) return 'Invalid number';
        return null;
      },
    );
  }
}
