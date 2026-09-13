import 'package:cloud_firestore/cloud_firestore.dart';

/// Donation model for a food donation record.
 class Donation {
  final String id;
  final String donorName;
  final String foodName;
  final String category;
  final int quantity;
  final DateTime expiryDate;
  final String pickupAddress;
  final String contactNumber;
  final String imageUrl;
  final DateTime createdAt;

  Donation({
    required this.id,
    required this.donorName,
    required this.foodName,
    required this.category,
    required this.quantity,
    required this.expiryDate,
    required this.pickupAddress,
    required this.contactNumber,
    required this.imageUrl,
    required this.createdAt,
  });

  factory Donation.fromMap(Map<String, dynamic> data, String id) {
    return Donation(
      id: id,
      donorName: data['donorName'] as String? ?? 'Anonymous',
      foodName: data['foodName'] as String? ?? '',
      category: data['category'] as String? ?? 'Other',
      quantity: (data['quantity'] as num?)?.toInt() ?? 0,
      expiryDate: _dateFromValue(data['expiryDate']) ?? DateTime.now(),
      pickupAddress: data['pickupAddress'] as String? ?? '',
      contactNumber: data['contactNumber'] as String? ?? '',
      imageUrl: data['imageUrl'] as String? ?? '',
      createdAt: _dateFromValue(data['createdAt']) ?? DateTime.now(),
    );
  }

  static DateTime? _dateFromValue(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  Map<String, dynamic> toMap() {
    return {
      'donorName': donorName,
      'foodName': foodName,
      'category': category,
      'quantity': quantity,
      'expiryDate': Timestamp.fromDate(expiryDate),
      'pickupAddress': pickupAddress,
      'contactNumber': contactNumber,
      'imageUrl': imageUrl,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
