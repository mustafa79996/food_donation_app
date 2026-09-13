import 'package:flutter/material.dart';

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
            Text(donation!.foodName, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('${donation!.quantity} servings • ${donation!.category}', style: const TextStyle(fontSize: 16, color: Colors.black54)),
            const SizedBox(height: 16),
            InfoTile(label: 'Expiry Date', value: donation!.expiryDate.toLocal().toString().split(' ')[0]),
            InfoTile(label: 'Drop-off', value: donation!.pickupAddress.isEmpty ? 'Nearest welfare center will be assigned' : donation!.pickupAddress),
            InfoTile(label: 'Contact Number', value: donation!.contactNumber),
            InfoTile(label: 'Donor', value: donation!.donorName),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {},
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
          Expanded(child: Text(value, style: const TextStyle(color: Colors.black87))),
        ],
      ),
    );
  }
}
