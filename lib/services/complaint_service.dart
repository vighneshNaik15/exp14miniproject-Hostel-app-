import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import '../models/complaint_model.dart';

class ComplaintService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Create a new complaint
  Future<ComplaintModel> createComplaint({
    required String title,
    required String description,
    required String category,
    required String roomNumber,
    required String hostelName,
    List<File>? images,
    String priority = 'medium',
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Upload images if any
      List<String> imageUrls = [];
      if (images != null && images.isNotEmpty) {
        for (var image in images) {
          final imageUrl = await _uploadImage(image, user.uid);
          imageUrls.add(imageUrl);
        }
      }

      // Create complaint data
      final complaintData = {
        'uid': user.uid,
        'email': user.email ?? '',
        'title': title,
        'description': description,
        'category': category,
        'status': 'Pending',
        'priority': priority,
        'roomNumber': roomNumber,
        'hostelName': hostelName,
        'imageUrls': imageUrls,
        'createdAt': FieldValue.serverTimestamp(),
        'isVip': false,
        'assignedTo': 'Warden-$hostelName', // Assign to warden of the hostel
      };

      // Add to Firestore
      final docRef = await _firestore.collection('complaints').add(complaintData);
      
      // Create initial update
      final initialUpdate = ComplaintUpdate(
        status: 'Pending',
        updatedBy: user.uid,
        remarks: 'Complaint submitted',
      );
      
      // Add initial update to the complaint
      await _firestore.collection('complaints').doc(docRef.id).update({
        'updates': FieldValue.arrayUnion([initialUpdate.toMap()]),
      });

      // Set a deadline for the complaint (e.g., 3 days from now)
      final deadline = DateTime.now().add(const Duration(days: 3));
      await _firestore.collection('complaints').doc(docRef.id).update({
        'deadline': deadline,
      });

      // Return the created complaint
      return ComplaintModel(
        id: docRef.id,
        uid: user.uid,
        email: user.email ?? '',
        title: title,
        description: description,
        category: category,
        status: 'Pending',
        priority: priority,
        roomNumber: roomNumber,
        hostelName: hostelName,
        imageUrls: imageUrls,
        updates: [initialUpdate],
        createdAt: DateTime.now(),
        deadline: deadline,
        isVip: false,
        assignedTo: 'Warden-$hostelName',
      );
    } catch (e) {
      throw Exception('Failed to create complaint: $e');
    }
  }

  // Update complaint status
  Future<void> updateComplaintStatus({
    required String complaintId,
    required String status,
    String? remarks,
    List<File>? images,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Upload new images if any
      List<String> imageUrls = [];
      if (images != null && images.isNotEmpty) {
        for (var image in images) {
          final imageUrl = await _uploadImage(image, user.uid);
          imageUrls.add(imageUrl);
        }
      }

      // Create update
      final update = ComplaintUpdate(
        status: status,
        updatedBy: user.uid,
        remarks: remarks,
        imageUrls: imageUrls.isNotEmpty ? imageUrls : null,
      );

      // Update complaint
      await _firestore.collection('complaints').doc(complaintId).update({
        'status': status,
        'updates': FieldValue.arrayUnion([update.toMap()]),
        if (status == 'Resolved by Warden') 'resolvedAt': FieldValue.serverTimestamp(),
      });

      // If complaint is not updated within 24 hours, escalate it
      if (status == 'Pending') {
        await _setupEscalationTimer(complaintId);
      }
    } catch (e) {
      throw Exception('Failed to update complaint status: $e');
    }
  }

  // Get complaints for a specific user
  Stream<List<ComplaintModel>> getUserComplaints(String userId) {
    return _firestore
        .collection('complaints')
        .where('uid', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
          final complaints = snapshot.docs
              .map((doc) => ComplaintModel.fromFirestore(doc))
              .toList();
          // Sort in memory instead of using Firestore orderBy to avoid index requirement
          complaints.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return complaints;
        });
  }

  // Get complaints for a specific warden (filtered by hostel)
  Stream<List<ComplaintModel>> getWardenComplaints(String hostelName) {
    return _firestore
        .collection('complaints')
        .where('hostelName', isEqualTo: hostelName)
        .snapshots()
        .map((snapshot) {
          final complaints = snapshot.docs
              .map((doc) => ComplaintModel.fromFirestore(doc))
              .toList();
          // Sort in memory instead of using Firestore orderBy to avoid index requirement
          complaints.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return complaints;
        });
  }

  // Get all complaints (for principal/admin)
  Stream<List<ComplaintModel>> getAllComplaints() {
    return _firestore
        .collection('complaints')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ComplaintModel.fromFirestore(doc))
            .toList());
  }

  // Get escalated complaints
  Stream<List<ComplaintModel>> getEscalatedComplaints() {
    return _firestore
        .collection('complaints')
        .where('status', isEqualTo: 'Escalated to Principal')
        .snapshots()
        .map((snapshot) {
          final complaints = snapshot.docs
              .map((doc) => ComplaintModel.fromFirestore(doc))
              .toList();
          // Sort in memory instead of using Firestore orderBy to avoid index requirement
          complaints.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return complaints;
        });
  }

  // Upload image to Firebase Storage
  Future<String> _uploadImage(File image, String userId) async {
    try {
      final String fileName = 'complaints/$userId/${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = _storage.ref().child(fileName);
      await ref.putFile(image);
      return await ref.getDownloadURL();
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }

  // Set up a timer to escalate the complaint if not updated in time
  Future<void> _setupEscalationTimer(String complaintId) async {
    // This is a simplified example. In a real app, you would use Cloud Functions
    // to handle the delayed escalation more reliably.
    await Future.delayed(const Duration(hours: 24));
    
    final doc = await _firestore.collection('complaints').doc(complaintId).get();
    if (doc.exists && doc['status'] == 'Pending') {
      await _firestore.collection('complaints').doc(complaintId).update({
        'status': 'Escalated to Principal',
        'escalatedReason': 'Not addressed within 24 hours',
        'assignedTo': 'Principal',
        'updates': FieldValue.arrayUnion([
          {
            'status': 'Escalated to Principal',
            'updatedBy': 'system',
            'updatedAt': FieldValue.serverTimestamp(),
            'remarks': 'Automatically escalated due to no response within 24 hours',
          }
        ]),
      });
    }
  }

  // Get complaint by ID
  Future<ComplaintModel> getComplaintById(String complaintId) async {
    try {
      final doc = await _firestore.collection('complaints').doc(complaintId).get();
      if (!doc.exists) throw Exception('Complaint not found');
      return ComplaintModel.fromFirestore(doc);
    } catch (e) {
      throw Exception('Failed to get complaint: $e');
    }
  }

  // Add remarks to a complaint (for warden/principal)
  Future<void> addRemarks({
    required String complaintId,
    required String remarks,
    List<File>? images,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Upload new images if any
      List<String> imageUrls = [];
      if (images != null && images.isNotEmpty) {
        for (var image in images) {
          final imageUrl = await _uploadImage(image, user.uid);
          imageUrls.add(imageUrl);
        }
      }

      // Get current status
      final doc = await _firestore.collection('complaints').doc(complaintId).get();
      final currentStatus = doc['status'];

      // Create update
      final update = ComplaintUpdate(
        status: currentStatus,
        updatedBy: user.uid,
        remarks: remarks,
        imageUrls: imageUrls.isNotEmpty ? imageUrls : null,
      );

      // Add update to the complaint
      await _firestore.collection('complaints').doc(complaintId).update({
        'wardenRemarks': remarks,
        'updates': FieldValue.arrayUnion([update.toMap()]),
        if (imageUrls.isNotEmpty) 'imageUrls': FieldValue.arrayUnion(imageUrls),
      });
    } catch (e) {
      throw Exception('Failed to add remarks: $e');
    }
  }
}
