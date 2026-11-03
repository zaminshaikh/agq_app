// ignore_for_file: deprecated_member_use

import 'package:agq_app/content/app_content.dart';
import 'package:agq_app/content/content_image.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:agq_app/database/models/client_model.dart';
import 'package:agq_app/screens/utils/resources.dart';
import 'package:agq_app/screens/utils/utilities.dart';

class AssetsStructureSection extends StatelessWidget {
  final Client client;
  final String fundName;
  final Map<String, double> accountSums = {};

  AssetsStructureSection({
    super.key,
    required this.client,
    required this.fundName,
  });

  @override
  Widget build(BuildContext context) {
    // 1) Gather all the account amounts across this client and any connected users
    double overallTotal = 0;

    // Threshold for displaying a slice in the pie chart
    const double thresholdPercent = 2.0;

    // Helper to add the specified fund’s assets to the map
    void addFundAssetsFromClient(Client client) {
      final fund = client.assets?.funds[fundName];
      if (fund == null) return;

      fund.assets.forEach((_, asset) {
        final amount = asset.amount;
        final accountName =
            '${client.firstName} ${client.lastName} - ${asset.displayTitle}'; // <- use the asset’s displayTitle
        accountSums[accountName] = (accountSums[accountName] ?? 0) + amount;
        overallTotal += amount;
      });
    }

    // Main client
    addFundAssetsFromClient(client);

    // Connected users
    if (client.connectedUsers != null) {
      for (final user in client.connectedUsers!) {
        if (user != null) {
          addFundAssetsFromClient(user);
        }
      }
    }

    // 2) Convert each account to a pie slice
    final List<PieChartSectionData> sections = [];
    final List<_AccountSlice> sliceData = [];

    // 3) Add a “hidden” slice for any accounts below the threshold
    final List<_AccountSlice> hiddenSliceData = [];

    // Provide a color palette for slices
    final colorPalette = <Color>[
      const Color(0xFF0D5EAF),
      const Color(0xFF3199DD),
      const Color.fromARGB(255, 103, 187, 243),
      const Color.fromARGB(255, 39, 71, 100),
      const Color.fromARGB(255, 30, 116, 84),
      const Color.fromARGB(255, 12, 78, 18),
      const Color.fromARGB(255, 91, 11, 14),
      AppColors.defaultRed400,
      const Color.fromARGB(255, 141, 141, 141),
      const Color.fromARGB(255, 115, 128, 141),
      const Color(0xFF0D3B5F),
      const Color(0xFF5BB7F0),
      const Color(0xFF0B2E47),
      const Color(0xFF90D5F7),
      const Color(0xFFD3EEFF),
    ];

    // Two separate indices: one for visible slices, one for hidden slices
    int visibleIdx = 0;
    int hiddenIdx = 0;

    if (overallTotal > 0) {
      // Loop over "displayNameSums" and decide which slices are hidden vs visible
      accountSums.forEach((displayName, sum) {
        final percent = (sum / overallTotal) * 100;

        if (percent < thresholdPercent) {
          // Get color from the back of the palette for hidden slices
          final color = colorPalette[
              colorPalette.length - 1 - (hiddenIdx % colorPalette.length)];
          hiddenIdx++;

          hiddenSliceData.add(
            _AccountSlice(
              accountName: displayName,
              color: color,
              percentage: percent,
            ),
          );
        } else {
          // Get color from the front of the palette for visible slices
          final color = colorPalette[visibleIdx % colorPalette.length];
          visibleIdx++;

          sections.add(
            PieChartSectionData(
              color: color,
              radius: 25,
              value: percent,
              showTitle: false,
            ),
          );
          sliceData.add(
            _AccountSlice(
              accountName: displayName,
              color: color,
              percentage: percent,
            ),
          );
        }
      });
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(15, 15, 15, 20),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 30, 41, 59),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          const SizedBox(height: 10),
          Row(
            children: [
              const SizedBox(width: 5),
              Text(
                AppContent.text(
                    'text.components.assets_structure_section.assets_structure_53d0db'),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontFamily: 'Titillium Web',
                ),
              ),
              const Spacer(),
              Row(
                children: [
                  if (fundName.toLowerCase() == 'agq')
                    const Padding(
                      padding: EdgeInsets.only(right: 10, top: 5),
                      child: AppContentImage(
                        'assets/icons/agq_logo.svg',
                        color: Colors.white,
                        height: 25,
                        width: 25,
                      ),
                    )
                  else
                    const Padding(
                      padding: EdgeInsets.only(right: 10, top: 5),
                      child: AppContentImage(
                        'assets/icons/ak1_logo.svg',
                        color: Colors.white,
                        height: 25,
                        width: 25,
                      ),
                    ),
                ],
              )
            ],
          ),

