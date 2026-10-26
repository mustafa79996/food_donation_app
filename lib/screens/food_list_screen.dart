import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/donation.dart';
import '../providers/donation_provider.dart';
import '../utils/routes.dart';
import '../utils/voice_input.dart';

class FoodListScreen extends StatelessWidget {
  const FoodListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final donationProvider = context.watch<DonationProvider>();
    final donations = donationProvider.filteredDonations;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Available Donations'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'Search donations',
            onPressed: () => showSearch(
              context: context,
              delegate: DonationSearchDelegate(donationProvider),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            CategoryChips(
              selectedCategory: donationProvider.selectedCategory,
              onSelected: donationProvider.selectCategory,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: donationProvider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : donationProvider.errorMessage != null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.error_outline, size: 48, color: Colors.orange),
                            const SizedBox(height: 12),
                            Text(
                              donationProvider.errorMessage!,
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    )
                  : donations.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.inventory_2_outlined, size: 64, color: Colors.green.shade300),
                            const SizedBox(height: 16),
                            const Text(
                              'No donations found',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Be the first to donate food to help local welfare centres!',
                              style: TextStyle(color: Colors.black54),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 20),
                            ElevatedButton.icon(
                              onPressed: () {
                                Navigator.pushNamed(context, Routes.donate);
                              },
                              icon: const Icon(Icons.volunteer_activism),
                              label: const Text('Donate Food Now'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1E7D45),
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: () async {
                        // Triggers a refresh via state
                        donationProvider.updateSearchQuery(donationProvider.searchQuery);
                      },
                      child: ListView.builder(
                        itemCount: donations.length,
                        itemBuilder: (context, index) {
                          final donation = donations[index];
                          return DonationCard(donation: donation);
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class CategoryChips extends StatelessWidget {
  final String selectedCategory;
  final ValueChanged<String> onSelected;

  const CategoryChips({
    super.key,
    required this.selectedCategory,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    const categories = [
      'All',
      'Vegetables',
      'Fruits',
      'Grains',
      'Meals',
      'Other',
    ];

    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final category = categories[index];
          final selected = category == selectedCategory;
          return ChoiceChip(
            label: Text(category),
            selected: selected,
            onSelected: (_) => onSelected(category),
          );
        },
      ),
    );
  }
}

class DonationCard extends StatelessWidget {
  final Donation donation;

  const DonationCard({super.key, required this.donation});

  Future<void> _deleteDonation(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete donation?'),
        content: const Text('Are you sure you want to delete this donation?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await FirebaseFirestore.instance
          .collection('donations')
          .doc(donation.id)
          .delete();

      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Donation deleted')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete donation: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () =>
          Navigator.pushNamed(context, Routes.details, arguments: donation),
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                height: 84,
                width: 84,
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: donation.imageUrl.isEmpty
                      ? const Icon(Icons.fastfood_outlined, size: 40)
                      : Image.network(
                          donation.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) =>
                              const Icon(Icons.fastfood_outlined, size: 40),
                        ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      donation.foodName,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${donation.quantity} servings • ${donation.category}',
                      style: const TextStyle(color: Colors.black54, fontSize: 13),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined, size: 14, color: Colors.black54),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            donation.pickupAddress.isEmpty
                                ? 'Hyderabad'
                                : donation.pickupAddress,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 13, color: Colors.black87),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (donation.donorId == FirebaseAuth.instance.currentUser?.uid)
                IconButton(
                  tooltip: 'Delete donation',
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () => _deleteDonation(context),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class DonationSearchDelegate extends SearchDelegate {
  final DonationProvider provider;

  DonationSearchDelegate(this.provider);

  @override
  String get searchFieldLabel => 'Search donations';

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      VoiceInputIconButton(
        tooltip: 'Search by voice',
        onResult: (value) {
          query = value;
          provider.updateSearchQuery(value);
        },
      ),
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
          provider.updateSearchQuery('');
        },
      ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    provider.updateSearchQuery(query);
    final results = provider.filteredDonations;

    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        final donation = results[index];
        return DonationCard(donation: donation);
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    provider.updateSearchQuery(query);
    final suggestions = provider.filteredDonations;

    return ListView.builder(
      itemCount: suggestions.length,
      itemBuilder: (context, index) {
        final donation = suggestions[index];
        return ListTile(
          leading: const Icon(Icons.fastfood_outlined),
          title: Text(donation.foodName),
          subtitle: Text('${donation.quantity} servings • ${donation.category}'),
          onTap: () {
            close(context, null);
            Navigator.pushNamed(context, Routes.details, arguments: donation);
          },
        );
      },
    );
  }
}
