import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ComplaintUpdate {
  final String status;
  final String updatedBy; // User ID or 'system' for auto-updates
  final DateTime updatedAt;
  final String? remarks;
  final List<String>? imageUrls;

  ComplaintUpdate({
    required this.status,
    required this.updatedBy,
    DateTime? updatedAt,
    this.remarks,
    this.imageUrls,
  }) : updatedAt = updatedAt ?? DateTime.now();

  factory ComplaintUpdate.fromMap(Map<String, dynamic> map) {
    return ComplaintUpdate(
      status: map['status'],
      updatedBy: map['updatedBy'],
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
      remarks: map['remarks'],
      imageUrls: map['imageUrls'] != null ? List<String>.from(map['imageUrls']) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'status': status,
      'updatedBy': updatedBy,
      'updatedAt': Timestamp.fromDate(updatedAt),
      'remarks': remarks,
      'imageUrls': imageUrls,
    };
  }
}

class ComplaintModel {
  final String id;
  final String uid;
  final String email;
  final String title;
  final String description;
  final String category; // Electrical, Water, Cleaning, Food, Discipline, etc.
  final String status; // Pending, In Progress, Resolved by Warden, Escalated to Principal
  final String priority; // low, medium, high, urgent
  final String roomNumber;
  final String hostelName; // Hostel A / Hostel B
  final List<String>? imageUrls;
  final String? wardenRemarks;
  final List<ComplaintUpdate> updates;
  final DateTime createdAt;
  final DateTime? deadline;
  final DateTime? resolvedAt;
  final bool isVip;
  final String? escalatedReason;
  final String? assignedTo; // Warden UID or 'Principal'

  ComplaintModel({
    required this.id,
    required this.uid,
    required this.email,
    required this.title,
    required this.description,
    required this.category,
    required this.status,
    this.priority = 'medium',
    required this.roomNumber,
    required this.hostelName,
    this.imageUrls,
    this.wardenRemarks,
    List<ComplaintUpdate>? updates,
    required this.createdAt,
    this.deadline,
    this.resolvedAt,
    this.isVip = false,
    this.escalatedReason,
    this.assignedTo,
  }) : updates = updates ?? [];

  factory ComplaintModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final updates = (data['updates'] as List<dynamic>?)
        ?.map((e) => ComplaintUpdate.fromMap(e as Map<String, dynamic>))
        .toList();
        
    return ComplaintModel(
      id: doc.id,
      uid: data['uid'] ?? '',
      email: data['email'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      category: data['category'] ?? 'Other',
      status: data['status'] ?? 'Pending',
      priority: data['priority'] ?? 'medium',
      roomNumber: data['roomNumber'] ?? '',
      hostelName: data['hostelName'] ?? '',
      imageUrls: List<String>.from(data['imageUrls'] ?? []),
      wardenRemarks: data['wardenRemarks'],
      updates: updates ?? [],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      deadline: (data['deadline'] as Timestamp?)?.toDate(),
      resolvedAt: (data['resolvedAt'] as Timestamp?)?.toDate(),
      isVip: data['isVip'] ?? false,
      escalatedReason: data['escalatedReason'],
      assignedTo: data['assignedTo'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'title': title,
      'description': description,
      'category': category,
      'status': status,
      'priority': priority,
      'roomNumber': roomNumber,
      'hostelName': hostelName,
      'imageUrls': imageUrls ?? [],
      'wardenRemarks': wardenRemarks,
      'updates': updates.map((update) => update.toMap()).toList(),
      'createdAt': Timestamp.fromDate(createdAt),
      'deadline': deadline != null ? Timestamp.fromDate(deadline!) : null,
      'resolvedAt': resolvedAt != null ? Timestamp.fromDate(resolvedAt!) : null,
      'isVip': isVip,
      'escalatedReason': escalatedReason,
      'assignedTo': assignedTo,
    };
  }

  // Calculate days remaining until deadline
  int? get daysRemaining {
    if (deadline == null) return null;
    final now = DateTime.now();
    final difference = deadline!.difference(now);
    return difference.inDays;
  }

  // Check if deadline is approaching (less than 2 days)
  bool get isDeadlineApproaching {
    final days = daysRemaining;
    return days != null && days <= 2 && days >= 0;
  }

  // Check if deadline is overdue
  bool get isOverdue {
    final days = daysRemaining;
    return days != null && days < 0;
  }

  // Get status color
  Color get statusColor {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'in progress':
        return Colors.blue;
      case 'resolved by warden':
        return Colors.green;
      case 'escalated to principal':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  // Get urgency color
  Color get urgencyColor {
    if (isOverdue) return Colors.red;
    if (isDeadlineApproaching) return Colors.orange;
    if (priority == 'urgent') return Colors.red;
    if (priority == 'high') return Colors.orange;
    if (priority == 'medium') return Colors.blue;
    return Colors.grey;
  }
  
  // Add an update to the complaint
  void addUpdate(ComplaintUpdate update) {
    updates.add(update);
  }
  
  // Get the latest update
  ComplaintUpdate? get latestUpdate => updates.isNotEmpty ? updates.last : null;
}
