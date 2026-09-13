import 'package:flutter/material.dart';

import '../models/donation.dart';
import '../screens/donation_details_screen.dart';
import '../screens/donate_food_screen.dart';
import '../screens/food_list_screen.dart';
import '../screens/home_screen.dart';
import '../screens/login_screen.dart';
import '../screens/nearest_welfare_centers_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/signup_screen.dart';
import '../screens/welfare_dashboard_screen.dart';
import '../screens/welfare_login_screen.dart';

abstract class Routes {
  static const login = '/login';
  static const signup = '/signup';
  static const main = '/main';
  static const donate = '/donate';
  static const foodList = '/food-list';
  static const details = '/details';
  static const profile = '/profile';
  static const settings = '/settings';
  static const nearestWelfareCenters = '/nearest-welfare-centers';
  static const welfareLogin = '/welfare-login';
  static const welfareDashboard = '/welfare-dashboard';

  static Map<String, Widget Function(BuildContext)> get routes => {
        login: (_) => const LoginScreen(),
        signup: (_) => const SignUpScreen(),
        main: (_) => const HomeScreen(),
        donate: (_) => const DonateFoodScreen(),
        foodList: (_) => const FoodListScreen(),
        profile: (_) => const ProfileScreen(),
        settings: (_) => const SettingsScreen(),
        nearestWelfareCenters: (_) =>
            const NearestWelfareCentersScreen(),
        welfareLogin: (_) => const WelfareLoginScreen(),
        welfareDashboard: (_) => const WelfareDashboardScreen(),
      };

  static Route<dynamic>? onGenerateRoute(
    RouteSettings settings,
  ) {
    if (settings.name == details) {
      final donation = settings.arguments as Donation?;

      return MaterialPageRoute(
        builder: (_) => DonationDetailsScreen(
          donation: donation,
        ),
      );
    }

    return null;
  }
}