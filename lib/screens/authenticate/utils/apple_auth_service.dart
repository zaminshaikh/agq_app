import 'package:agq_app/content/app_content.dart';
import 'dart:convert';
import 'dart:developer';
import 'dart:math' as math;
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:agq_app/components/alert_dialog.dart';
import 'package:agq_app/database/database.dart';
import 'package:agq_app/screens/authenticate/utils/app_state.dart';
import 'package:provider/provider.dart';

import 'package:agq_app/database/auth_helper.dart';

class AppleAuthService {
  /// Sign in with Apple (without CID - for login)
  Future<bool> signInWithApple(BuildContext context) async {
    try {
      // Check if Apple Sign In is available on this platform
      final isAvailable = await SignInWithApple.isAvailable();
      if (!isAvailable) {
        if (context.mounted) {
          await CustomAlertDialog.showAlertDialog(
            context,
            AppContent.text(
                'text.screens.authenticate.utils.apple_auth_service.not_available_4028c0'),
            AppContent.text(
                'text.screens.authenticate.utils.apple_auth_service.sign_in_with_apple_is_not_available_on_ab2a7e'),
            icon: const Icon(Icons.error_outline, color: Colors.red),
          );
        }
        return false;
      }

      log('Starting Apple sign in process (login flow)');

      // Generate secure nonce - MUST follow Firebase requirements
      final rawNonce = _generateNonce();
      final nonce = _sha256ofString(rawNonce);

      log('Generated nonce for Apple Sign In');

      // Request credential from Apple
      try {
        final appleCredential = await SignInWithApple.getAppleIDCredential(
          scopes: [
            AppleIDAuthorizationScopes.email,
            AppleIDAuthorizationScopes.fullName,
          ],
          nonce: nonce,
        );

        log('Got Apple credential with identity token length: ${appleCredential.identityToken?.length ?? 0}');

        if (appleCredential.identityToken == null) {
          log('Error: Identity token is null');
          throw FirebaseAuthException(
            code: 'invalid-credential',
            message: AppContent.text(
                'text.screens.authenticate.utils.apple_auth_service.apple_sign_in_failed_identity_token_is_c10704'),
          );
        }

        // Create OAuthCredential
        final oauthCredential = OAuthProvider('apple.com').credential(
          idToken: appleCredential.identityToken!,
          rawNonce: rawNonce,
          accessToken: appleCredential.authorizationCode,
        );

        log('Created OAuth credential for Firebase');

        // Sign in with Firebase
        final userCredential =
            await FirebaseAuth.instance.signInWithCredential(oauthCredential);
        final user = userCredential.user;

        if (user == null) {
          log('Error: Firebase user is null after sign in');
          throw FirebaseAuthException(
            code: 'user-not-found',
            message: AppContent.text(
                'text.screens.authenticate.utils.apple_auth_service.failed_to_get_user_after_apple_sign_in_100e83'),
          );
        }

        log('Successfully signed in with Firebase using Apple ID: ${user.uid}');

        // Update display name if needed
        if (appleCredential.givenName != null &&
            appleCredential.familyName != null) {
          String fullName =
              '${appleCredential.givenName} ${appleCredential.familyName}';
          if (user.displayName == null || user.displayName!.isEmpty) {
            await user.updateDisplayName(fullName);
          }
        }

        // Check if this user has a linked CID
        final db = DatabaseService(user.uid);
        final isLinked = await db.isUIDLinked(user.uid);

        if (!isLinked) {
          log('User is not linked to any CID');
          if (context.mounted) {
            await CustomAlertDialog.showAlertDialog(
              context,
              AppContent.text(
                  'text.screens.authenticate.utils.apple_auth_service.account_not_found_df3c9a'),
              AppContent.text(
                  'text.screens.authenticate.utils.apple_auth_service.this_apple_id_is_not_linked_to_any_acc_f9127a'),
              icon: const Icon(Icons.error_outline, color: Colors.red),
            );
          }
          await FirebaseAuth.instance.signOut();
          return false;
        }
        if (!context.mounted) return false;
        // Update Firebase messaging token
        await updateFirebaseMessagingToken(user, context);

        return true;
      } catch (signInError) {
        log('Error during Apple Sign In process: $signInError');
        rethrow;
      }
    } catch (e) {
      log('Error in Apple sign in: $e', stackTrace: StackTrace.current);
      if (context.mounted) {
        String message = AppContent.text(
            'text.screens.authenticate.utils.apple_auth_service.failed_to_sign_in_with_apple_7ea61e');
        if (e.toString().contains('canceled')) {
          message = AppContent.text(
              'text.screens.authenticate.utils.apple_auth_service.sign_in_was_canceled_1fcd7f');
        } else if (e.toString().contains('invalid-credential')) {
          message = AppContent.text(
              'text.screens.authenticate.utils.apple_auth_service.authentication_failed_please_try_again_c8a267');
        }
        await _showError(context, message);
      }
      return false;
    }
  }

