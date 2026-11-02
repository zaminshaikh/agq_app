// Flutter and Dart packages
import 'package:agq_app/content/app_content.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:developer';
import 'package:connectivity_plus/connectivity_plus.dart';

// Firebase packages
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:agq_app/firebase_options.dart';

// Third-party packages
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:agq_app/components/no_connection.dart';
import 'package:agq_app/components/progress_indicator.dart';

// Local packages
import 'package:agq_app/database/models/client_model.dart';
import 'package:agq_app/database/database.dart';
import 'package:agq_app/screens/authenticate/create_account/create_account.dart';
import 'package:agq_app/screens/authenticate/email_verification_screen.dart';
import 'package:agq_app/screens/activity/activity.dart';
import 'package:agq_app/screens/analytics/analytics.dart';
import 'package:agq_app/screens/authenticate/initial_face_id.dart';
import 'package:agq_app/screens/authenticate/onboarding.dart';
import 'package:agq_app/screens/authenticate/login/login.dart';
import 'package:agq_app/screens/authenticate/login/forgot_password.dart';
import 'package:agq_app/screens/authenticate/utils/faceid.dart';
import 'package:agq_app/screens/authenticate/utils/app_state.dart';
import 'package:agq_app/screens/dashboard/dashboard.dart';
import 'package:agq_app/screens/notifications/notifications.dart';
import 'package:agq_app/screens/profile/profile.dart';
import 'package:agq_app/screens/utils/push_notification.dart';
import 'package:agq_app/screens/utils/utilities.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize services and configurations
  await _initializeServices();

  // Lock device orientation to portrait mode
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(
    ChangeNotifierProvider(
      create: (context) => AuthState(),
      child: AppContentScope(child: Phoenix(child: const MyApp())),
    ),
  );
}

/// Initialize third-party services and configurations
Future<void> _initializeServices() async {
  // Ensure screen size is initialized
  await ScreenUtil.ensureScreenSize();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize push notifications
  await PushNotificationService().initialize();

  // Load application configuration
  await Config.loadConfig();

  // Reset Firestore settings to ensure a clean state
  await _resetFirestore();
  await AppContent.instance.initialize();
}

/// Reset Firestore settings to ensure a clean state
Future<void> _resetFirestore() async {
  // Terminate Firestore to detach any active listeners
  await FirebaseFirestore.instance.terminate();

  // Clear persisted data
  await FirebaseFirestore.instance.clearPersistence();

  // Disable persistence
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: false,
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  MyAppState createState() => MyAppState();
}

