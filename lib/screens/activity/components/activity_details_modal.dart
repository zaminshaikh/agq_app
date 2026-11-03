// ignore_for_file: deprecated_member_use

import 'package:agq_app/content/app_content.dart';
import 'package:agq_app/content/content_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:agq_app/database/models/activity_model.dart';
import 'package:agq_app/screens/utils/resources.dart';
import 'package:agq_app/screens/utils/utilities.dart';
import '../utils/activity_styles.dart';

final DateFormat timeFormat = DateFormat('h:mm a');
final DateFormat dateFormat = DateFormat('EEEE, MMM. d, yyyy');
final DateFormat dayHeaderFormat = DateFormat('MMMM d, yyyy');

class ActivityDetailsModal extends StatelessWidget {
  final Activity activity;
  final bool isFromAGQ; // make it final

  // The constructor no longer accepts isFromAGQ
  ActivityDetailsModal({
    required this.activity,
    super.key,
  }) : isFromAGQ = (activity.fund == 'AGQ');

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      heightFactor: 0.67,
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(30.0),
          topRight: Radius.circular(30.0),
        ),
        child: Container(
          color: AppColors.defaultBlueGray800,
          child: SingleChildScrollView(
            child: Column(
              children: [
                _buildModalHeader(context, isFromAGQ),
                _buildModalBody(activity),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModalHeader(BuildContext context, bool isFromAGQ) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(Icons.close_rounded,
                      color: Color.fromARGB(171, 255, 255, 255)),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          if (isFromAGQ)
            const Padding(
              padding: EdgeInsets.only(bottom: 25.0),
              child: AppContentImage(
                'assets/icons/agq_logo.svg',
                width: 40,
                height: 40,
              ),
            ),
          Text(
            AppContent.text(
                'text.screens.activity.components.activity_details_modal.activity_details_733a26'),
            style: const TextStyle(
              fontSize: 25.0,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontFamily: 'Titillium Web',
            ),
          ),
        ],
      );

  Widget _buildModalBody(Activity activity) {
    String date = dateFormat.format(activity.time);
    return Column(
      children: [
        Text(
          '${activity.type == 'withdrawal' ? '-' : ''}${currencyFormat(activity.amount.toDouble())}',
          style: TextStyle(
            fontSize: 30,
            color: getActivityColor(activity.type),
            fontWeight: FontWeight.bold,
            fontFamily: 'Titillium Web',
          ),
        ),
        const SizedBox(height: 15),
        Center(
          child: Text(
            getActivityDescription(activity),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              fontFamily: 'Titillium Web',
            ),
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              getActivityIcon(activity.type, size: 35),
              const SizedBox(width: 5),
              Text(
                getActivityType(activity),
                style: TextStyle(
                  fontSize: 16,
                  color: getActivityColor(activity.type),
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Titillium Web',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 25),
        _buildModalDetailSection(
          icon: AppContentImage(
            'assets/icons/activity_description.svg',
            color: getActivityColor(activity.type),
          ),
          title: AppContent.text(
              'text.screens.activity.components.activity_details_modal.description_55f8eb'),
          content: getActivityDescription(activity),
          underlayColor: getUnderlayColor(activity.type),
        ),
        const Divider(color: Colors.white, thickness: 0.2),
        _buildModalDetailSection(
          icon: AppContentImage(
            'assets/icons/activity_date.svg',
            color: getActivityColor(activity.type),
          ),
          title: AppContent.text(
              'text.screens.activity.components.activity_details_modal.date_eb9a4b'),
          content: date,
          underlayColor: getUnderlayColor(activity.type),
        ),
        const Divider(color: Colors.white, thickness: 0.2),
        _buildModalDetailSection(
          icon: AppContentImage(
            'assets/icons/activity_user.svg',
            color: getActivityColor(activity.type),
          ),
          title: AppContent.text(
              'text.screens.activity.components.activity_details_modal.recipient_903432'),
          content: activity.recipient,
          underlayColor: getUnderlayColor(activity.type),
        ),
      ],
    );
  }

  Widget _buildModalDetailSection({
    required Widget icon,
    required String title,
    required String content,
    required Color underlayColor,
  }) =>
      Padding(
        padding: const EdgeInsets.fromLTRB(18, 0, 18, 0),
        child: Row(
          children: [
            Stack(
              children: [
                Icon(
                  Icons.circle,
                  color: underlayColor,
                  size: 50,
                ),
                Positioned.fill(
                  child: Align(
                    alignment: Alignment.center,
                    child: icon,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Titillium Web',
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    content,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white,
                      fontFamily: 'Titillium Web',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  // Activity details modal
  // void _showActivityDetailsModal(BuildContext context, Activity activity, bool isFromAGQ) {
  //   showModalBottomSheet(
  //     context: context,
  //     isScrollControlled: true,
  //     backgroundColor: Colors.transparent,
  //     builder: (BuildContext context) => ClipRRect(
  //       borderRadius: const BorderRadius.only(
  //         topLeft: Radius.circular(20.0),
  //         topRight: Radius.circular(20.0),
  //       ),
  //       child: FractionallySizedBox(
  //         heightFactor: 0.67,
  //         child: Container(
  //           color: AppColors.defaultBlueGray800,
  //           child: SingleChildScrollView(
  //             child: Column(
  //               children: <Widget>[
  //                 _buildModalHeader(context, isFromAGQ),
  //                 _buildModalBody(activity),
  //               ],
  //             ),
  //           ),
  //         ),
  //       ),
  //     ),
  //   );
  // }
}
