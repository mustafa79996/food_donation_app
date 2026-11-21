import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../utils/admin_config.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  User? _user;
  String? _userRole;
  String? errorMessage;
  bool isLoading = false;

  AuthProvider() {
    _user = _auth.currentUser;
    if (_user != null) {
      _loadUserRole(_user!);
    }
    _auth.authStateChanges().listen((user) {
      _user = user;
      if (user != null) {
        _loadUserRole(user);
      } else {
        _userRole = null;
        AdminConfig.clear();
      }
      notifyListeners();
    });
  }

  User? get user => _user;
  bool get isSignedIn => _user != null;
  String? get userRole => _userRole;
  bool get isAdmin => _userRole == 'admin' || AdminConfig.isWelfareAdmin(_user);

  Future<void> _loadUserRole(User user) async {
    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists) {
        final role = doc.data()?['role']?.toString().toLowerCase() ?? 'donor';
        _userRole = role;
        AdminConfig.cacheRole(user.uid, role);
      } else {
        // Check if welfare centre
        final centreDoc = await _firestore.collection('welfare_centres').doc(user.uid).get();
        if (centreDoc.exists) {
          _userRole = 'welfare';
          AdminConfig.cacheRole(user.uid, 'welfare');
        } else {
          _userRole = 'donor';
          AdminConfig.cacheRole(user.uid, 'donor');
        }
      }
      notifyListeners();
    } catch (_) {}
  }

  Future<bool> signIn(String email, String password) async {
    try {
      isLoading = true;
      errorMessage = null;
      notifyListeners();

      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (credential.user != null) {
        await _loadUserRole(credential.user!);
      }
      return true;
    } on FirebaseAuthException catch (exception) {
      errorMessage = exception.message;
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> signUp(String email, String password, String displayName) async {
    try {
      isLoading = true;
      errorMessage = null;
      notifyListeners();

      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      await credential.user?.updateDisplayName(displayName);

      // Save user profile and role in Firestore
      if (credential.user != null) {
        await _firestore.collection('users').doc(credential.user!.uid).set({
          'name': displayName,
          'email': email.trim().toLowerCase(),
          'role': 'donor',
          'createdAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        _userRole = 'donor';
        AdminConfig.cacheRole(credential.user!.uid, 'donor');
      }

      return true;
    } on FirebaseAuthException catch (exception) {
      errorMessage = exception.message;
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    AdminConfig.clear();
    _userRole = null;
    await _auth.signOut();
  }
}
