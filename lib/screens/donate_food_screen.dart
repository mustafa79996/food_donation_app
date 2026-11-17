import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../models/donation.dart';
import '../providers/donation_provider.dart';
import '../utils/app_theme.dart';
import '../utils/routes.dart';
import '../utils/storage_helper.dart';
import '../utils/voice_input.dart';
import '../widgets/foodlink_ui_components.dart';
import '../widgets/notifications_modal.dart';

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
  String _selectedCategory = 'Meals';
  File? _imageFile;
  bool _submitting = false;

  // 4 Food Safety Checklist items from the screenshot
  bool _foodIsFresh = true;
  bool _foodStoredSafely = true;
  bool _properlyPacked = true;
  bool _expiryDateConfirmed = true;

  static const List<String> _categories = [
    'Meals',
    'Vegetables',
    'Fruits',
    'Grains',
    'Snacks',
    'Beverages',
    'Other',
  ];

  static const Map<String, String> _defaultCategoryImages = {
    'Meals':
        'https://images.unsplash.com/photo-1589302168068-964664d93dc0?w=600',
    'Vegetables':
        'https://images.unsplash.com/photo-1540420773420-3366772f4999?w=600',
    'Fruits':
        'https://images.unsplash.com/photo-1619566636858-adf3ef46400b?w=600',
    'Grains':
        'https://images.unsplash.com/photo-1586201375761-83865001e31c?w=600',
    'Snacks':
        'https://images.unsplash.com/photo-1599490659213-e2b9527bd087?w=600',
    'Beverages':
        'https://images.unsplash.com/photo-1544787219-7f47ccb76574?w=600',
    'Other':
        'https://images.unsplash.com/photo-1498837167922-ddd27525d352?w=600',
  };

  @override
  void initState() {
    super.initState();
    final defaultExpiry = DateTime.now().add(const Duration(days: 2));
    _expiryDate = defaultExpiry;
    _expiryController.text =
        '${defaultExpiry.day} ${_getMonthName(defaultExpiry.month)} ${defaultExpiry.year}';
  }

  String _getMonthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return months[(month - 1) % 12];
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
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primaryGreen,
              onPrimary: Colors.white,
              onSurface: AppTheme.textDark,
            ),
          ),
          child: child!,
        );
      },
    );
    if (date != null && mounted) {
      setState(() {
        _expiryDate = date;
        _expiryController.text =
            '${date.day} ${_getMonthName(date.month)} ${date.year}';
      });
    }
  }

  Future<void> _submitDonation() async {
    if (!_formKey.currentState!.validate()) return;

    if (_expiryDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an expiry date')),
      );
      return;
    }

    if (!_foodIsFresh ||
        !_foodStoredSafely ||
        !_properlyPacked ||
        !_expiryDateConfirmed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please check and confirm all food safety requirements.'),
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
          debugPrint('Image upload notice, using category visual: $e');
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
          : 'Mohammed Mustafa';
      final donorEmail = currentUser?.email ?? '';

      final donation = Donation(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        donorId: currentUser?.uid ?? 'JLF2gw2ZbaA6qH3derzVHEE1tr2',
        donorEmail: donorEmail,
        donorName: donorName,
        foodName: _foodNameController.text.trim(),
        category: _selectedCategory,
        quantity: int.tryParse(_quantityController.text.trim()) ?? 1,
        expiryDate: _expiryDate!,
        pickupAddress: _pickupAddressController.text.trim().isNotEmpty
            ? _pickupAddressController.text.trim()
            : 'Donor Contact',
        contactNumber: _contactController.text.trim(),
        imageUrl: imageUrl,
        createdAt: DateTime.now(),
        status: 'pending',
        foodSafetyChecklist: {
          'fresh': _foodIsFresh,
          'properlyStored': _foodStoredSafely,
          'properlyPacked': _properlyPacked,
          'expiryDateConfirmed': _expiryDateConfirmed,
        },
      );

      await donationProvider.addDonation(donation);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Donation posted! Notification & confirmation email sent to you and welfare centres.',
          ),
          backgroundColor: AppTheme.primaryGreen,
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'View History',
            textColor: Colors.white,
            onPressed: () {
              Navigator.pushNamed(
                context,
                Routes.foodList,
                arguments: {'myDonations': true},
              );
            },
          ),
        ),
      );

      _formKey.currentState?.reset();
      setState(() {
        _foodNameController.clear();
        _quantityController.clear();
        _contactController.clear();
        _pickupAddressController.clear();
        _imageFile = null;
        _selectedCategory = 'Meals';
        _foodIsFresh = true;
        _foodStoredSafely = true;
        _properlyPacked = true;
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
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Curved Green Header Banner matching SCREEN1.jpeg
            ClipPath(
              clipper: SoftCurvedHeaderClipper(),
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.fromLTRB(
                  20,
                  MediaQuery.of(context).padding.top + 10,
                  20,
                  36,
                ),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFF0D4A27), // Deep dark green
                      Color(0xFF135D39),
                      Color(0xFF166534), // Rich emerald
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Bar: Logo + Notification Bell
                    FoodLinkHeaderTopRow(
                      hasNotificationDot: true,
                      onTrailingTap: () => NotificationsModal.show(context),
                    ),
                    const SizedBox(height: 18),

                    // Banner Content Row (Title & Subtitle + Salad Bowl)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Donate Food',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Share a meal today',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Fill in the details below so volunteers can pick up the donation.',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.85),
                                  fontSize: 12.5,
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        const SaladBowlIllustration(size: 88),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Form Body
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Food name
                    _buildFieldLabel('Food name'),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _foodNameController,
                      decoration: InputDecoration(
                        hintText: 'e.g. Biryani, Idli, Pasta',
                        prefixIcon: const Icon(
                          Icons.dinner_dining_outlined,
                          color: Color(0xFF64748B),
                          size: 22,
                        ),
                        suffixIcon: Padding(
                          padding: const EdgeInsets.only(right: 6),
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

                    // Category
                    _buildFieldLabel('Category'),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedCategory,
                      items: _categories.map((cat) {
                        return DropdownMenuItem(
                          value: cat,
                          child: Text(cat),
                        );
                      }).toList(),
                      decoration: const InputDecoration(
                        hintText: 'Select category',
                        prefixIcon: Icon(
                          Icons.category_outlined,
                          color: Color(0xFF64748B),
                          size: 22,
                        ),
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

                    // Quantity
                    _buildFieldLabel('Quantity'),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _quantityController,
                      decoration: const InputDecoration(
                        hintText: 'e.g. 5 plates, 2 kg',
                        prefixIcon: Icon(
                          Icons.format_list_bulleted_rounded,
                          color: Color(0xFF64748B),
                          size: 22,
                        ),
                      ),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                              ? 'Enter quantity'
                              : null,
                    ),
                    const SizedBox(height: 16),

                    // Contact number
                    _buildFieldLabel('Contact number'),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _contactController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        hintText: 'e.g. 9876543210',
                        prefixIcon: Icon(
                          Icons.phone_outlined,
                          color: Color(0xFF64748B),
                          size: 22,
                        ),
                      ),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                              ? 'Enter contact number'
                              : null,
                    ),
                    const SizedBox(height: 16),

                    // Expiry date
                    _buildFieldLabel('Expiry date'),
                    const SizedBox(height: 6),
                    GestureDetector(
                      onTap: _selectExpiryDate,
                      child: AbsorbPointer(
                        child: TextFormField(
                          controller: _expiryController,
                          decoration: const InputDecoration(
                            hintText: 'Select date',
                            prefixIcon: Icon(
                              Icons.calendar_today_outlined,
                              color: Color(0xFF64748B),
                              size: 20,
                            ),
                            suffixIcon: Icon(
                              Icons.calendar_month_outlined,
                              color: Color(0xFF64748B),
                              size: 22,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Pickup Address (preserved for welfare pickups)
                    _buildFieldLabel('Pickup location (optional)'),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _pickupAddressController,
                      decoration: InputDecoration(
                        hintText: 'e.g. Street 4, Banjara Hills, Hyderabad',
                        prefixIcon: const Icon(
                          Icons.location_on_outlined,
                          color: Color(0xFF64748B),
                          size: 22,
                        ),
                        suffixIcon: Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: VoiceInputIconButton(
                            tooltip: 'Speak pickup address',
                            onResult: (value) {
                              _pickupAddressController.text = value;
                            },
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Upload food image
                    Row(
                      children: const [
                        Icon(
                          Icons.image_outlined,
                          size: 19,
                          color: Color(0xFF1E293B),
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Upload food image',
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (_imageFile == null)
                      DashedBorderContainer(
                        height: 95,
                        borderColor: const Color(0xFF86EFAC),
                        onTap: _pickImage,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                color: Color(0xFF135D39),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.camera_alt_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Tap to upload image',
                              style: TextStyle(
                                fontSize: 13,
                                color: Color(0xFF15803D),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.file(
                              _imageFile!,
                              height: 160,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: InkWell(
                              onTap: () => setState(() => _imageFile = null),
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: const BoxDecoration(
                                  color: Colors.black54,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 20),

                    // Food safety checklist Card
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0FDF4), // Pale mint green
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFFDCFCE7),
                          width: 1.2,
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(
                        vertical: 14,
                        horizontal: 14,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: const [
                              Icon(
                                Icons.check_circle_rounded,
                                color: Color(0xFF15803D),
                                size: 22,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Food safety checklist',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF14532D),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          _buildCheckItem(
                            title: 'The food is fresh and safe to consume.',
                            value: _foodIsFresh,
                            onChanged: (val) =>
                                setState(() => _foodIsFresh = val ?? false),
                          ),
                          _buildCheckItem(
                            title: 'Stored at a proper temperature.',
                            value: _foodStoredSafely,
                            onChanged: (val) => setState(
                              () => _foodStoredSafely = val ?? false,
                            ),
                          ),
                          _buildCheckItem(
                            title: 'Properly packed and sealed.',
                            value: _properlyPacked,
                            onChanged: (val) => setState(
                              () => _properlyPacked = val ?? false,
                            ),
                          ),
                          _buildCheckItem(
                            title: 'It is within the expiry date.',
                            value: _expiryDateConfirmed,
                            onChanged: (val) => setState(
                              () => _expiryDateConfirmed = val ?? false,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Nearest Welfare Centres Card
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFFE2E8F0),
                          width: 1.2,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F5E9),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.location_city_outlined,
                              color: Color(0xFF15803D),
                              size: 22,
                            ),
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
                                    fontSize: 14,
                                    color: Color(0xFF1E293B),
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Find nearby centres ready to distribute food.',
                                  style: TextStyle(
                                    color: Color(0xFF64748B),
                                    fontSize: 12,
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
                            icon: const Icon(
                              Icons.arrow_forward_rounded,
                              size: 16,
                              color: Color(0xFF15803D),
                            ),
                            label: const Text(
                              'View',
                              style: TextStyle(
                                color: Color(0xFF15803D),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Post Donation Button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _submitting ? null : _submitDonation,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0F5132), // Deep green
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                          elevation: 0,
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
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Icon(
                                    Icons.near_me_rounded,
                                    size: 20,
                                    color: Colors.white,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Post Donation',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 13.5,
        fontWeight: FontWeight.w600,
        color: Color(0xFF1E293B),
      ),
    );
  }

  Widget _buildCheckItem({
    required String title,
    required bool value,
    required ValueChanged<bool?> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: InkWell(
        onTap: () => onChanged(!value),
        borderRadius: BorderRadius.circular(6),
        child: Row(
          children: [
            SizedBox(
              height: 22,
              width: 22,
              child: Checkbox(
                value: value,
                activeColor: const Color(0xFF15803D),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5),
                ),
                side: const BorderSide(color: Color(0xFF94A3B8), width: 1.5),
                onChanged: onChanged,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 13.5,
                  color: Color(0xFF334155),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
