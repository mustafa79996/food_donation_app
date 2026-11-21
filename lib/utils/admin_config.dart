import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Database-driven administrator authorization configuration.
/// Role is verified from Firestore (/users/{uid} with role: 'admin') or custom claims,
/// rather than exposing hardcoded administrator emails in the client APK.
class AdminConfig {
  static final Set<String> _adminUids = {};
  static final Map<String, String> _userRoles = {};

  /// Synchronously checks if a user is an administrator based on cached role.
  static bool isWelfareAdmin(User? user) {
    if (user == null) return false;
    return _adminUids.contains(user.uid) || _userRoles[user.uid] == 'admin';
  }

  /// Asynchronously queries Firestore to verify the user's role from the database.
  static Future<bool> checkIsAdmin(User? user) async {
    if (user == null) return false;
    if (_adminUids.contains(user.uid)) return true;

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (userDoc.exists) {
        final role = userDoc.data()?['role']?.toString().toLowerCase();
        if (role != null) {
          _userRoles[user.uid] = role;
        }
        if (role == 'admin') {
          _adminUids.add(user.uid);
          return true;
        }
      }
    } catch (_) {}

    return false;
  }

  /// Cache a user's role in memory
  static void cacheRole(String uid, String role) {
    _userRoles[uid] = role.toLowerCase();
    if (role.toLowerCase() == 'admin') {
      _adminUids.add(uid);
    } else {
      _adminUids.remove(uid);
    }
  }

  /// Clear the authorization cache (e.g., on sign out)
  static void clear() {
    _adminUids.clear();
    _userRoles.clear();
  }
}

/// Helper functions for backwards compatibility across the application
bool isWelfareAdmin(User? user) => AdminConfig.isWelfareAdmin(user);
Future<bool> checkIsAdmin(User? user) => AdminConfig.checkIsAdmin(user);
