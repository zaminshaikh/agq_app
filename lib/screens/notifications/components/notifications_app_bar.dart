// notifications_app_bar.dart
import 'package:agq_app/content/app_content.dart';
import 'package:flutter/material.dart';

class NotificationsAppBar extends StatelessWidget {
  const NotificationsAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    AppContent.watch(context);
    return SliverAppBar(
      backgroundColor: const Color.fromARGB(255, 30, 41, 59),
      toolbarHeight: 80,
      expandedHeight: 0,
      snap: false,
      floating: true,
      pinned: true,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
        onPressed: () {
          Navigator.of(context).pop();
        },
      ),
      flexibleSpace: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 60.0, right: 20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppContent.text(
                        'text.screens.notifications.components.notifications_app_bar.notifications_753a22'),
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
    );
  }
}
