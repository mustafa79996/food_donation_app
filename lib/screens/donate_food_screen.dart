import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../models/donation.dart';
import '../providers/donation_provider.dart';
import '../utils/routes.dart';
import '../utils/storage_helper.dart';
import '../utils/voice_input.dart';

class DonateFoodScreen extends StatefulWidget {
  const DonateFoodScreen({super.key});

  @override
  State<DonateFoodScreen> createState() => _DonateFoodScreenState();
}

class _DonateFoodScreenState extends State<DonateFoodScreen> {
  final _formKey = GlobalKey<FormState>();
  final _foodNameController = TextEditingController();
  final _quantityController = TextEditingController();
  final _contactController = TextEditingController();
  final _pickupAddressController = TextEditingController();
  final _expiryController = TextEditingController();
  DateTime? _expiryDate;
  String _selectedCategory = 'Vegetables';
  File? _imageFile;
  bool _submitting = false;
  bool _foodIsFresh = true;
  bool _foodStoredSafely = true;
  bool _expiryDateConfirmed = true;

  static const Map<String, String> _defaultCategoryImages = {
    'Vegetables':
        'https://images.unsplash.com/photo-1540420773420-3366772f4999?w=500',
    'Fruits':
        'https://images.unsplash.com/photo-1619566636858-adf3ef46400b?w=500',
    'Grains':
        'https://images.unsplash.com/photo-1586201375761-83865001e31c?w=500',
    'Meals':
        'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=500',
    'Other':
        'https://images.unsplash.com/photo-1498837167922-ddd27525d352?w=500',
  };

