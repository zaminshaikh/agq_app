// ignore_for_file: use_build_context_synchronously

import 'package:agq_app/content/app_content.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/material.dart'; // For Navigator
import 'package:agq_app/database/auth_helper.dart';
import 'package:agq_app/database/database.dart';
import 'package:agq_app/screens/authenticate/login/login.dart';
import 'package:agq_app/screens/dashboard/dashboard.dart';
import 'package:agq_app/components/alert_dialog.dart';

bool showAlert = false;

class GoogleAuthService {
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<UserCredential?> signInWithGoogle(BuildContext context) async {
    debugPrint('GoogleAuthService: Starting Google sign-in process.');

    try {
      final GoogleSignInAccount? googleSignInAccount =
          await _googleSignIn.signIn();
      if (googleSignInAccount == null) {
        debugPrint('GoogleAuthService: Google sign-in aborted by user.');
        return null;
      }
      debugPrint('GoogleAuthService: Google sign-in successful.');

      final GoogleSignInAuthentication googleSignInAuthentication =
          await googleSignInAccount.authentication;
      debugPrint('GoogleAuthService: Google authentication obtained.');

      final credential = GoogleAuthProvider.credential(
        accessToken: googleSignInAuthentication.accessToken,
        idToken: googleSignInAuthentication.idToken,
      );
      debugPrint('GoogleAuthService: Firebase credential created.');

      final UserCredential userCredential =
          await _auth.signInWithCredential(credential);
      debugPrint('GoogleAuthService: Firebase sign-in successful.');

      // Check if the uid exists in Firestore
      final User? user = userCredential.user;
      if (user != null) {
        final DatabaseService? db =
            await DatabaseService.fetchCID(user.uid, context);
        if (db == null) {
          debugPrint(
              'GoogleAuthService: UID does not exist in Firestore. Deleting UID and redirecting to login.');

          showAlert = true;
          await showGoogleFailAlert(context);
          return null;
        }
      } else {
        debugPrint(
            'GoogleAuthService: User UID is null. Redirecting to login.');
        showAlert = true;
        await Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
        );
        return null;
      }

      await updateFirebaseMessagingToken(user, context);

      // Navigate to Dashboard
      await Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const DashboardPage()),
      );

      return userCredential;
    } catch (e) {
      debugPrint('GoogleAuthService: Error during Google sign-in: $e');
      rethrow;
    }
  }

  Future<bool> showGoogleFailAlert(context) async {
    if (showAlert) {
      await CustomAlertDialog.showAlertDialog(
          context,
          AppContent.text(
              'text.screens.authenticate.utils.google_auth_service.google_sign_in_failed_07ec0e'),
          AppContent.text(
              'text.screens.authenticate.utils.google_auth_service.the_gmail_account_you_tried_to_sign_in_9ad980'),
          icon: const Icon(
            FontAwesomeIcons.google,
            color: Colors.blue,
          ));
      return false;
    }
    return true;
  }

  Future<bool> showGoogleSignUpFailAlert(context, String message) async {
    if (showAlert) {
      await CustomAlertDialog.showAlertDialog(
          context,
          AppContent.text(
              'text.screens.authenticate.utils.google_auth_service.google_sign_in_failed_07ec0e'),
          message,
          icon: const Icon(
            FontAwesomeIcons.google,
            color: Colors.blue,
          ));
      return false;
    }
    return true;
  }

  Future<bool> wrongCIDFailAlert(context) async {
    if (showAlert) {
      await CustomAlertDialog.showAlertDialog(
          context,
          AppContent.text(
              'text.screens.authenticate.utils.google_auth_service.google_sign_up_failed_ff4b4f'),
          AppContent.text(
              'text.screens.authenticate.utils.google_auth_service.the_cid_you_entered_does_not_exist_ple_27932f'),
          icon: const Icon(
            FontAwesomeIcons.google,
            color: Colors.blue,
          ));
      return false;
    }
    return true;
  }

  Future<UserCredential?> signUpWithGoogle(
      BuildContext context, String cid) async {
    // Log the start of the Google sign-up process
    debugPrint('GoogleAuthService: Starting Google sign-up process.');

    try {
      // Attempt to sign in with Google
      final GoogleSignInAccount? googleSignInAccount =
          await _googleSignIn.signIn();
      if (googleSignInAccount == null) {
        // If the user aborts the sign-in process, log it and return null
        debugPrint('GoogleAuthService: Google sign-up aborted by user.');
        return null;
      }
      // Log successful Google sign-in
      debugPrint('GoogleAuthService: Google sign-up successful.');

      // Obtain Google authentication details
      final GoogleSignInAuthentication googleSignInAuthentication =
          await googleSignInAccount.authentication;
      // Log that Google authentication details have been obtained
      debugPrint('GoogleAuthService: Google authentication obtained.');

      // Create a credential for Firebase authentication using the Google authentication details
      final credential = GoogleAuthProvider.credential(
        accessToken: googleSignInAuthentication.accessToken,
        idToken: googleSignInAuthentication.idToken,
      );
      // Log that the Firebase credential has been created
      debugPrint('GoogleAuthService: Firebase credential created.');

      // Sign in to Firebase with the Google credential
      final UserCredential userCredential =
          await _auth.signInWithCredential(credential);
      // Log successful Firebase sign-in
      debugPrint('GoogleAuthService: Firebase sign-up successful.');

      // Get the user from the user credential
      final User? user = userCredential.user;
      if (user != null) {
        // Log the user's UID
        debugPrint('GoogleAuthService: User UID: ${user.uid}');
        // Check if the user exists in Firestore by fetching the CID
        final DatabaseService db = DatabaseService.withCID(user.uid, cid);

        bool uidLinked = await db.isUIDLinked(user.uid);
        bool docExists = await db.checkDocumentExists(cid);
        bool docLinked = await db.checkDocumentLinked(cid);

        // Check if CID exists and is not linked.
        if (uidLinked && docExists && !docLinked) {
          showAlert = true;
          await showGoogleSignUpFailAlert(
              context,
              AppContent.text(
                  'text.screens.authenticate.utils.google_auth_service.email_value1_is_already_associated_wit_ceaaf1',
                  {'value1': user.email}));
          return null;
        } else if (!docExists) {
          showAlert = true;
          await wrongCIDFailAlert(context);
          return null;
        } else if (docLinked) {
          showAlert = true;
          await showGoogleSignUpFailAlert(
              context,
              AppContent.text(
                  'text.screens.authenticate.utils.google_auth_service.user_already_exists_for_given_client_i_ec27db',
                  {'cid': cid}));
          return null;
        }
        // If the user does not exist in Firestore, log it and create a new user

        try {
          // Add the new user to Firestore with the provided CID
          debugPrint('cid: $cid');
          await db.linkNewUser(user.email!);
          await updateFirebaseMessagingToken(user, context);
        } catch (e) {
          // If there is an error adding the new user to Firestore, log the error and show an alert
          debugPrint('Error adding new user to Firestore: $e');
          showAlert = true;
          await showGoogleSignUpFailAlert(context, e.toString());
          return null;
        }
      } else {
        // If the user UID is null, log it and redirect to the login page
        debugPrint(
            'GoogleAuthService: User UID is null. Redirecting to login.');
        showAlert = true;
        await Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
        );
        return null;
      }

      // Navigate to the Dashboard page
      await Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const DashboardPage(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) =>
              child,
        ),
      );

      // Return the user credential
      return userCredential;
    } catch (e) {
      // If there is an error during the Google sign-up process, log the error and rethrow it
      debugPrint('GoogleAuthService: Error during Google sign-up: $e');
      rethrow;
    }
  }

  Future<void> signOut() async {
    debugPrint('GoogleAuthService: Starting sign-out process.');

    try {
      await _googleSignIn.signOut();
      debugPrint('GoogleAuthService: Google sign-out successful.');

      await _auth.signOut();
      debugPrint('GoogleAuthService: Firebase sign-out successful.');
    } catch (e) {
      debugPrint('GoogleAuthService: Error during sign-out: $e');
      rethrow;
    }
  }
}
