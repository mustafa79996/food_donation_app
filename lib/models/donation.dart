import 'package:cloud_firestore/cloud_firestore.dart';

/// Donation model for a food donation record.
class Donation {
  final String id;
  final String donorId;
  final String donorEmail;
  final String donorName;
  final String foodName;
  final String category;
  final int quantity;
  final DateTime expiryDate;
  final String pickupAddress;
  final String contactNumber;
  final String imageUrl;
  final DateTime createdAt;
  final String status;
  final String updatedBy;
  final String acceptedBy;
  final String acceptedByEmail;
  final Map<String, bool> foodSafetyChecklist;
  final Map<String, dynamic>? welfareChecklist;

  Donation({
    required this.id,
    this.donorId = '',
    this.donorEmail = '',
    required this.donorName,
    required this.foodName,
    required this.category,
    required this.quantity,
    required this.expiryDate,
    required this.pickupAddress,
    required this.contactNumber,
    required this.imageUrl,
    required this.createdAt,
    this.status = 'pending',
    this.updatedBy = '',
    this.acceptedBy = '',
    this.acceptedByEmail = '',
    this.foodSafetyChecklist = const {},
    this.welfareChecklist,
  });

  bool get hasWelfareChecklist =>
      welfareChecklist != null && welfareChecklist!.isNotEmpty;
  bool get isFoodFreshConfirmed =>
      welfareChecklist?['isFresh'] == true;
  bool get isFoodGoodQualityConfirmed =>
      welfareChecklist?['isGoodQuality'] == true;

  factory Donation.fromMap(Map<String, dynamic> data, String id) {
    return Donation(
      id: id,
      donorId: (data['userId'] ?? data['donorId'] ?? '')?.toString() ?? '',
      donorEmail: data['donorEmail']?.toString() ?? '',
      donorName: data['donorName']?.toString() ?? 'Anonymous',
      foodName: data['foodName']?.toString() ?? '',
      category: data['category']?.toString() ?? 'Other',
      quantity: _parseQuantity(data['quantity']),
      expiryDate: _dateFromValue(data['expiryDate']) ?? DateTime.now(),
      pickupAddress: data['pickupAddress']?.toString() ?? '',
      contactNumber: data['contactNumber']?.toString() ?? '',
      imageUrl: data['imageUrl']?.toString() ?? '',
      createdAt: _dateFromValue(data['createdAt']) ?? DateTime.now(),
      status: (data['status']?.toString() ?? 'pending').toLowerCase(),
      updatedBy: data['updatedBy']?.toString() ?? '',
      acceptedBy: (data['acceptedBy'] ?? data['acceptedByUid'] ?? '')?.toString() ?? '',
      acceptedByEmail: data['acceptedByEmail']?.toString() ?? '',
      foodSafetyChecklist: _parseSafetyChecklist(data['foodSafetyChecklist']),
      welfareChecklist: _parseWelfareChecklist(data['welfareChecklist']),
    );
  }

  static int _parseQuantity(Object? value) {
    if (value == null) return 1;
    if (value is num) return value.toInt();
    if (value is String) {
      final direct = int.tryParse(value.trim());
      if (direct != null) return direct;
      // Extract first sequence of digits, e.g. "5 plates" -> 5
      final match = RegExp(r'\d+').firstMatch(value);
      if (match != null) {
        return int.tryParse(match.group(0)!) ?? 1;
      }
    }
    return 1;
  }

  static Map<String, bool> _parseSafetyChecklist(Object? value) {
    if (value is! Map) return const {};
    final result = <String, bool>{};
    for (final entry in value.entries) {
      result[entry.key.toString()] = entry.value == true;
    }
    return result;
  }

  static Map<String, dynamic>? _parseWelfareChecklist(Object? value) {
    if (value is! Map) return null;
    final result = <String, dynamic>{};
    for (final entry in value.entries) {
      result[entry.key.toString()] = entry.value;
    }
    return result;
  }

  static DateTime? _dateFromValue(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  Map<String, dynamic> toMap() {
    return {
      'donorId': donorId,
      'userId': donorId,
      'donorEmail': donorEmail,
      'donorName': donorName,
      'foodName': foodName,
      'category': category,
      'quantity': quantity,
      'expiryDate': Timestamp.fromDate(expiryDate),
      'pickupAddress': pickupAddress,
      'contactNumber': contactNumber,
      'imageUrl': imageUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'status': status,
      'updatedBy': updatedBy,
      'acceptedBy': acceptedBy,
      'acceptedByEmail': acceptedByEmail,
      'foodSafetyChecklist': foodSafetyChecklist,
      if (welfareChecklist != null) 'welfareChecklist': welfareChecklist,
    };
  }

  Donation copyWith({
    String? id,
    String? donorId,
    String? donorEmail,
    String? donorName,
    String? foodName,
    String? category,
    int? quantity,
    DateTime? expiryDate,
    String? pickupAddress,
    String? contactNumber,
    String? imageUrl,
    DateTime? createdAt,
    String? status,
    String? updatedBy,
    String? acceptedBy,
    String? acceptedByEmail,
    Map<String, bool>? foodSafetyChecklist,
    Map<String, dynamic>? welfareChecklist,
  }) {
    return Donation(
      id: id ?? this.id,
      donorId: donorId ?? this.donorId,
      donorEmail: donorEmail ?? this.donorEmail,
      donorName: donorName ?? this.donorName,
      foodName: foodName ?? this.foodName,
      category: category ?? this.category,
      quantity: quantity ?? this.quantity,
      expiryDate: expiryDate ?? this.expiryDate,
      pickupAddress: pickupAddress ?? this.pickupAddress,
      contactNumber: contactNumber ?? this.contactNumber,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      updatedBy: updatedBy ?? this.updatedBy,
      acceptedBy: acceptedBy ?? this.acceptedBy,
      acceptedByEmail: acceptedByEmail ?? this.acceptedByEmail,
      foodSafetyChecklist: foodSafetyChecklist ?? this.foodSafetyChecklist,
      welfareChecklist: welfareChecklist ?? this.welfareChecklist,
    );
  }
}
