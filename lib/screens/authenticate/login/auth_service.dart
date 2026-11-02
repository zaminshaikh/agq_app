// ignore_for_file: library_private_types_in_public_api

import 'package:agq_app/content/app_content.dart';
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:agq_app/screens/dashboard/dashboard.dart';
import 'dart:developer';

void main() => runApp(const MyApp());

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  _MyAppState createState() => _MyAppState();
}

class AuthService {
  final LocalAuthentication auth = LocalAuthentication();

  Future<bool> authenticateWithBiometrics() async {
    final bool canAuthenticateWithBiometrics =
        await auth.canCheckBiometrics && await auth.isDeviceSupported();

    if (canAuthenticateWithBiometrics) {
      try {
        return await auth.authenticate(
          localizedReason: AppContent.text(
              'text.screens.authenticate.login.auth_service.authenticate_to_access_8d3f37'),
          options: const AuthenticationOptions(biometricOnly: true),
        );
      } catch (e) {
        log('auth_service.dart: $e');
        return false;
      }
    } else {
      return false;
    }
  }
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // App is resumed - check for authentication
      _authService.authenticateWithBiometrics().then((isAuthenticated) {
        if (!isAuthenticated) {
          // Handle authentication failure or redirect to a locked screen
          log('auth_service.dart: Authentication failed');
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    AppContent.watch(context);
    return const MaterialApp(
      home: DashboardPage(), // Your example page
    );
  }
}

Future<bool> isSimulator() async {
  if (Platform.isIOS) {
    var iosInfo = await DeviceInfoPlugin().iosInfo;
    return !iosInfo.isPhysicalDevice;
  } else if (Platform.isAndroid) {
    var androidInfo = await DeviceInfoPlugin().androidInfo;
    return !androidInfo.isPhysicalDevice;
  } else {
    return false;
  }
}
