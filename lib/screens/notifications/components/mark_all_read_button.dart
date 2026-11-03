// mark_all_as_read_button.dart
import 'package:agq_app/content/app_content.dart';
import 'package:flutter/material.dart';
import 'package:agq_app/database/models/client_model.dart';
import 'package:agq_app/database/database.dart';
import 'package:agq_app/screens/utils/resources.dart'; // Update with the correct import path

class MarkAllAsReadButton extends StatelessWidget {
  final Client client;
  final VoidCallback onRefresh;

  const MarkAllAsReadButton({
    super.key,
    required this.client,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    bool hasUnreadNotifications = (client.numNotifsUnread ?? 0) > 0;

    if (!hasUnreadNotifications) {
      return Container(); // Return an empty container if there are no unread notifications
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Align(
          alignment: Alignment.bottomCenter, // Align to bottom center
          child: Padding(
            padding: const EdgeInsets.all(16.0), // Adjust padding as needed
            child: ElevatedButton(
              onPressed: () async {
                await DatabaseService.withCID(client.uid, client.cid)
                    .markAllNotificationsAsRead();
                onRefresh();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.defaultBlue500,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                padding: const EdgeInsets.symmetric(
                    horizontal: 16.0), // Add padding to the button
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min, // Add this
                children: [
                  const Icon(Icons.checklist_rounded, color: Colors.white),
                  Text(
                    AppContent.text(
                        'text.screens.notifications.components.mark_all_read_button.mark_all_as_read_81b1f7'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontFamily: 'Titillium Web',
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
