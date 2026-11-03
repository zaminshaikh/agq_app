import 'package:agq_app/content/app_content.dart';
import 'package:agq_app/content/content_image.dart';
import 'dart:developer';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:agq_app/database/auth_helper.dart';
import 'package:agq_app/database/database.dart';
import 'package:agq_app/screens/authenticate/create_account/create_account.dart';
import 'package:agq_app/screens/authenticate/utils/app_state.dart';
import 'package:agq_app/screens/authenticate/login/forgot_password.dart';
import 'package:agq_app/screens/dashboard/dashboard.dart';
import 'package:local_auth/local_auth.dart';
import 'package:agq_app/screens/authenticate/utils/google_auth_service.dart';
import 'package:agq_app/components/alert_dialog.dart';
import 'package:agq_app/screens/authenticate/utils/apple_auth_service.dart';

// Creating a stateful widget for the Login page
class LoginPage extends StatefulWidget {
  final bool showAlert;

  const LoginPage({super.key, this.showAlert = false});

  @override
  LoginPageState createState() => LoginPageState();
}

// Controllers to store login email and password
final emailController = TextEditingController();
final passwordController = TextEditingController();

String? email = '';
bool _isLoading = false;

// State class for the LoginPage
class LoginPageState extends State<LoginPage> with WidgetsBindingObserver {
  // Boolean variable to set password visibility to hidden
  bool hidePassword = true;
  // Boolean variable to set the remember me checkbox to unchecked, and initializing that the user does not want the app to remember them
  bool rememberMe = false;

