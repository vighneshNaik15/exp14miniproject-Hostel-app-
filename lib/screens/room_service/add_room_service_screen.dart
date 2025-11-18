import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';

class AddRoomServiceScreen extends StatefulWidget {
  const AddRoomServiceScreen({super.key});

  @override
  State<AddRoomServiceScreen> createState() => _AddRoomServiceScreenState();
}

class _AddRoomServiceScreenState extends State<AddRoomServiceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descController = TextEditingController();
  String _serviceType = 'cleaning';
  String _hostelName = 'Hostel A';
  String _roomNumber = '';
  bool _loading = false;
  bool _isVip = false;

  final Map<String, Map<String, dynamic>> _serviceTypes = {
    'cleaning': {'label': 'Room Cleaning', 'icon': Icons.cleaning_services, 'time': 30},
    'laundry': {'label': 'Laundry Service', 'icon': Icons.local_laundry_service, 'time': 120},
    'mattress': {'label': 'Extra Mattress', 'icon': Icons.bed, 'time': 60},
    'bulb': {'label': 'Bulb Replacement', 'icon': Icons.lightbulb, 'time': 15},
    'maintenance': {'label': 'Maintenance', 'icon': Icons.build, 'time': 45},
    'other': {'label': 'Other', 'icon': Icons.room_service, 'time': 60},
  };

  @override
  void initState() {
    super.initState();
    _checkVipStatus();
    _loadUserData();
  }

  Future<void> _checkVipStatus() async {
    final auth = Provider.of<AuthService>(context, listen: false);
    final user = auth.currentUser;
    if (user == null || auth.isGuest) return;

    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final data = doc.data();
      if (mounted) {
        setState(() {
          _isVip = (data?['isVip'] as bool?) ?? false;
        });
      }
    } catch (e) {
      // Ignore
    }
  }

  Future<void> _loadUserData() async {
    final auth = Provider.of<AuthService>(context, listen: false);
    final user = auth.currentUser;
    if (user == null) return;

    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final data = doc.data();
      if (mounted && data != null) {
        setState(() {
          _roomNumber = data['roomNumber'] ?? '';
        });
      }
    } catch (e) {
      // Ignore
    }
  }

  @override
  void dispose() {
    _descController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      final auth = Provider.of<AuthService>(context, listen: false);
      final user = auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final estimatedTime = _serviceTypes[_serviceType]!['time'] as int;
      final vipTime = _isVip ? (estimatedTime * 0.7).round() : estimatedTime;

      await FirebaseFirestore.instance.collection('room_services').add({
        'uid': user.uid,
        'email': user.email ?? '',
        'serviceType': _serviceType,
        'description': _descController.text.trim(),
        'status': 'requested',
        'roomNumber': _roomNumber,
        'hostelName': _hostelName,
        'createdAt': FieldValue.serverTimestamp(),
        'isVip': _isVip,
        'estimatedTime': vipTime,
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isVip
              ? 'VIP Service request submitted! Priority processing.'
              : 'Service request submitted successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Service Request'),
        backgroundColor: Colors.purple.shade700,
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.purple.shade50, Colors.white],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_isVip)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.amber.shade400, Colors.orange.shade600],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.flash_on, color: Colors.white, size: 32),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'VIP Priority Service',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                '30% faster service guaranteed!',
                                style: TextStyle(color: Colors.white, fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                // Service Type Selection
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Select Service Type',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 0.9,
                          ),
                          itemCount: _serviceTypes.length,
                          itemBuilder: (context, index) {
                            final key = _serviceTypes.keys.elementAt(index);
                            final service = _serviceTypes[key]!;
                            final isSelected = _serviceType == key;

                            return InkWell(
                              onTap: () => setState(() => _serviceType = key),
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: isSelected ? Colors.purple.shade100 : Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isSelected ? Colors.purple.shade700 : Colors.transparent,
                                    width: 2,
                                  ),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      service['icon'] as IconData,
                                      size: 32,
                                      color: isSelected ? Colors.purple.shade700 : Colors.grey.shade600,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      service['label'] as String,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                        color: isSelected ? Colors.purple.shade700 : Colors.grey.shade700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Location Details
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Location Details',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: _hostelName,
                          decoration: InputDecoration(
                            labelText: 'Hostel',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                          ),
                          items: ['Hostel A', 'Hostel B']
                              .map((h) => DropdownMenuItem(value: h, child: Text(h)))
                              .toList(),
                          onChanged: (value) {
                            if (value != null) setState(() => _hostelName = value);
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          initialValue: _roomNumber,
                          decoration: InputDecoration(
                            labelText: 'Room Number',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                          ),
                          onChanged: (value) => _roomNumber = value,
                          validator: (v) => (v != null && v.isNotEmpty) ? null : 'Enter room number',
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Description
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Additional Details',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _descController,
                          decoration: InputDecoration(
                            hintText: 'Describe your request...',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                          ),
                          minLines: 3,
                          maxLines: 5,
                          validator: (v) => (v != null && v.isNotEmpty) ? null : 'Enter description',
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Estimated Time
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(Icons.access_time, color: Colors.purple.shade700),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Estimated Time',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _isVip
                                    ? '${((_serviceTypes[_serviceType]!['time'] as int) * 0.7).round()} mins (VIP Priority)'
                                    : '${_serviceTypes[_serviceType]!['time']} mins',
                                style: TextStyle(
                                  color: _isVip ? Colors.amber.shade700 : Colors.grey.shade700,
                                  fontWeight: _isVip ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple.shade700,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 4,
                    ),
                    child: _loading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.send),
                              SizedBox(width: 8),
                              Text('Submit Request', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
