import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shetravels/admin/data/controller/event_controller.dart';
import 'package:shetravels/admin/views/widgets/manage_event_head_text.dart';
import 'package:shetravels/admin/views/widgets/mobile_desktop_layout.dart';

List<Widget> notMobileWidget(
  bool isMobile,
  EventDashboardNotifier eventManager,
  WidgetRef ref,
  BuildContext context,
) {
  return [
    manageEventHeadText(isMobile, eventManager, ref, context),

    if (!isMobile) ...[
      const SizedBox(height: 16),
      Row(
        children: [
          buildStatCard(
            "Total Events",
            "${eventManager.events.length}",
            Icons.event,
            Colors.orange,
          ),
          const SizedBox(width: 16),
          buildStatCard(
            "Active",
            "${eventManager.events.length}",
            Icons.play_circle,
            Colors.green,
          ),
          const SizedBox(width: 16),
          buildStatCard("This Month", "0", Icons.calendar_month, Colors.blue),
        ],
      ),
    ],
  ];
}
