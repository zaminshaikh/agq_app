// ignore_for_file: deprecated_member_use

import 'package:agq_app/content/app_content.dart';
import 'package:agq_app/content/content_image.dart';
import 'dart:developer';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:agq_app/screens/authenticate/utils/app_state.dart';
import 'package:agq_app/screens/utils/resources.dart';

class AuthenticationPage extends StatefulWidget {
  const AuthenticationPage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _AuthenticationPageState createState() => _AuthenticationPageState();
}

class _AuthenticationPageState extends State<AuthenticationPage> {
  final Future<void> _initializeWidgetFuture = Future.value();

  String? cid;

  @override
  void initState() {
    super.initState();
    _loadAppLockState();
  }

  Future<void> _loadAppLockState() async {
    final prefs = await SharedPreferences.getInstance();
    final isEnabled = prefs.getBool('isAppLockEnabled') ?? false;
    if (!mounted) return;
    context.read<AuthState>().setAppLockEnabled(isEnabled);
    log('Loaded app lock state: $isEnabled');
  }

  Future<void> _saveAppLockState(bool isEnabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isAppLockEnabled', isEnabled);
    if (!mounted) return;
    context.read<AuthState>().setAppLockEnabled(isEnabled);
    log('Saved app lock state: $isEnabled');
  }

  @override
  Widget build(BuildContext context) {
    AppContent.watch(context);
    return FutureBuilder(
        future: _initializeWidgetFuture,
        builder: (context, snapshot) => buildAuthenticationPage(context));
  }

  Scaffold buildAuthenticationPage(BuildContext context) => Scaffold(
        body: Stack(
          children: [
            CustomScrollView(
              slivers: <Widget>[
                _buildAppBar(context),
                SliverPadding(
                  padding: const EdgeInsets.all(0.0),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate(
                      [
                        _buildLockFeatureInfo(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );

  SliverAppBar _buildAppBar(context) => SliverAppBar(
        backgroundColor: const Color.fromARGB(255, 30, 41, 59),
        automaticallyImplyLeading: false,
        toolbarHeight: 80,
        expandedHeight: 0,
        snap: false,
        floating: true,
        pinned: true,
        leading: IconButton(
          icon:
              const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        flexibleSpace: SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(left: 60.0, right: 20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppContent.text(
                      'text.screens.profile.pages.authentication.authentication_ee1acf'),
                  style: const TextStyle(
                    fontSize: 27,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Titillium Web',
                  ),
                ),
              ],
            ),
          ),
        ),
      );

  Column _buildLockFeatureInfo() => Column(
        children: [
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Row(
              children: [
                const AppContentImage(
                  'assets/icons/face_id.svg',
                  color: Colors.white,
                  height: 40,
                  width: 40,
                ),
                const SizedBox(width: 15),
                Text(
                  AppContent.text(
                      'text.screens.profile.pages.authentication.app_lock_155f0c'),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Titillium Web',
                    fontSize: 22,
                  ),
                ),
                const Spacer(),
                CupertinoSwitch(
                  value: context.watch<AuthState>().isAppLockEnabled,
                  onChanged: (bool value) {
                    context.read<AuthState>().setAppLockEnabled(value);
                    _saveAppLockState(value);
                    log('App lock enabled: $value');
                  },
                  activeColor: AppColors.defaultBlue300, // Set the active color
                )
              ],
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Text(
              AppContent.text(
                  'text.screens.profile.pages.authentication.when_enabled_a_passcode_or_biometric_a_4ea681'),
              style: const TextStyle(
                fontSize: 16,
                color: AppColors.defaultBlueGray400,
                fontFamily: 'Titillium Web',
              ),
            ),
          ),
          const SizedBox(height: 30),
        ],
      );
}
