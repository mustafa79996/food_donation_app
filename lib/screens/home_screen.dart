import 'package:flutter/material.dart';

import '../screens/donate_food_screen.dart';
import '../screens/food_list_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  static const List<Widget> _tabs = <Widget>[
    DonateFoodScreen(),
    FoodListScreen(),
    ProfileScreen(),
    SettingsScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Determine active navigation color based on current screen
    final isProfileTab = _selectedIndex == 2;
    final activeColor = isProfileTab
        ? const Color(0xFF5B4DDF) // Royal purple for profile
        : const Color(0xFF0F5132); // Deep forest green

    return Scaffold(
      body: _tabs[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: Colors.grey.shade200, width: 1),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(
                  index: 0,
                  icon: Icons.volunteer_activism_outlined,
                  activeIcon: Icons.volunteer_activism_rounded,
                  label: 'Donate',
                  isSelected: _selectedIndex == 0,
                  activeColor: activeColor,
                ),
                _buildNavItem(
                  index: 1,
                  icon: Icons.format_list_bulleted_rounded,
                  activeIcon: Icons.format_list_bulleted_rounded,
                  label: 'Donations',
                  isSelected: _selectedIndex == 1,
                  activeColor: activeColor,
                ),
                _buildNavItem(
                  index: 2,
                  icon: Icons.person_outline_rounded,
                  activeIcon: Icons.person_rounded,
                  label: 'Profile',
                  isSelected: _selectedIndex == 2,
                  activeColor: activeColor,
                  isProfilePill: true,
                ),
                _buildNavItem(
                  index: 3,
                  icon: Icons.settings_outlined,
                  activeIcon: Icons.settings_rounded,
                  label: 'Settings',
                  isSelected: _selectedIndex == 3,
                  activeColor: activeColor,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required bool isSelected,
    required Color activeColor,
    bool isProfilePill = false,
  }) {
    // Profile screen in screenshot has a soft purple circle/pill highlight
    final showPill = isSelected && isProfilePill;

    return InkWell(
      onTap: () => _onItemTapped(index),
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: showPill
                  ? const EdgeInsets.symmetric(horizontal: 14, vertical: 4)
                  : EdgeInsets.zero,
              decoration: showPill
                  ? BoxDecoration(
                      color: const Color(0xFFEDE9FE), // Soft purple capsule
                      borderRadius: BorderRadius.circular(16),
                    )
                  : null,
              child: Icon(
                isSelected ? activeIcon : icon,
                size: 23,
                color: isSelected ? activeColor : const Color(0xFF94A3B8),
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? activeColor : const Color(0xFF94A3B8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
