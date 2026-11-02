import 'package:agq_app/content/app_content.dart';
import 'package:agq_app/content/content_image.dart';
import 'dart:async';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:agq_app/components/alert_dialog.dart';
import 'package:agq_app/components/progress_indicator.dart';
import 'package:agq_app/database/auth_helper.dart';
import 'package:agq_app/screens/authenticate/utils/app_state.dart';

class EmailVerificationScreen extends StatefulWidget {
  const EmailVerificationScreen({super.key});

  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  bool _isLoading = false;
  bool _isCheckingVerification = false;
  Timer? _verificationCheckTimer;
  int _resendCooldown = 0;
  Timer? _cooldownTimer;

  @override
  void initState() {
    super.initState();
    _startVerificationCheck();
  }

  @override
  void dispose() {
    _verificationCheckTimer?.cancel();
    _cooldownTimer?.cancel();
    super.dispose();
  }

  void _startVerificationCheck() {
    _verificationCheckTimer = Timer.periodic(
      const Duration(seconds: 3),
      (timer) => _checkEmailVerification(),
    );
  }

  Future<void> _checkEmailVerification() async {
    if (_isCheckingVerification) return;

    setState(() {
      _isCheckingVerification = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await user.reload();
        final updatedUser = FirebaseAuth.instance.currentUser;

        if (updatedUser != null && updatedUser.emailVerified) {
          _verificationCheckTimer?.cancel();

          if (!mounted) return;

          // Update authentication state
          final authState = Provider.of<AuthState>(context, listen: false);
          authState.setInitiallyAuthenticated(true);

          // Update Firebase messaging token
          if (mounted) {
            await updateFirebaseMessagingToken(updatedUser, context);
          }

          // Show success message
          await CustomAlertDialog.showAlertDialog(
            context,
            AppContent.text(
                'text.screens.authenticate.email_verification_screen.email_verified_174614'),
            AppContent.text(
                'text.screens.authenticate.email_verification_screen.your_email_has_been_successfully_verif_23f3d5'),
            icon: const Icon(Icons.check_circle_outline_rounded,
                color: Colors.green),
          );

          if (!mounted) return;

          // Navigate to dashboard
          await Navigator.pushNamedAndRemoveUntil(
            context,
            '/dashboard',
            (route) => false,
          );
        }
      }
    } catch (e) {
      log('Error checking email verification: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isCheckingVerification = false;
        });
      }
    }
  }

  Future<void> _resendVerificationEmail() async {
    if (_resendCooldown > 0) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();

        if (!mounted) return;

        // Start cooldown
        setState(() {
          _resendCooldown = 5; // 5 seconds cooldown
        });

        _cooldownTimer = Timer.periodic(
          const Duration(seconds: 1),
          (timer) {
            if (_resendCooldown > 0) {
              setState(() {
                _resendCooldown--;
              });
            } else {
              timer.cancel();
            }
          },
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppContent.text(
                'text.screens.authenticate.email_verification_screen.verification_email_sent_to_value1_22ce48',
                {'value1': user.email})),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      log('Error resending verification email: $e');
      if (mounted) {
        String errorMessage = AppContent.text(
            'text.screens.authenticate.email_verification_screen.failed_to_send_verification_email_plea_884620');

        switch (e.code) {
          case 'too-many-requests':
            errorMessage = AppContent.text(
                'text.screens.authenticate.email_verification_screen.too_many_requests_please_wait_before_r_db7c32');
            break;
          case 'invalid-email':
            errorMessage = AppContent.text(
                'text.screens.authenticate.email_verification_screen.the_email_address_is_invalid_f9871e');
            break;
          case 'user-not-found':
            errorMessage = AppContent.text(
                'text.screens.authenticate.email_verification_screen.no_user_found_please_sign_in_again_257abd');
            break;
        }

        await CustomAlertDialog.showAlertDialog(
          context,
          AppContent.text(
              'text.screens.authenticate.email_verification_screen.error_7f2f6a'),
          errorMessage,
        );
      }
    } catch (e) {
      log('Unexpected error resending verification email: $e');
      if (mounted) {
        await CustomAlertDialog.showAlertDialog(
          context,
          AppContent.text(
              'text.screens.authenticate.email_verification_screen.error_7f2f6a'),
          AppContent.text(
              'text.screens.authenticate.email_verification_screen.an_unexpected_error_occurred_please_tr_d07ac0'),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _signOut() async {
    try {
      await FirebaseAuth.instance.signOut();
      if (!mounted) return;
      await Navigator.pushNamedAndRemoveUntil(
        context,
        '/login',
        (route) => false,
      );
    } catch (e) {
      log('Error signing out: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    AppContent.watch(context);
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 17, 24, 39),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Email verification icon
              const AppContentImage(
                'assets/icons/verify_email_iconart.svg',
                height: 200,
                width: 200,
              ),

              const SizedBox(height: 40),

              // Title
              Text(
                AppContent.text(
                    'text.screens.authenticate.email_verification_screen.verify_your_email_05fd7a'),
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontFamily: 'Titillium Web',
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 16),

              // Description
              Text(
                AppContent.text(
                    'text.screens.authenticate.email_verification_screen.we_sent_a_verification_email_to_value1_d80f36',
                    {'value1': user?.email ?? 'your email'}),
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                  fontFamily: 'Titillium Web',
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 8),

              Text(
                AppContent.text(
                    'text.screens.authenticate.email_verification_screen.please_check_your_email_and_click_the__611181'),
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                  fontFamily: 'Titillium Web',
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 40),

              // Checking verification status indicator
              if (_isCheckingVerification)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      AppContent.text(
                          'text.screens.authenticate.email_verification_screen.checking_verification_status_4b8267'),
                      style: const TextStyle(
                        color: Colors.blue,
                        fontFamily: 'Titillium Web',
                      ),
                    ),
                  ],
                ),

              const SizedBox(height: 32),

              // Resend verification email button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _resendCooldown > 0 || _isLoading
                      ? null
                      : _resendVerificationEmail,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 30, 75, 137),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  child: _isLoading
                      ? const CustomProgressIndicator()
                      : Text(
                          _resendCooldown > 0
                              ? AppContent.text(
                                  'text.screens.authenticate.email_verification_screen.resend_in_value1_s_b4463a',
                                  {
                                      'value1': _resendCooldown
                                    })
                              : AppContent.text(
                                  'text.screens.authenticate.email_verification_screen.resend_verification_email_072f96'),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Titillium Web',
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 16),

              // Sign out button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: TextButton(
                  onPressed: _signOut,
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.grey,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  child: Text(
                    AppContent.text(
                        'text.screens.authenticate.email_verification_screen.sign_out_61fd08'),
                    style: const TextStyle(
                      fontSize: 16,
                      fontFamily: 'Titillium Web',
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
