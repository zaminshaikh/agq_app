// ignore_for_file: sized_box_for_whitespace, deprecated_member_use

import 'package:agq_app/content/app_content.dart';
import 'package:agq_app/content/content_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:agq_app/database/models/activity_model.dart';
import 'package:agq_app/screens/activity/utils/activity_styles.dart';
import 'package:agq_app/screens/utils/utilities.dart';

class ActivityCardItem extends StatelessWidget {
  final Activity activity;

  const ActivityCardItem({
    required this.activity,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    AppContent.watch(context);
    final DateFormat timeFormat = DateFormat('h:mm a');
    final DateFormat dateFormat = DateFormat('MMM d, yyyy');
    String time = timeFormat.format(activity.time);
    String date = dateFormat.format(activity.time);

    return Container(
      width: MediaQuery.of(context).size.width * 0.6, // Set a fixed width
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(12.0),
          border:
              Border.all(color: getActivityColor(activity.type), width: 2.0),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildActivityDetails(),
                  const SizedBox(height: 16.0),
                  _buildActivityAmountAndRecipient(time),
                  const SizedBox(height: 16.0),
                  _buildActivityDateTime(date, time),
                ],
              ),
            ),
            _buildActivityIcon(),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityDateTime(String date, String time) => Row(
        children: [
          Text(
            date,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.white,
              fontFamily: 'Titillium Web',
            ),
          ),
          const SizedBox(width: 2),
          const AppContentImage(
            'assets/icons/line.svg',
            color: Colors.white,
            height: 15,
          ),
          const SizedBox(width: 2),
          Text(
            time,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.white,
              fontFamily: 'Titillium Web',
            ),
          ),
        ],
      );

  Widget _buildActivityIcon() => Stack(
        alignment: Alignment.center,
        children: [
          Icon(
            Icons.circle,
            color: getUnderlayColor(activity.type),
            size: 50,
          ),
          getActivityIcon(activity.type),
        ],
      );

  Widget _buildActivityDetails() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            activity.fund,
            style: const TextStyle(
              fontSize: 18,
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontFamily: 'Titillium Web',
            ),
          ),
          const SizedBox(height: 5),
          Text(
            getActivityType(activity),
            style: TextStyle(
              fontSize: 15,
              color: getActivityColor(activity.type),
              fontWeight: FontWeight.bold,
              fontFamily: 'Titillium Web',
            ),
          ),
        ],
      );

  Widget _buildActivityAmountAndRecipient(String time) => Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '${activity.type == 'withdrawal' ? '-' : ''}${currencyFormat(activity.amount.toDouble())}',
              style: TextStyle(
                fontSize: 18,
                color: getActivityColor(activity.type),
                fontWeight: FontWeight.bold,
                fontFamily: 'Titillium Web',
              ),
            ),
          ),
          const SizedBox(height: 5),
          Row(
            children: [
              Text(
                _getShortenedName(activity.recipient),
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Titillium Web',
                ),
              ),
            ],
          ),
        ],
      );

  // Helper function to get the shortened name
  String _getShortenedName(String name) {
    final parts = name.split(' ');
    if (parts.length > 1) {
      final firstName = parts[0];
      final lastName = parts[1];
      final fullName = '$firstName $lastName';
      if (fullName.length > 20) {
        return '${firstName.substring(0, 1)}. ${lastName.substring(0, 1)}.';
      } else {
        return fullName;
      }
    } else {
      return name.length > 20 ? '${name.substring(0, 1)}.' : name;
    }
  }
}
