import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../models/donation.dart';
import '../providers/donation_provider.dart';
import '../utils/routes.dart';
import '../utils/storage_helper.dart';

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
  final _expiryController = TextEditingController();
  DateTime? _expiryDate;
  String _selectedCategory = 'Vegetables';
  File? _imageFile;
  bool _submitting = false;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 75);
    if (picked != null) {
      setState(() {
        _imageFile = File(picked.path);
      });
    }
  }

  Future<void> _selectExpiryDate() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 30)),
    );
    if (date != null) {
      setState(() {
        _expiryDate = date;
        _expiryController.text = MaterialLocalizations.of(context).formatMediumDate(date);
      });
    }
  }

  Future<void> _submitDonation() async {
    if (!_formKey.currentState!.validate()) return;
    if (_imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please upload an image of the donation')));
      return;
    }
    if (_expiryDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Select an expiry date')));
      return;
    }

    setState(() {
      _submitting = true;
    });

    try {
      final donationProvider = Provider.of<DonationProvider>(context, listen: false);
      final imageUrl = await StorageHelper.uploadDonationImage(_imageFile!);
      final donation = Donation(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        donorName: 'Community Donor',
        foodName: _foodNameController.text.trim(),
        category: _selectedCategory,
        quantity: int.tryParse(_quantityController.text.trim()) ?? 1,
        expiryDate: _expiryDate!,
        pickupAddress: '',
        contactNumber: _contactController.text.trim(),
        imageUrl: imageUrl,
        createdAt: DateTime.now(),
      );
      await donationProvider.addDonation(donation);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Donation posted successfully')));
      _formKey.currentState?.reset();
      setState(() {
        _expiryDate = null;
        _expiryController.clear();
        _imageFile = null;
        _selectedCategory = 'Vegetables';
      });
    } on FirebaseException catch (error) {
      if (!mounted) return;
      final service = error.plugin == 'firebase_storage' ? 'image upload' : 'donation save';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to complete $service: ${error.message ?? error.code}')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Unable to submit donation: $error')));
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
              const Text('Share a meal today', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('Fill in the details below so volunteers can pick up the donation.', style: TextStyle(color: Colors.black54)),
              const SizedBox(height: 24),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _foodNameController,
                      decoration: const InputDecoration(labelText: 'Food name', prefixIcon: Icon(Icons.fastfood_outlined)),
                      validator: (value) => value == null || value.isEmpty ? 'Enter a food name' : null,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedCategory,
                      items: const [
                        DropdownMenuItem(value: 'Vegetables', child: Text('Vegetables')),
                        DropdownMenuItem(value: 'Fruits', child: Text('Fruits')),
                        DropdownMenuItem(value: 'Grains', child: Text('Grains')),
                        DropdownMenuItem(value: 'Meals', child: Text('Prepared Meals')),
                        DropdownMenuItem(value: 'Other', child: Text('Other')),
                      ],
                      decoration: const InputDecoration(labelText: 'Category', prefixIcon: Icon(Icons.category_outlined)),
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
                      decoration: const InputDecoration(labelText: 'Quantity', prefixIcon: Icon(Icons.format_list_numbered)),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Enter quantity';
                        }
                        if (int.tryParse(value) == null) {
                          return 'Quantity must be a number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _contactController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(labelText: 'Contact number', prefixIcon: Icon(Icons.phone_outlined)),
                      validator: (value) => value == null || value.isEmpty ? 'Enter a contact number' : null,
                    ),
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: _selectExpiryDate,
                      child: AbsorbPointer(
                        child: TextFormField(
                          controller: _expiryController,
                          decoration: InputDecoration(
                            labelText: 'Expiry date',
                            prefixIcon: const Icon(Icons.calendar_today_outlined),
                            hintText: 'Select a date',
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            const Icon(Icons.location_on_outlined, color: Colors.green),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: const [
                                  Text('Nearest welfare centers', style: TextStyle(fontWeight: FontWeight.bold)),
                                  SizedBox(height: 4),
                                  Text('We will connect your donation with the closest support center.'),
                                ],
                              ),
                            ),
                            TextButton.icon(
                              onPressed: () => Navigator.pushNamed(context, Routes.nearestWelfareCenters),
                              icon: const Icon(Icons.map_outlined),
                              label: const Text('View centers'),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _pickImage,
                            icon: const Icon(Icons.photo_library_outlined),
                            label: const Text('Upload image'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (_imageFile != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.file(
                          _imageFile!,
                          height: 180,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _submitting ? null : _submitDonation,
                      child: _submitting
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                            )
                          : const Text('Post Donation'),
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
