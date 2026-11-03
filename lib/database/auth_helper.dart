import 'package:agq_app/content/app_content.dart';
import 'dart:developer';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:agq_app/components/alert_dialog.dart';
import 'package:agq_app/database/database.dart';

/// Deletes any user currently in the Firebase Auth buffer.
Future<void> deleteUserInBuffer() async {
  if (FirebaseAuth.instance.currentUser != null) {
    try {
      await FirebaseAuth.instance.currentUser!.delete();
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        await FirebaseAuth.instance.signOut();
      } else {
        log('Error deleting user: $e', stackTrace: StackTrace.current);
      }
    }
    log('User after delete: ${FirebaseAuth.instance.currentUser ?? 'deleted'}');
  }
}

/// Handles FirebaseAuthException and displays an error message.
Future<void> handleFirebaseAuthException(
    BuildContext context, FirebaseAuthException e, String email) async {
  String errorMessage = AppContent.text(
      'text.database.auth_helper.failed_to_sign_up_please_try_again_2fb2a5');
  // String? temp = FirebaseAuth.instance.currentUser?.email;
  switch (e.code) {
    case 'email-already-in-use':
      if (FirebaseAuth.instance.currentUser?.email == email) {
        await deleteUserInBuffer();
      }
      errorMessage = AppContent.text(
          'text.database.auth_helper.email_email_is_already_in_use_please_u_d2abd2',
          {'email': email});
      break;
    case 'invalid-email':
      errorMessage = AppContent.text(
          'text.database.auth_helper.email_is_not_a_valid_email_format_plea_39414c',
          {'email': email});
      log('Invalid email format.');
      break;
    case 'weak-password':
      errorMessage = AppContent.text(
          'text.database.auth_helper.the_password_provided_is_too_weak_ad073f');
      log('Weak password.');
      break;
    default:
      log('FirebaseAuthException: $e');
  }
  if (!context.mounted) {
    return;
  }
  await CustomAlertDialog.showAlertDialog(context,
      AppContent.text('text.database.auth_helper.error_7f2f6a'), errorMessage,
      icon: const Icon(Icons.error, color: Colors.red));
}

/// Updates Firebase Messaging token.
Future<void> updateFirebaseMessagingToken(
    User? user, BuildContext context) async {
  if (user == null) {
    return;
  }
  String? token;
  try {
    token = await FirebaseMessaging.instance.getToken();
  } catch (e) {
    log('Error fetching token: $e');
    token = await FirebaseMessaging.instance.getAPNSToken();
    log('APNS Token found: $token');
  }
  if (token != null && context.mounted) {
    // Fetch CID using async constructor
    DatabaseService? db = await DatabaseService.fetchCID(user.uid, context);

    if (db != null) {
      try {
        List<dynamic> tokens = (await db.getField('tokens') ?? []);

        if (!tokens.contains(token)) {
          tokens = [...tokens, token];
          await db.updateField('tokens', tokens);
        }
      } catch (e) {
        log('login.dart: Error fetching tokens: $e');
      }
    }
  } // async gap widget mounting check
}

/// Deletes the Firebase Messaging token when the user signs out.
Future<void> deleteFirebaseMessagingToken(
    User? user, BuildContext context) async {
  if (user == null) {
    log('auth_helper.dart: User is null.');
    return;
  }
  // Retrieve the current FCM token
  String? token;
  try {
    token = await FirebaseMessaging.instance.getToken();
  } catch (e) {
    log('Error fetching token: $e');
    token = await FirebaseMessaging.instance.getAPNSToken();
    log('APNS Token found: $token');
  }

  if (token != null && context.mounted) {
    // Fetch the DatabaseService instance for the user
    DatabaseService? db = await DatabaseService.fetchCID(user.uid, context);

    if (db != null) {
      try {
        // Retrieve the current list of tokens from Firestore
        List<dynamic> tokens = (await db.getField('tokens')) ?? [];

        if (tokens.contains(token)) {
          // Remove the current token from the list
          tokens.remove(token);

          // Update the tokens field in Firestore
          await db.updateField('tokens', tokens);
          log('Token removed successfully.');
        }
      } catch (e) {
        log('Error deleting token: $e');
      }
    }
  }
}

/// Resends email verification to the current user.
Future<bool> resendEmailVerification(BuildContext context) async {
  try {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (context.mounted) {
        await CustomAlertDialog.showAlertDialog(
          context,
          AppContent.text('text.database.auth_helper.error_7f2f6a'),
          AppContent.text(
              'text.database.auth_helper.no_user_is_currently_signed_in_1c2c94'),
        );
      }
      return false;
    }

    if (user.emailVerified) {
      if (context.mounted) {
        await CustomAlertDialog.showAlertDialog(
          context,
          AppContent.text('text.database.auth_helper.already_verified_1c6aeb'),
          AppContent.text(
              'text.database.auth_helper.your_email_is_already_verified_a7a7b8'),
          icon: const Icon(Icons.check_circle_outline_rounded,
              color: Colors.green),
        );
      }
      return true;
    }

    await user.sendEmailVerification();

    if (context.mounted) {
      await CustomAlertDialog.showAlertDialog(
        context,
        AppContent.text(
            'text.database.auth_helper.verification_email_sent_508d93'),
        AppContent.text(
            'text.database.auth_helper.a_verification_email_has_been_sent_to__fe463c',
            {'value1': user.email}),
        icon: const Icon(Icons.email_outlined, color: Colors.blue),
      );
    }

    return true;
  } on FirebaseAuthException catch (e) {
    log('Error resending verification email: $e');
    String errorMessage = AppContent.text(
        'text.database.auth_helper.failed_to_send_verification_email_plea_792d65');

    switch (e.code) {
      case 'too-many-requests':
        errorMessage = AppContent.text(
            'text.database.auth_helper.too_many_requests_please_wait_before_r_db7c32');
        break;
      case 'invalid-email':
        errorMessage = AppContent.text(
            'text.database.auth_helper.the_email_address_is_invalid_f9871e');
        break;
      case 'user-not-found':
        errorMessage = AppContent.text(
            'text.database.auth_helper.no_user_found_please_sign_in_again_257abd');
        break;
    }

    if (context.mounted) {
      await CustomAlertDialog.showAlertDialog(
        context,
        AppContent.text('text.database.auth_helper.error_7f2f6a'),
        errorMessage,
        icon: const Icon(Icons.error, color: Colors.red),
      );
    }

    return false;
  } catch (e) {
    log('Unexpected error resending verification email: $e');

    if (context.mounted) {
      await CustomAlertDialog.showAlertDialog(
        context,
        AppContent.text('text.database.auth_helper.error_7f2f6a'),
        AppContent.text(
            'text.database.auth_helper.an_unexpected_error_occurred_please_tr_d07ac0'),
        icon: const Icon(Icons.error, color: Colors.red),
      );
    }

    return false;
  }
}
