import 'package:agq_app/content/app_content.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:agq_app/database/models/activity_model.dart';

/// Filters the given [activities] by type, recipients, parent names, and date range.
void filterActivities(
  List<Activity> activities,
  List<String> typeFilter,
  List<String> recipientsFilter,
  List<String> parentFilter,
  DateTimeRange selectedDates,
) {
  // 1) Provide defaults if empty
  if (typeFilter.isEmpty) {
    typeFilter = ['income', 'profit', 'deposit', 'withdrawal', 'pending'];
  }
  if (recipientsFilter.isEmpty) {
    recipientsFilter = []; // No filter
  }
  // If [parentFilter] is empty, interpret it as "no restriction," so we do NOT remove anything by parent name.

  // 2) Filter by parent name (only if [parentFilter] is non-empty)
  if (parentFilter.isNotEmpty) {
    activities.removeWhere((activity) {
      // If activity.parentName is null or not in [parentFilter], remove it
      final parentName = activity.parentName ?? '';
      return !parentFilter.contains(parentName);
    });
  }

  // 3) Filter by type
  activities.removeWhere((activity) => !typeFilter.contains(activity.type));

  // 4) Filter by recipient
  activities.removeWhere(
      (activity) => !recipientsFilter.contains(activity.recipient));

  // 5) Filter by date range
  activities.removeWhere((activity) =>
      activity.time.isBefore(selectedDates.start) ||
      activity.time.isAfter(selectedDates.end));
}

/// Returns a List of string “labels” summarizing the selected filters (for UI display).
List<String> getSelectedFilters(
  List<String> recipientsFilter,
  List<String> typeFilter,
  List<String> parentFilter,
  DateTimeRange selectedDates,
) {
  // Default type filters we don’t count as “selected”
  List<String> defaultTypeFilter = [
    'income',
    'profit',
    'deposit',
    'withdrawal',
    'pending'
  ];

  List<String> selectedFilters = [];

  // 1) If the type filters differ from the defaults, add them
  if (typeFilter.toSet().difference(defaultTypeFilter.toSet()).isNotEmpty) {
    selectedFilters.addAll(typeFilter);
  }

  // 2) If recipients are not empty, add them
  if (recipientsFilter.isNotEmpty) {
    selectedFilters.addAll(recipientsFilter);
  }

  // 3) If parentFilter is not empty, add them
  if (parentFilter.isNotEmpty) {
    selectedFilters.addAll(parentFilter);
  }

  // 4) Always add the date range
  String formatDate(DateTime date) => DateFormat('MM/dd/yy').format(date);
  String dateRange = AppContent.text(
      'text.screens.activity.utils.filter_activities.value1_to_value2_3535f6', {
    'value1': formatDate(selectedDates.start),
    'value2': formatDate(selectedDates.end)
  });
  selectedFilters.add(dateRange);

  return selectedFilters;
}
