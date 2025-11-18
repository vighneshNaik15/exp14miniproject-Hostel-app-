import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../complaints/complaint_detail_screen.dart';

class PrincipalDashboardScreen extends StatefulWidget {
  const PrincipalDashboardScreen({super.key});

  @override
  State<PrincipalDashboardScreen> createState() => _PrincipalDashboardScreenState();
}

class _PrincipalDashboardScreenState extends State<PrincipalDashboardScreen> {
  String _filterTab = 'all'; // all, escalated, unresolved, hostelA, hostelB

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Principal Dashboard'),
        backgroundColor: Colors.indigo.shade700,
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
                Icon(Icons.school, size: 16),
                SizedBox(width: 4),
                Text('Principal', style: TextStyle(fontWeight: FontWeight.bold)),
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
            colors: [Colors.indigo.shade50, Colors.white],
          ),
        ),
        child: Column(
          children: [
            // Stats Overview
            _buildStatsSection(),
            const SizedBox(height: 8),

            // Filter Tabs
            _buildFilterTabs(),
            const SizedBox(height: 8),

            // Complaints List
            Expanded(child: _buildComplaintsList()),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsSection() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('complaints').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();

        final docs = snapshot.data!.docs;
        final total = docs.length;
        final escalated = docs.where((d) => (d.data() as Map)['status'] == 'Escalated to Principal').length;
        final pending = docs.where((d) => (d.data() as Map)['status'] == 'Pending').length;
        final urgent = docs.where((d) => (d.data() as Map)['priority'] == 'urgent').length;

        return Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(child: _statCard('Total', total, Colors.blue, Icons.list_alt)),
              const SizedBox(width: 8),
              Expanded(child: _statCard('Escalated', escalated, Colors.red, Icons.warning)),
              const SizedBox(width: 8),
              Expanded(child: _statCard('Pending', pending, Colors.orange, Icons.pending)),
              const SizedBox(width: 8),
              Expanded(child: _statCard('Urgent', urgent, Colors.purple, Icons.priority_high)),
            ],
          ),
        );
      },
    );
  }

  Widget _statCard(String label, int count, Color color, IconData icon) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(12),
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
            Icon(icon, color: Colors.white, size: 24),
            const SizedBox(height: 4),
            Text(
              count.toString(),
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              label,
              style: const TextStyle(fontSize: 10, color: Colors.white),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterTabs() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _filterChip('all', 'All Complaints', Icons.list),
            const SizedBox(width: 8),
            _filterChip('escalated', 'Escalated', Icons.warning),
            const SizedBox(width: 8),
            _filterChip('unresolved', 'Unresolved', Icons.pending_actions),
            const SizedBox(width: 8),
            _filterChip('hostelA', 'Hostel A', Icons.home),
            const SizedBox(width: 8),
            _filterChip('hostelB', 'Hostel B', Icons.home_work),
          ],
        ),
      ),
    );
  }

  Widget _filterChip(String value, String label, IconData icon) {
    final isSelected = _filterTab == value;
    return FilterChip(
      avatar: Icon(icon, size: 16, color: isSelected ? Colors.indigo.shade700 : Colors.grey),
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) => setState(() => _filterTab = value),
      backgroundColor: Colors.white,
      selectedColor: Colors.indigo.shade100,
      checkmarkColor: Colors.indigo.shade700,
      labelStyle: TextStyle(
        color: isSelected ? Colors.indigo.shade700 : Colors.grey.shade700,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Widget _buildComplaintsList() {
    Query query = FirebaseFirestore.instance
        .collection('complaints')
        .orderBy('createdAt', descending: true);

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No complaints found'));
        }

        var docs = snapshot.data!.docs;

        // Apply filters
        docs = docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final status = data['status'] ?? 'Pending';
          final hostel = data['hostelName'] ?? '';

          switch (_filterTab) {
            case 'escalated':
              return status == 'Escalated to Principal';
            case 'unresolved':
              return status != 'Resolved by Warden' && status != 'Resolved';
            case 'hostelA':
              return hostel == 'Hostel A';
            case 'hostelB':
              return hostel == 'Hostel B';
            default:
              return true;
          }
        }).toList();

        if (docs.isEmpty) {
          return Center(child: Text('No $_filterTab complaints'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, i) {
            final data = docs[i].data() as Map<String, dynamic>;
            final docId = docs[i].id;
            return _complaintCard(context, data, docId);
          },
        );
      },
    );
  }

  Widget _complaintCard(BuildContext context, Map<String, dynamic> data, String docId) {
    final title = data['title'] ?? '';
    final status = data['status'] ?? 'Pending';
    final priority = data['priority'] ?? 'medium';
    final hostel = data['hostelName'] ?? '';
    final isVip = data['isVip'] ?? false;
    final escalatedReason = data['escalatedReason'];

    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isVip ? BorderSide(color: Colors.amber.shade400, width: 2) : BorderSide.none,
      ),
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ComplaintDetailScreen(complaintId: docId),
          ),
        ),
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
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  if (isVip)
                    Container(
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
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _badge(status, _getStatusColor(status)),
                  const SizedBox(width: 8),
                  _badge(priority.toUpperCase(), _getPriorityColor(priority)),
                  const SizedBox(width: 8),
                  _badge(hostel, Colors.blue.shade700),
                ],
              ),
              if (escalatedReason != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning, size: 16, color: Colors.red.shade700),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Escalated: $escalatedReason',
                          style: TextStyle(fontSize: 12, color: Colors.red.shade700),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () => _showPrincipalActions(context, data, docId),
                    icon: const Icon(Icons.admin_panel_settings, size: 16),
                    label: const Text('Manage'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'resolved by warden':
      case 'resolved':
        return Colors.green;
      case 'in progress':
        return Colors.blue;
      case 'escalated to principal':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'urgent':
        return Colors.red.shade700;
      case 'high':
        return Colors.orange.shade700;
      case 'medium':
        return Colors.blue.shade700;
      default:
        return Colors.grey;
    }
  }

  void _showPrincipalActions(BuildContext context, Map<String, dynamic> data, String docId) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Principal Actions',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.indigo.shade700),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.priority_high, color: Colors.red),
              title: const Text('Mark as Urgent'),
              onTap: () => _markAsUrgent(docId, context),
            ),
            ListTile(
              leading: const Icon(Icons.check_circle, color: Colors.green),
              title: const Text('Mark as Resolved'),
              onTap: () => _markAsResolved(docId, context),
            ),
            ListTile(
              leading: const Icon(Icons.assignment_ind, color: Colors.blue),
              title: const Text('Re-assign Complaint'),
              onTap: () => _reassignComplaint(docId, data, context),
            ),
            ListTile(
              leading: const Icon(Icons.warning, color: Colors.orange),
              title: const Text('Send Warning to Warden'),
              onTap: () => _sendWarning(docId, data, context),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _markAsUrgent(String docId, BuildContext context) async {
    await FirebaseFirestore.instance.collection('complaints').doc(docId).update({
      'priority': 'urgent',
      'updates': FieldValue.arrayUnion([
        {
          'status': 'Priority Updated',
          'updatedBy': FirebaseAuth.instance.currentUser?.uid ?? 'principal',
          'updatedAt': Timestamp.now(),
          'remarks': 'Marked as URGENT by Principal',
        }
      ]),
    });
    if (!context.mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Marked as urgent'), backgroundColor: Colors.red),
    );
  }

  Future<void> _markAsResolved(String docId, BuildContext context) async {
    await FirebaseFirestore.instance.collection('complaints').doc(docId).update({
      'status': 'Resolved',
      'resolvedAt': FieldValue.serverTimestamp(),
      'updates': FieldValue.arrayUnion([
        {
          'status': 'Resolved',
          'updatedBy': FirebaseAuth.instance.currentUser?.uid ?? 'principal',
          'updatedAt': Timestamp.now(),
          'remarks': 'Resolved by Principal',
        }
      ]),
    });
    if (!context.mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Complaint resolved'), backgroundColor: Colors.green),
    );
  }

  void _reassignComplaint(String docId, Map<String, dynamic> data, BuildContext context) {
    Navigator.pop(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Re-assign Complaint'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Warden - Hostel A'),
              onTap: () => _performReassign(docId, 'Warden-Hostel A', context),
            ),
            ListTile(
              title: const Text('Warden - Hostel B'),
              onTap: () => _performReassign(docId, 'Warden-Hostel B', context),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _performReassign(String docId, String assignTo, BuildContext context) async {
    await FirebaseFirestore.instance.collection('complaints').doc(docId).update({
      'assignedTo': assignTo,
      'status': 'In Progress',
      'updates': FieldValue.arrayUnion([
        {
          'status': 'Re-assigned',
          'updatedBy': FirebaseAuth.instance.currentUser?.uid ?? 'principal',
          'updatedAt': Timestamp.now(),
          'remarks': 'Re-assigned to $assignTo by Principal',
        }
      ]),
    });
    if (!context.mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Re-assigned to $assignTo'), backgroundColor: Colors.blue),
    );
  }

  Future<void> _sendWarning(String docId, Map<String, dynamic> data, BuildContext context) async {
    Navigator.pop(context);
    final hostel = data['hostelName'] ?? '';
    await FirebaseFirestore.instance.collection('complaints').doc(docId).update({
      'updates': FieldValue.arrayUnion([
        {
          'status': 'Warning Issued',
          'updatedBy': FirebaseAuth.instance.currentUser?.uid ?? 'principal',
          'updatedAt': Timestamp.now(),
          'remarks': 'Warning sent to Warden of $hostel for delayed response',
        }
      ]),
    });
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Warning sent to warden'), backgroundColor: Colors.orange),
    );
  }
}
