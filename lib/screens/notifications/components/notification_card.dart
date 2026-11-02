// notification_card.dart
import 'package:agq_app/content/app_content.dart';
import 'package:agq_app/content/content_image.dart';
import 'package:flutter/material.dart';
import 'package:agq_app/screens/profile/pages/documents.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:agq_app/database/models/client_model.dart';
import 'package:agq_app/database/models/notification_model.dart';
import 'package:agq_app/database/database.dart';
import 'package:agq_app/screens/utils/resources.dart';
import 'package:agq_app/screens/activity/activity.dart';
// Update with the correct import path

class NotificationCard extends StatelessWidget {
  final Notif notification;
  final Client client;

  const NotificationCard({
    super.key,
    required this.notification,
    required this.client,
  });

  @override
  Widget build(BuildContext context) {
    AppContent.watch(context);
    return _buildNotification(context, notification);
  }

  Widget _buildNotification(BuildContext context, Notif notification) {
    String title;
    switch (notification.type) {
      case 'activity':
        title = AppContent.text(
            'text.screens.notifications.components.notification_card.new_activity_f8bc95');
// Replace with your actual Activity page widget
        break;
      case 'statement':
        title = AppContent.text(
            'text.screens.notifications.components.notification_card.new_statement_2daf44');
// Replace with your actual Profile page widget
        break;
      default:
        title = AppContent.text(
            'text.screens.notifications.components.notification_card.new_notification_8fbc0f');
// Replace with your actual Notification page widget
        break;
    }

    // Determine if the message contains "AK1" or "AGQ"
    bool containsAK1 = notification.message.contains('AK1');
    bool containsAGQ = notification.message.contains('AGQ');

    // Calculate the time ago string
    String timeAgo = timeago.format(notification.time, locale: 'en_short');

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(15, 5, 20, 5),
          child: Column(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: null,
                  borderRadius:
                      BorderRadius.circular(15.0), // Set the border radius
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
                  child: Column(
                    children: [
                      ListTile(
                        leading: !notification.isRead
                            ? const CircleAvatar(
                                radius: 6,
                                backgroundColor: AppColors.defaultBlue300,
                              )
                            : const CircleAvatar(
                                radius: 6,
                                backgroundColor: Colors.transparent,
                              ),
                        title: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Title and icons
                            Row(
                              children: [
                                Text(
                                  title,
                                  style: AppTextStyles.lBold(
                                      color: AppColors.defaultWhite),
                                ),
                                const SizedBox(width: 12.0),
                                if (containsAK1)
                                  const AppContentImage(
                                    'assets/icons/ak1_logo.svg',
                                    height: 16.0,
                                    width: 16.0,
                                  ),
                                if (containsAGQ)
                                  const AppContentImage(
                                    'assets/icons/agq_logo.svg',
                                    height: 16.0,
                                    width: 16.0,
                                  ),
                              ],
                            ),
                            // Time ago
                            Text(
                              timeAgo,
                              style: AppTextStyles.sRegular(
                                  color: AppColors.defaultWhite),
                            ),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(
                              notification.message,
                              style: AppTextStyles.xsRegular(
                                  color: AppColors.defaultWhite),
                              softWrap: true,
                              overflow: TextOverflow.visible,
                            ),
                          ],
                        ),
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 8.0),
                        dense: true,

                        // ...existing code...
                        onTap: () async {
                          final targetPage = (notification.type == 'activity')
                              ? const ActivityPage()
                              : const DocumentsPage();

                          await Navigator.pushReplacement(
                            context,
                            PageRouteBuilder(
                              pageBuilder:
                                  (context, animation, secondaryAnimation) =>
                                      targetPage,
                              transitionDuration: Duration.zero,
                              reverseTransitionDuration: Duration.zero,
                              transitionsBuilder: (context, animation,
                                      secondaryAnimation, child) =>
                                  child,
                            ),
                          );

                          final notificationCID = notification.parentCID;
                          final myCID = client.cid;

                          DatabaseService db;

                          if (notificationCID == myCID) {
                            // The notification belongs to the main client
                            db =
                                DatabaseService.withCID(client.uid, client.cid);
                          } else {
                            // Loop through connectedUsers to find a matching CID
                            Client? connectedUser;
                            for (var c in client.connectedUsers ?? []) {
                              if (c != null && c.cid == notificationCID) {
                                connectedUser = c;
                                break;
                              }
                            }

                            if (connectedUser != null) {
                              // Found a matching connected user
                              db = DatabaseService.withCID(
                                  connectedUser.uid, connectedUser.cid);
                            } else {
                              // If not found, fallback to current client
                              db = DatabaseService.withCID(
                                  client.uid, client.cid);
                            }
                          }

                          await db.markNotificationAsRead(notification.id);
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const Divider(
          thickness: 0.5,
        ),
      ],
    );
  }
}