          const SizedBox(height: 60),

          // Pie chart with a center label
          SizedBox(
            width: 250,
            height: 250,
            child: Stack(
              children: [
                PieChart(
                  PieChartData(
                    startDegreeOffset: 120,
                    centerSpaceRadius: 100,
                    sectionsSpace: 10,
                    sections: sections, // Our newly built list
                  ),
                ),
                // “Total” in the center
                Align(
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        AppContent.text(
                            'text.components.assets_structure_section.total_b25928'),
                        style: const TextStyle(
                          fontSize: 18,
                          color: Colors.white,
                          fontFamily: 'Titillium Web',
                        ),
                      ),
                      Text(
                        currencyFormat(overallTotal),
                        style: const TextStyle(
                          fontSize: 22,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Titillium Web',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),

          // If we have no data, show a “No data” message
          if (overallTotal == 0)
            Text(
              AppContent.text(
                  'text.components.assets_structure_section.no_data_available_for_this_fund_4b86b9'),
              style: const TextStyle(color: Colors.white),
            )
          else ...[
            // Otherwise, show the table of slices
            Row(
              children: [
                const SizedBox(width: 30),
                Text(
                  AppContent.text(
                      'text.components.assets_structure_section.account_85dfa3'),
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color.fromARGB(255, 216, 216, 216),
                    fontFamily: 'Titillium Web',
                  ),
                ),
                const Spacer(),
                const Text(
                  '%',
                  style: TextStyle(
                    fontSize: 16,
                    color: Color.fromARGB(255, 216, 216, 216),
                    fontFamily: 'Titillium Web',
                  ),
                ),
                const SizedBox(width: 10),
              ],
            ),
            const SizedBox(height: 5),
            const Divider(
              thickness: 1.2,
              height: 1,
              color: Color.fromARGB(255, 102, 102, 102),
            ),
            const SizedBox(height: 10),
            Column(
              children: sliceData.map((slice) {
                final pctString = slice.percentage.toStringAsFixed(1);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Row(
                    children: [
                      Icon(
                        Icons.circle,
                        size: 20,
                        color: slice.color,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        slice.accountName,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Titillium Web',
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '$pctString%',
                        style: const TextStyle(
                          fontSize: 15,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Titillium Web',
                        ),
                      ),
                      const SizedBox(width: 10),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
          if (hiddenSliceData.isNotEmpty) ...[
            const SizedBox(height: 20),
            Row(
              children: [
                const SizedBox(width: 30),
                Text(
                  AppContent.text(
                      'text.components.assets_structure_section.not_shown_4a382a'),
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color.fromARGB(255, 216, 216, 216),
                    fontFamily: 'Titillium Web',
                  ),
                ),
                const Spacer(),
                const Text(
                  '%',
                  style: TextStyle(
                    fontSize: 16,
                    color: Color.fromARGB(255, 216, 216, 216),
                    fontFamily: 'Titillium Web',
                  ),
                ),
                const SizedBox(width: 10),
              ],
            ),
            const SizedBox(height: 5),
            const Divider(
              thickness: 1.2,
              height: 1,
              color: Color.fromARGB(255, 102, 102, 102),
            ),
            const SizedBox(height: 10),
            Column(
              children: hiddenSliceData.map((slice) {
                final pctString = slice.percentage.toStringAsFixed(1);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Row(
                    children: [
                      Icon(
                        Icons.circle,
                        size: 20,
                        color: slice.color,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        slice.accountName,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Titillium Web',
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '$pctString%',
                        style: const TextStyle(
                          fontSize: 15,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Titillium Web',
                        ),
                      ),
                      const SizedBox(width: 10),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}

/// Helper class for building the “legend” of accounts below the chart.
class _AccountSlice {
  final String accountName;
  final Color color;
  final double percentage;
  _AccountSlice({
    required this.accountName,
    required this.color,
    required this.percentage,
  });
}
