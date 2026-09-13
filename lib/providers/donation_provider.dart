import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/donation.dart';

class DonationProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final List<Donation> _donations = [];

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _subscription;

  List<Donation> get donations => List.unmodifiable(_donations);

  String _searchQuery = '';
  String _selectedCategory = 'All';

  String get searchQuery => _searchQuery;
  String get selectedCategory => _selectedCategory;

  DonationProvider() {
    _listenToDonations();
  }

  void _listenToDonations() {
    final user = _auth.currentUser;

    if (user == null) {
      _donations.clear();
      notifyListeners();
      return;
    }

    _subscription = _firestore
        .collection('donations')
        .where('userId', isEqualTo: user.uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen((snapshot) {
      _donations.clear();

      for (final doc in snapshot.docs) {
        _donations.add(
          Donation.fromMap(doc.data(), doc.id),
        );
      }

      notifyListeners();
    });
  }

  List<Donation> get filteredDonations {
    final query = _searchQuery.trim().toLowerCase();

    return _donations.where((donation) {
      final matchesSearch =
          query.isEmpty ||
          donation.foodName.toLowerCase().contains(query) ||
          donation.category.toLowerCase().contains(query);

      final matchesCategory =
          _selectedCategory == 'All' ||
          donation.category == _selectedCategory;

      return matchesSearch && matchesCategory;
    }).toList();
  }

  Future<void> addDonation(Donation donation) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('Please login before posting a donation.');
    }

    final donationData = donation.toMap();

    // Attach the Firebase user's UID to this donation.
    donationData['userId'] = user.uid;
    donationData['status'] = 'pending';

    await _firestore
        .collection('donations')
        .add(donationData);
  }

  void updateSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void selectCategory(String category) {
    _selectedCategory = category;
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
