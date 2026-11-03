// ignore_for_file: deprecated_member_use

import 'package:agq_app/content/app_content.dart';
import 'package:agq_app/content/content_image.dart';
import 'package:flutter/material.dart';
import 'package:agq_app/screens/activity/utils/sort_activities.dart';
import 'package:agq_app/screens/utils/resources.dart';
import 'package:agq_app/database/models/activity_model.dart';
import 'package:agq_app/screens/utils/utilities.dart';

// Get Activity Type Text
String getActivityType(Activity activity) {
  switch (activity.type) {
    case 'income':
    case 'profit':
      return AppContent.text(
          'text.screens.activity.utils.activity_styles.profit_8544a4');
    case 'deposit':
      return AppContent.text(
          'text.screens.activity.utils.activity_styles.deposit_e7b0b3');
    case 'withdrawal':
      return AppContent.text(
          'text.screens.activity.utils.activity_styles.withdrawal_730e37');
    case 'pending':
      return AppContent.text(
          'text.screens.activity.utils.activity_styles.pending_withdrawal_e109f0');
    default:
      return AppContent.text(
          'text.screens.activity.utils.activity_styles.error_7f2f6a');
  }
}

// Get color based on activity type
Color getActivityColor(String type) {
  switch (type) {
    case 'deposit':
      return AppColors.defaultGreen400;
    case 'withdrawal':
      return AppColors.defaultRed400;
    case 'pending':
      return AppColors.defaultYellow400;
    case 'income':
    case 'profit':
      return AppColors.defaultBlue300;
    default:
      return Colors.white;
  }
}

// Get underlay color based on activity type
Color getUnderlayColor(String type) {
  switch (type) {
    case 'deposit':
      return const Color.fromARGB(255, 21, 52, 57);
    case 'withdrawal':
      return const Color.fromARGB(255, 41, 25, 28);
    case 'pending':
    case 'income':
    case 'profit':
      return const Color.fromARGB(255, 24, 46, 68);
    default:
      return Colors.white;
  }
}

// Get the icon for each activity type
Widget getActivityIcon(String type, {double size = 50.0}) {
  switch (type) {
    case 'deposit':
      return AppContentImage(
        'assets/icons/deposit.svg',
        color: getActivityColor(type),
        height: size,
        width: size,
      );
    case 'withdrawal':
      return AppContentImage(
        'assets/icons/withdrawal.svg',
        color: getActivityColor(type),
        height: size,
        width: size,
      );
    case 'pending':
      return AppContentImage(
        'assets/icons/pending_withdrawal.svg',
        color: getActivityColor(type),
        height: size,
        width: size,
      );
    case 'income':
    case 'profit':
      return AppContentImage(
        'assets/icons/variable_income.svg',
        color: getActivityColor(type),
        height: size,
        width: size,
      );
    default:
      return Icon(
        Icons.circle,
        color: Colors.transparent,
        size: size,
      );
  }
}

// Helper functions at the top
String getActivityDescription(Activity activity) {
  String action;
  switch (activity.type) {
    case 'deposit':
      action = AppContent.text(
          'text.screens.activity.utils.activity_styles.deposit_to_your_investment_at_0d0e00');
      break;
    case 'withdrawal':
      action = AppContent.text(
          'text.screens.activity.utils.activity_styles.withdrawal_from_your_investment_at_623589');
      break;
    case 'pending':
      action = AppContent.text(
          'text.screens.activity.utils.activity_styles.pending_withdrawal_from_your_investmen_ea67d0');
      break;
    case 'income':
    case 'profit':
      action = AppContent.text(
          'text.screens.activity.utils.activity_styles.profit_to_your_investment_at_abd1de');
      break;
    default:
      action = '';
  }
  return '$action ${activity.fund}';
}

/// Generates the date button text based on the selected date range.
String getDateButtonText(DateTime startDate, DateTime endDate) {
  DateTime startOfRange = DateTime(1900, 1, 1);
  DateTime today = DateTime.now();
  DateTime todayDate = DateTime(today.year, today.month, today.day);

  bool isAllTime = startDate == startOfRange &&
      (endDate == todayDate || endDate.isAfter(todayDate));
  if (isAllTime) {
    return AppContent.text(
        'text.screens.activity.utils.activity_styles.all_time_4745c5');
  } else {
    String formattedStartDate =
        '${startDate.month}/${startDate.day}/${startDate.year}';
    String formattedEndDate = '${endDate.month}/${endDate.day}/${endDate.year}';
    return '$formattedStartDate - $formattedEndDate';
  }
}

/// Generates the type button text based on the selected types.
String getTypeButtonText(List<String> typeFilter) {
  List<String> allTypes = ['profit', 'deposit', 'withdrawal'];

  if (allTypes.every((type) => typeFilter.contains(type))) {
    return AppContent.text(
        'text.screens.activity.utils.activity_styles.all_types_eb672c');
  } else if (typeFilter.isEmpty) {
    return AppContent.text(
        'text.screens.activity.utils.activity_styles.no_types_selected_9d927b');
  } else {
    List<String> displayTypes = typeFilter
        .where((type) => type != 'income')
        .map((type) => toTitleCase(type))
        .toList();
    return displayTypes.join(', ');
  }
}

/// Generates the recipients button text based on the selected recipients.
String getRecipientsButtonText(
    List<String> recipientsFilter, List<String> allRecipients) {
  if (allRecipients
      .every((recipient) => recipientsFilter.contains(recipient))) {
    return AppContent.text(
        'text.screens.activity.utils.activity_styles.all_recipients_3b7e46');
  } else if (recipientsFilter.isEmpty) {
    return AppContent.text(
        'text.screens.activity.utils.activity_styles.no_recipients_selected_639bd8');
  } else {
    return recipientsFilter.join(', ');
  }
}

/// Returns a string representation of the sort order.
String getSortOrderText(SortOrder order) {
  switch (order) {
    case SortOrder.newToOld:
      return AppContent.text(
          'text.screens.activity.utils.activity_styles.date_new_to_old_560139');
    case SortOrder.oldToNew:
      return AppContent.text(
          'text.screens.activity.utils.activity_styles.date_old_to_new_77fdcc');
    case SortOrder.lowToHigh:
      return AppContent.text(
          'text.screens.activity.utils.activity_styles.amount_low_to_high_e12d6c');
    case SortOrder.highToLow:
      return AppContent.text(
          'text.screens.activity.utils.activity_styles.amount_high_to_low_6235dc');
    default:
      return '';
  }
}
