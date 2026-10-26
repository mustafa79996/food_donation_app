import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../utils/admin_config.dart';
import '../utils/routes.dart';

class WelfareVerificationScreen extends StatefulWidget {
  const WelfareVerificationScreen({super.key});

  @override
  State<WelfareVerificationScreen> createState() =>
      _WelfareVerificationScreenState();
}

class _WelfareVerificationScreenState extends State<WelfareVerificationScreen> {
  final Set<String> _updatingCentres = {};

  Future<void> _reviewCentre(
    String centreId,
    String status,
    Map<String, dynamic> centreData,
  ) async {
    setState(() => _updatingCentres.add(centreId));
    try {
      final firestore = FirebaseFirestore.instance;
      final batch = firestore.batch();

      batch.set(firestore.collection('welfare_centres').doc(centreId), {
        'status': status,
        'reviewedBy': welfareAdminEmail,
        'reviewedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      final latitude = centreData['latitude'];
      final longitude = centreData['longitude'];
      final name = centreData['name'] as String? ?? 'Welfare Centre';
      final address = centreData['address'] as String? ?? '';
      final phone = centreData['phone'] as String? ?? '';

      if (status == 'approved') {
        batch.set(
          firestore.collection('public_welfare_centres').doc(centreId),
          {
            'name': name,
            'address': address,
            'phone': phone,
            'latitude': latitude is num ? latitude.toDouble() : 17.3850,
            'longitude': longitude is num ? longitude.toDouble() : 78.4867,
            'status': 'approved',
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      } else {
        batch.delete(
          firestore.collection('public_welfare_centres').doc(centreId),
        );
      }

      await batch.commit();

      // Launch email to notify applicant
      try {
        final centreEmail = centreData['email'] as String?;
        if (centreEmail != null && centreEmail.isNotEmpty) {
          final subject = Uri.encodeComponent(
            status == 'approved'
                ? 'Welfare Centre Application Approved - FoodLink'
                : 'Welfare Centre Application Status - FoodLink',
          );
          final body = Uri.encodeComponent(
            status == 'approved'
                ? 'Congratulations!\n\nYour welfare centre application for "$name" has been approved by admin mustafa79996@gmail.com.\n\nYou can now log in to FoodLink and access the Welfare Dashboard.'
                : 'Your welfare centre application for "$name" was reviewed by admin mustafa79996@gmail.com and was not approved.\n\nPlease contact mustafa79996@gmail.com if you have any questions.',
          );
          final mailtoUri = Uri.parse(
            'mailto:$centreEmail?subject=$subject&body=$body',
          );
          await launchUrl(mailtoUri, mode: LaunchMode.externalApplication);
        }
      } catch (_) {
        // Ignore email launch issues
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            status == 'approved'
                ? 'Application accepted! The welfare centre can now log in.'
                : 'Application rejected.',
          ),
          backgroundColor: status == 'approved' ? const Color(0xFF1E7D45) : Colors.red,
        ),
      );
    } on FirebaseException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to update verification: ${error.message ?? error.code}',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) setState(() => _updatingCentres.remove(centreId));
    }
  }

  Future<void> _openCertificate(String path) async {
    if (path.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No certificate uploaded.')),
      );
      return;
    }

    try {
      if (path.startsWith('http://') || path.startsWith('https://')) {
        await launchUrl(Uri.parse(path), mode: LaunchMode.externalApplication);
        return;
      }

      final url = await FirebaseStorage.instance.ref(path).getDownloadURL();
      final opened = await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      );
      if (!opened && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open certificate URL.')),
        );
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to open certificate: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Welfare Verification'),
        actions: [
          IconButton(
            icon: const Icon(Icons.dashboard_outlined),
            tooltip: 'Welfare Dashboard',
            onPressed: () =>
                Navigator.pushNamed(context, Routes.welfareDashboard),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('welfare_centres')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.orange),
                    const SizedBox(height: 12),
                    Text(
                      'Unable to load applications: ${snapshot.error}',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final allDocs = snapshot.data?.docs ?? [];
          // Filter applications where status is pending (or untagged)
          final applications = allDocs.where((doc) {
            final data = doc.data();
            final status = (data['status'] as String? ?? 'pending').toLowerCase();
            return status == 'pending';
          }).toList();

          if (applications.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.task_alt, size: 64, color: Colors.green.shade400),
                    const SizedBox(height: 16),
                    const Text(
                      'No pending applications',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'All welfare centre registrations have been reviewed.',
                      style: TextStyle(color: Colors.black54),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: applications.length,
            itemBuilder: (context, index) {
              final application = applications[index];
              final data = application.data();
              final name = data['name'] as String? ?? 'Welfare Centre';
              final email = data['email'] as String? ?? 'No email';
              final phone = data['phone'] as String? ?? 'Not provided';
              final address = data['address'] as String? ?? 'Address not set';
              final certificatePath =
                  data['certificatePath'] as String? ?? '';
              final updating = _updatingCentres.contains(application.id);

              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              name,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade50,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'Pending',
                              style: TextStyle(
                                color: Colors.orange,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.email_outlined, size: 16, color: Colors.black54),
                          const SizedBox(width: 6),
                          Expanded(child: Text(email)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.phone_outlined, size: 16, color: Colors.black54),
                          const SizedBox(width: 6),
                          Expanded(child: Text('Phone: $phone')),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined, size: 16, color: Colors.black54),
                          const SizedBox(width: 6),
                          Expanded(child: Text(address)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: certificatePath.isEmpty || updating
                            ? null
                            : () => _openCertificate(certificatePath),
                        icon: const Icon(Icons.description_outlined),
                        label: Text(
                          certificatePath.isEmpty
                              ? 'No certificate attached'
                              : 'View registration certificate',
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: updating
                                  ? null
                                  : () => _reviewCentre(
                                      application.id,
                                      'approved',
                                      data,
                                    ),
                              icon: const Icon(Icons.check_circle_outline),
                              label: const Text('Accept'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1E7D45),
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: updating
                                  ? null
                                  : () => _reviewCentre(
                                      application.id,
                                      'rejected',
                                      data,
                                    ),
                              icon: const Icon(Icons.cancel_outlined),
                              label: const Text('Reject'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (updating)
                        const Padding(
                          padding: EdgeInsets.only(top: 12),
                          child: LinearProgressIndicator(),
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