class MyAppState extends State<MyApp> with WidgetsBindingObserver {
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  late final Stream<Client?> clientStream;
  Timer? _inactivityTimer;
  bool _isAppLockEnabled = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final appState = Provider.of<AuthState>(context, listen: false);
      appState.setHasNavigatedToFaceIDPage(false);
    });

    _loadAppLockState();
  }

  Future<void> _loadAppLockState() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isAppLockEnabled = prefs.getBool('isAppLockEnabled') ?? false;
      log('Bruh Loaded app lock state: $_isAppLockEnabled');
    });
    if (!mounted) return;
    final appState = Provider.of<AuthState>(context, listen: false);
    if (!_isAppLockEnabled) {
      appState.setInitiallyAuthenticated(true);
      log('App lock is disabled. Setting initiallyAuthenticated to true.');
      log('initiallyAuthenticated: ${appState.initiallyAuthenticated}');
    } else {
      appState.setInitiallyAuthenticated(false);
      log('App lock is enabled. Setting initiallyAuthenticated to false.');
    }
  }

  @override
  void dispose() {
    // Remove this widget from the observer list
    WidgetsBinding.instance.removeObserver(this);
    _inactivityTimer?.cancel();
    log('Timer cancelled in dispose');
    super.dispose();
  }

  /// Stream that provides Client data based on authentication state
  Stream<Client?> getClientStream() =>
      FirebaseAuth.instance.userChanges().asyncExpand((User? user) async* {
        if (user == null) {
          // User is not authenticated
          yield null;
        } else if (mounted) {
          // Fetch DatabaseService for the authenticated user
          DatabaseService? db =
              await DatabaseService.fetchCID(user.uid, context);
          if (db == null) {
            // CID doc not found
            yield null;
          } else {
            yield* db.getClientStream();
          }
        }
      });

  @override
  Future<void> didChangeAppLifecycleState(AppLifecycleState state) async {
    final appState = Provider.of<AuthState>(context, listen: false);
    log('AppLifecycleState changed: $state');

    if (state == AppLifecycleState.resumed) {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        return;
      }
      DatabaseService? db = await DatabaseService.fetchCID(user.uid, context);
      if (db != null) {
        await db.updateField('lastLoggedIn', Timestamp.now());
      }

      // Cancel the timer when the app is resumed
      _inactivityTimer?.cancel();
      log('Timer cancelled on app resume');
    } else if ((state == AppLifecycleState.paused ||
            state == AppLifecycleState.inactive ||
            state == AppLifecycleState.hidden) &&
        !appState.hasNavigatedToFaceIDPage &&
        await isAuthenticated() &&
        appState.initiallyAuthenticated &&
        appState.isAppLockEnabled) {
      // log when all conditions are met
      log('All conditions met: Navigating to FaceIdPage after timer');

      _inactivityTimer?.cancel();
      _inactivityTimer = Timer(Duration.zero, () {
        appState.setHasNavigatedToFaceIDPage(true);
        navigatorKey.currentState?.pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                const FaceIdPage(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) => child,
          ),
        );
      });
    } else {
      if (state != AppLifecycleState.paused &&
          state != AppLifecycleState.inactive &&
          state != AppLifecycleState.hidden) {
        log('Condition not met: AppLifecycleState is not paused, inactive, or hidden');
      }
      if (appState.hasNavigatedToFaceIDPage) {
        log('Condition not met: hasNavigatedToFaceIDPage is true');
      }
      if (!(await isAuthenticated())) {
        log('Condition not met: User is not authenticated');
      }
      if (!appState.initiallyAuthenticated) {
        log('Condition not met: initiallyAuthenticated is false');
      }
      if (!appState.isAppLockEnabled) {
        log('Condition not met: isAppLockEnabled is false');
      }
    }

    if (appState.justAuthenticated) {
      // Reset navigation flags when the user has just authenticated
      appState.setHasNavigatedToFaceIDPage(false);
      appState.setJustAuthenticated(false);
      log('Reset navigation flags after authentication');
      log('Reset navigation flags after authentication');
    }
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
  Widget build(BuildContext context) {
    AppContent.watch(context);
    return StreamBuilder<ConnectivityResult>(
      stream: Connectivity().onConnectivityChanged.expand((results) => results),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data == ConnectivityResult.none) {
          return const MaterialApp(
            debugShowCheckedModeBanner: false,
            home: NoInternetScreen(),
          );
        }

        return StreamBuilder<User?>(
          stream: FirebaseAuth.instance.userChanges(),
          builder: (context, authSnapshot) {
            final user = authSnapshot.data;
            return StreamProvider<Client?>(
              key: ValueKey(user?.uid),
              create: (_) => getClientStream(),
              catchError: (context, error) {
                log('main.dart: Error in fetching client stream: $error');
                return null;
              },
              initialData: null,
              child: MaterialApp(
                debugShowCheckedModeBanner: false,
                initialRoute: '/',
                navigatorKey: navigatorKey,
                builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(context).copyWith(
                    boldText: false,
                    textScaler: const TextScaler.linear(1),
                  ),
                  child: child!,
                ),
                title: AppContent.text('text.main.agq_investments_e6d2b6'),
                theme: _buildAppTheme(),
                // home: const AuthCheck(),
                routes: {
                  '/': (context) => const AuthCheck(),
                  '/create_account': (context) => const CreateAccountPage(),
                  '/login': (context) => const LoginPage(),
                  '/forgot_password': (context) => const ForgotPasswordPage(),
                  '/email_verification': (context) =>
                      const EmailVerificationScreen(),
                  '/dashboard': (context) => const DashboardPage(),
                  '/analytics': (context) => const AnalyticsPage(),
                  '/activity': (context) => const ActivityPage(),
                  '/profile': (context) => const ProfilePage(),
                  '/notification': (context) => const NotificationPage(),
                  '/onboarding': (context) => const OnboardingPage(),
                },
              ),
            );
          },
        );
      },
    );
  }

  /// Build the application theme
  ThemeData _buildAppTheme() => ThemeData(
        scaffoldBackgroundColor: const Color.fromARGB(255, 17, 24, 39),
        textTheme: const TextTheme(
          titleLarge: TextStyle(
              color: Colors.white,
              fontFamily: 'Titillium Web',
              fontWeight: FontWeight.bold),
          titleMedium: TextStyle(
              color: Colors.white,
              fontFamily: 'Titillium Web',
              fontWeight: FontWeight.bold),
          titleSmall: TextStyle(
              color: Colors.white,
              fontFamily: 'Titillium Web',
              fontWeight: FontWeight.bold),
          labelLarge:
              TextStyle(color: Colors.white, fontFamily: 'Titillium Web'),
          labelMedium:
              TextStyle(color: Colors.white, fontFamily: 'Titillium Web'),
          labelSmall:
              TextStyle(color: Colors.white, fontFamily: 'Titillium Web'),
          displayLarge:
              TextStyle(color: Colors.white, fontFamily: 'Titillium Web'),
          displayMedium:
              TextStyle(color: Colors.white, fontFamily: 'Titillium Web'),
          displaySmall:
              TextStyle(color: Colors.white, fontFamily: 'Titillium Web'),
          headlineLarge: TextStyle(
              color: Colors.white,
              fontFamily: 'Titillium Web',
              fontWeight: FontWeight.bold),
          headlineMedium: TextStyle(
              color: Colors.white,
              fontFamily: 'Titillium Web',
              fontWeight: FontWeight.bold),
          headlineSmall: TextStyle(
              color: Colors.white,
              fontFamily: 'Titillium Web',
              fontWeight: FontWeight.bold),
          bodyLarge:
              TextStyle(color: Colors.white, fontFamily: 'Titillium Web'),
          bodyMedium:
              TextStyle(color: Colors.white, fontFamily: 'Titillium Web'),
          bodySmall:
              TextStyle(color: Colors.white, fontFamily: 'Titillium Web'),
        ),
      );
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

