import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

/// Secure storage helper.
///
/// Images are uploaded directly to Firebase Storage using authenticated Firebase credentials
/// and evaluated against storage security rules (storage.rules).
/// No third-party API keys, secrets, or upload presets are bundled in the client APK.
class StorageHelper {
  /// Uploads an image file to Firebase Storage under the /donations path.
  static Future<String> uploadDonationImage(File imageFile) async {
    if (!await imageFile.exists()) {
      throw Exception(
        'The selected image is no longer available. Please choose it again.',
      );
    }

    try {
      final fileName =
          'donation_${DateTime.now().millisecondsSinceEpoch}_${imageFile.path.split(Platform.pathSeparator).last}';
      final storageRef =
          FirebaseStorage.instance.ref().child('donations').child(fileName);

      final uploadTask = await storageRef.putFile(
        imageFile,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      final downloadUrl = await uploadTask.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      debugPrint('Firebase Storage upload failed: $e');
      throw Exception(
        'Failed to securely upload image: ${e.toString()}',
      );
    }
  }
}
