import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';

class AddComplaintScreen extends StatefulWidget {
  const AddComplaintScreen({super.key});
  @override
  State<AddComplaintScreen> createState() => _AddComplaintScreenState();
}

class _AddComplaintScreenState extends State<AddComplaintScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _desc = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _title.dispose();
    _desc.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final user = Provider.of<AuthService>(context, listen: false).currentUser;
      await FirebaseFirestore.instance.collection('complaints').add({
        'title': _title.text.trim(),
        'description': _desc.text.trim(),
        'uid': user?.uid,
        'email': user?.email,
        'status': 'open',
        'createdAt': FieldValue.serverTimestamp(),
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Complaint submitted'), backgroundColor: Colors.green));
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Complaint')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          elevation: 6,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(14.0),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(controller: _title, decoration: const InputDecoration(labelText: 'Title'), validator: (v) => (v != null && v.isNotEmpty) ? null : 'Enter title'),
                  const SizedBox(height: 12),
                  TextFormField(controller: _desc, decoration: const InputDecoration(labelText: 'Description'), minLines: 3, maxLines: 5, validator: (v) => (v != null && v.isNotEmpty) ? null : 'Enter description'),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton(onPressed: _loading ? null : _submit, child: _loading ? const CircularProgressIndicator() : const Text('Submit')),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
