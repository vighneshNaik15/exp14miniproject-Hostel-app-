import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/auth_service.dart';
import 'vip_dashboard_screen.dart';

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
    // If VIP is active, show the VIP Dashboard
    if (_isVip == true) {
      return const VipDashboardScreen();
    }

    // Otherwise show subscription screen
    return Scaffold(
      appBar: AppBar(
        title: const Text('VIP Subscription'),
        backgroundColor: Colors.amber.shade700,
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.amber.shade50,
              Colors.orange.shade50,
            ],
          ),
        ),
        child: RefreshIndicator(
          onRefresh: _loadVipStatus,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // VIP Premium Card
              Card(
                elevation: 8,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.amber.shade400, Colors.orange.shade600],
                    ),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      Icon(
                        Icons.workspace_premium,
                        size: 80,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'VIP PREMIUM',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Unlock exclusive features and priority support',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Benefits Card
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.star, color: Colors.amber.shade700, size: 28),
                          const SizedBox(width: 12),
                          const Text(
                            'VIP Benefits',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _buildBenefitItem(
                        Icons.speed,
                        'Priority Handling',
                        '30% faster response time on all complaints',
                      ),
                      _buildBenefitItem(
                        Icons.support_agent,
                        '24/7 Support',
                        'Dedicated support team available anytime',
                      ),
                      _buildBenefitItem(
                        Icons.verified,
                        'Guaranteed Resolution',
                        'SLA-backed complaint resolution',
                      ),
                      _buildBenefitItem(
                        Icons.notifications_active,
                        'Real-time Updates',
                        'Instant notifications on complaint status',
                      ),
                      _buildBenefitItem(
                        Icons.room_service,
                        'Premium Services',
                        'Access to exclusive room services',
                      ),
                      _buildBenefitItem(
                        Icons.campaign,
                        'VIP Announcements',
                        'Early access to important updates',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Error message
              if (_error != null)
                Card(
                  color: Colors.red.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Icon(Icons.error, color: Colors.red.shade700),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _error!,
                            style: TextStyle(color: Colors.red.shade700),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              if (_error != null) const SizedBox(height: 16),

              // Subscribe Button
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: _loading ? null : () => _updateVipStatus(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber.shade700,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 4,
                  ),
                  child: _loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.workspace_premium, size: 28),
                            SizedBox(width: 12),
                            Text(
                              'Subscribe to VIP',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 16),

              // Terms
              Text(
                'By subscribing, you agree to our terms and conditions. Cancel anytime from your VIP dashboard.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBenefitItem(IconData icon, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.amber.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.amber.shade700, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.check_circle, color: Colors.green.shade600, size: 24),
        ],
      ),
    );
  }
}