  @override
  void initState() {
    super.initState();
    final defaultExpiry = DateTime.now().add(const Duration(days: 2));
    _expiryDate = defaultExpiry;
    _expiryController.text =
        '${defaultExpiry.day}/${defaultExpiry.month}/${defaultExpiry.year}';
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 75,
    );
    if (picked != null && mounted) {
      setState(() {
        _imageFile = File(picked.path);
      });
    }
  }

  Future<void> _selectExpiryDate() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _expiryDate ?? now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 60)),
    );
    if (date != null && mounted) {
      setState(() {
        _expiryDate = date;
        _expiryController.text =
            '${date.day}/${date.month}/${date.year}';
      });
    }
  }

  Future<void> _submitDonation() async {
    if (!_formKey.currentState!.validate()) return;

    if (_expiryDate == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Select an expiry date')));
      return;
    }

    if (!_foodIsFresh || !_foodStoredSafely || !_expiryDateConfirmed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please confirm all food safety requirements.'),
        ),
      );
      return;
    }

    setState(() {
      _submitting = true;
    });

    try {
      final donationProvider = Provider.of<DonationProvider>(
        context,
        listen: false,
      );

      String imageUrl = '';
      if (_imageFile != null) {
        try {
          imageUrl = await StorageHelper.uploadDonationImage(_imageFile!);
        } catch (e) {
          debugPrint('Image upload note, using fallback: $e');
          imageUrl = _defaultCategoryImages[_selectedCategory] ??
              _defaultCategoryImages['Other']!;
        }
      } else {
        imageUrl = _defaultCategoryImages[_selectedCategory] ??
            _defaultCategoryImages['Other']!;
      }

      final currentUser = FirebaseAuth.instance.currentUser;
      final donorName = currentUser?.displayName?.isNotEmpty == true
          ? currentUser!.displayName!
          : 'Community Donor';

      final donation = Donation(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        donorName: donorName,
        foodName: _foodNameController.text.trim(),
        category: _selectedCategory,
        quantity: int.tryParse(_quantityController.text.trim()) ?? 1,
        expiryDate: _expiryDate!,
        pickupAddress: _pickupAddressController.text.trim().isNotEmpty
            ? _pickupAddressController.text.trim()
            : 'Contact donor for pickup address',
        contactNumber: _contactController.text.trim(),
        imageUrl: imageUrl,
        createdAt: DateTime.now(),
        foodSafetyChecklist: {
          'fresh': _foodIsFresh,
          'properlyStored': _foodStoredSafely,
          'expiryDateConfirmed': _expiryDateConfirmed,
        },
      );

      await donationProvider.addDonation(donation);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Donation posted successfully! Welfare centres can now accept it.'),
          backgroundColor: Color(0xFF1E7D45),
          duration: Duration(seconds: 4),
        ),
      );

      _formKey.currentState?.reset();
      setState(() {
        _foodNameController.clear();
        _quantityController.clear();
        _contactController.clear();
        _pickupAddressController.clear();
        _imageFile = null;
        _selectedCategory = 'Vegetables';
        _foodIsFresh = true;
        _foodStoredSafely = true;
        _expiryDateConfirmed = true;
      });
    } on FirebaseException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to post donation: ${error.message ?? error.code}',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to submit donation: $error')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _submitting = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _foodNameController.dispose();
    _quantityController.dispose();
    _contactController.dispose();
    _pickupAddressController.dispose();
    _expiryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Donate Food')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Share a meal today',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              const Text(
                'Fill in the food details below. Nearby welfare centres will be notified to accept your donation.',
                style: TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 20),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _foodNameController,
                      decoration: InputDecoration(
                        labelText: 'Food item name',
                        hintText: 'e.g. Cooked rice and curry, Apples, Bread',
                        prefixIcon: const Icon(Icons.fastfood_outlined),
                        border: const OutlineInputBorder(),
                        suffixIcon: Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: VoiceInputIconButton(
                            tooltip: 'Speak food name',
                            onResult: (value) {
                              _foodNameController.text = value;
                              _foodNameController.selection =
                                  TextSelection.fromPosition(
                                TextPosition(
                                  offset: _foodNameController.text.length,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                              ? 'Enter a food name'
                              : null,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedCategory,
                      items: const [
                        DropdownMenuItem(
                          value: 'Vegetables',
                          child: Text('Vegetables'),
                        ),
                        DropdownMenuItem(
                          value: 'Fruits',
                          child: Text('Fruits'),
                        ),
                        DropdownMenuItem(
                          value: 'Grains',
                          child: Text('Grains'),
                        ),
                        DropdownMenuItem(
                          value: 'Meals',
                          child: Text('Prepared Meals'),
                        ),
                        DropdownMenuItem(
                          value: 'Other',
                          child: Text('Other'),
                        ),
                      ],
                      decoration: const InputDecoration(
                        labelText: 'Category',
                        prefixIcon: Icon(Icons.category_outlined),
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _selectedCategory = value;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _quantityController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Quantity (number of servings/packets)',
                        prefixIcon: Icon(Icons.format_list_numbered),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Enter quantity';
                        }
                        final quantity = int.tryParse(value);
                        if (quantity == null || quantity < 1) {
                          return 'Quantity must be at least 1';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _contactController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Contact phone number',
                        prefixIcon: Icon(Icons.phone_outlined),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) => value == null || value.trim().isEmpty
                          ? 'Enter a contact number'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _pickupAddressController,
                      decoration: InputDecoration(
                        labelText: 'Pickup Address / Location',
                        hintText: 'e.g. Street 4, Banjara Hills, Hyderabad',
                        prefixIcon: const Icon(Icons.location_on_outlined),
                        border: const OutlineInputBorder(),
                        suffixIcon: Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: VoiceInputIconButton(
                            tooltip: 'Speak pickup address',
                            onResult: (value) {
                              _pickupAddressController.text = value;
                            },
                          ),
                        ),
                      ),
                      validator: (value) => value == null || value.trim().isEmpty
                          ? 'Enter pickup address'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: _selectExpiryDate,
                      child: AbsorbPointer(
                        child: TextFormField(
                          controller: _expiryController,
                          decoration: const InputDecoration(
                            labelText: 'Expiry date / Safe until',
                            prefixIcon: Icon(Icons.calendar_today_outlined),
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Card(
                      elevation: 1,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Padding(
                              padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
                              child: Text(
                                'Food safety checklist',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            CheckboxListTile(
                              value: _foodIsFresh,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                              title: const Text(
                                'The food is fresh and safe to eat.',
                              ),
                              onChanged: (value) =>
                                  setState(() => _foodIsFresh = value ?? false),
                            ),
                            CheckboxListTile(
                              value: _foodStoredSafely,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                              title: const Text(
                                'The food has been stored safely.',
                              ),
                              onChanged: (value) => setState(
                                () => _foodStoredSafely = value ?? false,
                              ),
                            ),
                            CheckboxListTile(
                              value: _expiryDateConfirmed,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                              title: const Text(
                                'The expiry / consumption date is accurate.',
                              ),
                              onChanged: (value) => setState(
                                () => _expiryDateConfirmed = value ?? false,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Card(
                      elevation: 1,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.business_outlined,
                              color: Color(0xFF1E7D45),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Nearest Welfare Centres',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Find nearby centres ready to distribute food.',
                                    style: TextStyle(
                                      color: Colors.black54,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            TextButton.icon(
                              onPressed: () => Navigator.pushNamed(
                                context,
                                Routes.nearestWelfareCenters,
                              ),
                              icon: const Icon(Icons.arrow_forward),
                              label: const Text('View'),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _pickImage,
                            icon: const Icon(Icons.photo_library_outlined),
                            label: Text(
                              _imageFile != null
                                  ? 'Change Image'
                                  : 'Upload food image (optional)',
                            ),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_imageFile != null) ...[
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.file(
                          _imageFile!,
                          height: 180,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _submitting ? null : _submitDonation,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          backgroundColor: const Color(0xFF1E7D45),
                          foregroundColor: Colors.white,
                        ),
                        child: _submitting
                            ? const SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Post Donation',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
