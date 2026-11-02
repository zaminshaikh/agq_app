// ignore_for_file: deprecated_member_use

import 'package:agq_app/content/app_content.dart';
import 'package:agq_app/content/content_image.dart';
import 'dart:async';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:agq_app/database/auth_helper.dart';
import 'package:agq_app/database/models/client_model.dart';
import 'package:agq_app/screens/utils/resources.dart';

class LogoutButton extends StatefulWidget {
  final Client client;

  const LogoutButton({super.key, required this.client});

  @override
  LogoutButtonState createState() => LogoutButtonState();
}

class LogoutButtonState extends State<LogoutButton> {
  @override
  Widget build(BuildContext context) {
    AppContent.watch(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
      child: Column(
        children: [
          GestureDetector(
            onTap: () => _showLogoutDialog(context),
            child: Container(
              height: 45,
              decoration: BoxDecoration(
                color: Colors
                    .transparent, // Changed from Color.fromARGB(255, 149, 28, 28)
                border: Border.all(color: Colors.red), // Added red border
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const AppContentImage(
                      'assets/icons/logout.svg',
                      color: Colors.red, // Changed from Colors.white
                      height: 20,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      AppContent.text(
                          'text.screens.profile.components.logout_button.logout_e43d61'),
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.red, // Changed from Colors.white
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Titillium Web',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) => AlertDialog(
        backgroundColor: AppColors.defaultBlueGray800,
        content: SingleChildScrollView(
          child: ListBody(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  children: <Widget>[
                    Text(
                      AppContent.text(
                          'text.screens.profile.components.logout_button.confirm_logout_6e6ea0'),
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(width: 10),
                    const AppContentImage(
                      'assets/icons/logout.svg',
                      width: 24,
                      height: 24,
                      color: Colors.white,
                    ),
                  ],
                ),
              ),
              Text(AppContent.text(
                  'text.screens.profile.components.logout_button.are_you_sure_you_want_to_log_out_97c2c6')),
            ],
          ),
        ),
        actions: <Widget>[
          GestureDetector(
            onTap: () {
              Navigator.of(context).pop();
              _logout();
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: Colors
                    .transparent, // Changed from Color.fromARGB(255, 149, 28, 28)
                border: Border.all(
                    color: Colors.red, width: 1.5), // Added red border
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                AppContent.text(
                    'text.screens.profile.components.logout_button.logout_e43d61'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: Colors.red, // Changed from default color
                    fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: () {
              Navigator.of(context).pop();
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: Colors.transparent,
                border: Border.all(
                  color: Colors.white,
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                AppContent.text(
                    'text.screens.profile.components.logout_button.cancel_77dfd2'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _logout() async {
    log('settings.dart: Signing out...');

    Future<void> handleLogout() async {
      // Continue sign out asynchronously.
      await deleteFirebaseMessagingToken(
          FirebaseAuth.instance.currentUser, context);
      await FirebaseAuth.instance.signOut();
      assert(FirebaseAuth.instance.currentUser == null);
      log('settings.dart: Successfully signed out');
      return;
    }

    unawaited(handleLogout());
    // Immediately navigate away to avoid security rules issues when signed out.
    await Navigator.of(context)
        .pushNamedAndRemoveUntil('/onboarding', (route) => false);

    // Continue sign out asynchronously.
    return;
  }
}
