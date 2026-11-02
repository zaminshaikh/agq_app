// ignore_for_file: deprecated_member_use, use_build_context_synchronously, duplicate_ignore, prefer_expression_function_bodies, unused_catch_clause, empty_catches

import 'package:agq_app/content/app_content.dart';
import 'package:agq_app/content/content_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:agq_app/components/custom_bottom_navigation_bar.dart';
import 'package:agq_app/components/progress_indicator.dart';
import 'package:agq_app/database/models/client_model.dart';
import 'package:agq_app/screens/utils/resources.dart';
import 'package:agq_app/screens/profile/pages/authentication.dart';
import 'package:agq_app/screens/notifications/notifications.dart';
import 'package:agq_app/screens/profile/pages/disclaimer.dart';
import 'package:agq_app/screens/profile/pages/documents.dart';
import 'package:agq_app/screens/profile/components/logout_button.dart';
import 'package:agq_app/screens/profile/pages/help.dart';
import 'package:agq_app/screens/profile/pages/settings.dart';
import 'package:agq_app/screens/profile/pages/profiles.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});
  @override
  // ignore: library_private_types_in_public_api
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Client? client;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    client = Provider.of<Client?>(context);
  }

  @override
  Widget build(BuildContext context) {
    AppContent.watch(context);
    if (client == null) {
      return const CustomProgressIndicatorPage();
    }
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
                      _buildClientNameAndID(),
                      _buildCupertinoListSection(),
                      LogoutButton(
                        client: client!,
                      ),
                      _buildDisclaimer(),
                      const SizedBox(height: 120),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child:
                CustomBottomNavigationBar(currentItem: NavigationItem.profile),
          ),
        ],
      ),
    );
  }

  Widget _buildCupertinoListSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.defaultBlueGray800, // Gray background
          borderRadius: BorderRadius.circular(12.0), // Rounded borders
        ),
        child: Column(
          children: [
            const SizedBox(height: 10),
            CupertinoListTile(
              leading: const AppContentImage(
                'assets/icons/profile_help_center_icon.svg',
                color: Colors.white,
                height: 20,
              ),
              title: Text(
                AppContent.text('text.screens.profile.profile.help_c47ae1'),
                style: const TextStyle(
                  fontFamily: 'Titillium Web',
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              trailing: const CupertinoListTileChevron(),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const HelpPage()),
                );
              },
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.0),
              child: Divider(color: CupertinoColors.separator, thickness: 1.5),
            ),
            CupertinoListTile(
              leading: const AppContentImage(
                'assets/icons/profile_statements_icon.svg',
                color: Colors.white,
                height: 20,
              ),
              title: Text(
                AppContent.text(
                    'text.screens.profile.profile.documents_687c82'),
                style: const TextStyle(
                  fontFamily: 'Titillium Web',
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              trailing: const CupertinoListTileChevron(),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const DocumentsPage()),
                );
              },
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.0),
              child: Divider(color: CupertinoColors.separator, thickness: 1.5),
            ),
            CupertinoListTile(
              leading: const AppContentImage(
                'assets/icons/profile_settings_icon.svg',
                color: Colors.white,
                height: 20,
              ),
              title: Text(
                AppContent.text('text.screens.profile.profile.settings_c7f73b'),
                style: const TextStyle(
                  fontFamily: 'Titillium Web',
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              trailing: const CupertinoListTileChevron(),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SettingsPage()),
                );
              },
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.0),
              child: Divider(color: CupertinoColors.separator, thickness: 1.5),
            ),
            CupertinoListTile(
              leading: const AppContentImage(
                'assets/icons/profile_profiles_icon.svg',
                color: Colors.white,
                height: 20,
              ),
              title: Text(
                AppContent.text('text.screens.profile.profile.profiles_0c2a93'),
                style: const TextStyle(
                  fontFamily: 'Titillium Web',
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              trailing: const CupertinoListTileChevron(),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ProfilesPage()),
                );
              },
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.0),
              child: Divider(color: CupertinoColors.separator, thickness: 1.5),
            ),
            CupertinoListTile(
              leading: const AppContentImage(
                'assets/icons/face_id.svg',
                color: Colors.white,
                height: 40,
              ),
              title: Text(
                AppContent.text(
                    'text.screens.profile.profile.authentication_ee1acf'),
                style: const TextStyle(
                  fontFamily: 'Titillium Web',
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              trailing: const CupertinoListTileChevron(),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const AuthenticationPage()),
                );
              },
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _buildDisclaimer() {
    return Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            const Divider(
                color: Color.fromARGB(46, 255, 255, 255), thickness: 1.5),
            const SizedBox(height: 15),
            Text(
              AppContent.text('text.screens.profile.profile.disclaimer_752e0c'),
              style: const TextStyle(
                fontSize: 20,
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontFamily: 'Titillium Web',
              ),
            ),
            const SizedBox(height: 15),
            Text(
              AppContent.text(
                  'text.screens.profile.profile.investment_products_and_services_are_o_e86030'),
              style: const TextStyle(
                fontSize: 16,
                color: Colors.white,
                fontFamily: 'Titillium Web',
              ),
            ),
            const SizedBox(height: 15),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const DisclaimerPage()),
                );
              },
              child: Center(
                child: Row(
                  children: [
                    Text(
                      AppContent.text(
                          'text.screens.profile.profile.read_full_disclaimer_09d9e1'),
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Titillium Web',
                      ),
                    ),
                    const SizedBox(width: 5),
                    const Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.blue,
                      size: 16,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ));
  }

  SliverAppBar _buildAppBar(context) => SliverAppBar(
        backgroundColor: const Color.fromARGB(255, 30, 41, 59),
        automaticallyImplyLeading: false,
        toolbarHeight: 80,
        expandedHeight: 0,
        snap: false,
        floating: true,
        pinned: true,
        flexibleSpace: SafeArea(
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 20.0, right: 20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppContent.text(
                          'text.screens.profile.profile.profile_ff4fc0'),
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
            ],
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 5.0, bottom: 5.0),
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const NotificationPage(),
                  ),
                );
              },
              child: Container(
                color: const Color.fromRGBO(239, 232, 232, 0),
                padding: const EdgeInsets.all(10.0),
                child: ClipRect(
                  child: Stack(
                    children: <Widget>[
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Colors
                                    .transparent, // Change this color to the one you want
                                width: 0.3, // Adjust width to your need
                              ),
                              shape: BoxShape
                                  .rectangle, // or BoxShape.rectangle if you want a rectangle
                            ),
                            child: const Center(
                              child: AppContentImage(
                                'assets/icons/bell.svg',
                                colorFilter: ColorFilter.mode(
                                    Colors.white, BlendMode.srcIn),
                                height: 32,
                              ),
                            ),
                          ),
                          Positioned(
                            right: 0,
                            top: 5,
                            child: (client?.numNotifsUnread ?? 0) > 0
                                ? Container(
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF267DB5),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    constraints: const BoxConstraints(
                                      minWidth: 18,
                                      minHeight: 18,
                                    ),
                                    child: Text(
                                      '${client?.numNotifsUnread}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w800,
                                        fontFamily: 'Titillium Web',
                                        fontSize: 12,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  )
                                : Container(),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      );

  Widget _buildClientNameAndID() {
    // Compute a display name without overflowing
    final fullName = '${client!.firstName} ${client!.lastName}';
    String displayName;

    if (fullName.length > 20) {
      // Use an initial for the longer name
      if (client!.firstName.length <= client!.lastName.length) {
        displayName =
            '${client!.firstName} ${client!.lastName.substring(0, 1)}.';
      } else {
        displayName =
            '${client!.firstName.substring(0, 1)}. ${client!.lastName}';
      }
    } else {
      displayName = fullName;
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName,
                    style: const TextStyle(
                      fontSize: 22,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Titillium Web',
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    AppContent.text(
                        'text.screens.profile.profile.client_id_value1_7c72cb',
                        {'value1': client!.cid}),
                    style: const TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                      fontFamily: 'Titillium Web',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
