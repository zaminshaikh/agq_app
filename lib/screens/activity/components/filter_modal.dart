// activity_filter_modal.dart

import 'package:agq_app/content/app_content.dart';
import 'package:flutter/material.dart';
import 'package:agq_app/screens/utils/resources.dart';
import 'package:agq_app/screens/utils/utilities.dart';

/// A modal widget for filtering activities.
class ActivityFilterModal extends StatefulWidget {
  final List<String> typeFilter;
  final List<String> recipientsFilter;
  final List<String> allRecipients;

  // NEW: for Parent Name filter
  final List<String> clientsFilter;
  final List<String> allClients;

  final DateTimeRange selectedDates;

  // Updated: onApply now must return clientsFilter as well
  final Function(
    List<String> typeFilter,
    List<String> recipientsFilter,
    List<String> clientsFilter,
    DateTimeRange selectedDates,
  ) onApply;

  const ActivityFilterModal({
    super.key,
    required this.typeFilter,
    required this.recipientsFilter,
    required this.allRecipients,

    // NEW
    required this.clientsFilter,
    required this.allClients,
    required this.selectedDates,
    required this.onApply,
  });

  @override
  ActivityFilterModalState createState() => ActivityFilterModalState();
}

class ActivityFilterModalState extends State<ActivityFilterModal> {
  late List<String> _typeFilter;
  late List<String> _recipientsFilter;

  // NEW
  late List<String> _clientsFilter;

  late DateTimeRange _selectedDates;

  @override
  void initState() {
    super.initState();
    _typeFilter = List.from(widget.typeFilter);
    _recipientsFilter = List.from(widget.recipientsFilter);
    // Initialize clientsFilter with allclients if 'All' is selected
    _clientsFilter = widget.clientsFilter.isEmpty
        ? List.from(widget.allClients)
        : List.from(widget.clientsFilter);
    _selectedDates = widget.selectedDates;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: Container(
        color: const Color.fromRGBO(0, 0, 0, 0.001),
        child: GestureDetector(
          onTap: () {},
          child: DraggableScrollableSheet(
            initialChildSize: 0.8,
            minChildSize: 0.8,
            maxChildSize: 0.8,
            builder: (_, controller) => Container(
              decoration: const BoxDecoration(
                color: AppColors.defaultBlueGray800,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(25.0),
                  topRight: Radius.circular(25.0),
                ),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 5),
                  const Icon(Icons.remove, color: Colors.transparent),
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(25.0),
                      child: Text(
                        AppContent.text(
                            'text.screens.activity.components.filter_modal.filter_activity_527606'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Titillium Web',
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      controller: controller,
                      children: [
                        _buildTimePeriodFilter(),
                        _buildFilter(
                          AppContent.text(
                              'text.screens.activity.components.filter_modal.type_3deb74'),
                          widget.typeFilter,
                          _typeFilter,
                        ),
                        _buildFilter(
                          AppContent.text(
                              'text.screens.activity.components.filter_modal.recipients_78cbf8'),
                          widget.allRecipients,
                          _recipientsFilter,
                        ),
                        // NEW: Parent Name Filter Section
                        _buildFilter(
                          AppContent.text(
                              'text.screens.activity.components.filter_modal.clients_28e22f'),
                          widget.allClients,
                          _clientsFilter,
                        ),
                      ],
                    ),
                  ),
                  _buildFilterApplyClearButtons(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Builds the time period filter option.
  Widget _buildTimePeriodFilter() => ListTile(
        title: GestureDetector(
          onTap: () async {
            final DateTimeRange? dateTimeRange = await showDateRangePicker(
              context: context,
              firstDate: DateTime(2000),
              lastDate: DateTime(3000),
              builder: (BuildContext context, Widget? child) => Theme(
                data: Theme.of(context).copyWith(
                  scaffoldBackgroundColor: AppColors.defaultBlueGray800,
                  colorScheme: const ColorScheme.dark().copyWith(
                    brightness: Brightness.dark,
                    primary: Colors.white,
                    onPrimary: AppColors.altBlueGray800,
                    secondary: AppColors.altBlueGray800,
                    onSecondary: AppColors.altBlueGray800,
                    secondaryContainer: AppColors.altBlueGray800,
                    onSecondaryContainer: AppColors.altBlueGray800,
                    secondaryFixed: AppColors.altBlueGray800,
                    secondaryFixedDim: AppColors.altBlueGray800,
                  ),
                ),
                child: child!,
              ),
            );
            if (dateTimeRange != null) {
              setState(() {
                _selectedDates = dateTimeRange;
              });
            }
          },
          child: Container(
            color: Colors.transparent,
            child: Text(
              AppContent.text(
                  'text.screens.activity.components.filter_modal.by_time_period_f7e29b'),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontFamily: 'Titillium Web',
              ),
            ),
          ),
        ),
      );

  /// Builds a filter section with checkboxes.
  Widget _buildFilter(
    String title,
    List<String> items,
    List<String> filterList,
  ) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 5.0),
        child: ExpansionTile(
          title: Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontFamily: 'Titillium Web',
            ),
          ),
          iconColor: Colors.white,
          collapsedIconColor: Colors.white,
          children: items
              .map(
                (item) => _buildCheckbox(
                  toTitleCase(item),
                  item,
                  filterList,
                ),
              )
              .toList(),
        ),
      );

