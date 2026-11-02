// ignore_for_file: deprecated_member_use

import 'package:agq_app/content/app_content.dart';
import 'package:agq_app/content/content_image.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:agq_app/database/models/client_model.dart';
import 'package:agq_app/database/models/graph_point_model.dart';
import 'package:agq_app/database/models/graph_model.dart'; // Import Graph class
import 'package:agq_app/screens/utils/resources.dart';
import 'package:agq_app/screens/analytics/utils/analytics_utilities.dart';

/// A widget that displays the line chart section in the Analytics page.
///
/// This widget is responsible for preparing the data points and rendering the
/// line chart that shows the asset timeline for the client.
class LineChartSection extends StatefulWidget {
  /// The client data containing the graph points.
  final Client client;

  /// Creates a new instance of [LineChartSection].
  const LineChartSection({super.key, required this.client});

  @override
  LineChartSectionState createState() => LineChartSectionState();
}

class LineChartSectionState extends State<LineChartSection> {
  // Variables for the line chart data
  List<FlSpot> spots = [];
  double _minAmount = double.maxFinite;
  double _maxAmount = 0.0;
  String dropdownValue = 'last-2-years';

  // Variables for account selection
  String? selectedAccount;
  Graph? selectedGraph;

  // Variables for client selection
  late final List<Client> allClients;
  Client? selectedClient;

  @override
  void initState() {
    super.initState();
    allClients = [
      widget.client,
      ...(widget.client.connectedUsers?.whereType<Client>() ?? [])
    ];
    selectedClient = allClients.isNotEmpty ? allClients.first : null;
    // Default to the cumulative graph if available
    if (selectedClient != null &&
        (selectedClient!.graphs?.isNotEmpty ?? false)) {
      selectedGraph = selectedClient!.graphs!.firstWhere(
        (g) => g.account.toLowerCase() == 'cumulative',
        orElse: () => selectedClient!.graphs!.first,
      );
      selectedAccount = selectedGraph?.account;
    }
    _prepareGraphPoints();
  }

  /// Prepares the data points for the line chart based on the selected graph's graph points.
  ///
  /// This method processes the selected graph's graph points, calculates the appropriate
  /// x and y values, and populates the [spots] list with [FlSpot] instances.
  /// It also calculates the maximum amount for setting the y-axis limit.
  void _prepareGraphPoints() {
    spots.clear();

    // Track min and max amounts
    double localMinAmount = double.maxFinite;
    double localMaxAmount = 0.0;

    if (selectedGraph != null && selectedGraph!.graphPoints.isNotEmpty) {
      for (var point in selectedGraph!.graphPoints) {
        final DateTime dateTime = point.time;
        final double amount = point.amount;

        // Compute the x position for the point based on the filter
        final double xValue = calculateXValue(dateTime, dropdownValue);
        if (xValue >= 0) {
          spots.add(FlSpot(xValue, amount));
        }
      }

      // Sort spots by x
      spots.sort((a, b) => a.x.compareTo(b.x));

      // Add a starting data point at x=0 if needed
      if (spots.isNotEmpty && spots.first.x > 0) {
        double firstXValue = spots.first.x;
        double startingY = 0;

        // Find the starting y-value from previous data points
        for (var point in selectedGraph!.graphPoints.reversed) {
          double xValue = calculateXValue(point.time, dropdownValue);
          if (xValue < firstXValue) {
            startingY = point.amount;
            break;
          }
        }

        // Insert the starting spot at the beginning
        FlSpot startingSpot = FlSpot(0, startingY);
        spots.insert(0, startingSpot);
      }

      // Add an ending data point at the max x-axis value if needed
      double maxXValue = maxX(dropdownValue);
      if (spots.isNotEmpty && spots.last.x < maxXValue) {
        FlSpot lastSpot = spots.last;
        FlSpot extendedSpot = FlSpot(maxXValue, lastSpot.y);
        spots.add(extendedSpot);
      } else if (spots.isEmpty) {
        // No data points, add default spots
        GraphPoint mostRecentSpot = selectedGraph!.graphPoints.last;
        spots.add(FlSpot(0, mostRecentSpot.amount));
        spots.add(FlSpot(maxXValue, mostRecentSpot.amount));
        _maxAmount = (mostRecentSpot.amount) * 1.5;
      }
    } else {
      // No data points
      localMinAmount = 0.0;
      localMaxAmount = 100000.0;
      spots.add(const FlSpot(0, 0));
      spots.add(FlSpot(maxX(dropdownValue), 0));
    }

    for (var spot in spots) {
      if (spot.y < localMinAmount) {
        localMinAmount = spot.y;
      }
      if (spot.y > localMaxAmount) {
        localMaxAmount = spot.y;
      }
    }

    // Finally, store them in class-level variables (so we can use them in the build method)
    setState(() {
      _minAmount = localMinAmount;
      _maxAmount = localMaxAmount;
    });
  }

