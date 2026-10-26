import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/donation.dart';

class DonationDetailsScreen extends StatelessWidget {
  final Donation? donation;

  const DonationDetailsScreen({super.key, required this.donation});

  @override
  Widget build(BuildContext context) {
    if (donation == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Donation Details')),
        body: const Center(child: Text('Donation not found')),
      );
    }
    const safetyChecks = {
      'fresh': 'Fresh and safe to eat',
      'properlyStored': 'Stored safely',
      'expiryDateConfirmed': 'Expiry date confirmed',
    };

    return Scaffold(
      appBar: AppBar(title: const Text('Donation Details')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.network(
                donation!.imageUrl,
                height: 220,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              donation!.foodName,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              '${donation!.quantity} servings • ${donation!.category}',
              style: const TextStyle(fontSize: 16, color: Colors.black54),
            ),
            const SizedBox(height: 16),
            InfoTile(
              label: 'Expiry Date',
              value: donation!.expiryDate.toLocal().toString().split(' ')[0],
            ),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Food safety checklist',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    for (final check in safetyChecks.entries)
                      ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(
                          donation!.foodSafetyChecklist[check.key] == true
                              ? Icons.check_circle
                              : Icons.help_outline,
                          color:
                              donation!.foodSafetyChecklist[check.key] == true
                              ? Colors.green
                              : Colors.black45,
                        ),
                        title: Text(check.value),
                      ),
                  ],
                ),
              ),
            ),
            InfoTile(
              label: 'Drop-off',
              value: donation!.pickupAddress.isEmpty
                  ? 'Nearest welfare center will be assigned'
                  : donation!.pickupAddress,
            ),
            InfoTile(label: 'Contact Number', value: donation!.contactNumber),
            InfoTile(label: 'Donor', value: donation!.donorName),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () async {
                final contactNumber = donation!.contactNumber.trim();
                if (contactNumber.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('No donor phone number is available.'),
                    ),
                  );
                  return;
                }

                try {
                  final launched = await launchUrl(
                    Uri(scheme: 'tel', path: contactNumber),
                  );
                  if (!launched && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Unable to open the phone dialer.'),
                      ),
                    );
                  }
                } catch (error) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Unable to call donor: $error')),
                  );
                }
              },
              icon: const Icon(Icons.call),
              label: const Text('Contact Donor'),
            ),
          ],
        ),
      ),
    );
  }
}

class InfoTile extends StatelessWidget {
  final String label;
  final String value;

  const InfoTile({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label:', style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(value, style: const TextStyle(color: Colors.black87)),
          ),
        ],
      ),
    );
  }
}
