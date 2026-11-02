import 'package:agq_app/content/app_content.dart';
import 'dart:async';
import 'dart:developer';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:provider/provider.dart';
import 'package:agq_app/screens/authenticate/utils/app_state.dart';
import 'package:agq_app/screens/utils/resources.dart';

class NoInternetScreen extends StatefulWidget {
  const NoInternetScreen({super.key});

  @override
  NoInternetScreenState createState() => NoInternetScreenState();
}

class NoInternetScreenState extends State<NoInternetScreen> {
  // We'll keep track of the connectivity status as a single value.
  ConnectivityResult _connectionStatus = ConnectivityResult.none;
  final Connectivity _connectivity = Connectivity();
  // Note: The stream now emits a List<ConnectivityResult>
  late final StreamSubscription<List<ConnectivityResult>>
      _connectivitySubscription;

  @override
  void initState() {
    super.initState();
    _initConnectivity();
    _connectivitySubscription =
        _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
  }

  // Initial connectivity check remains the same.
  Future<void> _initConnectivity() async {
    List<ConnectivityResult> results;
    try {
      results = await _connectivity.checkConnectivity();
    } catch (e) {
      results = [ConnectivityResult.none];
    }
    if (!mounted) return;
    setState(() {
      // Choose the first result if available; otherwise, default to none.
      _connectionStatus =
          results.isNotEmpty ? results.first : ConnectivityResult.none;
    });
    log('Initial connectivity: $_connectionStatus');
  }

  // Update our state with the new connectivity status.
  // Since the stream now provides a List, we pick one result.
  void _updateConnectionStatus(List<ConnectivityResult> results) {
    // Here, we choose the first element if available; otherwise, we assume none.
    setState(() {
      _connectionStatus = ConnectivityResult.wifi;
    });
    log('Connectivity List: $results');
    log('Connectivity changed: $_connectionStatus');
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    super.dispose();
  }

  Future<void> _reload(BuildContext context) async {
    if (_connectionStatus != ConnectivityResult.none) {
      log('Reload button pressed - connection available: $_connectionStatus');
      final authState = Provider.of<AuthState>(context, listen: false);
      authState.setForceDashboard(true);
      Phoenix.rebirth(context);
    } else {
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(
            AppContent.text(
                'text.components.no_connection.no_internet_connection_549961'),
            style: const TextStyle(
              color: Colors.white,
              fontFamily: 'Titillium Web',
            ),
          ),
          content: Text(
            AppContent.text(
                'text.components.no_connection.please_check_your_internet_connection__10cd84'),
            style: const TextStyle(
              color: Colors.white,
              fontFamily: 'Titillium Web',
            ),
          ),
          actions: [
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 30, 75, 137),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  AppContent.text('text.components.no_connection.ok_9ce3bd'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ),
            )
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    AppContent.watch(context);
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 17, 24, 39),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi_off, size: 80, color: Colors.white),
            const SizedBox(height: 20),
            Text(
              AppContent.text(
                  'text.components.no_connection.no_internet_connection_549961'),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontFamily: 'Titillium Web',
              ),
            ),
            const SizedBox(height: 10),
            Text(
              AppContent.text(
                  'text.components.no_connection.please_connect_to_wi_fi_first_bfd20c'),
              style: const TextStyle(
                color: Colors.white70,
                fontFamily: 'Titillium Web',
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  side: const BorderSide(
                    color: Color.fromARGB(150, 255, 255, 255),
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                elevation: 5,
                textStyle: const TextStyle(
                  fontSize: 18,
                  fontFamily: 'Titillium Web',
                  fontWeight: FontWeight.bold,
                ),
              ),
              onPressed: () async {
                log('Current connectivity: $_connectionStatus');
                if (_connectionStatus == ConnectivityResult.wifi ||
                    _connectionStatus == ConnectivityResult.mobile) {
                  await _reload(context);
                } else {
                  await showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      backgroundColor: AppColors.altBlueGray900,
                      title: Text(
                        AppContent.text(
                            'text.components.no_connection.no_internet_connection_549961'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontFamily: 'Titillium Web',
                        ),
                      ),
                      content: Text(
                        AppContent.text(
                            'text.components.no_connection.please_check_your_internet_connection__10cd84'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontFamily: 'Titillium Web',
                        ),
                      ),
                      actions: [
                        GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: const Color.fromARGB(255, 30, 75, 137),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              AppContent.text(
                                  'text.components.no_connection.ok_9ce3bd'),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        )
                      ],
                    ),
                  );
                }
              },
              child: Text(
                AppContent.text('text.components.no_connection.reload_cce715'),
                style: const TextStyle(
                  color: Colors.white,
                  fontFamily: 'Titillium Web',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
