import 'package:agq_app/content/app_content.dart';
import 'package:agq_app/content/content_image.dart';
import 'package:flutter/material.dart';
import 'package:agq_app/database/models/client_model.dart';
import 'package:agq_app/screens/notifications/notifications.dart';

class AnalyticsAppBar extends StatelessWidget {
  final Client client;

  const AnalyticsAppBar({
    super.key,
    required this.client,
  });

  @override
  Widget build(BuildContext context) {
    AppContent.watch(context);
    return SliverAppBar(
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
                        'text.screens.analytics.components.analytics_app_bar.analytics_25bc96'),
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
                          child: (client.numNotifsUnread ?? 0) > 0
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
                                    '${client.numNotifsUnread}',
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
  }
}
