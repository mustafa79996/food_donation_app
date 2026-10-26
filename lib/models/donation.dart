import 'package:cloud_firestore/cloud_firestore.dart';

/// Donation model for a food donation record.
class Donation {
  final String id;
  final String donorId;
  final String donorName;
  final String foodName;
  final String category;
  final int quantity;
  final DateTime expiryDate;
  final String pickupAddress;
  final String contactNumber;
  final String imageUrl;
  final DateTime createdAt;
  final Map<String, bool> foodSafetyChecklist;

  Donation({
    required this.id,
    this.donorId = '',
    required this.donorName,
    required this.foodName,
    required this.category,
    required this.quantity,
    required this.expiryDate,
    required this.pickupAddress,
    required this.contactNumber,
    required this.imageUrl,
    required this.createdAt,
    this.foodSafetyChecklist = const {},
  });

  factory Donation.fromMap(Map<String, dynamic> data, String id) {
    return Donation(
      id: id,
      donorId: data['userId'] as String? ?? '',
      donorName: data['donorName'] as String? ?? 'Anonymous',
      foodName: data['foodName'] as String? ?? '',
      category: data['category'] as String? ?? 'Other',
      quantity: (data['quantity'] as num?)?.toInt() ?? 0,
      expiryDate: _dateFromValue(data['expiryDate']) ?? DateTime.now(),
      pickupAddress: data['pickupAddress'] as String? ?? '',
      contactNumber: data['contactNumber'] as String? ?? '',
      imageUrl: data['imageUrl'] as String? ?? '',
      createdAt: _dateFromValue(data['createdAt']) ?? DateTime.now(),
      foodSafetyChecklist:
          (data['foodSafetyChecklist'] as Map<String, dynamic>? ?? {}).map(
            (key, value) => MapEntry(key, value == true),
          ),
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
      'foodSafetyChecklist': foodSafetyChecklist,
    };
  }
}
