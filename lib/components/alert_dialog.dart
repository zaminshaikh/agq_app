// ignore_for_file: deprecated_member_use

import 'package:agq_app/content/app_content.dart';
import 'package:agq_app/content/content_image.dart';
import 'package:agq_app/screens/utils/resources.dart';
import 'package:flutter/material.dart';

/// A class that provides a custom alert dialog.
///
/// Displays an alert dialog with the specified [title] and [message].
///
/// The [context] parameter is required to show the dialog.
/// The [title] parameter specifies the title of the dialog.
/// The [message] parameter specifies the message content of the dialog.
///
/// Example usage:
///
/// ```dart
/// CustomAlertDialog.showAlertDialog(context, 'Alert', 'This is an alert message');
/// ```
/// A class that provides a custom alert dialog.
///
/// Displays an alert dialog with the specified [title] and [message].
///
/// The [context] parameter is required to show the dialog.
/// The [title] parameter specifies the title of the dialog.
/// The [message] parameter specifies the message content of the dialog.
///
/// Example usage:
///
/// ```dart
/// CustomAlertDialog.showAlertDialog(context, 'Alert', 'This is an alert message');
/// ```
class CustomAlertDialog {
  static Future<void> showAlertDialog(
    BuildContext context,
    String title,
    String message, {
    Icon? icon,
    String? svgIconPath,
    Color?
        svgIconColor, // Add this parameter to specify the color of the SVG icon
  }) async =>
      showDialog<void>(
        context: context,
        barrierDismissible: false, // user must tap button!
        builder: (BuildContext context) => AlertDialog(
          backgroundColor: AppColors.defaultBlueGray800,
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    children: <Widget>[
                      Text(title,
                          style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(width: 10),
                      if (svgIconPath != null)
                        AppContentImage(
                          svgIconPath,
                          width: 24,
                          height: 24,
                          color: svgIconColor, // Set the color of the SVG icon
                        )
                      else
                        icon ??
                            const Icon(Icons.square, color: Colors.transparent),
                    ],
                  ),
                ),
                Text(message),
              ],
            ),
          ),
          actions: <Widget>[
            GestureDetector(
              onTap: () {
                Navigator.of(context).pop();
              },
              child: Container(
                width: double
                    .infinity, // This will make the container take up the full width of the AlertDialog
                padding: const EdgeInsets.symmetric(
                    vertical: 10), // Add some vertical padding
                decoration: BoxDecoration(
                  color: const Color.fromARGB(
                      255, 30, 75, 137), // Change this to the color you want
                  borderRadius: BorderRadius.circular(
                      20), // This will make the corners rounded
                ),
                child: Text(
                  AppContent.text(
                      'text.components.alert_dialog.continue_2e0262'),
                  textAlign: TextAlign.center, // This will center the text
                ),
              ),
            )
          ],
        ),
      );
}
