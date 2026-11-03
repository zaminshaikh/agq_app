// ignore_for_file: deprecated_member_use

import 'package:agq_app/content/app_content.dart';
import 'package:agq_app/content/content_image.dart';
import 'dart:async';
import 'dart:developer';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:agq_app/database/auth_helper.dart';
import 'package:agq_app/database/models/client_model.dart';
import 'package:agq_app/screens/utils/resources.dart';
import 'package:agq_app/screens/utils/utilities.dart';

class DeleteAccountButton extends StatefulWidget {
  // Renamed widget
  final Client client;

  const DeleteAccountButton({super.key, required this.client});

  @override
  DeleteAccountButtonState createState() =>
      DeleteAccountButtonState(); // Renamed state class
}

class DeleteAccountButtonState extends State<DeleteAccountButton> {
  // Renamed state class
  final TextEditingController _clientIdController = TextEditingController();
  final FocusNode _clientIdFocusNode = FocusNode(); // Add a FocusNode
  String? _errorText; // Added error text state variable

  @override
  void dispose() {
    _clientIdController.dispose();
    _clientIdFocusNode.dispose(); // Dispose the FocusNode
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    AppContent.watch(context, keys: const {
      'text.screens.profile.components.delete_account_button.are_you_sure_you_want_to_permanently_d_12ba10',
      'text.screens.profile.components.delete_account_button.cid_does_not_match_please_enter_the_co_a731d7',
    });
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
      child: Column(
        children: [
          GestureDetector(
            onTap: () =>
                _showDeleteAccountDialog(context), // Updated method name
            child: Container(
              height: 45,
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(
                    0.1), // Light red background with slight transparency
                // border: Border.all(color: Colors.red), // Red border remains
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const AppContentImage(
                      'assets/icons/trash.svg', // Updated icon asset (ensure it's available)
                      color: Colors.red,
                      height: 20,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      AppContent.text(
                          'text.screens.profile.components.delete_account_button.delete_account_ee1b9a'), // Updated label text
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.red,
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

  void _showDeleteAccountDialog(BuildContext context) {
    // Renamed method
    // Reset error text when dialog opens
    setState(() {
      _errorText = null;
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) => StatefulBuilder(
        // Use StatefulBuilder to update dialog content
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppColors.defaultBlueGray800,
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Row(
                    children: <Widget>[
                      Text(
                        AppContent.text(
                            'text.screens.profile.components.delete_account_button.confirm_delete_account_8629da'), // Updated dialog title
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(width: 10),
                      const AppContentImage(
                        'assets/icons/trash.svg', // Updated icon asset
                        width: 24,
                        height: 24,
                        color: Colors.white,
                      ),
                    ],
                  ),
                ),
                Text(AppContent.text(
                    'text.screens.profile.components.delete_account_button.are_you_sure_you_want_to_permanently_d_12ba10')), // Updated message
                Padding(
                  padding: const EdgeInsets.fromLTRB(0, 20, 0, 20),
                  child: Text(
                    AppContent.text(
                        'text.screens.profile.components.delete_account_button.type_your_cid_to_confirm_deletion_885a10'),
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: Colors.white),
                  ),
                ),
                TextField(
                  controller: _clientIdController,
                  focusNode: _clientIdFocusNode, // Use the focus node
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white),
                  onChanged: (value) {
                    // Lose focus after 8 digits
                    if (value.length >= 8) {
                      _clientIdFocusNode.unfocus();
                    }
                  },
                  decoration: InputDecoration(
                    hintText: AppContent.text(
                        'text.screens.profile.components.delete_account_button.your_cid_value1_9430ed',
                        {'value1': widget.client.cid}),
                    hintStyle: const TextStyle(color: Colors.white70),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: _errorText != null ? Colors.red : Colors.white,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: _errorText != null ? Colors.red : Colors.white,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    errorText: _errorText,
                    errorStyle: const TextStyle(color: Colors.red),
                  ),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            GestureDetector(
              onTap: () {
                if (_clientIdController.text != widget.client.cid) {
                  // Update error message within the dialog using StatefulBuilder
                  setDialogState(() {
                    _errorText = AppContent.text(
                        'text.screens.profile.components.delete_account_button.cid_does_not_match_please_enter_the_co_a731d7');
                  });
                  return;
                }
                Navigator.of(context).pop();
                _deleteAccount();
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.2), // Solid red background
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  AppContent.text(
                      'text.screens.profile.components.delete_account_button.delete_f6fdbe'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: Colors.red, // Updated text color for contrast
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
                      'text.screens.profile.components.delete_account_button.cancel_77dfd2'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _deleteAccount() async {
    // Renamed method
    log('delete_account_button.dart: Deleting account...');

    Future<void> handleDeleteAccount() async {
      await deleteFirebaseMessagingToken(
          FirebaseAuth.instance.currentUser, context);

      HttpsCallable callable =
          FirebaseFunctions.instance.httpsCallable('unlinkUser');
      final response = await callable.call({
        'uid': widget.client.uid,
        'cid': widget.client.cid,
        'usersCollectionID': Config.get('FIRESTORE_ACTIVE_USERS_COLLECTION'),
      });
      log('Cloud function unlinkUser called successfully: ${response.data}');

      await FirebaseAuth.instance.signOut();

      assert(FirebaseAuth.instance.currentUser == null);
    }

    unawaited(handleDeleteAccount());

    if (!mounted) {
      return;
    }

    await Navigator.of(context)
        .pushNamedAndRemoveUntil('/onboarding', (route) => false);

    return;
  }
}
