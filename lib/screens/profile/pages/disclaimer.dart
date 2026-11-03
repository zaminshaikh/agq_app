// ignore_for_file: deprecated_member_use, use_build_context_synchronously, duplicate_ignore, prefer_expression_function_bodies, unused_catch_clause, empty_catches

import 'package:agq_app/content/app_content.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

class DisclaimerPage extends StatefulWidget {
  const DisclaimerPage({super.key});
  @override
  // ignore: library_private_types_in_public_api
  _DisclaimerPageState createState() => _DisclaimerPageState();
}

class PdfFileWithCid {
  final Reference file;
  final String cid;

  PdfFileWithCid(this.file, this.cid);
}

class _DisclaimerPageState extends State<DisclaimerPage> {
  @override
  Widget build(BuildContext context) {
    AppContent.watch(context, keys: const {
      'text.screens.profile.pages.disclaimer.agq_consulting_llc_is_a_florida_limite_bf4710',
    });
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
                      _disclaimer(),
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
                      'text.screens.profile.pages.disclaimer.disclaimer_4c4a2e'),
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

// This is the Disclaimer Center section
  Container _disclaimer() => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                Text(
                  AppContent.text(
                      'text.screens.profile.pages.disclaimer.agq_consulting_llc_99d049'),
                  style: const TextStyle(
                    fontSize: 20,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Titillium Web',
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  AppContent.text(
                      'text.screens.profile.pages.disclaimer.agq_consulting_llc_is_a_florida_limite_bf4710'),
                  style: const TextStyle(
                    fontSize: 15,
                    color: Colors.white,
                    fontFamily: 'Titillium Web',
                  ),
                ),
              ],
            )
          ],
        ),
      );
}
