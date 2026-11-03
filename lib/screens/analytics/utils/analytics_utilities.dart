import 'package:agq_app/content/app_content.dart';

/// Calculate the x-coordinate value based on the date and selected time range.
///
/// The function calculates the proportional position on the x-axis for a given date
/// within the selected date range (`dropdownValue`), which determines the scale of the x-axis.
///
/// - Parameters:
///   - [dateTime]: The date to calculate the x-axis value for.
///   - [dropdownValue]: A string determining the time range, e.g., 'last-week', 'last-month'.
/// - Returns:
///   - A double representing the x-coordinate on the chart, or -1.0 if out of range.
double calculateXValue(DateTime dateTime, String dropdownValue) {
  DateTime now = DateTime.now();
  DateTime startDate;
  double totalPeriod;
  double maxXValue = maxX(dropdownValue);

  switch (dropdownValue) {
    case 'last-week':
      startDate = now.subtract(const Duration(days: 6));
      totalPeriod = 7;
      break;
    case 'last-month':
      startDate = DateTime(now.year, now.month - 1, now.day);
      totalPeriod = 30;
      break;
    case 'last-6-months':
      startDate = DateTime(now.year, now.month - 5, now.day);
      totalPeriod = 180;
      break;
    case 'last-year':
      startDate = DateTime(now.year - 1, now.month, now.day);
      totalPeriod = now.difference(startDate).inDays.toDouble();
      break;
    case 'year-to-date':
      startDate = DateTime(now.year, 1, 1);
      totalPeriod = now.difference(startDate).inDays.toDouble();
      break;
    case 'last-2-years':
      startDate = DateTime(now.year - 2, now.month, now.day);
      totalPeriod = now.difference(startDate).inDays.toDouble();
      break;
    default:
      return -1.0; // Return -1.0 if the range is not recognized.
  }

  if (dateTime.isBefore(startDate) || dateTime.isAfter(now)) {
    return -1.0;
  }

  double dayDifference = dateTime.difference(startDate).inDays.toDouble();
  return (dayDifference / totalPeriod) * maxXValue;
}

/// Convert an x-axis value back to a corresponding date within the selected range.
///
/// This function reverses the transformation applied in `calculateXValue`, converting an x-value
/// back to the corresponding date.
///
/// - Parameters:
///   - [xValue]: The x-axis value to convert.
///   - [dropdownValue]: The selected time range.
/// - Returns:
///   - A DateTime corresponding to the x-axis value.
DateTime calculateDateTimeFromXValue(double xValue, String dropdownValue) {
  DateTime now = DateTime.now();
  DateTime startDate;
  DateTime endDate;
  double totalPeriod;
  double maxXValue = maxX(dropdownValue);

  switch (dropdownValue) {
    case 'last-week':
      startDate = now.subtract(const Duration(days: 6));
      endDate = now;
      break;
    case 'last-month':
      startDate = now.subtract(const Duration(days: 29));
      endDate = now;
      break;
    case 'last-6-months':
      startDate = DateTime(now.year, now.month - 5, now.day);
      endDate = now;
      break;
    case 'last-year':
      startDate = DateTime(now.year - 1, now.month, now.day);
      endDate = now;
      break;
    case 'year-to-date':
      startDate = DateTime(now.year, 1, 1);
      endDate = now;
      break;
    case 'last-2-years':
      startDate = DateTime(now.year - 2, now.month, now.day);
      endDate = now;
      break;
    default:
      return DateTime.now();
  }

  totalPeriod = endDate.difference(startDate).inDays.toDouble();
  double dayDifference = (xValue / maxXValue) * totalPeriod;
  return startDate.add(Duration(days: dayDifference.round()));
}

