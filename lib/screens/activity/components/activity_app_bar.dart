import 'package:agq_app/content/app_content.dart';
import 'package:agq_app/content/content_image.dart';
import 'package:flutter/material.dart';
import 'package:agq_app/database/models/client_model.dart';
import 'package:agq_app/screens/notifications/notifications.dart';
import 'package:agq_app/screens/utils/resources.dart';

class ActivityAppBar extends StatefulWidget implements PreferredSizeWidget {
  final Client client;

  // Add two callbacks that the parent (ActivityPage) can pass in
  final VoidCallback onFilterPressed;
  final VoidCallback onSortPressed;

  const ActivityAppBar({
    super.key,
    required this.client,
    required this.onFilterPressed,
    required this.onSortPressed,
  });

  @override
  ActivityAppBarState createState() => ActivityAppBarState();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 95);
}

class ActivityAppBarState extends State<ActivityAppBar> {
  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      backgroundColor: const Color.fromARGB(255, 30, 41, 59),
      automaticallyImplyLeading: false,
      toolbarHeight: widget.preferredSize.height,
      expandedHeight: 0,
      snap: false,
      floating: true,
      pinned: true,
      flexibleSpace: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Activity Title + Bell icon
            Padding(
              padding: const EdgeInsets.only(left: 20, top: 17, right: 15),
              child: Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Text(
                      AppContent.text(
                          'text.screens.activity.components.activity_app_bar.activity_81c0d9'),
                      style: const TextStyle(
                        fontSize: 27,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Titillium Web',
                      ),
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const NotificationPage(),
                        ),
                      );
                    },
                    child: Container(
                      color: Colors.transparent,
                      child: Stack(
                        clipBehavior: Clip.none,
                        alignment: Alignment.center,
                        children: <Widget>[
                          const AppContentImage(
                            'assets/icons/bell.svg',
                            colorFilter: ColorFilter.mode(
                              Colors.white,
                              BlendMode.srcIn,
                            ),
                            height: 32,
                          ),
                          Positioned(
                            right: 0,
                            top: -6,
                            child: (widget.client.numNotifsUnread ?? 0) > 0
                                ? Container(
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF267DB5),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    constraints: const BoxConstraints(
                                      minWidth: 18,
                                      minHeight: 18,
                                    ),
                                    child: Text(
                                      '${widget.client.numNotifsUnread}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w800,
                                        fontFamily: 'Titillium Web',
                                        fontSize: 12,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  )
                                : Container(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const Spacer(),

            // Filter and Sort Buttons
            Padding(
              padding: const EdgeInsets.only(left: 20, right: 20, bottom: 15.0),
              child: Row(
                children: [
                  Expanded(child: _buildFilterButton()),
                  const SizedBox(width: 10),
                  Expanded(child: _buildSortButton()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the Filter button. You can style it however you wish.
  Widget _buildFilterButton() => ElevatedButton.icon(
        icon: const AppContentImage(
          'assets/icons/filter.svg',
          colorFilter: ColorFilter.mode(Colors.white, BlendMode.srcIn),
          height: 22,
          width: 22,
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color.fromARGB(255, 17, 24, 39),
          splashFactory: NoSplash.splashFactory,
          side: const BorderSide(color: Color.fromARGB(255, 17, 24, 39)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
          elevation: 0,
        ),
        label: Text(
          AppContent.text(
              'text.screens.activity.components.activity_app_bar.filter_d7decf'),
          style: const TextStyle(
            color: AppColors.defaultGray200,
            fontWeight: FontWeight.bold,
            fontSize: 18,
            fontFamily: 'Titillium Web',
          ),
        ),
        onPressed: widget.onFilterPressed,
      );

  /// Builds the Sort button.
  Widget _buildSortButton() => ElevatedButton.icon(
        icon: const AppContentImage(
          'assets/icons/sort.svg',
          colorFilter: ColorFilter.mode(Colors.white, BlendMode.srcIn),
          height: 22,
          width: 22,
        ),
        style: ElevatedButton.styleFrom(
          splashFactory: NoSplash.splashFactory,
          backgroundColor: const Color.fromARGB(255, 17, 24, 39),
          side: const BorderSide(color: Color.fromARGB(255, 17, 24, 39)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
          elevation: 0,
        ),
        label: Text(
          AppContent.text(
              'text.screens.activity.components.activity_app_bar.sort_adc4e9'),
          style: const TextStyle(
            color: AppColors.defaultGray200,
            fontWeight: FontWeight.bold,
            fontSize: 18,
            fontFamily: 'Titillium Web',
          ),
        ),
        onPressed: widget.onSortPressed,
      );
}
