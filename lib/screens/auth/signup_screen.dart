import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});
  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _pass = TextEditingController();
  final _room = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _pass.dispose();
    _room.dispose();
    super.dispose();
  }

  Future<void> _signup() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    final auth = Provider.of<AuthService>(context, listen: false);
    final err = await auth.signUpWithEmail(
      email: _email.text.trim(),
      password: _pass.text,
      name: _name.text.trim(),
      roomNumber: _room.text.trim(),
    );
    setState(() => _loading = false);
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err), backgroundColor: Colors.red));
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Account created!'), backgroundColor: Colors.green));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Account')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Card(
          elevation: 6,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(14.0),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(controller: _name, decoration: const InputDecoration(labelText: 'Full name'), validator: (v) => (v != null && v.length >= 3) ? null : 'Enter name'),
                  const SizedBox(height: 12),
                  TextFormField(controller: _email, decoration: const InputDecoration(labelText: 'Email'), validator: (v) => (v != null && v.contains('@')) ? null : 'Email'),
                  const SizedBox(height: 12),
                  TextFormField(controller: _room, decoration: const InputDecoration(labelText: 'Room number'), validator: (v) => (v != null && v.isNotEmpty) ? null : 'Room'),
                  const SizedBox(height: 12),
                  TextFormField(controller: _pass, decoration: const InputDecoration(labelText: 'Password'), obscureText: true, validator: (v) => (v != null && v.length >= 6) ? null : 'Min 6'),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton(onPressed: _loading ? null : _signup, child: _loading ? const CircularProgressIndicator() : const Text('Create Account')),
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
