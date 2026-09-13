import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class WelfareDashboardScreen extends StatelessWidget {
  const WelfareDashboardScreen({super.key});

  Future<void> updateRequest(
    BuildContext context,
    String requestId,
    String status,
  ) async {
    try {
      await FirebaseFirestore.instance
          .collection('donations')
          .doc(requestId)
          .update({
        'status': status,
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              status == 'accepted'
                  ? 'Request accepted'
                  : 'Request rejected',
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Welfare Centre Dashboard'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('donations')
            .where('status', isEqualTo: 'pending')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          final requests = snapshot.data?.docs ?? [];

          if (requests.isEmpty) {
            return const Center(
              child: Text(
                'No pending requests',
                style: TextStyle(fontSize: 18),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final request = requests[index];
              final data = request.data() as Map<String, dynamic>;

              return Card(
                margin: const EdgeInsets.only(bottom: 15),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data['foodName'] as String? ?? 'Donation',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 10),

                      Text('Donor ID: ${data['userId'] ?? 'Unknown'}'),
                      Text('Category: ${data['category'] ?? 'Unknown'}'),
                      Text('Quantity: ${data['quantity'] ?? 'Unknown'}'),
                      Text('Contact: ${data['contactNumber'] ?? 'Unknown'}'),
                      Text(
                        'Status: ${data['status'] ?? 'Unknown'}',
                      ),

                      const SizedBox(height: 15),

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
      ),
    );
  }
}
