// ignore_for_file: library_private_types_in_public_api, empty_catches, use_build_context_synchronously

import 'package:agq_app/content/app_content.dart';
import 'package:agq_app/content/content_image.dart';
import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Import SharedPreferences

import 'package:agq_app/screens/authenticate/utils/app_state.dart';
import 'package:agq_app/screens/dashboard/dashboard.dart';
import 'package:agq_app/screens/utils/resources.dart';

class InitialFaceIdPage extends StatefulWidget {
  const InitialFaceIdPage({super.key});

  @override
  _InitialFaceIdPageState createState() => _InitialFaceIdPageState();
}

class _InitialFaceIdPageState extends State<InitialFaceIdPage>
    with WidgetsBindingObserver {
  final LocalAuthentication auth = LocalAuthentication();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _initialAuthenticate(BuildContext context) async {
    if (!mounted) return;

    try {
      bool authenticated = await auth.authenticate(
        localizedReason: AppContent.text(
            'text.screens.authenticate.initial_face_id.please_authenticate_to_login_5faeb2'),
        options: const AuthenticationOptions(
          useErrorDialogs: true,
          stickyAuth: true,
        ),
      );

      if (authenticated && mounted) {
        final appState = Provider.of<AuthState>(context, listen: false);
        appState.setInitiallyAuthenticated(true); // Set the flag

        // Set hasTransitioned to false
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setBool('hasTransitioned', false);

        await Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                const DashboardPage(fromFaceIdPage: true),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) => child,
          ),
        );
      }
    } catch (e) {
      // Handle authentication error if needed
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 40, 20, 20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 80.0),
                    const AppContentImage(
                      'assets/icons/agq_logo.png',
                      height: 60,
                    ),
                    const SizedBox(height: 20.0),
                    Align(
                      alignment: Alignment.center,
                      child: Text(
                        AppContent.text(
                            'text.screens.authenticate.initial_face_id.agq_app_locked_dda619'),
                        style: const TextStyle(
                          fontSize: 25,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 16.0),
                    Align(
                      alignment: Alignment.center,
                      child: Text(
                        AppContent.text(
                            'text.screens.authenticate.initial_face_id.unlock_with_face_id_to_continue_7814ef'),
                        style: const TextStyle(
                          fontSize: 18,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: SizedBox(
                  width: double.infinity,
                  height: 45,
                  child: ElevatedButton(
                    onPressed: () async {
                      await _initialAuthenticate(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.defaultBlue500,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                    ),
                    child: Text(
                      AppContent.text(
                          'text.screens.authenticate.initial_face_id.use_face_id_f3ef71'),
                      style: const TextStyle(
                        fontSize: 18,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
