import 'package:agq_app/content/app_content.dart';
import 'package:flutter/material.dart';
import 'package:agq_app/screens/activity/utils/sort_activities.dart';
import 'package:agq_app/screens/utils/resources.dart';

/// A modal widget for selecting sort options.
class ActivitySortModal extends StatelessWidget {
  final SortOrder currentOrder;
  final Function(SortOrder) onSelect;

  const ActivitySortModal({
    super.key,
    required this.currentOrder,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    AppContent.watch(context);
    return SingleChildScrollView(
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20.0),
          topRight: Radius.circular(20.0),
        ),
        child: Container(
          color: AppColors.defaultBlueGray800,
          child: Column(
            children: [
              const SizedBox(height: 20.0),
              Padding(
                padding: const EdgeInsets.fromLTRB(20.0, 0, 0, 0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    AppContent.text(
                        'text.screens.activity.components.sort_modal.sort_by_311158'),
                    style: const TextStyle(
                        fontSize: 22.0,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontFamily: 'Titillium Web'),
                  ),
                ),
              ),
              const SizedBox(height: 20.0),
              _buildSortOption(
                  context,
                  AppContent.text(
                      'text.screens.activity.components.sort_modal.date_new_to_old_default_81c34e'),
                  SortOrder.newToOld),
              _buildSortOption(
                  context,
                  AppContent.text(
                      'text.screens.activity.components.sort_modal.date_old_to_new_77fdcc'),
                  SortOrder.oldToNew),
              _buildSortOption(
                  context,
                  AppContent.text(
                      'text.screens.activity.components.sort_modal.amount_low_to_high_e12d6c'),
                  SortOrder.lowToHigh),
              _buildSortOption(
                  context,
                  AppContent.text(
                      'text.screens.activity.components.sort_modal.amount_high_to_low_6235dc'),
                  SortOrder.highToLow),
              const SizedBox(height: 20.0),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds an individual sort option.
  Widget _buildSortOption(
          BuildContext context, String title, SortOrder value) =>
      ListTile(
        title: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: currentOrder == value
                ? AppColors.defaultBlue500
                : Colors.transparent,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Text(
            title,
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 18,
                fontFamily: 'Titillium Web'),
          ),
        ),
        onTap: () {
          Navigator.pop(context);
          onSelect(value);
        },
      );
}
