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
  StreamSubscription<User?>? _authSubscription;

  List<Donation> get donations => List.unmodifiable(_donations);

  bool isLoading = true;
  String? errorMessage;
  String _searchQuery = '';
  String _selectedCategory = 'All';

  String get searchQuery => _searchQuery;
  String get selectedCategory => _selectedCategory;

  DonationProvider() {
    _authSubscription = _auth.authStateChanges().listen(_listenToDonations);
    // Also initiate listening if already signed in
    if (_auth.currentUser != null) {
      _listenToDonations(_auth.currentUser);
    } else {
      isLoading = false;
      notifyListeners();
    }
  }

  void _listenToDonations(User? user) {
    unawaited(_subscription?.cancel() ?? Future<void>.value());
    _subscription = null;
    _donations.clear();
    errorMessage = null;

    if (user == null) {
      isLoading = false;
      notifyListeners();
      return;
    }

    isLoading = true;
    notifyListeners();

    _subscription = _firestore
        .collection('donations')
        .snapshots()
        .listen(
          (snapshot) {
            final parsedList = <Donation>[];
            for (final doc in snapshot.docs) {
              try {
                final data = doc.data();
                final status = (data['status'] as String? ?? 'pending').toLowerCase();
                // Include pending or untagged donations
                if (status == 'pending' || status == '') {
                  parsedList.add(Donation.fromMap(data, doc.id));
                }
              } catch (e) {
                debugPrint('Error parsing donation ${doc.id}: $e');
              }
            }

            parsedList.sort(
              (first, second) => second.createdAt.compareTo(first.createdAt),
            );

            _donations
              ..clear()
              ..addAll(parsedList);

            isLoading = false;
            errorMessage = null;
            notifyListeners();
          },
          onError: (Object error) {
            debugPrint('Donations stream error: $error');
            isLoading = false;
            if (error.toString().contains('permission-denied')) {
              errorMessage =
                  'Firestore Permission Denied.\n\nPlease update your Firestore Security Rules in Firebase Console (see firestore.rules in project).';
            } else {
              errorMessage = 'Unable to load donations: $error';
            }
            notifyListeners();
          },
        );
  }

  List<Donation> get filteredDonations {
    return searchDonations(_searchQuery);
  }

  List<Donation> searchDonations(String searchText) {
    final query = searchText.trim().toLowerCase();

    return _donations.where((donation) {
      final matchesSearch =
          query.isEmpty ||
          donation.foodName.toLowerCase().contains(query) ||
          donation.category.toLowerCase().contains(query) ||
          donation.pickupAddress.toLowerCase().contains(query);

      final matchesCategory =
          _selectedCategory == 'All' || donation.category == _selectedCategory;

      return matchesSearch && matchesCategory;
    }).toList();
  }

  Future<void> addDonation(Donation donation) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('Please login before posting a donation.');
    }

    final donationData = donation.toMap();

    // Attach donor user UID, status, and server timestamps
    donationData['userId'] = user.uid;
    donationData['donorName'] = user.displayName?.isNotEmpty == true
        ? user.displayName
        : (donation.donorName.isNotEmpty ? donation.donorName : 'Community Donor');
    donationData['status'] = 'pending';
    donationData['createdAt'] = FieldValue.serverTimestamp();
    donationData['foodSafetyConfirmedAt'] = FieldValue.serverTimestamp();

    await _firestore.collection('donations').add(donationData);
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
    unawaited(_subscription?.cancel() ?? Future<void>.value());
    unawaited(_authSubscription?.cancel() ?? Future<void>.value());
    super.dispose();
  }
}
