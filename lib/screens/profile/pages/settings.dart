// ignore_for_file: deprecated_member_use, use_build_context_synchronously, duplicate_ignore, prefer_expression_function_bodies, unused_catch_clause, empty_catches

import 'package:agq_app/content/app_content.dart';
import 'package:agq_app/content/content_image.dart';
import 'package:app_settings/app_settings.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:agq_app/components/alert_dialog.dart';
import 'package:agq_app/components/progress_indicator.dart';
import 'package:agq_app/database/auth_helper.dart';
import 'package:agq_app/database/models/client_model.dart';
import 'package:agq_app/screens/profile/components/delete_account_button.dart';
import 'package:agq_app/screens/utils/resources.dart';
import 'package:agq_app/screens/profile/components/logout_button.dart';
import 'dart:developer';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  SettingsPageState createState() => SettingsPageState();
}

class SettingsPageState extends State<SettingsPage> {
  Client? client;
  bool notifsSwitchValue = false;

  @override
  void initState() {
    super.initState();
    _loadSwitchValue();
  }

  // Future<void> _checkNotificationPermission() async {
  //     // Fetch the current notification permission status
  //     var status = await Permission.notification.status;
  //     setState(() {
  //         // Update the switch based on whether permission is granted
  //         notifsSwitchValue = status.isGranted;
  //     });
  // }