  @override
  Widget build(BuildContext context) {
    AppContent.watch(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          // Client selection buttons
          buildClientButtonsRow(
            context,
            allClients,
            selectedClient,
            (client) {
              setState(() {
                selectedClient = client;
                selectedGraph = client.graphs?.first;
                selectedAccount = selectedGraph?.account;
                _prepareGraphPoints();
              });
            },
            _getInitials,
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 30, 41, 59),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, // Align to start
              children: [
                const SizedBox(height: 10),
                // Header section with title and dropdowns
                Padding(
                  padding: const EdgeInsets.all(5.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1) Row with "Asset Timeline" label and a date/time dropdown to its right
                      _buildAssetTimelineRow(),
                      const SizedBox(height: 28),
                      // 2) Row with "Account" label and a dropdown button to its right
                      _buildAccountModalButton(),
                      const SizedBox(height: 15),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                // Line chart container
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.only(right: 20, bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: LineChart(
                        LineChartData(
                          gridData: _buildGridData(),
                          titlesData: titlesData,
                          borderData: FlBorderData(show: false),
                          minX: 0,
                          maxX: maxX(dropdownValue),
                          minY: calculateDynamicMin(_minAmount),
                          maxY: calculateDynamicMax(_maxAmount),
                          lineBarsData: [_buildLineChartBarData()],
                          lineTouchData: _buildLineTouchData(),
                        ),
                      ),
                    ),
                  ),
                ),
                // Date range text
                const SizedBox(height: 20),
                keyAndLogoRow(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget keyAndLogoRow() => Padding(
        padding: const EdgeInsets.fromLTRB(10.0, 0, 0, 10),
        child: Center(
            child: Row(
          crossAxisAlignment:
              CrossAxisAlignment.end, // Align children to the bottom
          mainAxisAlignment: MainAxisAlignment.center, // Center horizontally
          children: [
            // Date range text
            _buildDateRangeText(),
          ],
        )),
      );

  Widget _buildAccountModalButton() {
    // If no client or no graphs, just show "No accounts"
    if (selectedClient == null ||
        selectedClient!.graphs == null ||
        selectedClient!.graphs!.isEmpty) {
      return Text(
        AppContent.text(
            'text.screens.analytics.components.line_chart.no_accounts_f34b92'),
        style: const TextStyle(color: Colors.white),
      );
    }

    final graphs = selectedClient!.graphs!;

    // If there are exactly 2 graphs, pick the non-cumulative one by default
    if (graphs.length == 2) {
      // For example, we assume the 'title' or 'name' can identify cumulative
      // Adjust the check as needed based on your graph model
      final nonCumulative = graphs.firstWhere(
        (graph) => graph.account.toLowerCase() != 'cumulative',
        orElse: () => graphs.first,
      );
      selectedAccount = nonCumulative.account;
      selectedGraph = nonCumulative;
    }
    // Otherwise, fall back to the original logic if selectedAccount is still null
    if (selectedAccount == null) {
      selectedAccount = graphs.first.account;
      selectedGraph = graphs.first;
    }

    final currentAccountLabel = selectedAccount!.length > 20
        ? _getInitials(selectedAccount!)
        : selectedAccount!;

    return GestureDetector(
      onTap: graphs.length == 2
          ? null
          : () => _showAccountModalSheet(context, graphs),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white30, width: 2),
        ),
        child: Row(
          children: [
            Text(
              currentAccountLabel,
              style: const TextStyle(
                color: Colors.white,
                fontFamily: 'Titillium Web',
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            if (graphs.length > 2)
              const RotatedBox(
                quarterTurns: 3,
                child: Icon(
                  Icons.arrow_back_ios_rounded,
                  color: Colors.white30,
                  size: 22,
                ),
              )
            else
              const SizedBox(width: 10),
          ],
        ),
      ),
    );
  }

  void _showAccountModalSheet(BuildContext context, List<Graph> graphs) {
    // Create a copy of the graphs list to modify
    List<Graph> availableGraphs = List.from(graphs);

    // If the user has only 2 accounts, remove the one titled "Cumulative"
    if (availableGraphs.length == 2) {
      availableGraphs = availableGraphs
          .where((g) => g.account.toLowerCase() != 'cumulative')
          .toList();
    }

    showModalBottomSheet(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      backgroundColor: AppColors.defaultBlueGray800,
      context: context,
      builder: (BuildContext ctx) => Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: Container(
          height: MediaQuery.of(ctx).size.height * 0.5,
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
          ),
          child: ListView.builder(
            itemCount: availableGraphs.length,
            itemBuilder: (context, index) {
              final g = availableGraphs[index];
              final accountLabel =
                  g.account.length > 20 ? _getInitials(g.account) : g.account;
              final isSelected = (selectedAccount == g.account);

              return ListTile(
                title: Text(
                  accountLabel,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.white70,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                    fontFamily: 'Titillium Web',
                    fontSize: 18,
                  ),
                ),
                onTap: () {
                  setState(() {
                    selectedAccount = g.account;
                    selectedGraph = g;
                    _prepareGraphPoints();
                  });
                  Navigator.pop(context);
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Widget buildClientButtonsRow(
    BuildContext context,
    List<Client> allClients,
    Client? selectedClient,
    Function(Client) onClientSelected,
    String Function(String) getInitials,
  ) {
    if (allClients.isEmpty) {
      return Text(
        AppContent.text(
            'text.screens.analytics.components.line_chart.no_clients_available_58aacd'),
        style: const TextStyle(color: Colors.white),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: allClients.map((clientItem) {
          final displayName =
              '${clientItem.firstName} ${clientItem.lastName}'.trim();
          final isSelected = (selectedClient == clientItem);

          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: InkWell(
              onTap: () => onClientSelected(clientItem),
              borderRadius: BorderRadius.circular(30),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.defaultBlue500
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color:
                        isSelected ? AppColors.defaultBlue500 : Colors.white30,
                    width: 1,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8.0, 0, 8, 0),
                  child: Row(
                    children: [
                      const AppContentImage(
                        'assets/icons/single_person.svg',
                        width: 16,
                        height: 16,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        displayName.length > 20
                            ? getInitials(displayName)
                            : displayName,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight:
                              isSelected ? FontWeight.w700 : FontWeight.w300,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  /// 3) Row with "Asset Timeline" label and a date/time dropdown to its right
  Widget _buildAssetTimelineRow() => Row(
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppContent.text(
                    'text.screens.analytics.components.line_chart.asset_timeline_291567'),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const Spacer(),
          _buildTimeFilter(context),
        ],
      );

  /// Custom "time filter" widget that shows a bottom sheet when tapped.
  Widget _buildTimeFilter(BuildContext context) {
    // Display text for the currently selected option
    final selectedText = _getTimeLabel(dropdownValue);

    return GestureDetector(
      onTap: () => _showTimeOptionsBottomSheet(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.defaultBlueGray500, width: 1),
        ),
        child: Padding(
          padding: const EdgeInsets.all(4.0),
          child: Row(
            children: [
              Text(
                selectedText,
                style: const TextStyle(
                  fontFamily: 'Titillium Web',
                  color: AppColors.defaultBlueGray100,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(width: 10),
              const RotatedBox(
                quarterTurns: 3,
                child: Icon(
                  Icons.arrow_back_ios_rounded,
                  color: AppColors.defaultBlueGray500,
                  size: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Displays a bottom sheet with all the available time filter options.
  void _showTimeOptionsBottomSheet(BuildContext context) {
    var timeOptions = [
      'last-week',
      'last-month',
      'last-year',
      'year-to-date',
      'last-2-years'
    ];

    showModalBottomSheet(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      backgroundColor: AppColors.defaultBlueGray800,
      context: context,
      isScrollControlled: true, // allows the sheet to size itself appropriately
      builder: (BuildContext ctx) => SafeArea(
        top: false,
        child: Container(
          decoration: const BoxDecoration(
            color: AppColors.defaultBlueGray800,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
          ),
          // Use a Column with mainAxisSize.min so the modal only grows as tall as needed
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              // Here we use ListView with shrinkWrap and no Expanded
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: timeOptions.length,
                  itemBuilder: (context, index) {
                    final option = timeOptions[index];
                    final textLabel = _getTimeLabel(option);
                    final isSelected = (dropdownValue == option);

                    return ListTile(
                      title: Text(
                        textLabel,
                        style: TextStyle(
                          fontFamily: 'Titillium Web',
                          color: isSelected ? Colors.white : Colors.white70,
                          fontSize: 16,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        setState(() {
                          dropdownValue = option;
                          _prepareGraphPoints();
                        });
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Returns the label for the selected time filter option.
  ///
  /// This method returns a human-readable label for the selected time filter option.
  String _getTimeLabel(String option) {
    switch (option) {
      case 'last-week':
        return AppContent.text(
            'text.screens.analytics.components.line_chart.last_week_bc159a');
      case 'last-month':
        return AppContent.text(
            'text.screens.analytics.components.line_chart.last_month_20fe4f');
      case 'last-year':
        return AppContent.text(
            'text.screens.analytics.components.line_chart.last_year_ab9f82');
      case 'year-to-date':
        return AppContent.text(
            'text.screens.analytics.components.line_chart.year_to_date_c84334');
      case 'last-2-years':
        return AppContent.text(
            'text.screens.analytics.components.line_chart.last_2_years_047f9e');
      default:
        return 'Unknown';
    }
  }

  /// Returns the initials for the given name.
  ///
  String _getInitials(String name) {
    List<String> names = name.split(' ');
    if (names.length == 1) {
      return names[0];
    }
    String firstName = names.first;
    String lastInitial =
        names.length > 1 ? '${names.last[0].toUpperCase()}.' : '';
    return '$firstName $lastInitial';
  }

  /// Builds the grid data for the line chart.
  ///
  /// Configures the appearance of the horizontal grid lines on the chart.
  FlGridData _buildGridData() => FlGridData(
        show: true,
        drawVerticalLine: false,
        getDrawingHorizontalLine: (value) => const FlLine(
          color: Color.fromARGB(255, 102, 102, 102),
          strokeWidth: 0.5,
        ),
      );

  /// Configures the titles data for the line chart axes.
  ///
  /// This includes settings for the left, right, top, and bottom titles (labels).
  FlTitlesData get titlesData => FlTitlesData(
        topTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 55,
            getTitlesWidget: (value, meta) {
              // Hide top (max) and bottom (min) labels
              if (value == meta.min || value == meta.max) {
                return const SizedBox.shrink();
              }
              return Padding(
                padding: const EdgeInsets.only(right: 5),
                child: Text(
                  abbreviateNumber(value),
                  textAlign: TextAlign.center,
                ),
              );
            },
          ),
        ),
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: getBottomTitleInterval(dropdownValue),
            getTitlesWidget: bottomTitlesWidget,
          ),
        ),
      );

  /// Builds the line chart bar data, which defines the appearance and behavior of the line.
  ///
  /// This includes settings for the line's color, width, dot appearance, and the area below the line.
  LineChartBarData _buildLineChartBarData() => LineChartBarData(
        spots: spots,
        isCurved: false,
        isStepLineChart: true,
        lineChartStepData: const LineChartStepData(stepDirection: 0),
        barWidth: 3,
        color: AppColors.defaultBlue300,
        isStrokeCapRound: true,
        dotData: FlDotData(
          show: false,
          getDotPainter: (spot, percent, barData, index) {
            if (spot.x == 0 || spot.x == maxX(dropdownValue)) {
              // Hide dots for the starting and ending points
              return FlDotCirclePainter(
                radius: 0,
                color: Colors.transparent,
                strokeWidth: 0,
                strokeColor: Colors.transparent,
              );
            }
            // Show dots only if there are actual data points
            if (selectedGraph != null &&
                selectedGraph!.graphPoints.isNotEmpty) {
              return FlDotCirclePainter(
                radius: 4,
                color: AppColors.defaultBlue300,
                strokeWidth: 2,
                strokeColor: Colors.white,
              );
            } else {
              // Hide dots when there are no data points
              return FlDotCirclePainter(
                radius: 0,
                color: Colors.transparent,
                strokeWidth: 0,
                strokeColor: Colors.transparent,
              );
            }
          },
        ),
        belowBarData: BarAreaData(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.defaultBlue300,
              AppColors.defaultBlue500,
              AppColors.defaultBlue500.withOpacity(0.2),
            ],
          ),
          show: true,
        ),
      );

  /// Configures the touch behavior and tooltips for the line chart.
  ///
  /// This includes settings for how tooltips appear when the user interacts with the chart.
  LineTouchData _buildLineTouchData() => LineTouchData(
        touchTooltipData: LineTouchTooltipData(
          tooltipRoundedRadius: 16.0,
          getTooltipItems: (List<LineBarSpot> touchedSpots) =>
              touchedSpots.map((barSpot) {
            if (barSpot.x == 0 || barSpot.x == maxX(dropdownValue)) {
              // Exclude the starting and ending data points from showing tooltip
              return null;
            }
            final yValue = barSpot.y;
            final xValue = barSpot.x;
            final formattedYValue =
                NumberFormat.currency(symbol: '\$').format(yValue);

            DateTime dateTime =
                calculateDateTimeFromXValue(xValue, dropdownValue);
            final formattedDate = DateFormat('MMM dd').format(dateTime);

            return LineTooltipItem(
              '$formattedYValue\n$formattedDate',
              const TextStyle(
                color: AppColors.defaultBlue300,
                fontWeight: FontWeight.bold,
                fontFamily: 'Titillium Web',
                fontSize: 16,
              ),
            );
          }).toList(),
        ),
        getTouchedSpotIndicator:
            (LineChartBarData barData, List<int> spotIndexes) =>
                spotIndexes.map((index) {
          final FlSpot spot = barData.spots[index];
          if (spot.x == 0 || spot.x == maxX(dropdownValue)) {
            // Exclude the starting and ending data points from touch indicators
            return null;
          }
          return const TouchedSpotIndicatorData(
            FlLine(color: Colors.white, strokeWidth: 2),
            FlDotData(show: false),
          );
        }).toList(),
        handleBuiltInTouches: true,
      );

  /// Widget for displaying the bottom axis titles.
  ///
  /// This method formats and returns the appropriate labels for the x-axis based on the time frame.
  Widget bottomTitlesWidget(double value, TitleMeta meta) {
    DateTime dateTime = calculateDateTimeFromXValue(value, dropdownValue);
    String text = '';

    if (dropdownValue == 'last-year') {
      if (value == 0) {
        text = DateFormat('MMM yyyy').format(dateTime);
      } else if (value == maxX(dropdownValue) / 2) {
        text = DateFormat('MMM yyyy').format(calculateDateTimeFromXValue(
            maxX(dropdownValue) / 2, dropdownValue));
      } else if (value == maxX(dropdownValue)) {
        text = DateFormat('MMM yyyy').format(
            calculateDateTimeFromXValue(maxX(dropdownValue), dropdownValue));
      }
    } else if (dropdownValue == 'year-to-date') {
      if (value == 0) {
        text = DateFormat('MMM dd').format(dateTime);
      } else if (value == maxX(dropdownValue)) {
        text = DateFormat('MMM dd').format(
            calculateDateTimeFromXValue(maxX(dropdownValue), dropdownValue));
      }
    } else if (dropdownValue == 'last-2-years') {
      if (value == 0) {
        text = DateFormat('MMM yyyy').format(dateTime);
      } else if (value == maxX(dropdownValue) / 2) {
        text = DateFormat('MMM yyyy').format(calculateDateTimeFromXValue(
            maxX(dropdownValue) / 2, dropdownValue));
      } else if (value == maxX(dropdownValue)) {
        text = DateFormat('MMM yyyy').format(
            calculateDateTimeFromXValue(maxX(dropdownValue), dropdownValue));
      }
    } else {
      // Default weekly/daily
      text = DateFormat('MMM dd').format(dateTime);
    }

    if (text.isEmpty) return const SizedBox();
    return SideTitleWidget(
      axisSide: meta.axisSide,
      space: 3,
      child: Text(
        text,
        style: const TextStyle(
            fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
      ),
    );
  }

  /// Builds the date range text displayed below the chart.
  ///
  /// This method shows the selected date range and handles the case where no data is available.
  Widget _buildDateRangeText() {
    String displayText = '';
    DateTime now = DateTime.now();
    DateFormat dateFormat = DateFormat('MMM. dd, yy');

    switch (dropdownValue) {
      case 'last-week':
        {
          DateTime startOfWeek = now.subtract(Duration(days: now.weekday));
          DateTime endOfWeek = startOfWeek.add(const Duration(days: 6));
          displayText =
              '${dateFormat.format(startOfWeek)} - ${dateFormat.format(endOfWeek)}';
        }
        break;
      case 'last-month':
        {
          DateTime startOfLast30Days = now.subtract(const Duration(days: 29));
          DateTime endOfLast30Days = now;
          displayText =
              '${dateFormat.format(startOfLast30Days)} - ${dateFormat.format(endOfLast30Days)}';
        }
        break;
      case 'last-year':
        {
          DateTime startOfLastYear = DateTime(now.year - 1, now.month, now.day);
          displayText =
              '${dateFormat.format(startOfLastYear)} - ${dateFormat.format(now)}';
        }
        break;
      case 'year-to-date':
        {
          DateTime startOfThisYear = DateTime(now.year, 1, 1);
          displayText =
              '${dateFormat.format(startOfThisYear)} - ${dateFormat.format(now)}';
        }
        break;
      case 'last-2-years':
        {
          DateTime startOfTwoYearsAgo =
              DateTime(now.year - 2, now.month, now.day);
          displayText =
              '${dateFormat.format(startOfTwoYearsAgo)} - ${dateFormat.format(now)}';
        }
        break;
      default:
        displayText = 'Unknown';
        break;
    }

    return Container(
      color: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.only(right: 20.0),
        child: Column(
          children: [
            // Display the date range text
            Text(
              displayText,
              style: const TextStyle(
                fontSize: 18,
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontFamily: 'Titillium Web',
              ),
            ),
            // Show a message if no data is available
            if (spots.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 25),
                child: Row(
                  children: [
                    const SizedBox(width: 10),
                    const Icon(
                      Icons.circle,
                      size: 20,
                      color: AppColors.defaultBlue500,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      AppContent.text(
                          'text.screens.analytics.components.line_chart.no_data_available_for_this_time_period_bebf4f'),
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.w300,
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
