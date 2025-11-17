import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  bool _isGuest = false;

  User? get currentUser => _auth.currentUser;
  bool get isGuest => _isGuest;

  void enterGuestMode() {
    _isGuest = true;
    notifyListeners();
  }

  Future<void> exitGuestMode() async {
    _isGuest = false;
    notifyListeners();
  }

  // sign up
  Future<String?> signUpWithEmail({
    required String email,
    required String password,
    required String name,
    required String roomNumber,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      await _firestore.collection('users').doc(credential.user!.uid).set({
        'uid': credential.user!.uid,
        'email': email,
        'name': name,
        'roomNumber': roomNumber,
        'role': 'student',
        'isVip': false,
        'vipActivatedAt': null,
        'createdAt': FieldValue.serverTimestamp(),
      });

      notifyListeners();
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message;
    } catch (e) {
      return e.toString();
    }
  }

  // sign in
  Future<String?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      _isGuest = false;
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      notifyListeners();
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> signInWithGoogle() async {
    try {
      _isGuest = false;
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        return 'Google sign-in canceled';
      }
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final userCredential = await _auth.signInWithCredential(credential);

      final userDoc = _firestore.collection('users').doc(userCredential.user!.uid);
      final docSnapshot = await userDoc.get();
      if (!docSnapshot.exists) {
        await userDoc.set({
          'uid': userCredential.user!.uid,
          'email': userCredential.user!.email,
          'name': userCredential.user!.displayName,
          'roomNumber': '',
          'role': 'student',
          'isVip': false,
          'vipActivatedAt': null,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      notifyListeners();
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message;
    } catch (e) {
      return e.toString();
    }
  }

  // sign out
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
    _isGuest = false;
    notifyListeners();
  }
}
