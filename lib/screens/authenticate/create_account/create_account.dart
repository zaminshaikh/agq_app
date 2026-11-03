// create_account_page.dart

import 'package:agq_app/content/app_content.dart';
import 'package:agq_app/content/content_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:agq_app/components/alert_dialog.dart';
import 'package:agq_app/components/progress_indicator.dart';
import 'package:agq_app/database/auth_helper.dart';
import 'dart:developer';
import 'package:agq_app/database/database.dart';
import 'package:agq_app/screens/authenticate/create_account/components/email_verification_dialog.dart';
import 'package:agq_app/screens/authenticate/create_account/components/password_security_indicator.dart';
import 'package:agq_app/screens/authenticate/create_account/components/password_validation.dart';
import 'package:agq_app/screens/authenticate/login/login.dart';
import 'package:agq_app/screens/authenticate/utils/app_state.dart';
import 'package:agq_app/screens/authenticate/utils/google_auth_service.dart';
import 'package:agq_app/screens/authenticate/utils/apple_auth_service.dart';

/// A StatefulWidget representing the Create Account page.
class CreateAccountPage extends StatefulWidget {
  const CreateAccountPage({super.key});

  @override
  CreateAccountPageState createState() => CreateAccountPageState();
}

/// State class for the CreateAccountPage.
class CreateAccountPageState extends State<CreateAccountPage> {
  bool isLoading = false;

  // Controllers for text fields.
  final TextEditingController _clientIDController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _createAccountPasswordController =
      TextEditingController();
  final TextEditingController _confirmCreateAccountPasswordController =
      TextEditingController();

  // Focus node for Client ID field
  final FocusNode _clientIDFocusNode = FocusNode();

  // Firebase and app state.
  late DatabaseService db;
  late AuthState appState;

  // User inputs and states.
  bool _isButtonEnabled = false;
  bool _hidePassword = true;
  String _cid = '';
  String _email = '';
  String _createAccountPasswordString = '';
  String _confirmCreateAccountPasswordString = '';
  int _passwordSecurityIndicator = 0;

  @override
  void initState() {
    super.initState();
    _clientIDController.addListener(_checkIfFilled);
  }

