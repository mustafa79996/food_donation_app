import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/donation.dart';
import '../services/notification_service.dart';

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
  String _selectedStatus = 'All'; // 'All', 'pending', 'accepted', 'rejected'
  String _selectedScope = 'All'; // 'All', 'My Donations'

  String get searchQuery => _searchQuery;
  String get selectedCategory => _selectedCategory;
  String get selectedStatus => _selectedStatus;
  String get selectedScope => _selectedScope;

  User? get currentUser => _auth.currentUser;

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
                parsedList.add(Donation.fromMap(data, doc.id));
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

  bool _isDonationFromUser(Donation donation) {
    final user = _auth.currentUser;
    if (user == null) return false;

    final uid = user.uid;
    final email = user.email?.trim().toLowerCase();
    final name = user.displayName?.trim().toLowerCase();

    if (donation.donorId.isNotEmpty && donation.donorId == uid) return true;
    if (email != null &&
        donation.donorEmail.isNotEmpty &&
        donation.donorEmail.toLowerCase() == email) {
      return true;
    }
    if (name != null &&
        donation.donorName.isNotEmpty &&
        donation.donorName.toLowerCase() == name) {
      return true;
    }
    return false;
  }

  List<Donation> get myDonations {
    return _donations.where(_isDonationFromUser).toList();
  }

  int get totalCount => _selectedScope == 'My Donations'
      ? myDonations.length
      : _donations.length;

  int get pendingCount {
    final base = _selectedScope == 'My Donations' ? myDonations : _donations;
    return base.where((d) {
      final s = d.status.toLowerCase();
      return s == 'pending' || s == '';
    }).length;
  }

  int get acceptedCount {
    final base = _selectedScope == 'My Donations' ? myDonations : _donations;
    return base.where((d) {
      final s = d.status.toLowerCase();
      return s == 'accepted' || s == 'approved';
    }).length;
  }

  int get rejectedCount {
    final base = _selectedScope == 'My Donations' ? myDonations : _donations;
    return base.where((d) {
      final s = d.status.toLowerCase();
      return s == 'rejected';
    }).length;
  }

  List<Donation> get filteredDonations {
    return searchDonations(_searchQuery);
  }

  List<Donation> searchDonations(String searchText) {
    final query = searchText.trim().toLowerCase();
    final source = _selectedScope == 'My Donations' ? myDonations : _donations;

    return source.where((donation) {
      final matchesSearch =
          query.isEmpty ||
          donation.foodName.toLowerCase().contains(query) ||
          donation.category.toLowerCase().contains(query) ||
          donation.pickupAddress.toLowerCase().contains(query) ||
          donation.status.toLowerCase().contains(query);

      final matchesCategory =
          _selectedCategory == 'All' ||
          donation.category.toLowerCase() == _selectedCategory.toLowerCase();

      bool matchesStatus = true;
      final st = donation.status.toLowerCase();
      if (_selectedStatus != 'All') {
        if (_selectedStatus == 'pending') {
          matchesStatus = st == 'pending' || st == '';
        } else if (_selectedStatus == 'accepted') {
          matchesStatus = st == 'accepted' || st == 'approved';
        } else if (_selectedStatus == 'rejected') {
          matchesStatus = st == 'rejected';
        }
      }

      return matchesSearch && matchesCategory && matchesStatus;
    }).toList();
  }

  Future<void> addDonation(Donation donation) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('Please login before posting a donation.');
    }

    final donorEmail = user.email ?? (donation.donorEmail.isNotEmpty ? donation.donorEmail : 'donor@foodlink.org');
    final donorName = user.displayName?.isNotEmpty == true
        ? user.displayName!
        : (donation.donorName.isNotEmpty ? donation.donorName : 'Mohammed Mustafa');

    final donationData = donation.toMap();

    // Attach donor user UID, email, status, and server timestamps
    donationData['userId'] = user.uid;
    donationData['donorId'] = user.uid;
    donationData['donorEmail'] = donorEmail;
    donationData['donorName'] = donorName;
    donationData['status'] = 'pending';
    donationData['createdAt'] = FieldValue.serverTimestamp();
    donationData['foodSafetyConfirmedAt'] = FieldValue.serverTimestamp();

    final docRef = await _firestore.collection('donations').add(donationData);

    // Create a local donation representation for immediate notification triggering
    final createdDonation = Donation(
      id: docRef.id,
      donorId: user.uid,
      donorEmail: donorEmail,
      donorName: donorName,
      foodName: donation.foodName,
      category: donation.category,
      quantity: donation.quantity,
      expiryDate: donation.expiryDate,
      pickupAddress: donation.pickupAddress,
      contactNumber: donation.contactNumber,
      imageUrl: donation.imageUrl,
      createdAt: DateTime.now(),
      status: 'pending',
      foodSafetyChecklist: donation.foodSafetyChecklist,
    );

    // Notify donor and all welfare centres with in-app notifications and email!
    await NotificationService.notifyDonationCreated(
      donation: createdDonation,
      donorEmail: donorEmail,
    );
  }

  Future<void> deleteDonation(String donationId) async {
    await _firestore.collection('donations').doc(donationId).delete();
    _donations.removeWhere((d) => d.id == donationId);
    notifyListeners();
  }

  void updateSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void selectCategory(String category) {
    _selectedCategory = category;
    notifyListeners();
  }

  void selectStatus(String status) {
    _selectedStatus = status;
    notifyListeners();
  }

  void selectScope(String scope) {
    _selectedScope = scope;
    notifyListeners();
  }

  @override
  void dispose() {
    unawaited(_subscription?.cancel() ?? Future<void>.value());
    unawaited(_authSubscription?.cancel() ?? Future<void>.value());
    super.dispose();
  }
}