  /// Sign up with Apple account (with CID)
  Future<void> signUpWithApple(BuildContext context, String cid) async {
    try {
      // Check if Apple Sign In is available on this platform
      final isAvailable = await SignInWithApple.isAvailable();
      if (!isAvailable) {
        if (context.mounted) {
          await CustomAlertDialog.showAlertDialog(
            context,
            AppContent.text(
                'text.screens.authenticate.utils.apple_auth_service.not_available_4028c0'),
            AppContent.text(
                'text.screens.authenticate.utils.apple_auth_service.sign_in_with_apple_is_not_available_on_ab2a7e'),
            icon: const Icon(Icons.error_outline, color: Colors.red),
          );
        }
        return;
      }

      log('Starting Apple sign in process');

      // Generate secure nonce - MUST follow Firebase requirements
      final rawNonce = _generateNonce();
      final nonce = _sha256ofString(rawNonce);

      log('Generated nonce for Apple Sign In');

      // Request credential from Apple
      try {
        final appleCredential = await SignInWithApple.getAppleIDCredential(
          scopes: [
            AppleIDAuthorizationScopes.email,
            AppleIDAuthorizationScopes.fullName,
          ],
          nonce: nonce,
        );

        log('Got Apple credential with identity token length: ${appleCredential.identityToken?.length ?? 0}');

        if (appleCredential.identityToken == null) {
          log('Error: Identity token is null');
          throw FirebaseAuthException(
            code: 'invalid-credential',
            message: AppContent.text(
                'text.screens.authenticate.utils.apple_auth_service.apple_sign_in_failed_identity_token_is_c10704'),
          );
        }

        // Create OAuthCredential
        final oauthCredential = OAuthProvider('apple.com').credential(
          idToken: appleCredential.identityToken!,
          rawNonce: rawNonce,
          accessToken: appleCredential.authorizationCode,
        );

        log('Created OAuth credential for Firebase');

        // Sign in with Firebase
        final userCredential =
            await FirebaseAuth.instance.signInWithCredential(oauthCredential);
        final user = userCredential.user;

        if (user == null) {
          log('Error: Firebase user is null after sign in');
          throw FirebaseAuthException(
            code: 'user-not-found',
            message: AppContent.text(
                'text.screens.authenticate.utils.apple_auth_service.failed_to_get_user_after_apple_sign_in_100e83'),
          );
        }

        log('Successfully signed in with Firebase using Apple ID: ${user.uid}');

        // Process the user data
        String displayName = 'Apple User';
        if (appleCredential.givenName != null &&
            appleCredential.familyName != null) {
          displayName =
              '${appleCredential.givenName} ${appleCredential.familyName}';
          // Update display name if needed
          if (user.displayName == null || user.displayName!.isEmpty) {
            await user.updateDisplayName(displayName);
          }
        }
        if (!context.mounted) return;
        // Process sign-up with database
        await _processSignUp(context, userCredential, cid);
      } catch (signInError) {
        log('Error during Apple Sign In process: $signInError');
        rethrow;
      }
    } catch (e) {
      log('Error in Apple sign up: $e', stackTrace: StackTrace.current);
      if (context.mounted) {
        String message = AppContent.text(
            'text.screens.authenticate.utils.apple_auth_service.failed_to_sign_up_with_apple_e98f0d');
        if (e.toString().contains('canceled')) {
          message = AppContent.text(
              'text.screens.authenticate.utils.apple_auth_service.sign_in_was_canceled_1fcd7f');
        } else if (e.toString().contains('invalid-credential')) {
          message = AppContent.text(
              'text.screens.authenticate.utils.apple_auth_service.authentication_failed_please_try_again_c8a267');
        }
        await _showError(context, message);
      }
    }
  }