  /// Check if the user is authenticated and linked
  Future<bool> isAuthenticated() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return false;
    }

    String uid = user.uid;

    DatabaseService db = DatabaseService(uid);

    bool isLinked = await db.isUIDLinked(uid);

    return isLinked;
  }

  @override
  void dispose() async {
    _clientIDController.removeListener(_checkIfFilled);
    _clientIDController.dispose();
    _clientIDFocusNode.dispose(); // Dispose focus node
    super.dispose();
    if (!(await isAuthenticated())) {
      await FirebaseAuth.instance.signOut();
    }
  }

  /// Checks if the Client ID field is filled to enable the button.
  void _checkIfFilled() {
    setState(() {
      _cid = _clientIDController.text;
      _isButtonEnabled = _cid.isNotEmpty;
    });
  }

  /// Handles the sign-up process.
  void _signUserUp() async {
    setState(() {
      isLoading = true;
    });
    // Delete any existing user in the buffer.
    await deleteUserInBuffer();

    try {
      // Create a new user with email and password.
      UserCredential userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _createAccountPasswordController.text.trim(),
      );

      if (userCredential.user == null) {
        throw FirebaseAuthException(code: 'operation-not-allowed');
      }

      log('UserCredential created: ${userCredential.user!.uid}. In buffer.');

      // Initialize database service with CID.
      db = DatabaseService.withCID(userCredential.user!.uid, _cid);

      // Check if CID exists and is not linked.
      if (!(await db.checkDocumentExists(_cid))) {
        await _showErrorAndDeleteUser(AppContent.text(
            'text.screens.authenticate.create_account.create_account.there_is_no_record_of_the_client_id_va_96674c',
            {'value1': _cid}));
        return;
      } else if (await db.checkDocumentLinked(_cid)) {
        await _showErrorAndDeleteUser(AppContent.text(
            'text.screens.authenticate.create_account.create_account.user_already_exists_for_given_client_i_e4c8b5',
            {'value1': _cid}));
        return;
      }

      // Send email verification.
      User? user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _createAccountPasswordController.text.trim(),
        );
      }

      user = FirebaseAuth.instance.currentUser;

      await FirebaseAuth.instance.currentUser!.sendEmailVerification();

      // Show email verification dialog.
      if (!mounted) return;
      await showDialog(
        context: context,
        builder: (BuildContext context) => EmailVerificationDialog(
          onContinue: _verifyEmail,
        ),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      await handleFirebaseAuthException(context, e, _email);
    } catch (e) {
      log('Error signing user up: $e', stackTrace: StackTrace.current);
      await FirebaseAuth.instance.currentUser?.delete();
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  /// Verifies if the email is confirmed and proceeds accordingly.
  Future<bool> _verifyEmail() async {
    setState(() {
      isLoading = true;
    });
    User? user = FirebaseAuth.instance.currentUser;
    await user?.reload();
    user = FirebaseAuth.instance.currentUser;

    if (user != null && user.emailVerified) {
      String uid = user.uid;
      await db.linkNewUser(user.email!);
      log('User $uid connected to Client ID $_cid');

      if (!mounted) return true;
      await updateFirebaseMessagingToken(user, context);

      if (!mounted) return true;
      await CustomAlertDialog.showAlertDialog(
        context,
        AppContent.text(
            'text.screens.authenticate.create_account.create_account.success_42a8f6'),
        AppContent.text(
            'text.screens.authenticate.create_account.create_account.email_verified_successfully_b1a0f1'),
        icon:
            const Icon(Icons.check_circle_outline_rounded, color: Colors.green),
      );
      if (!mounted) return true;
      appState = Provider.of<AuthState>(context, listen: false);
      appState.setInitiallyAuthenticated(true);
      setState(() {
        isLoading = false;
      });

      await Navigator.of(context)
          .pushNamedAndRemoveUntil('/dashboard', (route) => false);

      return true;
    } else {
      if (!mounted) return false;
      await CustomAlertDialog.showAlertDialog(
        context,
        AppContent.text(
            'text.screens.authenticate.create_account.create_account.error_7f2f6a'),
        AppContent.text(
            'text.screens.authenticate.create_account.create_account.email_not_verified_please_check_your_i_e2adbf'),
        icon: const Icon(Icons.error_outline, color: Colors.red),
      );
      setState(() {
        isLoading = false;
      });
      return false;
    }
  }

  /// Shows an error dialog and deletes the current user.
  Future<void> _showErrorAndDeleteUser(String message) async {
    if (!mounted) return;
    await CustomAlertDialog.showAlertDialog(
        context,
        AppContent.text(
            'text.screens.authenticate.create_account.create_account.error_7f2f6a'),
        message);
    await FirebaseAuth.instance.currentUser?.delete();
    log('Error: $message');
  }

  /// Updates the password strength indicator.
  void _updatePasswordSecurityIndicator() {
    int conditionsMet = 0;

    if (_createAccountPasswordString.length > 7) {
      conditionsMet++;
    }

    if (_createAccountPasswordString.contains(RegExp(r'\d'))) {
      conditionsMet++;
    }

    if (_createAccountPasswordString.contains(RegExp(r'[A-Z]'))) {
      conditionsMet++;
    }

    if (_createAccountPasswordString.contains(RegExp(r'[a-z]'))) {
      conditionsMet++;
    }

    // Update _passwordSecurityIndicator based on the number of conditions met
    _passwordSecurityIndicator = conditionsMet;
  }

  /// Updates the password string and security indicator.
  void _updateFields(String value) {
    setState(() {
      _createAccountPasswordString = value;
      _createAccountPasswordController.text = value;
      _updatePasswordSecurityIndicator();
    });
  }

  /// Checks if the passwords match.
  bool _doPasswordsMatch() =>
      _createAccountPasswordString == _confirmCreateAccountPasswordString &&
      _createAccountPasswordString.isNotEmpty;

  /// Builds the create account screen widget.
  @override
  Widget build(BuildContext context) {
    AppContent.watch(context, keys: const {
      'signup.cid_help',
      'text.screens.authenticate.create_account.create_account.email_not_verified_please_check_your_i_e2adbf',
      'text.screens.authenticate.create_account.create_account.invalid_authentication_please_try_agai_bb127a',
      'text.screens.authenticate.create_account.create_account.sign_in_with_apple_is_not_available_on_f881d6',
      'text.screens.authenticate.create_account.create_account.there_is_no_record_of_the_client_id_va_96674c',
      'text.screens.authenticate.create_account.create_account.there_was_a_problem_signing_in_with_ap_e31638',
      'text.screens.authenticate.create_account.create_account.user_already_exists_for_given_client_i_e4c8b5',
      'text.screens.authenticate.create_account.create_account.we_need_your_cid_to_authenticate_with__59fafa',
      'text.screens.authenticate.create_account.create_account.we_need_your_cid_to_authenticate_with__88fd95',
    });
    return Scaffold(
      body: Stack(
        children: [
          SingleChildScrollView(
            // Wrapping everything in a column to arrange children vertically
            child: Column(
              // Centering the children
              mainAxisAlignment: MainAxisAlignment.center,

              // Making a list of child widgets in the Column
              children: <Widget>[
                // Logo and branding
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0xFF0D5EAF), // Start color
                        Color.fromARGB(255, 17, 24, 39), // End color
                      ],
                    ),
                  ),
                  child: const Stack(
                    children: [
                      // PNG gradient overlay
                      Positioned.fill(
                        child: Opacity(
                          opacity: 0.3, // Adjust the opacity as needed
                          child: AppContentImage(
                            'assets/icons/total_assets_gradient.png', // Path to your PNG gradient
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Column(
                        children: [
                          SizedBox(height: 60.0),
                          Padding(
                            padding: EdgeInsets.fromLTRB(20, 32, 20, 32),
                            child: Align(
                              alignment: Alignment(-1.0, -1.0),
                              child: AppContentImage(
                                'assets/icons/agq_logo.png',
                                height: 50,
                              ),
                            ),
                          ),
                          SizedBox(height: 40.0),
                        ],
                      ),
                    ],
                  ),
                ),

                // Additional container with another gradient
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color.fromARGB(255, 20, 33, 57), // End color
                        Color.fromARGB(255, 17, 24, 39), // End color
                      ],
                    ),
                  ),
                  child: Stack(
                    children: [
                      Column(
                        children: [
                          Text(
                            AppContent.text(
                                'text.screens.authenticate.create_account.create_account.create_an_account_db933d'),
                            style: const TextStyle(
                              fontSize: 26,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Titillium Web',
                            ),
                          ),
                          const SizedBox(height: 20.0),
                          const Row(
                            children: [Text(''), Spacer(), Text('')],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      // Client ID input field
                      _buildClientIDField(),

                      // Adding some space here
                      const SizedBox(height: 32.0),

                      // Google Sign-Up button
                      _buildGoogleSignUpButton(),

                      // Adding some space here
                      const SizedBox(height: 16.0),

                      // Apple Sign-Up button
                      _buildAppleSignUpButton(),

                      // Adding some space here
                      const SizedBox(height: 32.0),

                      // OR divider
                      _buildOrDivider(),

                      // Adding some space here
                      const SizedBox(height: 32.0),

                      // Email input field
                      _buildEmailField(),

                      // Adding some space here
                      const SizedBox(height: 16.0),

                      // Password input field
                      _buildPasswordField(),

                      // Adding some space here
                      const SizedBox(height: 12.0),

                      // Password security indicator
                      PasswordSecurityIndicator(
                          strength: _passwordSecurityIndicator),

                      // Adding some space here
                      const SizedBox(height: 20.0),

                      // Password validation checks
                      PasswordValidation(
                          password: _createAccountPasswordString),

                      // Adding some space here
                      const SizedBox(height: 16.0),

                      // Confirm password input field
                      _buildConfirmPasswordField(),

                      // Adding some space here
                      const SizedBox(height: 16.0),

                      // Next button
                      _buildNextButton(),

                      // Adding some space here
                      const SizedBox(height: 30.0),

                      // Login option
                      _buildLoginOption(),

                      // Adding some space here
                      const SizedBox(height: 20.0),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (isLoading || isLoading) ...[
            const Opacity(
              opacity: 0.5,
              child: ModalBarrier(
                dismissible: false,
                color: Colors.black,
              ),
            ),
            const Center(
              child: CustomProgressIndicator(),
            ),
          ],
        ],
      ),
    );
  }

  /// Builds the Client ID input field.
  Widget _buildClientIDField() => Container(
        padding: const EdgeInsets.all(4.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Text(
                  AppContent.text(
                      'text.screens.authenticate.create_account.create_account.client_id_a766cd'),
                  style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      fontFamily: 'Titillium Web'),
                ),
                const Spacer(),
                GestureDetector(
                  child: Container(
                    color: Colors.transparent,
                    child: Row(
                      children: [
                        Text(
                          AppContent.text(
                              'text.screens.authenticate.create_account.create_account.what_is_my_client_id_bd1e22'),
                          style: const TextStyle(
                              fontSize: 16,
                              color: Color.fromARGB(255, 157, 157, 157),
                              fontFamily: 'Titillium Web'),
                        ),
                        const SizedBox(width: 5),
                        const Icon(
                          Icons.help_outline_rounded,
                          color: Color(0xFF3199DD),
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                  onTap: () => CustomAlertDialog.showAlertDialog(
                    context,
                    AppContent.text(
                        'text.screens.authenticate.create_account.create_account.client_id_a766cd'),
                    AppContent.text('signup.cid_help'),
                    icon: const Icon(Icons.numbers_rounded,
                        color: Color(0xFF3199DD)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10.0),
            TextField(
              controller: _clientIDController,
              focusNode: _clientIDFocusNode, // Add focus node
              keyboardType: TextInputType.number,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.white,
                fontFamily: 'Titillium Web',
              ),
              decoration: InputDecoration(
                hintText: AppContent.text(
                    'text.screens.authenticate.create_account.create_account.enter_your_client_id_c015bb'),
                hintStyle: const TextStyle(
                  color: Color.fromARGB(255, 122, 122, 122),
                  fontFamily: 'Titillium Web',
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(11),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(11),
                  borderSide: const BorderSide(
                    color: Color.fromARGB(255, 27, 123, 201),
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 14,
                  horizontal: 14,
                ),
              ),
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(8), // Limit to 8 digits
              ],
              onChanged: (value) {
                setState(() {
                  _cid = value;
                  // Auto-unfocus when 8 digits are entered
                  if (value.length == 8) {
                    _clientIDFocusNode.unfocus();
                  }
                });
              },
            ),
          ],
        ),
      );

  Widget _buildGoogleSignUpButton() => GestureDetector(
        onTap: _isButtonEnabled
            ? () async {
                // Dismiss the keyboard
                FocusScope.of(context).unfocus();
                try {
                  setState(() => isLoading = true);
                  await GoogleAuthService().signUpWithGoogle(context, _cid);
                } finally {
                  setState(() => isLoading = false);
                }
              }
            : () {
                // Dismiss the keyboard
                FocusScope.of(context).unfocus();

                CustomAlertDialog.showAlertDialog(
                  context,
                  AppContent.text(
                      'text.screens.authenticate.create_account.create_account.please_enter_your_cid_a9ada6'),
                  AppContent.text(
                      'text.screens.authenticate.create_account.create_account.we_need_your_cid_to_authenticate_with__59fafa'),
                );
              },
        child: Container(
          height: 55,
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: const Color.fromARGB(255, 30, 75, 137),
              width: 4,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                FontAwesomeIcons.google,
                color: Colors.blue,
              ),
              const SizedBox(width: 15),
              Text(
                AppContent.text(
                    'text.screens.authenticate.create_account.create_account.sign_up_with_google_338492'),
                style: const TextStyle(
                  fontSize: 18,
                  color: Colors.blue,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Titillium Web',
                ),
              ),
            ],
          ),
        ),
      );

  /// Builds the Apple Sign-Up button.
  Widget _buildAppleSignUpButton() => GestureDetector(
        onTap: _isButtonEnabled
            ? () async {
                // Dismiss the keyboard
                FocusScope.of(context).unfocus();
                try {
                  setState(() => isLoading = true);
                  log('Apple Sign In button pressed, checking availability...');

                  // Check if Sign In with Apple is available first
                  final isAvailable = await SignInWithApple.isAvailable();
                  log('Apple Sign In available: $isAvailable');

                  if (!isAvailable) {
                    if (mounted) {
                      await CustomAlertDialog.showAlertDialog(
                        context,
                        AppContent.text(
                            'text.screens.authenticate.create_account.create_account.not_available_4028c0'),
                        AppContent.text(
                            'text.screens.authenticate.create_account.create_account.sign_in_with_apple_is_not_available_on_f881d6'),
                      );
                    }
                    return;
                  }

                  log('Starting Apple sign in process with CID: $_cid');
                  if (!mounted) return;
                  await AppleAuthService().signUpWithApple(context, _cid);
                } on FirebaseAuthException catch (e) {
                  log('Firebase Auth Error in Apple sign-in: ${e.code} - ${e.message}',
                      stackTrace: StackTrace.current);
                  if (mounted) {
                    String message = AppContent.text(
                        'text.screens.authenticate.create_account.create_account.authentication_failed_2db8da');
                    switch (e.code) {
                      case 'invalid-credential':
                        message = AppContent.text(
                            'text.screens.authenticate.create_account.create_account.invalid_authentication_please_try_agai_bb127a');
                        break;
                      case 'user-disabled':
                        message = AppContent.text(
                            'text.screens.authenticate.create_account.create_account.this_user_account_has_been_disabled_b7de08');
                        break;
                      case 'operation-not-allowed':
                        message = AppContent.text(
                            'text.screens.authenticate.create_account.create_account.apple_sign_in_is_not_enabled_for_this__e41fa9');
                        break;
                      default:
                        message = AppContent.text(
                            'text.screens.authenticate.create_account.create_account.authentication_failed_value1_e19ef8',
                            {'value1': e.message});
                    }
                    await CustomAlertDialog.showAlertDialog(
                      context,
                      AppContent.text(
                          'text.screens.authenticate.create_account.create_account.sign_in_failed_9c06fa'),
                      message,
                    );
                  }
                } catch (e) {
                  log('Error in Apple sign-in button: $e',
                      stackTrace: StackTrace.current);
                  if (mounted) {
                    await CustomAlertDialog.showAlertDialog(
                      context,
                      AppContent.text(
                          'text.screens.authenticate.create_account.create_account.apple_sign_in_failed_2122ea'),
                      AppContent.text(
                          'text.screens.authenticate.create_account.create_account.there_was_a_problem_signing_in_with_ap_e31638'),
                    );
                  }
                } finally {
                  if (mounted) {
                    setState(() => isLoading = false);
                  }
                }
              }
            : () {
                // Dismiss the keyboard
                FocusScope.of(context).unfocus();

                CustomAlertDialog.showAlertDialog(
                  context,
                  AppContent.text(
                      'text.screens.authenticate.create_account.create_account.please_enter_your_cid_a9ada6'),
                  AppContent.text(
                      'text.screens.authenticate.create_account.create_account.we_need_your_cid_to_authenticate_with__88fd95'),
                );
              },
        child: Container(
          height: 55,
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
              width: 4,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                FontAwesomeIcons.apple,
                color: Colors.white,
              ),
              const SizedBox(width: 15),
              Text(
                AppContent.text(
                    'text.screens.authenticate.create_account.create_account.sign_up_with_apple_73ca82'),
                style: const TextStyle(
                  fontSize: 18,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Titillium Web',
                ),
              ),
            ],
          ),
        ),
      );

  /// Builds the OR divider.
  Widget _buildOrDivider() => Row(
        children: [
          Expanded(
            child: Container(
              height: 3,
              color: const Color.fromARGB(255, 122, 122, 122),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Text(
              AppContent.text(
                  'text.screens.authenticate.create_account.create_account.or_f579c5'),
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: Colors.white,
                  fontFamily: 'Titillium Web'),
            ),
          ),
          Expanded(
            child: Container(
              height: 3,
              color: const Color.fromARGB(255, 122, 122, 122),
            ),
          ),
        ],
      );

  /// Builds the Email input field.
  Widget _buildEmailField() => Container(
        padding: const EdgeInsets.all(4.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              AppContent.text(
                  'text.screens.authenticate.create_account.create_account.email_84add5'),
              style: const TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                  fontFamily: 'Titillium Web'),
            ),
            const SizedBox(height: 10.0),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              style: const TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                  fontFamily: 'Titillium Web'),
              decoration: InputDecoration(
                hintText: AppContent.text(
                    'text.screens.authenticate.create_account.create_account.enter_your_email_8cdbba'),
                hintStyle: const TextStyle(
                    color: Color.fromARGB(255, 122, 122, 122),
                    fontFamily: 'Titillium Web'),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(11),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(11),
                  borderSide: const BorderSide(
                      color: Color.fromARGB(255, 27, 123, 201)),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
              ),
              onChanged: (value) {
                setState(() {
                  _email = value;
                });
              },
            ),
          ],
        ),
      );

  /// Builds the Password input field.
  Widget _buildPasswordField() => Container(
        padding: const EdgeInsets.all(4.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              AppContent.text(
                  'text.screens.authenticate.create_account.create_account.password_8be3c9'),
              style: const TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                  fontFamily: 'Titillium Web'),
            ),
            const SizedBox(height: 10.0),
            TextField(
              controller: _createAccountPasswordController,
              style: const TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                  fontFamily: 'Titillium Web'),
              decoration: InputDecoration(
                hintText: AppContent.text(
                    'text.screens.authenticate.create_account.create_account.create_a_password_f26d53'),
                hintStyle: const TextStyle(
                    color: Color.fromARGB(255, 122, 122, 122),
                    fontFamily: 'Titillium Web'),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(11),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(11),
                  borderSide: const BorderSide(
                      color: Color.fromARGB(255, 27, 123, 201)),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
                suffixIcon: GestureDetector(
                  onTap: () {
                    setState(() {
                      _hidePassword = !_hidePassword;
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(0.0),
                    child: Icon(
                      _hidePassword
                          ? Icons.remove_red_eye_outlined
                          : Icons.remove_red_eye_rounded,
                      size: 25,
                      color: const Color.fromARGB(255, 154, 154, 154),
                    ),
                  ),
                ),
              ),
              obscureText: _hidePassword,
              onChanged: _updateFields,
            ),
          ],
        ),
      );

  /// Builds the Confirm Password input field.
  Widget _buildConfirmPasswordField() => Container(
        padding: const EdgeInsets.all(4.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              AppContent.text(
                  'text.screens.authenticate.create_account.create_account.confirm_password_c2d404'),
              style: _passwordSecurityIndicator == 4
                  ? const TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      fontFamily: 'Titillium Web')
                  : const TextStyle(
                      color: Color.fromARGB(255, 122, 122, 122),
                      fontFamily: 'Titillium Web'),
            ),
            const SizedBox(height: 10.0),
            TextField(
              controller: _confirmCreateAccountPasswordController,
              style: const TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                  fontFamily: 'Titillium Web'),
              decoration: InputDecoration(
                hintText: AppContent.text(
                    'text.screens.authenticate.create_account.create_account.enter_your_password_137816'),
                hintStyle: const TextStyle(
                    color: Color.fromARGB(255, 122, 122, 122),
                    fontFamily: 'Titillium Web'),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(11),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(11),
                  borderSide: const BorderSide(
                      color: Color.fromARGB(255, 27, 123, 201)),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
              ),
              obscureText: true,
              onChanged: (value) {
                setState(() {
                  _confirmCreateAccountPasswordString = value;
                });
              },
              enabled: _passwordSecurityIndicator == 4,
            ),
          ],
        ),
      );

  /// Builds the Next button.
  Widget _buildNextButton() => GestureDetector(
        onTap: _doPasswordsMatch() ? () => _signUserUp() : null,
        child: Container(
          height: 50,
          decoration: BoxDecoration(
            color: _doPasswordsMatch()
                ? const Color.fromARGB(255, 30, 75, 137)
                : const Color.fromARGB(255, 85, 86, 87),
            borderRadius: BorderRadius.circular(25),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                AppContent.text(
                    'text.screens.authenticate.create_account.create_account.next_bc9819'),
                style: const TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Titillium Web'),
              ),
              const SizedBox(width: 10),
              const Icon(Icons.arrow_forward_ios_rounded,
                  color: Colors.white, size: 15),
            ],
          ),
        ),
      );

  /// Builds the login option row.
  Widget _buildLoginOption() => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            AppContent.text(
                'text.screens.authenticate.create_account.create_account.already_have_an_account_855903'),
            style: const TextStyle(
                fontSize: 18, color: Colors.white, fontFamily: 'Titillium Web'),
          ),
          GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () {
              Navigator.push(
                context,
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) =>
                      const LoginPage(),
                  transitionsBuilder:
                      (context, animation, secondaryAnimation, child) => child,
                ),
              );
            },
            child: TextButton(
              onPressed: null,
              child: Text(
                AppContent.text(
                    'text.screens.authenticate.create_account.create_account.login_4e5a28'),
                style: const TextStyle(
                    fontSize: 18,
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Titillium Web'),
              ),
            ),
          ),
        ],
      );
}
