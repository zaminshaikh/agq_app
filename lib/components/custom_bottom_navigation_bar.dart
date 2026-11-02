import 'package:agq_app/content/app_content.dart';
import 'package:agq_app/content/content_image.dart';
import 'package:flutter/material.dart';
import 'package:agq_app/screens/activity/activity.dart';
import 'package:agq_app/screens/analytics/analytics.dart';
import 'package:agq_app/screens/dashboard/dashboard.dart';
import 'package:agq_app/screens/profile/profile.dart';

enum NavigationItem { dashboard, analytics, activity, profile }

class CustomBottomNavigationBar extends StatelessWidget {
  final NavigationItem currentItem;

  const CustomBottomNavigationBar({
    super.key,
    required this.currentItem,
  });

  void _onItemTapped(BuildContext context, NavigationItem item) {
    if (item == currentItem) {
      return; // Do nothing if the item is already selected
    }

    Widget page;
    switch (item) {
      case NavigationItem.dashboard:
        page = const DashboardPage();
        break;
      case NavigationItem.analytics:
        page = const AnalyticsPage();
        break;
      case NavigationItem.activity:
        page = const ActivityPage();
        break;
      case NavigationItem.profile:
        page = const ProfilePage();
        break;
    }

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    AppContent.watch(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 30, right: 20, left: 20),
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 30, 41, 59),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            spreadRadius: 8,
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildNavItem(
            context,
            item: NavigationItem.dashboard,
            iconFilled: 'assets/icons/dashboard_filled.svg',
            iconHollowed: 'assets/icons/dashboard_hollowed.svg',
            height: 22,
          ),
          _buildNavItem(
            context,
            item: NavigationItem.analytics,
            iconFilled: 'assets/icons/analytics_filled.svg',
            iconHollowed: 'assets/icons/analytics_hollowed.svg',
            height: 25,
          ),
          _buildNavItem(
            context,
            item: NavigationItem.activity,
            iconFilled: 'assets/icons/activity_filled.svg',
            iconHollowed: 'assets/icons/activity_hollowed.svg',
            height: 22,
          ),
          _buildNavItem(
            context,
            item: NavigationItem.profile,
            iconFilled: 'assets/icons/profile_filled.svg',
            iconHollowed: 'assets/icons/profile_hollowed.svg',
            height: 22,
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required NavigationItem item,
    required String iconFilled,
    required String iconHollowed,
    required double height,
  }) {
    final isSelected = item == currentItem;
    final icon = isSelected ? iconFilled : iconHollowed;

    return GestureDetector(
      onTap: () => _onItemTapped(context, item),
      child: Container(
        color: Colors.transparent,
        padding: const EdgeInsets.all(20.0),
        child: AppContentImage(
          icon,
          height: height,
        ),
      ),
    );
  }
}