/// Determines the maximum x-value based on the selected time range.
///
/// This function provides the upper limit of the x-axis based on the time range selected,
/// which corresponds to the number of intervals on the x-axis.
///
/// - Parameter:
///   - [dropdownValue]: The selected time range.
/// - Returns:
///   - The maximum x-value for the chart's x-axis.
double maxX(String dropdownValue) {
  switch (dropdownValue) {
    case 'last-week':
      return 6; // 7 days (0 to 6)
    case 'last-month':
      return 29; // 30 days (0 to 29)
    case 'last-6-months':
      return 5; // 6 months (0 to 5)
    case 'last-year':
      return 11; // 12 months (0 to 11)
    default:
      return 6; // Default value if no match
  }
}

/// Abbreviates large numbers for better display on chart axes.
///
/// This function formats large numbers into a shorter form using 'K' for thousands,
/// 'M' for millions. This is useful for displaying large figures concisely on chart axes.
///
/// - Parameter:
///   - [value]: The number to abbreviate.
/// - Returns:
///   - A string representing the abbreviated form of the number.
String abbreviateNumber(double value) {
  if (value >= 1e6) {
    return AppContent.text(
        'text.screens.analytics.utils.analytics_utilities.value1_m_79b41b',
        {'value1': (value / 1e6).toStringAsFixed(1)});
  } else if (value >= 1e3) {
    return AppContent.text(
        'text.screens.analytics.utils.analytics_utilities.value1_k_ccd2fd',
        {'value1': (value / 1e3).toStringAsFixed(1)});
  } else {
    return value.toStringAsFixed(0);
  }
}

/// Calculate the maximum Y value to use in charts, rounded to a suitable increment.
///
/// This function takes the maximum Y value from the data and adjusts it upwards to the nearest
/// 'nice' value to ensure that the chart's Y-axis ticks are neatly aligned and spaced.
///
/// - Parameter:
///   - [value]: The proposed maximum Y value from the data.
/// - Returns:
///   - The adjusted maximum Y value for the chart.
double calculateMaxY(double value) {
  double increment = 1.0;
  if (value >= 10000000) {
    increment = 1000000;
  } else if (value >= 1000000) {
    increment = 100000;
  } else if (value >= 100000) {
    increment = 10000;
  } else if (value >= 10000) {
    increment = 1000;
  } else if (value >= 1000) {
    increment = 100;
  } else if (value >= 500) {
    increment = 50;
  }

  return ((value / increment).ceil() * increment).toDouble();
}

/// Calculate a dynamic lower bound for the Y-axis.
/// If the minAmount is 0 or less, we simply return 0.
/// Otherwise, we subtract 10% of minAmount or 50k, whichever is smaller.
double calculateDynamicMin(double minAmount) {
  if (minAmount <= 0) return 0;
  // Subtract 10% or 50k (whichever is smaller)
  return minAmount - (minAmount * 0.1).clamp(0, 50000);
}

/// Calculate a dynamic upper bound for the Y-axis.
/// We add 10% of maxAmount or 500k, whichever is smaller.
/// (No more calls to calculateMaxY.)
double calculateDynamicMax(double maxAmount) {
  double buffer = (maxAmount * 0.1).clamp(0, 500000);
  return maxAmount + buffer;
}

/// Determine the interval at which to show axis titles based on the chart's x-axis range.
///
/// This function determines the spacing between labels on the x-axis based on the selected time range,
/// ensuring that labels are neither too sparse nor too densely packed.
///
/// - Parameter:
///   - [dropdownValue]: The selected time range.
/// - Returns:
///   - The interval at which to place x-axis labels.
double getBottomTitleInterval(String dropdownValue) {
  switch (dropdownValue) {
    case 'last-week':
      return maxX(dropdownValue) / 2; // Label every other day
    case 'last-month':
      return maxX(dropdownValue) / 2; // Start and end of the month
    case 'last-6-months':
      return maxX(dropdownValue) / 2.5; // Approximately every two months
    case 'last-year':
      return maxX(dropdownValue) / 2; // Start, middle, end of the year
    default:
      return 1; // Default case for unspecified ranges
  }
}
