import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/auth_service.dart';

class VipScreen extends StatefulWidget {
  const VipScreen({super.key});

  @override
  State<VipScreen> createState() => _VipScreenState();
}

class _VipScreenState extends State<VipScreen> {
  bool? _isVip;
  Timestamp? _activatedAt;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadVipStatus();
  }

  Future<void> _loadVipStatus() async {
    final auth = Provider.of<AuthService>(context, listen: false);
    final user = auth.currentUser;
    if (user == null) {
      setState(() {
        _error = 'Please sign in to view VIP features.';
      });
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final data = doc.data();
      setState(() {
        _isVip = (data?['isVip'] as bool?) ?? false;
        _activatedAt = data?['vipActivatedAt'] as Timestamp?;
        _error = null;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load VIP status: $e';
      });
    }
  }

  Future<void> _updateVipStatus(bool enable) async {
    final auth = Provider.of<AuthService>(context, listen: false);
    final user = auth.currentUser;
    if (user == null) return;

    setState(() => _loading = true);
    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'isVip': enable,
        'vipActivatedAt': enable ? FieldValue.serverTimestamp() : null,
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(enable ? 'VIP activated 🎉' : 'VIP cancelled'),
          backgroundColor: enable ? Colors.green : Colors.orange,
        ),
      );
      setState(() {
        _isVip = enable;
        _activatedAt = enable ? Timestamp.now() : null;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to update VIP status: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = _isVip == true ? 'Active' : 'Not active';
    return Scaffold(
      appBar: AppBar(
        title: const Text('VIP Subscription'),
      ),
      body: RefreshIndicator(
        onRefresh: _loadVipStatus,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'VIP Status: $status',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _activatedAt != null
                          ? 'Activated on ${_activatedAt!.toDate()}'
                          : 'Unlock VIP perks like faster complaint handling, exclusive notices, and priority support.',
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        _error!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ],
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: (_isVip == true || _loading) ? null : () => _updateVipStatus(true),
                        icon: const Icon(Icons.workspace_premium),
                        label: _loading
                            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Text('Subscribe to VIP'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: (_isVip == true && !_loading) ? () => _updateVipStatus(false) : null,
                      child: const Text('Cancel VIP Subscription'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


