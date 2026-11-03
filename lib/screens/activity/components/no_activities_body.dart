import 'package:agq_app/content/app_content.dart';
import 'package:flutter/material.dart';

Widget buildNoActivityMessage() => Padding(
      padding: const EdgeInsets.all(30.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          const Icon(
            Icons.info_outline,
            size: 50,
            color: Colors.grey,
          ),
          Text(
            AppContent.text(
                'text.screens.activity.components.no_activities_body.no_activities_57741f'),
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(
              height: 8), // Provides spacing between the text widgets
          Text(
            AppContent.text(
                'text.screens.activity.components.no_activities_body.please_adjust_your_filters_to_view_act_a64525'),
            style: const TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