  final LocalAuthentication auth = LocalAuthentication();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (emailController.text.isNotEmpty &&
          passwordController.text.isNotEmpty) {
        _authenticate(context);
      }
    });
  }

  @override
  void dispose() {
    emailController.clear();
    passwordController.clear();
    WidgetsBinding.instance.removeObserver(this);
    _isLoading = false;
    super.dispose();
  }

  // Sign user in method
  Future<bool> signUserIn(BuildContext context) async {
    log('login.dart: Attempting to sign user in...'); // Debugging output
    try {
      log('login.dart: Calling FirebaseAuth to sign in with email and password...'); // Debugging output
      UserCredential userCredential =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text,
        password: passwordController.text,
      );

      // Check if email is verified
      await userCredential.user?.reload();
      final user = FirebaseAuth.instance.currentUser;

      if (user != null && !user.emailVerified) {
        log('login.dart: User email not verified, showing verification screen');
        if (!context.mounted) return false;
        await Navigator.pushNamedAndRemoveUntil(
          context,
          '/email_verification',
          (route) => false,
        );
        return false; // Don't proceed to dashboard
      }

      if (!context.mounted) return false;
      await updateFirebaseMessagingToken(userCredential.user, context);
      log('login.dart: Signed in user ${userCredential.user!.uid}'); // Debugging output
      log('login.dart: Sign in successful, proceeding to dashboard...'); // Debugging output

      // Set initiallyAuthenticated to true
      if (!context.mounted) return false;
      Provider.of<AuthState>(context, listen: false)
          .setInitiallyAuthenticated(true);

      return true;
    } on FirebaseAuthException catch (e) {
      log('login.dart: Caught FirebaseAuthException: $e'); // Debugging output
      String errorMessage = '';
      if (e.code == 'user-not-found') {
        errorMessage = AppContent.text(
            'text.screens.authenticate.login.login.email_not_found_please_check_your_emai_87403f');
        log('login.dart: Error: $errorMessage'); // Debugging output
      } else {
        errorMessage = AppContent.text(
            'text.screens.authenticate.login.login.error_signing_in_please_check_your_ema_cefa55',
            {'e': e});
        log('login.dart: Error: $errorMessage'); // Debugging output
      }
      log('login.dart: Showing error dialog...'); // Debugging output
      await CustomAlertDialog.showAlertDialog(
          context,
          AppContent.text(
              'text.screens.authenticate.login.login.error_logging_in_d88bcb'),
          errorMessage);
      log('login.dart: Error dialog shown, returning false...'); // Debugging output
      return false;
    } catch (e) {
      log('login.dart: An unexpected error occurred: $e'); // Debugging output for any other exceptions
      return false;
    }
  }

  Future<void> _authenticate(BuildContext context) async {
    bool authenticated = false;

    try {
      authenticated = await auth.authenticate(
        localizedReason: AppContent.text(
            'text.screens.authenticate.login.login.please_authenticate_to_login_5faeb2'),
        options: const AuthenticationOptions(
          useErrorDialogs: true,
          stickyAuth: true,
        ),
      );
    } catch (e) {
      log('login.dart: Error authenticating: $e');
    }

    if (authenticated) {
      // ignore: unawaited_futures
      // Navigator.pushReplacement(
      //   context,
      //   PageRouteBuilder(
      //     pageBuilder: (context, animation, secondaryAnimation) =>
      //         const DashboardPage(),
      //     transitionsBuilder: (context, animation, secondaryAnimation, child) =>
      //         child,
      //   ),
      // );
      if (!context.mounted) return;
      await Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
    } else {
      // Handle failed authentication
    }
  }

  // Add method to handle Apple sign-in
  Future<void> _signInWithApple() async {
    log('login.dart: Attempting to sign in with Apple...');
    try {
      setState(() => _isLoading = true);

      // Check if Sign In with Apple is available first
      final isAvailable = await SignInWithApple.isAvailable();
      log('login.dart: Apple Sign In available: $isAvailable');

      if (!isAvailable) {
        if (mounted) {
          await CustomAlertDialog.showAlertDialog(
            context,
            AppContent.text(
                'text.screens.authenticate.login.login.not_available_4028c0'),
            AppContent.text(
                'text.screens.authenticate.login.login.sign_in_with_apple_is_not_available_on_f3c1de'),
          );
        }
        return;
      }

      // Generate secure nonce
      final AppleAuthService appleAuthService = AppleAuthService();
      if (!mounted) return;
      final isSignedIn = await appleAuthService.signInWithApple(context);

      if (isSignedIn) {
        log('login.dart: Apple Sign In successful');
        // Set initiallyAuthenticated to true
        if (!mounted) return;
        Provider.of<AuthState>(context, listen: false)
            .setInitiallyAuthenticated(true);

        // Navigate to dashboard
        if (mounted) {
          await Navigator.pushNamedAndRemoveUntil(
              context, '/dashboard', (route) => false);
        }
      }
    } catch (e) {
      log('login.dart: Error signing in with Apple: $e',
          stackTrace: StackTrace.current);
      if (mounted) {
        await CustomAlertDialog.showAlertDialog(
            context,
            AppContent.text(
                'text.screens.authenticate.login.login.sign_in_failed_9c06fa'),
            AppContent.text(
                'text.screens.authenticate.login.login.there_was_an_error_signing_in_with_app_529e8a'));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // The build method for the login screen widget
  @override
  Widget build(BuildContext context) {
    AppContent.watch(context, keys: const {
      'text.screens.authenticate.login.login.email_not_found_please_check_your_emai_87403f',
      'text.screens.authenticate.login.login.error_signing_in_please_check_your_ema_cefa55',
      'text.screens.authenticate.login.login.sign_in_with_apple_is_not_available_on_f3c1de',
      'text.screens.authenticate.login.login.there_was_an_error_signing_in_with_app_529e8a',
    });
    return Scaffold(
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
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
                                'text.screens.authenticate.login.login.login_to_your_account_95704e'),
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
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Column(
                    children: [
                      // Email input field
                      Container(
                        padding: const EdgeInsets.all(4.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              AppContent.text(
                                  'text.screens.authenticate.login.login.email_84add5'),
                              style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                  fontFamily: 'Titillium Web'),
                            ),
                            const SizedBox(height: 10.0),
                            TextField(
                              controller: emailController,
                              style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                  fontFamily: 'Titillium Web'),
                              // Input field styling
                              decoration: InputDecoration(
                                hintText: AppContent.text(
                                    'text.screens.authenticate.login.login.enter_your_email_8cdbba'),
                                hintStyle: const TextStyle(
                                    color: Color.fromARGB(255, 122, 122, 122),
                                    fontFamily: 'Titillium Web'),
                                // Border and focus styling
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(11),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(11),
                                  borderSide: const BorderSide(
                                      color: Color.fromARGB(255, 27, 123, 201)),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                    vertical: 14, horizontal: 14),
                              ),
                              onChanged: (value) {
                                if (mounted) {
                                  setState(() {
                                    emailController.text = value;
                                  });
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                      // Spacing
                      const SizedBox(height: 16.0),

                      // Password input field
                      Container(
                        padding: const EdgeInsets.all(4.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              AppContent.text(
                                  'text.screens.authenticate.login.login.password_8be3c9'),
                              style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                  fontFamily: 'Titillium Web'),
                            ),
                            const SizedBox(height: 10.0),
                            TextField(
                              controller: passwordController,
                              style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                  fontFamily: 'Titillium Web'),
                              // Input field styling with password visibility toggle
                              decoration: InputDecoration(
                                hintText: AppContent.text(
                                    'text.screens.authenticate.login.login.enter_your_password_137816'),
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
                                contentPadding: const EdgeInsets.symmetric(
                                    vertical: 14, horizontal: 14),
                                suffixIcon: GestureDetector(
                                  onTap: () {
                                    if (mounted) {
                                      setState(() {
                                        hidePassword = !hidePassword;
                                      });
                                    }
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.all(0.0),
                                    child: Icon(
                                      hidePassword
                                          ? Icons.remove_red_eye_outlined
                                          : Icons.remove_red_eye_rounded,
                                      size: 25,
                                      color: const Color.fromARGB(
                                          255, 154, 154, 154),
                                    ),
                                  ),
                                ),
                              ),
                              obscureText: hidePassword,
                              onChanged: (value) {
                                if (mounted) {
                                  setState(() {
                                    passwordController.text = value;
                                  });
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                      // Spacing
                      const SizedBox(height: 20.0),

                      // Remember Me and Forgot Password section
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // GestureDetector(
                          //   onTap: () {
                          //     setState(() {
                          //       rememberMe = !rememberMe;
                          //     });
                          //   },
                          //   child: Padding(
                          //     padding: const EdgeInsets.all(6.0),
                          //     child: Icon(
                          //       rememberMe ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                          //       size: 24,
                          //       color: Colors.white,
                          //     ),
                          //   ),
                          // ),
                          // const Text('Remember Me',
                          //   style: TextStyle(
                          //     fontSize: 16,
                          //     color: Colors.white,
                          //     fontFamily: 'Titillium Web'
                          //   )
                          // ),
                          // const SizedBox(width: 100),

                          // Forgot Password link
                          GestureDetector(
                            behavior: HitTestBehavior.translucent,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        const ForgotPasswordPage()), // Navigate to the Log In page
                              );
                            },
                            child: TextButton(
                              onPressed: null,
                              child: Text(
                                AppContent.text(
                                    'text.screens.authenticate.login.login.forgot_password_1cc8d1'),
                                style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue,
                                    fontFamily: 'Titillium Web'),
                              ),
                            ),
                          ),
                        ],
                      ),
                      // Spacing
                      const SizedBox(height: 20.0),

                      // Login Button
                      GestureDetector(
                        onTap: () async {
                          bool success = await signUserIn(context);
                          if (success) {
                            String? token;
                            try {
                              token =
                                  await FirebaseMessaging.instance.getToken();
                            } catch (e) {
                              log('Error fetching token: $e');
                              token = await FirebaseMessaging.instance
                                  .getAPNSToken();
                              log('APNS Token found: $token');
                            }
                            if (token != null) {
                              User? user = FirebaseAuth.instance.currentUser;
                              // If we do not have a user and the context is valid
                              if (user == null && context.mounted) {
                                log('login.dart: User is not logged in');
                                await Navigator.pushReplacementNamed(
                                    context, '/login');
                              }
                              if (!context.mounted) return;
                              // Fetch CID using async constructor
                              DatabaseService? db =
                                  await DatabaseService.fetchCID(
                                      user!.uid, context);

                              if (db != null) {
                                try {
                                  List<dynamic> tokens =
                                      (await db.getField('tokens') ?? []);

                                  if (!tokens.contains(token)) {
                                    tokens = [...tokens, token];
                                    await db.updateField('tokens', tokens);
                                  }
                                } catch (e) {
                                  log('login.dart: Error fetching tokens: $e');
                                }
                              }
                            }
                            if (!context.mounted) return;
                            await Navigator.pushReplacement(
                              context,
                              PageRouteBuilder(
                                pageBuilder:
                                    (context, animation1, animation2) =>
                                        const DashboardPage(),
                                transitionDuration: Duration.zero,
                              ),
                            );
                          }
                        },
                        child: Container(
                          height: 55,
                          decoration: BoxDecoration(
                            color: passwordController.text.isNotEmpty &&
                                    emailController.text.isNotEmpty
                                ? const Color.fromARGB(255, 30, 75, 137)
                                : const Color.fromARGB(255, 85, 86, 87),
                            borderRadius: BorderRadius.circular(25),
                          ),
                          child: Center(
                            child: Text(
                              AppContent.text(
                                  'text.screens.authenticate.login.login.login_4e5a28'),
                              style: const TextStyle(
                                  fontSize: 18,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Titillium Web'),
                            ),
                          ),
                        ),
                      ),
                      // Spacing
                      const SizedBox(height: 20.0),

                      GestureDetector(
                        onTap: () async {
                          if (mounted) setState(() => _isLoading = true);
                          try {
                            await GoogleAuthService().signInWithGoogle(context);
                            // Navigate to dashboard or home
                            // e.g., Navigator.pushReplacementNamed(context, '/dashboard');
                          } finally {
                            if (mounted) setState(() => _isLoading = false);
                          }
                        },
                        child: Container(
                          height: 55,
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(25),
                            border: Border.all(
                                color: const Color.fromARGB(255, 30, 75, 137),
                                width: 4),
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
                                    'text.screens.authenticate.login.login.sign_in_with_google_4a0b72'),
                                style: const TextStyle(
                                    fontSize: 18,
                                    color: Colors.blue,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Titillium Web'),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Add spacing before Apple Sign In button
                      const SizedBox(height: 16.0),

                      // Apple Sign In Button
                      GestureDetector(
                        onTap: _signInWithApple,
                        child: Container(
                          height: 55,
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(25),
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
                                    'text.screens.authenticate.login.login.sign_in_with_apple_a5331c'),
                                style: const TextStyle(
                                    fontSize: 18,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Titillium Web'),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 40.0),

                      // Sign-Up Section
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            AppContent.text(
                                'text.screens.authenticate.login.login.don_t_have_an_account_f838dc'),
                            style: const TextStyle(
                                fontSize: 18,
                                color: Colors.white,
                                fontFamily: 'Titillium Web'),
                          ),
                          GestureDetector(
                            behavior: HitTestBehavior.translucent,
                            onTap: () {
                              Navigator.push(
                                context,
                                PageRouteBuilder(
                                  pageBuilder: (context, animation,
                                          secondaryAnimation) =>
                                      const CreateAccountPage(),
                                  transitionsBuilder: (context, animation,
                                          secondaryAnimation, child) =>
                                      child,
                                ),
                              );
                            },
                            child: TextButton(
                              onPressed: null,
                              child: Text(
                                AppContent.text(
                                    'text.screens.authenticate.login.login.sign_up_2ba402'),
                                style: const TextStyle(
                                    fontSize: 18,
                                    color: Colors.blue,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Titillium Web'),
                              ),
                            ),
                          ),
                        ],
                      ),
                      // Spacing
                      const SizedBox(height: 20.0),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // A loading overlay that covers the screen when _isLoading is true
          if (_isLoading)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }
}
