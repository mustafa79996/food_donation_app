import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../utils/admin_config.dart';
import '../utils/routes.dart';

class WelfareDashboardScreen extends StatelessWidget {
  const WelfareDashboardScreen({super.key});

  Future<void> updateRequest(
    BuildContext context,
    String requestId,
    String status,
  ) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      await FirebaseFirestore.instance
          .collection('donations')
          .doc(requestId)
          .update({
            'status': status,
            'updatedBy': user?.email ?? 'Welfare Centre',
            'updatedAt': FieldValue.serverTimestamp(),
          });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              status == 'accepted'
                  ? 'Donation accepted successfully'
                  : 'Donation rejected',
            ),
            backgroundColor: status == 'accepted' ? const Color(0xFF1E7D45) : Colors.red,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating donation: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final isAdmin = isWelfareAdmin(user);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Welfare Dashboard'),
        actions: [
          if (isAdmin)
            IconButton(
              icon: const Icon(Icons.verified_user_outlined),
              tooltip: 'Review Welfare Applications',
              onPressed: () =>
                  Navigator.pushNamed(context, Routes.welfareVerification),
            ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sign Out',
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, Routes.login);
              }
            },
          ),
        ],
      ),
      body: user == null
          ? const Center(
              child: Text('Sign in with an approved welfare account.'),
            )
          : StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('welfare_centres')
                  .doc(user.uid)
                  .snapshots(),
              builder: (context, centreSnapshot) {
                if (centreSnapshot.connectionState == ConnectionState.waiting && !isAdmin) {
                  return const Center(child: CircularProgressIndicator());
                }

                final centreData = centreSnapshot.data?.data();
                final status = (centreData?['status'] as String? ?? '').toLowerCase();

                if (!isAdmin && status != 'approved') {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.lock_outline, size: 48, color: Colors.orange),
                          const SizedBox(height: 16),
                          const Text(
                            'Access Restricted',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            status == 'pending'
                                ? 'Your welfare centre account is waiting for approval by administrator mustafa79996@gmail.com.'
                                : 'This dashboard is available to approved welfare centres only.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.black54),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: FirebaseFirestore.instance
                      .collection('donations')
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    }

                    final allDocs = snapshot.data?.docs ?? [];
                    // Filter donations where status is pending or untagged
                    final requests = allDocs.where((doc) {
                      final data = doc.data();
                      final st = (data['status'] as String? ?? 'pending').toLowerCase();
                      return st == 'pending' || st == '';
                    }).toList();

                    if (requests.isEmpty) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.inbox_outlined, size: 64, color: Colors.black38),
                              SizedBox(height: 16),
                              Text(
                                'No pending donation requests',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'New food donations from the community will appear here.',
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
                      itemCount: requests.length,
                      itemBuilder: (context, index) {
                        final request = requests[index];
                        final data = request.data();

                        return Card(
                          margin: const EdgeInsets.only(bottom: 16),
                          elevation: 2,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        data['foodName'] as String? ?? 'Food Donation',
                                        style: Theme.of(context).textTheme.titleLarge,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.green.shade50,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        data['category'] as String? ?? 'Meal',
                                        style: const TextStyle(
                                          color: Color(0xFF1E7D45),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                if (data['imageUrl'] != null &&
                                    (data['imageUrl'] as String).isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 10),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: Image.network(
                                        data['imageUrl'] as String,
                                        height: 140,
                                        width: double.infinity,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) =>
                                            const SizedBox(),
                                      ),
                                    ),
                                  ),
                                Row(
                                  children: [
                                    const Icon(Icons.inventory_2_outlined, size: 16, color: Colors.black54),
                                    const SizedBox(width: 6),
                                    Text('Quantity: ${data['quantity'] ?? 1} servings'),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.person_outline, size: 16, color: Colors.black54),
                                    const SizedBox(width: 6),
                                    Text('Donor: ${data['donorName'] ?? 'Community Donor'}'),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.phone_outlined, size: 16, color: Colors.black54),
                                    const SizedBox(width: 6),
                                    Text('Contact: ${data['contactNumber'] ?? 'Not provided'}'),
                                  ],
                                ),
                                if (data['pickupAddress'] != null &&
                                    (data['pickupAddress'] as String).isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(Icons.location_on_outlined, size: 16, color: Colors.black54),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text('Pickup: ${data['pickupAddress']}'),
                                      ),
                                    ],
                                  ),
                                ],
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        onPressed: () {
                                          updateRequest(
                                            context,
                                            request.id,
                                            'accepted',
                                          );
                                        },
                                        icon: const Icon(Icons.check),
                                        label: const Text('Accept'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFF1E7D45),
                                          foregroundColor: Colors.white,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: () {
                                          updateRequest(
                                            context,
                                            request.id,
                                            'rejected',
                                          );
                                        },
                                        icon: const Icon(Icons.close),
                                        label: const Text('Reject'),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: Colors.red,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
    );
  }
}