  void _showPermissionDeniedDialog() {
    showCupertinoDialog(
      context: context,
      builder: (context) {
        return CupertinoAlertDialog(
          title: Text(
            AppContent.text(
                'text.screens.profile.pages.settings.notifications_disabled_5d140e'),
            style: const TextStyle(
              color: CupertinoColors
                  .darkBackgroundGray, // Changed from default/purple to blue
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          content: Text(
            AppContent.text(
                'text.screens.profile.pages.settings.please_enable_notifications_in_your_de_9ac069'),
            style: const TextStyle(
              color:
                  CupertinoColors.black, // Changed from default/purple to blue
              fontSize: 16,
            ),
          ),
          actions: [
            CupertinoDialogAction(
              child: Text(
                AppContent.text(
                    'text.screens.profile.pages.settings.cancel_77dfd2'),
                style: const TextStyle(
                  color: CupertinoColors
                      .activeBlue, // Changed from default/purple to blue
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            CupertinoDialogAction(
              child: Text(
                AppContent.text(
                    'text.screens.profile.pages.settings.settings_c7f73b'),
                style: const TextStyle(
                  color: CupertinoColors
                      .activeBlue, // Changed from default/purple to blue
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                AppSettings.openAppSettings();
              },
            ),
          ],
        );
      },
    );
  }

  // Future<void> _requestNotificationPermission() async {
  //     // Request the notification permission if it's not granted
  //     var status = await Permission.notification.request();

  //     if (status.isGranted) {
  //         // Update the state if permission is granted
  //         setState(() {
  //         notifsSwitchValue = true;
  //         _saveSwitchValue(notifsSwitchValue);
  //         });
  //         _showCupertinoDialog('Notifications enabled');
  //     } else {
  //         // If denied, show a message and provide an option to go to settings
  //         _showCupertinoDialog('Notification permission denied. Please enable it in settings.');
  //     }
  // }

  // void _showCupertinoDialog(String message) {
  //     showCupertinoDialog(
  //         context: context,
  //         builder: (BuildContext context) {
  //             return CupertinoAlertDialog(
  //             title: const Text('Notification Permission'),
  //             content: Text(message),
  //             actions: <Widget>[
  //                 CupertinoDialogAction(
  //                 child: const Text('OK'),
  //                 onPressed: () {
  //                     Navigator.of(context).pop();
  //                 },
  //                 ),
  //                 if (message.contains('denied'))
  //                 CupertinoDialogAction(
  //                     child: const Text('Settings'),
  //                     onPressed: () {
  //                     Navigator.of(context).pop();
  //                     _openAppSettings();
  //                     },
  //                 ),
  //             ],
  //             );
  //         },
  //     );
  // }

  // Future<void> _openAppSettings() async {
  //   // Open app settings to manually enable notifications
  //   await openAppSettings();
  // }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    client = Provider.of<Client?>(context);
    _loadSwitchValue();
  }

  Future<void> _loadSwitchValue() async {
    final prefs = await SharedPreferences.getInstance();
    bool savedValue = prefs.getBool('notifsSwitchValue') ?? false;
    setState(() {
      notifsSwitchValue = savedValue;
    });
  }

  Future<void> _saveSwitchValue(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifsSwitchValue', value);
  }

  @override
  Widget build(BuildContext context) {
    AppContent.watch(context);
    return buildSettingsPage();
  }

  Scaffold buildSettingsPage() {
    if (client == null) {
      return const Scaffold(
        body: CustomProgressIndicatorPage(),
      );
    }

    return Scaffold(
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
                      _settings(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Column _settings() => Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 20, right: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 25),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppContent.text(
                                    'text.screens.profile.pages.settings.notifications_753a22'),
                                style: const TextStyle(
                                  fontSize: 18,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Titillium Web',
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                AppContent.text(
                                    'text.screens.profile.pages.settings.let_me_know_about_new_activities_and_s_569b76'),
                                style: const TextStyle(
                                  fontSize: 15,
                                  color: Colors.white,
                                  fontFamily: 'Titillium Web',
                                ),
                                softWrap: true,
                                overflow: TextOverflow.visible,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CupertinoSwitch(
                          value: notifsSwitchValue,
                          activeColor: CupertinoColors.activeBlue,
                          onChanged: (bool value) async {
                            if (value) {
                              // Request notification permissions
                              NotificationSettings settings =
                                  await FirebaseMessaging.instance
                                      .requestPermission(
                                alert: true,
                                badge: true,
                                sound: true,
                              );

                              if (settings.authorizationStatus ==
                                  AuthorizationStatus.authorized) {
                                // Permissions granted
                                setState(() {
                                  notifsSwitchValue = true;
                                });
                                await _saveSwitchValue(true);
                                // Enable notifications
                                await updateFirebaseMessagingToken(
                                    FirebaseAuth.instance.currentUser, context);
                              } else {
                                // Permissions denied
                                _showPermissionDeniedDialog();
                                setState(() {
                                  notifsSwitchValue = false;
                                });
                                await _saveSwitchValue(false);
                              }
                            } else {
                              // Switch turned off
                              setState(() {
                                notifsSwitchValue = false;
                              });
                              await _saveSwitchValue(false);
                              // Disable notifications
                              await deleteFirebaseMessagingToken(
                                  FirebaseAuth.instance.currentUser, context);
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 15),

                const Divider(
                  color: Colors.white,
                  thickness: 0.2,
                  height: 20,
                ),

                const SizedBox(height: 15),

                // Security Section with options to change email and password
                Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppContent.text(
                              'text.screens.profile.pages.settings.security_f25ce1'),
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Titillium Web',
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          FirebaseAuth.instance.currentUser?.email ?? '',
                          style: const TextStyle(
                            fontSize: 15,
                            color: Colors.white,
                            fontFamily: 'Titillium Web',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                Column(
                  children: [
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            TextEditingController emailController =
                                TextEditingController();

                            Widget buildCloseButton(BuildContext context) {
                              return Align(
                                alignment: Alignment.topRight,
                                child: GestureDetector(
                                  onTap: () => Navigator.pop(context),
                                  child: const Icon(Icons.close,
                                      color: Colors.white),
                                ),
                              );
                            }

                            Widget buildIconArt() {
                              return const AppContentImage(
                                'assets/icons/change_email_and_password_icon_art.svg',
                                // Optional: You can specify width, height, color, etc. if needed
                              );
                            }

                            Widget buildEmailInputSection(
                                TextEditingController emailController) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    AppContent.text(
                                        'text.screens.profile.pages.settings.change_email_12dffa'),
                                    style: const TextStyle(
                                        fontSize: 20,
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'Titillium Web'),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    AppContent.text(
                                        'text.screens.profile.pages.settings.you_are_changing_the_email_associated__380ca8'),
                                    style: const TextStyle(
                                        fontSize: 14,
                                        color: Colors.white70,
                                        fontFamily: 'Titillium Web'),
                                  ),
                                  const SizedBox(height: 20),
                                  Text(
                                    AppContent.text(
                                        'text.screens.profile.pages.settings.email_84add5'),
                                    style: const TextStyle(
                                        fontSize: 16,
                                        color: Colors.white,
                                        fontFamily: 'Titillium Web'),
                                  ),
                                  const SizedBox(height: 10),
                                  TextField(
                                    controller: emailController,
                                    readOnly:
                                        false, // Ensure this is false to allow typing
                                    keyboardType: TextInputType
                                        .emailAddress, // Add this line to bring up email keyboard
                                    style: const TextStyle(
                                        fontSize: 16,
                                        color: Colors.white,
                                        fontFamily: 'Titillium Web'),
                                    decoration: InputDecoration(
                                      hintText: AppContent.text(
                                          'text.screens.profile.pages.settings.enter_your_new_email_57c67c'),
                                      hintStyle: TextStyle(
                                          color: Colors.grey[400],
                                          fontFamily: 'Titillium Web'),
                                      border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(11)),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(11),
                                        borderSide: const BorderSide(
                                            color: Colors.blue, width: 2),
                                      ),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                              vertical: 14, horizontal: 14),
                                    ),
                                  ),
                                ],
                              );
                            }

                            Widget buildContinueButton(BuildContext context,
                                TextEditingController emailController) {
                              return ElevatedButton(
                                onPressed: () async {
                                  try {
                                    // Get the new email from the controller
                                    String newEmail =
                                        emailController.text.trim();

                                    // Get the current user
                                    var user =
                                        FirebaseAuth.instance.currentUser;

                                    if (user != null) {
                                      // Send email verification to the new email address
                                      await user.updateEmail(newEmail);
                                      await user.sendEmailVerification();

                                      // Show a message to inform the user to check their email for verification.
                                      await CustomAlertDialog.showAlertDialog(
                                        context,
                                        AppContent.text(
                                            'text.screens.profile.pages.settings.email_change_requested_f9a41f'),
                                        AppContent.text(
                                            'text.screens.profile.pages.settings.please_check_your_email_for_a_verifica_d6c220'),
                                      );
                                    }
                                  } catch (e) {
                                    // log the error for debugging
                                    log('settings.dart: Error updating email: $e');

                                    // Handle error, display a message, etc.
                                    await CustomAlertDialog.showAlertDialog(
                                      context,
                                      AppContent.text(
                                          'text.screens.profile.pages.settings.error_7f2f6a'),
                                      AppContent.text(
                                          'text.screens.profile.pages.settings.error_updating_email_e_a4dcc5',
                                          {'e': e}),
                                    );
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color.fromARGB(
                                      255, 30, 75, 137), // Updated from primary
                                  foregroundColor: Colors.white, // Text color
                                  splashFactory: NoSplash.splashFactory,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 30, vertical: 15),
                                ),
                                child: Text(
                                  AppContent.text(
                                      'text.screens.profile.pages.settings.continue_2e0262'),
                                  style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'Titillium Web'),
                                ),
                              );
                            }

                            AlertDialog buildsettingsDialog(
                                BuildContext context,
                                TextEditingController emailController) {
                              return AlertDialog(
                                backgroundColor: AppColors.defaultBlueGray800,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                content: SingleChildScrollView(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      buildCloseButton(context),
                                      const SizedBox(height: 20),
                                      buildIconArt(),
                                      const SizedBox(height: 30),
                                      buildEmailInputSection(emailController),
                                      const SizedBox(height: 20),
                                      buildContinueButton(
                                          context, emailController),
                                    ],
                                  ),
                                ),
                              );
                            }

                            return buildsettingsDialog(
                                context, emailController);
                          },
                        );
                      },
                      child: Container(
                        height: 45,
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Colors.blue,
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            AppContent.text(
                                'text.screens.profile.pages.settings.change_email_12dffa'),
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.blue,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Titillium Web',
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            TextEditingController passwordController =
                                TextEditingController();

                            Widget buildCloseButton(BuildContext context) {
                              return Align(
                                alignment: Alignment.topRight,
                                child: GestureDetector(
                                  onTap: () => Navigator.pop(context),
                                  child: const Icon(Icons.close,
                                      color: Colors.white),
                                ),
                              );
                            }

                            Widget buildIconArt() {
                              return const AppContentImage(
                                'assets/icons/change_email_and_password_icon_art.svg',
                                // Optional: You can specify width, height, color, etc. if needed
                              );
                            }

                            Widget buildPasswordInputSection(
                                TextEditingController passwordController) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    AppContent.text(
                                        'text.screens.profile.pages.settings.change_password_49289d'),
                                    style: const TextStyle(
                                        fontSize: 20,
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'Titillium Web'),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    AppContent.text(
                                        'text.screens.profile.pages.settings.you_are_changing_the_password_associat_ce88d3'),
                                    style: const TextStyle(
                                        fontSize: 14,
                                        color: Colors.white70,
                                        fontFamily: 'Titillium Web'),
                                  ),
                                  const SizedBox(height: 20),
                                  Text(
                                    AppContent.text(
                                        'text.screens.profile.pages.settings.new_password_4894cb'),
                                    style: const TextStyle(
                                        fontSize: 16,
                                        color: Colors.white,
                                        fontFamily: 'Titillium Web'),
                                  ),
                                  const SizedBox(height: 10),
                                  TextField(
                                    controller: passwordController,
                                    obscureText:
                                        true, // Ensure this is true for password fields
                                    style: const TextStyle(
                                        fontSize: 16,
                                        color: Colors.white,
                                        fontFamily: 'Titillium Web'),
                                    decoration: InputDecoration(
                                      hintText: AppContent.text(
                                          'text.screens.profile.pages.settings.enter_your_new_password_7bec90'),
                                      hintStyle: TextStyle(
                                          color: Colors.grey[400],
                                          fontFamily: 'Titillium Web'),
                                      border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(11)),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(11),
                                        borderSide: const BorderSide(
                                            color: Colors.blue, width: 2),
                                      ),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                              vertical: 14, horizontal: 14),
                                    ),
                                  ),
                                ],
                              );
                            }

                            Widget buildContinueButton(BuildContext context,
                                TextEditingController passwordController) {
                              return ElevatedButton(
                                onPressed: () async {
                                  try {
                                    // Get the new password from the controller
                                    String newPassword =
                                        passwordController.text.trim();

                                    // Get the current user
                                    var user =
                                        FirebaseAuth.instance.currentUser;

                                    if (user != null) {
                                      // Update the user's password
                                      await user.updatePassword(newPassword);

                                      // Show a message to inform the user that the password has been changed.
                                      await CustomAlertDialog.showAlertDialog(
                                        context,
                                        AppContent.text(
                                            'text.screens.profile.pages.settings.success_42a8f6'),
                                        AppContent.text(
                                            'text.screens.profile.pages.settings.your_password_has_been_updated_success_fd29a6'),
                                        icon: const Icon(
                                          Icons.check_circle_outline_rounded,
                                          color: Colors.green,
                                          size: 28,
                                        ),
                                      );
                                    }
                                  } catch (e) {
                                    // log the error for debugging
                                    log('settings.dart: Error updating password: $e');

                                    // Handle error, display a message, etc.
                                    await CustomAlertDialog.showAlertDialog(
                                      context,
                                      AppContent.text(
                                          'text.screens.profile.pages.settings.error_7f2f6a'),
                                      AppContent.text(
                                          'text.screens.profile.pages.settings.error_updating_password_e_3e4e91',
                                          {'e': e}),
                                    );
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color.fromARGB(
                                      255, 30, 75, 137), // Updated from primary
                                  foregroundColor:
                                      Colors.white, // Updated from onPrimary
                                  splashFactory: NoSplash.splashFactory,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 30, vertical: 15),
                                ),
                                child: Text(
                                  AppContent.text(
                                      'text.screens.profile.pages.settings.continue_2e0262'),
                                  style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'Titillium Web'),
                                ),
                              );
                            }

                            AlertDialog buildsettingsDialog(
                                BuildContext context,
                                TextEditingController passwordController) {
                              return AlertDialog(
                                backgroundColor: AppColors.defaultBlueGray800,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                content: SingleChildScrollView(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      buildCloseButton(context),
                                      const SizedBox(height: 20),
                                      buildIconArt(),
                                      const SizedBox(height: 30),
                                      buildPasswordInputSection(
                                          passwordController),
                                      const SizedBox(height: 20),
                                      buildContinueButton(
                                          context, passwordController),
                                    ],
                                  ),
                                ),
                              );
                            }

                            return buildsettingsDialog(
                                context, passwordController);
                          },
                        );
                      },
                      child: Container(
                        height: 45,
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Colors.blue,
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            AppContent.text(
                                'text.screens.profile.pages.settings.change_password_49289d'),
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.blue,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Titillium Web',
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),

                const Divider(
                  color: Colors.white,
                  thickness: 0.2,
                  height: 20,
                ),

                const SizedBox(height: 15),

                Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppContent.text(
                              'text.screens.profile.pages.settings.logout_e43d61'),
                          style: const TextStyle(
                            fontSize: 18,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Titillium Web',
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          AppContent.text(
                              'text.screens.profile.pages.settings.log_out_of_your_account_44c4e0'),
                          style: const TextStyle(
                            fontSize: 15,
                            color: Colors.white,
                            fontFamily: 'Titillium Web',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
          LogoutButton(client: client!),
          Padding(
            padding: const EdgeInsets.only(left: 20, right: 20),
            child: Column(
              children: [
                const SizedBox(height: 20),
                const Divider(
                  color: Colors.white,
                  thickness: 0.2,
                  height: 20,
                ),
                const SizedBox(height: 15),
                Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppContent.text(
                              'text.screens.profile.pages.settings.delete_your_account_a0b7ba'),
                          style: const TextStyle(
                            fontSize: 18,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Titillium Web',
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          AppContent.text(
                              'text.screens.profile.pages.settings.delete_your_account_this_cannot_be_und_220d07'),
                          style: const TextStyle(
                            fontSize: 15,
                            color: Colors.white,
                            fontFamily: 'Titillium Web',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          DeleteAccountButton(client: client!),
          const SizedBox(height: 50),
        ],
      );

  // This is the app bar
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
                      'text.screens.profile.pages.settings.settings_c7f73b'),
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
}
