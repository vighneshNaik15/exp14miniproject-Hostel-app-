import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class RoomServiceModel {
  final String id;
  final String uid;
  final String email;
  final String serviceType; // cleaning, laundry, mattress, bulb, maintenance, other
  final String description;
  final String status; // requested, accepted, in-progress, completed, cancelled
  final String roomNumber;
  final String hostelName;
  final DateTime createdAt;
  final DateTime? acceptedAt;
  final DateTime? completedAt;
  final bool isVip;
  final String? assignedTo;
  final String? remarks;
  final int? estimatedTime; // in minutes

  RoomServiceModel({
    required this.id,
    required this.uid,
    required this.email,
    required this.serviceType,
    required this.description,
    required this.status,
    required this.roomNumber,
    required this.hostelName,
    required this.createdAt,
    this.acceptedAt,
    this.completedAt,
    this.isVip = false,
    this.assignedTo,
    this.remarks,
    this.estimatedTime,
  });

  factory RoomServiceModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return RoomServiceModel(
      id: doc.id,
      uid: data['uid'] ?? '',
      email: data['email'] ?? '',
      serviceType: data['serviceType'] ?? '',
      description: data['description'] ?? '',
      status: data['status'] ?? 'requested',
      roomNumber: data['roomNumber'] ?? '',
      hostelName: data['hostelName'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      acceptedAt: (data['acceptedAt'] as Timestamp?)?.toDate(),
      completedAt: (data['completedAt'] as Timestamp?)?.toDate(),
      isVip: data['isVip'] ?? false,
      assignedTo: data['assignedTo'],
      remarks: data['remarks'],
      estimatedTime: data['estimatedTime'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'serviceType': serviceType,
      'description': description,
      'status': status,
      'roomNumber': roomNumber,
      'hostelName': hostelName,
      'createdAt': Timestamp.fromDate(createdAt),
      'acceptedAt': acceptedAt != null ? Timestamp.fromDate(acceptedAt!) : null,
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'isVip': isVip,
      'assignedTo': assignedTo,
      'remarks': remarks,
      'estimatedTime': estimatedTime,
    };
  }

  Color get statusColor {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'in-progress':
        return Colors.blue;
      case 'accepted':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData get serviceIcon {
    switch (serviceType.toLowerCase()) {
      case 'cleaning':
        return Icons.cleaning_services;
      case 'laundry':
        return Icons.local_laundry_service;
      case 'mattress':
        return Icons.bed;
      case 'bulb':
        return Icons.lightbulb;
      case 'maintenance':
        return Icons.build;
      default:
        return Icons.room_service;
    }
  }

  String get estimatedTimeText {
    if (estimatedTime == null) return 'Not specified';
    if (estimatedTime! < 60) return '$estimatedTime mins';
    final hours = estimatedTime! ~/ 60;
    final mins = estimatedTime! % 60;
    return mins > 0 ? '$hours hrs $mins mins' : '$hours hrs';
  }
}
