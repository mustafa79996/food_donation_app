import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/donation.dart';
import '../providers/donation_provider.dart';
import '../utils/routes.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
            onPressed: () {
              showSearch(context: context, delegate: DonationSearchDelegate(donationProvider));
            },
          )
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
              child: donations.isEmpty
                  ? const Center(
                      child: Text('No donations found. Try adjusting the filters.'),
                    )
                  : ListView.builder(
                      itemCount: donations.length,
                      itemBuilder: (context, index) {
                        final donation = donations[index];
                        return DonationCard(donation: donation);
                      },
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

  const CategoryChips({super.key, required this.selectedCategory, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    const categories = ['All', 'Vegetables', 'Fruits', 'Grains', 'Meals', 'Other'];

    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
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
        content: const Text(
          'Are you sure you want to delete this donation?',
        ),
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Donation deleted'),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete donation: $e'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(
        context,
        Routes.details,
        arguments: donation,
      ),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                height: 88,
                width: 88,
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(16),
                  image: DecorationImage(
                    image: NetworkImage(donation.imageUrl),
                    fit: BoxFit.cover,
                  ),
                ),
              ),

              const SizedBox(width: 16),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      donation.foodName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${donation.quantity} items • ${donation.category}',
                      style: const TextStyle(color: Colors.black54),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      donation.pickupAddress.isEmpty
                          ? 'Nearest welfare center will be assigned'
                          : donation.pickupAddress,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              IconButton(
                icon: const Icon(Icons.delete_outline),
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
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
          provider.updateSearchQuery('');
        },
      )
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
        return DonationCard(donation: donation);
      },
    );
  }
}