  /// Builds an individual checkbox for the filter.
  Widget _buildCheckbox(
    String title,
    String filterKey,
    List<String> filterList,
  ) {
    bool isChecked = filterList.contains(filterKey);
    return StatefulBuilder(
      builder: (BuildContext context, StateSetter setState) => CheckboxListTile(
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 16.0,
            color: Colors.white,
            fontFamily: 'Titillium Web',
          ),
        ),
        activeColor: AppColors.defaultBlue500,
        value: isChecked,
        onChanged: (bool? value) {
          setState(() {
            isChecked = value ?? false;
            if (isChecked) {
              // Special case if filterKey is 'profit'
              if (filterKey == 'profit') {
                if (!filterList.contains('income')) {
                  filterList.add('income');
                }
              }
              if (!filterList.contains(filterKey)) {
                filterList.add(filterKey);
              }
            } else {
              if (filterKey == 'profit') {
                filterList.remove('income');
              }
              filterList.remove(filterKey);
            }

            // Update _allSelected if all clients are selected or none
            if (widget.allClients.length == filterList.length) {
              _allSelected = true;
              _clientsFilter = [];
            } else if (filterList.isEmpty) {
              _allSelected = true;
              _clientsFilter = List.from(widget.allClients);
            } else {
              _allSelected = false;
            }
          });
        },
      ),
    );
  }

  /// Builds the apply and clear buttons for the filter modal.
  Widget _buildFilterApplyClearButtons() => Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.defaultBlue500,
                ),
                child: Text(
                  AppContent.text(
                      'text.screens.activity.components.filter_modal.apply_cfea41'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Titillium Web',
                  ),
                ),
                onPressed: () {
                  // If all clients are selected, clear _clientsFilter to indicate "All" is selected
                  if (_clientsFilter.length == widget.allClients.length) {
                    _clientsFilter.clear();
                  }
                  Navigator.pop(context);
                  widget.onApply(
                    _typeFilter,
                    _recipientsFilter,
                    _clientsFilter, // NEW
                    _selectedDates,
                  );
                },
              ),
            ),
          ),
          GestureDetector(
            child: Container(
              color: Colors.transparent,
              child: Padding(
                padding: const EdgeInsets.all(4.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    const Icon(Icons.close, color: Colors.white),
                    const SizedBox(width: 5),
                    Text(
                      AppContent.text(
                          'text.screens.activity.components.filter_modal.clear_719ea3'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Titillium Web',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            onTap: () {
              setState(() {
                // Reset everything to defaults
                _typeFilter = ['income', 'profit', 'deposit', 'withdrawal'];
                _recipientsFilter = List.from(widget.allRecipients);

                // NEW: reset the clients filter to all
                _clientsFilter = List.from(widget.allClients);
                _allSelected = true;

                _selectedDates = DateTimeRange(
                  start: DateTime(1900),
                  end: DateTime.now().add(const Duration(days: 30)),
                );
              });
              Navigator.pop(context);
              widget.onApply(
                _typeFilter,
                _recipientsFilter,
                _clientsFilter,
                _selectedDates,
              );
            },
          ),
        ],
      );

  // ignore: unused_field
  bool _allSelected = false; // Add this state
}
