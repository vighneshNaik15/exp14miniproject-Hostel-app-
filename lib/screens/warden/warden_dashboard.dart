import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class WardenDashboardScreen extends StatefulWidget {
  const WardenDashboardScreen({super.key});

  @override
  State<WardenDashboardScreen> createState() => _WardenDashboardScreenState();
}

class _WardenDashboardScreenState extends State<WardenDashboardScreen> {
  String _filterStatus = 'all';
  String? _wardenHostel;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadWardenHostel();
  }

  Future<void> _loadWardenHostel() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final data = doc.data();
      
      if (mounted) {
        setState(() {
          _wardenHostel = data?['hostelName'] as String?;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_wardenHostel == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Warden Dashboard'),
          backgroundColor: Colors.deepPurple.shade700,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Text('No hostel assigned. Please contact admin.'),
        ),
      );
    }

    Query query = FirebaseFirestore.instance
        .collection('complaints')
        .where('hostelName', isEqualTo: _wardenHostel)
        .orderBy('createdAt', descending: true);

    return Scaffold(
      appBar: AppBar(
        title: Text('Warden - $_wardenHostel'),
        backgroundColor: Colors.deepPurple.shade700,
        foregroundColor: Colors.white,
        actions: [
          Container(
            margin: const EdgeInsets.all(8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              children: [
                Icon(Icons.admin_panel_settings, size: 16),
                SizedBox(width: 4),
                Text('Warden', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.deepPurple.shade50, Colors.white],
          ),
        ),
        child: Column(
          children: [
            // Stats Cards
            Container(
              padding: const EdgeInsets.all(16),
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('complaints')
                    .where('hostelName', isEqualTo: _wardenHostel)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const SizedBox();
                  
                  final docs = snapshot.data!.docs;
                  final pending = docs.where((d) => (d.data() as Map)['status'] == 'Pending').length;
                  final inProgress = docs.where((d) => (d.data() as Map)['status'] == 'In Progress').length;
                  final resolved = docs.where((d) => (d.data() as Map)['status'] == 'Resolved by Warden').length;
                  
                  return Row(
                    children: [
                      Expanded(child: _statCard('Pending', pending, Colors.orange)),
                      const SizedBox(width: 12),
                      Expanded(child: _statCard('In Progress', inProgress, Colors.blue)),
                      const SizedBox(width: 12),
                      Expanded(child: _statCard('Resolved', resolved, Colors.green)),
                    ],
                  );
                },
              ),
            ),

            // Filter Chips
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _filterChip('all', 'All'),
                    const SizedBox(width: 8),
                    _filterChip('Pending', 'Pending'),
                    const SizedBox(width: 8),
                    _filterChip('In Progress', 'In Progress'),
                    const SizedBox(width: 8),
                    _filterChip('Resolved by Warden', 'Resolved'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Complaints List
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: query.snapshots(),
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snap.hasData || snap.data!.docs.isEmpty) {
                    return const Center(child: Text('No complaints'));
                  }

                  var docs = snap.data!.docs;
                  
                  if (_filterStatus != 'all') {
                    docs = docs.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      return data['status'] == _filterStatus;
                    }).toList();
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: docs.length,
                    itemBuilder: (context, i) {
                      final d = docs[i].data() as Map<String, dynamic>;
                      final docId = docs[i].id;
                      
                      return _complaintCard(context, d, docId);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statCard(String label, int count, Color color) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [color.withOpacity(0.7), color],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            Text(
              count.toString(),
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _filterChip(String value, String label) {
    final isSelected = _filterStatus == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() => _filterStatus = value);
      },
      backgroundColor: Colors.white,
      selectedColor: Colors.deepPurple.shade100,
      checkmarkColor: Colors.deepPurple.shade700,
    );
  }

  Widget _complaintCard(BuildContext context, Map<String, dynamic> data, String docId) {
    final title = data['title'] ?? '';
    final desc = data['description'] ?? '';
    final status = data['status'] ?? 'Pending';
    final priority = data['priority'] ?? 'medium';
    final deadline = data['deadline'] as Timestamp?;
    final email = data['email'] ?? '';
    final isVip = data['isVip'] ?? false;

    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isVip ? BorderSide(color: Colors.amber.shade400, width: 2) : BorderSide.none,
      ),
      child: InkWell(
        onTap: () => _showManageDialog(context, data, docId),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (isVip)
                    Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.amber.shade400, Colors.orange.shade600],
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.flash_on, size: 12, color: Colors.white),
                          SizedBox(width: 2),
                          Text('VIP', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  _statusBadge(status),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                desc,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.grey.shade700),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.person, size: 14, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Expanded(child: Text(email, style: TextStyle(fontSize: 12, color: Colors.grey.shade600))),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: _getPriorityColor(priority).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      priority.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: _getPriorityColor(priority),
                      ),
                    ),
                  ),
                ],
              ),
              if (deadline != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.access_time, size: 14, color: Colors.grey.shade600),
                    const SizedBox(width: 4),
                    Text(
                      'Deadline: ${deadline.toDate().day}/${deadline.toDate().month}/${deadline.toDate().year}',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'urgent':
        return Colors.red;
      case 'high':
        return Colors.orange;
      case 'medium':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  Widget _statusBadge(String status) {
    Color color;
    switch (status) {
      case 'resolved':
        color = Colors.green;
        break;
      case 'in-progress':
        color = Colors.orange;
        break;
      default:
        color = Colors.blue;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.toUpperCase(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _showManageDialog(BuildContext context, Map<String, dynamic> data, String docId) {
    final currentStatus = data['status'] ?? 'Pending';
    final remarksController = TextEditingController();
    
    String newStatus = currentStatus;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Manage Complaint'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data['title'] ?? '',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 16),
                const Text('Update Status:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    _statusChip('Pending', 'Pending', newStatus, (value) {
                      setDialogState(() => newStatus = value);
                    }),
                    _statusChip('In Progress', 'In Progress', newStatus, (value) {
                      setDialogState(() => newStatus = value);
                    }),
                    _statusChip('Resolved by Warden', 'Resolved', newStatus, (value) {
                      setDialogState(() => newStatus = value);
                    }),
                  ],
                ),
                const SizedBox(height: 16),
                const Text('Add Remarks:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                TextField(
                  controller: remarksController,
                  decoration: const InputDecoration(
                    hintText: 'Enter your remarks...',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final user = FirebaseAuth.instance.currentUser;
                if (user == null) return;

                await FirebaseFirestore.instance.collection('complaints').doc(docId).update({
                  'status': newStatus,
                  'updatedAt': FieldValue.serverTimestamp(),
                  if (remarksController.text.isNotEmpty) 'wardenRemarks': remarksController.text,
                  'updates': FieldValue.arrayUnion([
                    {
                      'status': newStatus,
                      'updatedBy': user.uid,
                      'updatedAt': Timestamp.now(),
                      'remarks': remarksController.text.isNotEmpty ? remarksController.text : null,
                    }
                  ]),
                  if (newStatus == 'Resolved by Warden') 'resolvedAt': FieldValue.serverTimestamp(),
                });
                if (!context.mounted) return;
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Complaint updated'), backgroundColor: Colors.green),
                );
              },
              child: const Text('Update'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusChip(String value, String label, String currentValue, Function(String) onSelected) {
    final isSelected = currentValue == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) onSelected(value);
      },
    );
  }
}
