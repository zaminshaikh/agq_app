import 'package:agq_app/content/app_content.dart';
import 'package:flutter/material.dart';
import 'package:agq_app/database/models/activity_model.dart';
import 'package:agq_app/screens/activity/activity.dart';
import 'package:agq_app/screens/dashboard/components/activity_card_item.dart';
import 'package:agq_app/screens/utils/resources.dart';

class ActivityTilesSection extends StatefulWidget {
  final List<Activity> activities;

  const ActivityTilesSection({required this.activities, super.key});

  @override
  ActivityTilesSectionState createState() => ActivityTilesSectionState();
}

class ActivityTilesSectionState extends State<ActivityTilesSection> {
  final ScrollController _scrollController = ScrollController();
  double _gradientOpacity = 0.8;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.atEdge) {
      bool isEnd = _scrollController.position.pixels != 0;
      setState(() {
        _gradientOpacity = isEnd ? 0.0 : 0.8;
      });
    } else {
      double maxScrollExtent = _scrollController.position.maxScrollExtent;
      double currentScrollPosition = _scrollController.position.pixels;
      double threshold = maxScrollExtent - 50; // Adjust the threshold as needed

      setState(() {
        _gradientOpacity = currentScrollPosition >= threshold ? 0.0 : 0.8;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    AppContent.watch(context);
    if (widget.activities.isEmpty) {
      return Container();
    }

    // ignore: sized_box_for_whitespace
    return Container(
      width: double.infinity, // Ensure the container takes up the full width
      height: 200, // Adjust the height as needed
      child: Stack(
        children: [
          ListView.builder(
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            itemCount: widget.activities.length +
                1, // Add one more item for the "View All" button
            itemBuilder: (context, index) {
              if (index < widget.activities.length) {
                return Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8.0), // Add some spacing between cards
                  child: ActivityCardItem(activity: widget.activities[index]),
                );
              } else {
                return Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12.0), // Add some spacing for the button
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          Navigator.pushReplacement(
                            context,
                            PageRouteBuilder(
                              pageBuilder:
                                  (context, animation, secondaryAnimation) =>
                                      const ActivityPage(),
                              transitionsBuilder: (context, animation,
                                      secondaryAnimation, child) =>
                                  child,
                            ),
                          );
                        },
                        child: Container(
                          color: Colors.transparent,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8.0,
                              vertical: 4.0), // Add padding to the container
                          child: Row(
                            children: [
                              Text(
                                AppContent.text(
                                    'text.screens.dashboard.components.three_recent_activities.view_all_efd835'),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(width: 2),
                              const Icon(
                                Icons.arrow_forward_ios,
                                size: 15,
                                color: Colors.blue,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }
            },
          ),
          Align(
            alignment: Alignment.centerRight,
            child: AnimatedOpacity(
              opacity: _gradientOpacity,
              duration: const Duration(
                  milliseconds: 300), // Adjust the duration as needed
              child: Container(
                width: 50, // Adjust the width of the gradient
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      Colors.transparent,
                      AppColors.defaultBlueGray900,
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
