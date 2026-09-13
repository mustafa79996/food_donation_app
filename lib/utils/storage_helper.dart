import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

class StorageHelper {
  static Future<String> uploadDonationImage(File imageFile) async {
    if (!await imageFile.exists()) {
      throw Exception(
        'The selected image is no longer available. Please choose it again.',
      );
    }

    const cloudName = 'ptdl8yij';
    const uploadPreset = 'flutter_upload';

    final url = Uri.parse(
      'https://api.cloudinary.com/v1_1/$cloudName/image/upload',
    );

    final request = http.MultipartRequest('POST', url);

    request.fields['upload_preset'] = uploadPreset;

    request.files.add(
      await http.MultipartFile.fromPath(
        'file',
        imageFile.path,
      ),
    );

    final response = await request.send();
    final responseBody = await response.stream.bytesToString();

    if (response.statusCode == 200) {
      final data = jsonDecode(responseBody);
      return data['secure_url'];
    }

    throw Exception(
      'Cloudinary upload failed: $responseBody',
    );
  }
}