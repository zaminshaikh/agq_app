// ignore_for_file: library_private_types_in_public_api

import 'package:agq_app/content/app_content.dart';
import 'package:agq_app/content/content_image.dart';
import 'package:flutter/material.dart';
import 'package:agq_app/screens/authenticate/create_account/create_account.dart';
import 'package:agq_app/screens/authenticate/login/login.dart'; // Adjust the import path as necessary
import 'package:local_auth/local_auth.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  _OnboardingPageState createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage>
    with TickerProviderStateMixin {
  late AnimationController _fadeAnimationController;
  late Animation<double> _fadeAnimation;
  late AnimationController _slideAnimationController;
  late Animation<Offset> _slideAnimation;
  final LocalAuthentication auth = LocalAuthentication();

  @override
  void initState() {
    super.initState();
    _fadeAnimationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _fadeAnimation =
        Tween(begin: 0.0, end: 1.0).animate(_fadeAnimationController);

    _slideAnimationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1), // Start from slightly below the final position
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideAnimationController,
      curve: Curves.easeInOut,
    ));

    // Listen to the status of the slide animation
    _slideAnimationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        // Start the fade animation once the slide animation is complete
        _fadeAnimationController.forward();
      }
    });

    // Start the slide animation
    _slideAnimationController.forward();
  }

  @override
  void dispose() {
    _fadeAnimationController.dispose();
    _slideAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    AppContent.watch(context);
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.only(left: 40, right: 40),
        child: Center(
          // This centers the content horizontally.
          child: Column(
            mainAxisAlignment: MainAxisAlignment
                .center, // This centers the content vertically.
            children: [
              SlideTransition(
                position: _slideAnimation,
                child: const AppContentImage(
                  'assets/icons/agq_logo.png',
                  height: 80,
                ),
              ),
              const SizedBox(height: 30),
              FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                        AppContent.text(
                            'text.screens.authenticate.onboarding.welcome_to_agq_b71855'),
                        style: const TextStyle(
                            fontSize: 24, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    Text(
                        AppContent.text(
                            'text.screens.authenticate.onboarding.please_log_in_or_create_a_new_account__111f2e'),
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w300)),
                    const SizedBox(height: 30),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  const LoginPage()), // Navigate to the Log In page
                        );
                      },
                      child: Container(
                        height: 55,
                        decoration: BoxDecoration(
                          color: const Color.fromARGB(255, 7, 48, 89),
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: Center(
                          child: Text(
                            AppContent.text(
                                'text.screens.authenticate.onboarding.login_4e5a28'),
                            style: const TextStyle(
                              fontSize: 18,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Titillium Web',
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(
                        height: 10), // Provides spacing between the buttons
                    OutlinedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  const CreateAccountPage()), // Navigate to the Sign Up page
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(
                            color: Color.fromARGB(255, 0, 74, 147),
                            width: 2.0), // Border color
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                        padding: EdgeInsets.zero, // Remove default padding
                      ),
                      child: Container(
                        height: 55,
                        alignment: Alignment.center,
                        child: Text(
                          AppContent.text(
                              'text.screens.authenticate.onboarding.sign_up_2ba402'),
                          style: const TextStyle(
                            fontSize: 18,
                            color: Color.fromARGB(255, 0, 100, 199),
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Titillium Web',
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
