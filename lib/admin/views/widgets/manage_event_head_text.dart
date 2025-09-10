import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shetravels/admin/data/controller/event_controller.dart';

Row manageEventHeadText(
  bool isMobile,
  EventDashboardNotifier eventManager,
  WidgetRef ref,
  BuildContext context,
) {
  return Row(
    children: [
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.event_available, color: Colors.white, size: 28),
      ),
      const SizedBox(width: 16),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Event Manager",
              style: TextStyle(
                color: Colors.white,
                fontSize: isMobile ? 20 : 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              "Manage your events with style",
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: isMobile ? 12 : 14,
              ),
            ),
          ],
        ),
      ),

      Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: () {
                ref.read(eventManagerDashboardProvider).isLoading
                    ? null
                    : ref
                        .read(eventManagerDashboardProvider)
                        .loadEvents(context);
              },
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.add, color: Colors.white),
              onPressed: () {
                ref.watch(eventManagerDashboardProvider).isLoading
                    ? null
                    : eventManager.showAddDialog(context, ref);
              },
            ),
          ),
        ],
      ),
    ],
  );
}