  /// Generates a cryptographically secure random nonce
  String _generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = math.Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)])
        .join();
  }

  /// Returns the SHA-256 hash of [input] in hex notation
  String _sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Process the sign up after authentication
  Future<void> _processSignUp(
      BuildContext context, UserCredential userCredential, String cid) async {
    User user = userCredential.user!;
    log('Processing Apple sign up for user: ${user.uid}');

    // Check if this is a new user
    final isNewUser = userCredential.additionalUserInfo?.isNewUser ?? false;
    log('Is new user: $isNewUser');

    try {
      // Initialize database with CID
      final db = DatabaseService.withCID(user.uid, cid);

      // Check if CID exists
      if (!(await db.checkDocumentExists(cid)) && context.mounted) {
        log('No record found for Client ID: $cid');
        await _showError(
            context,
            AppContent.text(
                'text.screens.authenticate.utils.apple_auth_service.no_record_found_for_client_id_cid_plea_025e5d',
                {'cid': cid}));
        await FirebaseAuth.instance.signOut();
        return;
      }

      // Check if CID is already linked
      if (await db.checkDocumentLinked(cid)) {
        if (!isNewUser && context.mounted) {
          // User is logging in with existing account
          log('Existing user logging in with Apple ID');
          await updateFirebaseMessagingToken(user, context);
          if (context.mounted) {
            Provider.of<AuthState>(context, listen: false)
                .setInitiallyAuthenticated(true);
            await Navigator.of(context)
                .pushNamedAndRemoveUntil('/dashboard', (route) => false);
          }
        } else if (context.mounted) {
          // Someone else has already linked with this CID
          log('CID already linked to another account: $cid');
          await _showError(
              context,
              AppContent.text(
                  'text.screens.authenticate.utils.apple_auth_service.this_client_id_is_already_linked_to_an_3226d4'));
          await FirebaseAuth.instance.signOut();
        }
        return;
      }

      // Link new user
      log('Linking new user with Apple ID');
      // Use displayName if available, otherwise email or a default
      final userIdentifier = user.displayName ?? user.email ?? 'Apple User';
      await db.linkNewUser(userIdentifier);
      if (!context.mounted) return;
      await updateFirebaseMessagingToken(user, context);

      // Notify user of success
      if (context.mounted) {
        await CustomAlertDialog.showAlertDialog(
          context,
          AppContent.text(
              'text.screens.authenticate.utils.apple_auth_service.success_42a8f6'),
          AppContent.text(
              'text.screens.authenticate.utils.apple_auth_service.your_account_has_been_created_and_link_f01413'),
          icon: const Icon(Icons.check_circle_outline_rounded,
              color: Colors.green),
        );
        if (!context.mounted) return;
        // Update app state and navigate to dashboard
        Provider.of<AuthState>(context, listen: false)
            .setInitiallyAuthenticated(true);
        await Navigator.of(context)
            .pushNamedAndRemoveUntil('/dashboard', (route) => false);
      }
    } catch (e) {
      log('Error in _processSignUp: $e', stackTrace: StackTrace.current);
      if (context.mounted) {
        await _showError(
            context,
            AppContent.text(
                'text.screens.authenticate.utils.apple_auth_service.failed_to_process_sign_up_value1_766de4',
                {'value1': e.toString()}));
        await FirebaseAuth.instance.signOut();
      }
    }
  }

  /// Show error dialog
  Future<void> _showError(BuildContext context, String message) async {
    if (context.mounted) {
      await CustomAlertDialog.showAlertDialog(
        context,
        AppContent.text(
            'text.screens.authenticate.utils.apple_auth_service.error_7f2f6a'),
        message,
        icon: const Icon(Icons.error_outline, color: Colors.red),
      );
    }
  }
}
