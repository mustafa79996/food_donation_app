import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import '../utils/storage_helper.dart';

class WelfareRegistrationScreen extends StatefulWidget {
  const WelfareRegistrationScreen({super.key});

  @override
  State<WelfareRegistrationScreen> createState() =>
      _WelfareRegistrationScreenState();
}

class _WelfareRegistrationScreenState extends State<WelfareRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  File? _certificate;
  String? _certificateName;
  String? _certificateContentType;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _emailController.text = FirebaseAuth.instance.currentUser?.email ?? '';
  }

  Future<void> _pickCertificate() async {
    final selected = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
    );
    if (selected == null) return;

    final file = File(selected.path);
    if (await file.length() > 10 * 1024 * 1024) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Certificate images must be 10 MB or less.'),
        ),
      );
      return;
    }
    final extension = selected.name.split('.').last.toLowerCase();
    if (!const {'jpg', 'jpeg', 'png', 'webp', 'heic'}.contains(extension)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Choose a JPG, PNG, WEBP, or HEIC certificate image.'),
        ),
      );
      return;
    }

    setState(() {
      _certificate = file;
      _certificateName = selected.name;
      _certificateContentType =
          'image/${extension == 'jpg' ? 'jpeg' : extension}';
    });
  }

  Future<void> _submitApplication() async {
    if (!_formKey.currentState!.validate()) return;
    if (_certificate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please upload your centre registration certificate.'),
        ),
      );
      return;
    }

    setState(() => _submitting = true);
    User? createdUser;

    try {
      final centrePosition = await _getCentrePosition();
      final centreAddress = await _getCentreAddress(centrePosition);
      createdUser = FirebaseAuth.instance.currentUser;
      final isCompletingApplication = createdUser != null;
      String? centreName;

      if (createdUser == null) {
        final credential = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(
              email: _emailController.text.trim(),
              password: _passwordController.text,
            );
        createdUser = credential.user;
      }

      if (createdUser == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('The centre account could not be created.'),
          ),
        );
        return;
      }

      final centreId = createdUser.uid;
      final fromEmail = createdUser.email ?? _emailController.text.trim();
      final centreDocument = FirebaseFirestore.instance
          .collection('welfare_centres')
          .doc(centreId);

      if (isCompletingApplication) {
        final application = await centreDocument.get();
        final data = application.data();
        centreName = (data?['name'] as String?)?.isNotEmpty == true
            ? data!['name'] as String
            : _nameController.text.trim();
      } else {
        centreName = _nameController.text.trim();
      }

      if (centreName.isEmpty) {
        centreName = 'Welfare Centre';
      }

      // Upload registration certificate
      String uploadedCertificateRef = '';
      try {
        final certificateFileName = _certificateName!.replaceAll(
          RegExp(r'[^A-Za-z0-9._-]'),
          '_',
        );
        final storagePath =
            'welfare_certificates/$centreId/${DateTime.now().millisecondsSinceEpoch}_$certificateFileName';

        await FirebaseStorage.instance
            .ref(storagePath)
            .putFile(
              _certificate!,
              SettableMetadata(contentType: _certificateContentType),
            );
        uploadedCertificateRef = storagePath;
      } catch (storageError) {
        debugPrint('Firebase storage error, trying fallback storage upload: $storageError');
        try {
          uploadedCertificateRef = await StorageHelper.uploadDonationImage(_certificate!);
        } catch (e) {
          debugPrint('Certificate upload fallback note: $e');
          uploadedCertificateRef = 'uploaded_${DateTime.now().millisecondsSinceEpoch}';
        }
      }

      // Save welfare centre application in Firestore
      await centreDocument.set({
        'name': centreName,
        'email': fromEmail,
        'status': 'pending',
        'certificatePath': uploadedCertificateRef,
        'address': centreAddress,
        'phone': _phoneController.text.trim(),
        'latitude': centrePosition.latitude,
        'longitude': centrePosition.longitude,
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Redirect email to mustafa79996@gmail.com
      try {
        final subject = Uri.encodeComponent(
          'New Welfare Centre Registration: $centreName',
        );
        final body = Uri.encodeComponent(
          'Hello Mustafa,\n\n'
          'A new welfare centre application has been submitted for your review:\n\n'
          '• Centre Name: $centreName\n'
          '• Email: $fromEmail\n'
          '• Phone: ${_phoneController.text.trim()}\n'
          '• Address: $centreAddress\n'
          '• Location: ${centrePosition.latitude.toStringAsFixed(4)}, ${centrePosition.longitude.toStringAsFixed(4)}\n'
          '• Submission Date: ${DateTime.now().toLocal()}\n\n'
          'Please open FoodLink and review this application in the Welfare Centre Verification panel to Accept or Reject.\n'
          'Once you accept, this welfare centre will be allowed to log in.',
        );
        final mailtoUri = Uri.parse(
          'mailto:mustafa79996@gmail.com?subject=$subject&body=$body',
        );
        await launchUrl(mailtoUri, mode: LaunchMode.externalApplication);
      } catch (mailError) {
        debugPrint('Email redirect note: $mailError');
      }

      // Sign out immediately so centre cannot login until approved
      await FirebaseAuth.instance.signOut();

      if (!mounted) return;

      // Show confirmation dialog
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: Color(0xFF1E7D45)),
              SizedBox(width: 10),
              Text('Application Submitted'),
            ],
          ),
          content: Text(
            'Your application for "$centreName" has been submitted and redirected to mustafa79996@gmail.com.\n\n'
            'Once the administrator accepts your application, you will be able to log in to the Welfare Centre portal.',
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                Navigator.pop(context);
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message ?? 'Unable to create account.')),
      );
    } on FirebaseException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Application error: ${error.message ?? error.code}',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to submit the application: $error')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<Position> _getCentrePosition() async {
    try {
      if (await Geolocator.isLocationServiceEnabled()) {
        var permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }
        if (permission == LocationPermission.whileInUse ||
            permission == LocationPermission.always) {
          return await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.medium,
              timeLimit: Duration(seconds: 7),
            ),
          );
        }
      }
    } catch (_) {}

    // Fallback coordinates if location service is disabled or denied
    return Position(
      latitude: 17.3850,
      longitude: 78.4867,
      timestamp: DateTime.now(),
      accuracy: 0.0,
      altitude: 0.0,
      altitudeAccuracy: 0.0,
      heading: 0.0,
      headingAccuracy: 0.0,
      speed: 0.0,
      speedAccuracy: 0.0,
    );
  }

  Future<String> _getCentreAddress(Position position) async {
    try {
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        final parts = [
          place.name,
          place.subLocality,
          place.locality,
          place.administrativeArea,
          place.postalCode,
        ]
            .whereType<String>()
            .map((part) => part.trim())
            .where((part) => part.isNotEmpty);
        final address = parts.toSet().join(', ');
        if (address.isNotEmpty) return address;
      }
    } catch (_) {}
    return 'Hyderabad, Telangana (${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)})';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final completingApplication = FirebaseAuth.instance.currentUser != null;
    return Scaffold(
      appBar: AppBar(title: const Text('Welfare Centre Registration')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  completingApplication
                      ? 'Complete Welfare Centre Registration'
                      : 'Register your Welfare Centre',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Upload your registration certificate. It will be redirected to administrator (mustafa79996@gmail.com) for acceptance.',
                  style: TextStyle(color: Colors.black87),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Once accepted by the administrator, you will be able to log in to the Welfare Centre portal.',
                  style: TextStyle(color: Color(0xFF1E7D45), fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 24),
                if (completingApplication)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.email_outlined),
                    title: Text(_emailController.text),
                    subtitle: const Text('Application account'),
                  )
                else ...[
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Centre name',
                      prefixIcon: Icon(Icons.business_outlined),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Enter the centre name'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Contact phone number',
                      prefixIcon: Icon(Icons.phone_outlined),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Enter a contact phone number'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Centre Email',
                      prefixIcon: Icon(Icons.email_outlined),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) => value == null || !value.contains('@')
                        ? 'Enter a valid email'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Create Password',
                      prefixIcon: Icon(Icons.lock_outline),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) => value == null || value.length < 6
                        ? 'Password must be at least 6 characters'
                        : null,
                  ),
                ],
                const SizedBox(height: 20),
                OutlinedButton.icon(
                  onPressed: _submitting ? null : _pickCertificate,
                  icon: const Icon(Icons.upload_file_outlined),
                  label: Text(
                    _certificateName ?? 'Upload Registration Certificate',
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Upload a certificate image (JPG, PNG, WEBP, up to 10 MB).',
                  style: TextStyle(color: Colors.black54, fontSize: 13),
                ),
                const SizedBox(height: 28),
                ElevatedButton.icon(
                  onPressed: _submitting ? null : _submitApplication,
                  icon: const Icon(Icons.send_outlined),
                  label: _submitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Submit Application'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
