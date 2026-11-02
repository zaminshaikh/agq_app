// ignore_for_file: deprecated_member_use

import 'package:agq_app/content/app_content.dart';
import 'package:agq_app/content/content_image.dart';
import 'package:flutter/material.dart';
import 'package:agq_app/database/models/client_model.dart';
import 'package:agq_app/screens/utils/resources.dart';
import 'package:agq_app/screens/utils/utilities.dart';

class TotalAssetsSection extends StatelessWidget {
  final Client client;

  const TotalAssetsSection({super.key, required this.client});

  @override
  Widget build(BuildContext context) {
    AppContent.watch(context);
    double totalAssets = client.assets?.totalAssets ?? 0;

    // Check if connectedUsers is not null before iterating
    if (client.connectedUsers != null) {
      for (var user in client.connectedUsers!) {
        totalAssets += user?.assets?.totalAssets ?? 0;
      }
    }
    return Stack(
      children: [
        Container(
          width: double.infinity,
          height: 160,
          padding: const EdgeInsets.only(left: 12, top: 10),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color(0xFF3199DD),
                Color.fromARGB(255, 13, 94, 175),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(15),
            image: const DecorationImage(
              image: AssetImage('assets/icons/total_assets_gradient.png'),
              fit: BoxFit.cover,
              alignment: Alignment.centerRight,
            ),
          ),
          child: Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),
                  Text(
                    AppContent.text(
                        'text.screens.dashboard.components.total_assets_section.total_assets_5d9f9a'),
                    style: const TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                      fontFamily: 'Titillium Web',
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    currencyFormat(totalAssets),
                    style: const TextStyle(
                      fontSize: 35,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      fontFamily: 'Titillium Web',
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const AppContentImage(
                        'assets/icons/YTD.svg',
                        height: 13,
                        color: Color.fromRGBO(74, 222, 128, 1),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        currencyFormat(client.assets?.totalYTD ?? 0),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          fontFamily: 'Titillium Web',
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ],
          ),
        ),
        Positioned(
          bottom: 5,
          right: 5,
          child: IconButton(
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
            icon: const Icon(Icons.info_outline_rounded,
                color: Color.fromARGB(71, 255, 255, 255)),
            onPressed: () {
              showDialog(
                context: context,
                builder: (BuildContext context) => AlertDialog(
                  backgroundColor: AppColors.defaultBlueGray800,
                  content: SingleChildScrollView(
                    child: ListBody(
                      children: <Widget>[
                        const SizedBox(height: 5),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 5),
                          child: Row(
                            children: <Widget>[
                              Text(
                                  AppContent.text(
                                      'text.screens.dashboard.components.total_assets_section.what_is_9c9e11'),
                                  style:
                                      Theme.of(context).textTheme.titleLarge),
                              const SizedBox(width: 5),
                              const AppContentImage(
                                'assets/icons/YTD.svg',
                                height: 20,
                              ),
                              const SizedBox(width: 5),
                              Text('?',
                                  style:
                                      Theme.of(context).textTheme.titleLarge),
                            ],
                          ),
                        ),
                        Text(AppContent.text(
                            'text.screens.dashboard.components.total_assets_section.ytd_stands_for_year_to_date_it_is_a_fi_61a2da')),
                        const SizedBox(height: 20),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 5),
                          child: Row(
                            children: <Widget>[
                              Text(
                                  AppContent.text(
                                      'text.screens.dashboard.components.total_assets_section.what_are_my_total_assets_5bea76'),
                                  style:
                                      Theme.of(context).textTheme.titleLarge),
                            ],
                          ),
                        ),
                        Text(AppContent.text(
                            'text.screens.dashboard.components.total_assets_section.total_assets_are_the_sum_of_all_assets_98d27d')),
                      ],
                    ),
                  ),
                  actions: <Widget>[
                    GestureDetector(
                      onTap: () {
                        Navigator.of(context).pop();
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color.fromARGB(255, 30, 75, 137),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          AppContent.text(
                              'text.screens.dashboard.components.total_assets_section.continue_2e0262'),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