class AuthCheck extends StatefulWidget {
  const AuthCheck({super.key});

  @override
  State<AuthCheck> createState() => _AuthCheckState();
}

class _AuthCheckState extends State<AuthCheck> {
  late Future<bool> _isAuthenticatedAndVerifiedFuture;
  late Future<bool> _isSignedInButNotVerifiedFuture;
  late Future<bool> _loadAppLockStateFuture;

  @override
  void initState() {
    super.initState();
    _isAuthenticatedAndVerifiedFuture = isAuthenticatedAndVerified();
    _isSignedInButNotVerifiedFuture = isSignedInButNotVerified();
    _loadAppLockStateFuture = _loadAppLockState();
  }

  Future<bool> _loadAppLockState() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('isAppLockEnabled') ?? false;
  }

  /// Check if the user is authenticated, email verified, and linked
  Future<bool> isAuthenticatedAndVerified() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return false;
    }

    await user.reload();

    if (!user.emailVerified) {
      return false;
    }

    String uid = user.uid;

    DatabaseService db = DatabaseService(uid);

    bool isLinked = await db.isUIDLinked(uid);

    return isLinked;
  }

  /// Check if user is signed in but email not verified
  Future<bool> isSignedInButNotVerified() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return false;
    }

    await user.reload();

    return !user.emailVerified;
  }

  @override
  Widget build(BuildContext context) {
    AppContent.watch(context);
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.userChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CustomProgressIndicator());
        } else if (snapshot.hasError) {
          log('AuthCheck: StreamBuilder error: ${snapshot.error}');
          return Center(
              child: Text(AppContent.text('text.main.error_value1_54e519',
                  {'value1': snapshot.error})));
        } else if (snapshot.hasData) {
          final user = snapshot.data!;
          log('AuthCheck: User is logged in as ${user.email}');

          final authState = Provider.of<AuthState>(context, listen: false);

          // Use the stored future
          return FutureBuilder<bool>(
              future: _isAuthenticatedAndVerifiedFuture,
              builder: (context, authSnapshot) {
                if (authSnapshot.connectionState == ConnectionState.waiting) {
                  log('AuthCheck: FutureBuilder waiting for authentication check.');
                  if (authState.forceDashboard) {
                    log('AuthCheck: User is not authenticated or linked, but has reloaded the app from the no internet screen. Navigating to DashboardPage.');
                    return const DashboardPage();
                  } else {
                    return const Center(child: CustomProgressIndicator());
                  }
                } else if (authSnapshot.hasError) {
                  log('AuthCheck: FutureBuilder error: ${authSnapshot.error}');
                  return Center(
                      child: Text(AppContent.text(
                          'text.main.error_value1_54e519',
                          {'value1': authSnapshot.error})));
                } else if (authSnapshot.hasData && authSnapshot.data == true) {
                  // Now proceed to check app lock state
                  return FutureBuilder<bool>(
                    future: _loadAppLockStateFuture,
                    builder: (context, appLockSnapshot) {
                      if (appLockSnapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const Center(child: CustomProgressIndicator());
                      } else if (appLockSnapshot.hasError) {
                        log('AuthCheck: FutureBuilder error: ${appLockSnapshot.error}');
                        return Center(
                            child: Text(AppContent.text(
                                'text.main.error_value1_54e519',
                                {'value1': appLockSnapshot.error})));
                      } else if (appLockSnapshot.hasData) {
                        final isAppLockEnabled = appLockSnapshot.data!;
                        if (!isAppLockEnabled) {
                          log('AuthCheck: App lock is disabled. Navigating to DashboardPage.');
                          return const DashboardPage();
                        }
                        log('AuthCheck: App lock is enabled. Navigating to InitialFaceIdPage.');
                        return const InitialFaceIdPage();
                      } else {
                        return const InitialFaceIdPage();
                      }
                    },
                  );
                } else {
                  // Check if user is signed in but not verified
                  return FutureBuilder<bool>(
                    future: _isSignedInButNotVerifiedFuture,
                    builder: (context, verificationSnapshot) {
                      if (verificationSnapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const Center(child: CustomProgressIndicator());
                      } else if (verificationSnapshot.hasError) {
                        log('AuthCheck: FutureBuilder error: ${verificationSnapshot.error}');
                        return Center(
                            child: Text(AppContent.text(
                                'text.main.error_value1_54e519',
                                {'value1': verificationSnapshot.error})));
                      } else if (verificationSnapshot.hasData &&
                          verificationSnapshot.data == true) {
                        // User is signed in but email not verified
                        log('AuthCheck: User is signed in but email not verified. Navigating to EmailVerificationScreen.');
                        return const EmailVerificationScreen();
                      } else {
                        // User is not authenticated or linked
                        if (!authState.forceDashboard) {
                          log('AuthCheck: User is not authenticated or linked. Navigating to OnboardingPage.');
                          return const OnboardingPage();
                        } else {
                          return const DashboardPage();
                        }
                      }
                    },
                  );
                }
              });
        } else {
          log('AuthCheck: User is not logged in yet.');
          return const OnboardingPage();
        }
      },
    );
  }
}
