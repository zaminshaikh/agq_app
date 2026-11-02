// ignore_for_file: deprecated_member_use, use_build_context_synchronously, duplicate_ignore, prefer_expression_function_bodies, unused_catch_clause, empty_catches, library_private_types_in_public_api

import 'package:agq_app/content/app_content.dart';
import 'package:agq_app/content/content_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:agq_app/screens/utils/resources.dart';
import 'package:agq_app/screens/profile/components/custom_expansion_tile.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpPage extends StatefulWidget {
  const HelpPage({super.key});
  @override
  // ignore: library_private_types_in_public_api
  _HelpPageState createState() => _HelpPageState();
}

class _HelpPageState extends State<HelpPage> {
  @override
  Widget build(BuildContext context) {
    AppContent.watch(context);
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
                      _helpCenter(),
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
                      'text.screens.profile.pages.help.help_c47ae1'),
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

// This is the Help Center section
  Container _helpCenter() => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Advisors Section
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppContent.text(
                      'text.screens.profile.pages.help.point_of_contact_0631b7'),
                  style: const TextStyle(
                    fontSize: 25,
                    color: Color.fromRGBO(255, 255, 255, 1),
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Titillium Web',
                  ),
                ),

                const SizedBox(height: 20),

                // Sonny Shaikh Info
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: AppColors.defaultBlueGray600,
                        width: 2), // Add this line
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // name and icon
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            const ClipOval(
                                child: AppContentImage(
                                    'assets/icons/sonny_headshot.png',
                                    width: 50,
                                    height: 50,
                                    fit: BoxFit.cover)),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  AppContent.text(
                                      'text.screens.profile.pages.help.ahsan_sonny_shaikh_7502e6'),
                                  style: const TextStyle(
                                    fontSize: 20,
                                    color: Color.fromRGBO(255, 255, 255, 1),
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Titillium Web',
                                  ),
                                ),
                                Text(
                                  AppContent.text(
                                      'text.screens.profile.pages.help.partner_9357e0'),
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.grey[400],
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Titillium Web',
                                  ),
                                ),
                              ],
                            )
                          ],
                        ),

                        const SizedBox(height: 20),

                        // contact info
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppContent.text(
                                  'text.screens.profile.pages.help.contact_info_d01b04'),
                              style: const TextStyle(
                                fontSize: 18,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Titillium Web',
                              ),
                            ),
                            const SizedBox(height: 15),
                            GestureDetector(
                              onTap: () async {
                                final Uri emailLaunchUri = Uri(
                                  scheme: 'mailto',
                                  path: AppContent.contactTarget(
                                      'contact.sonny_email_message'),
                                  query:
                                      'subject=${Uri.encodeComponent(AppContent.text("contact.email_subject"))}',
                                );
                                if (await canLaunch(
                                    emailLaunchUri.toString())) {
                                  await launch(emailLaunchUri.toString());
                                } else {}
                              },
                              child: Row(
                                children: [
                                  const AppContentImage(
                                    'assets/icons/email.svg',
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    AppContent.text(
                                        'contact.sonny_email_message'),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      color: Colors.white,
                                      fontFamily: 'Titillium Web',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 10),
                            GestureDetector(
                              onTap: () async {
                                final url = Uri(
                                        scheme: 'tel',
                                        path: AppContent.contactTarget(
                                            'contact.sonny_phone_message'))
                                    .toString();
                                try {
                                  bool launched = await launch(url);
                                  if (!launched) {}
                                } on PlatformException catch (e) {
                                } catch (e) {}
                              },
                              child: Row(
                                children: [
                                  const AppContentImage(
                                    'assets/icons/phone.svg',
                                    color: Colors.white,
                                    height: 16,
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    AppContent.text(
                                        'contact.sonny_phone_message'),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      color: Colors.white,
                                      fontFamily: 'Titillium Web',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 10),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Kash Shaikh Info
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: AppColors.defaultBlueGray600,
                        width: 2), // Add this line
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // name and icon
                        Row(
                          children: [
                            const ClipOval(
                                child: AppContentImage(
                                    'assets/icons/kash_headshot.png',
                                    width: 50,
                                    height: 50,
                                    fit: BoxFit.cover)),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  AppContent.text(
                                      'text.screens.profile.pages.help.kashif_shaikh_9d51d3'),
                                  style: const TextStyle(
                                    fontSize: 20,
                                    color: Color.fromRGBO(255, 255, 255, 1),
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Titillium Web',
                                  ),
                                ),
                                Text(
                                  AppContent.text(
                                      'text.screens.profile.pages.help.partner_9357e0'),
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.grey[400],
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Titillium Web',
                                  ),
                                ),
                              ],
                            )
                          ],
                        ),

                        const SizedBox(height: 20),

                        // contact info
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppContent.text(
                                  'text.screens.profile.pages.help.contact_info_d01b04'),
                              style: const TextStyle(
                                fontSize: 18,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Titillium Web',
                              ),
                            ),
                            const SizedBox(height: 15),
                            GestureDetector(
                              onTap: () async {
                                final Uri emailLaunchUri = Uri(
                                  scheme: 'mailto',
                                  path: AppContent.contactTarget(
                                      'contact.kash_email_message'),
                                  query:
                                      'subject=${Uri.encodeComponent(AppContent.text("contact.email_subject"))}',
                                );
                                if (await canLaunch(
                                    emailLaunchUri.toString())) {
                                  await launch(emailLaunchUri.toString());
                                } else {}
                              },
                              child: Container(
                                color: Colors.transparent,
                                child: Row(
                                  children: [
                                    const AppContentImage(
                                      'assets/icons/email.svg',
                                      color: Colors.white,
                                      height: 16,
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      AppContent.text(
                                          'contact.kash_email_message'),
                                      style: const TextStyle(
                                        fontSize: 16,
                                        color: Colors.white,
                                        fontFamily: 'Titillium Web',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            GestureDetector(
                              onTap: () async {
                                final url = Uri(
                                        scheme: 'tel',
                                        path: AppContent.contactTarget(
                                            'contact.kash_phone_message'))
                                    .toString();
                                try {
                                  bool launched = await launch(url);
                                  if (!launched) {}
                                } on PlatformException catch (e) {
                                } catch (e) {}
                              },
                              child: Container(
                                color: Colors.transparent,
                                child: Row(
                                  children: [
                                    const AppContentImage(
                                      'assets/icons/phone.svg',
                                      color: Colors.white,
                                      height: 16,
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      AppContent.text(
                                          'contact.kash_phone_message'),
                                      style: const TextStyle(
                                        fontSize: 16,
                                        color: Colors.white,
                                        fontFamily: 'Titillium Web',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 40),

            // FAQ Section
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const SizedBox(width: 10),
                    Text(
                      AppContent.text(
                          'text.screens.profile.pages.help.faq_03688b'),
                      style: const TextStyle(
                        fontSize: 22,
                        color: Color.fromRGBO(255, 255, 255, 1),
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Titillium Web',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                CustomExpansionTile(
                  title: AppContent.text(
                      'text.screens.profile.pages.help.is_the_app_secure_8e37a6'),
                  content: AppContent.text(
                      'text.screens.profile.pages.help.absolutely_the_agq_app_employs_cutting_54d0ec'),
                ),
                CustomExpansionTile(
                  title: AppContent.text(
                      'text.screens.profile.pages.help.how_do_i_contact_customer_support_6a03d1'),
                  content: AppContent.text(
                      'text.screens.profile.pages.help.you_can_contact_us_via_email_at_manage_155913'),
                ),
                CustomExpansionTile(
                  title: AppContent.text(
                      'text.screens.profile.pages.help.how_do_i_update_my_personal_informatio_942784'),
                  content: AppContent.text(
                      'text.screens.profile.pages.help.log_in_to_your_account_go_to_profile_s_8470f8'),
                ),
                CustomExpansionTile(
                  title: AppContent.text(
                      'text.screens.profile.pages.help.what_should_i_do_if_my_phone_is_lost_o_97df21'),
                  content: AppContent.text(
                      'text.screens.profile.pages.help.if_your_phone_is_lost_or_stolen_contac_ec6456'),
                ),
                CustomExpansionTile(
                  title: AppContent.text(
                      'text.screens.profile.pages.help.how_can_i_export_my_financial_data_0b0bfd'),
                  content: AppContent.text(
                      'text.screens.profile.pages.help.go_to_the_documents_section_click_the__869bb2'),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ],
        ),
      );
}
