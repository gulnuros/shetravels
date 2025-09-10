import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shetravels/admin/data/controller/event_controller.dart';

ScaleTransition floatingActionWidget(
  EventDashboardNotifier eventManager,
  AnimationController fabAnimationController,
  BuildContext context,
  WidgetRef ref,
) {
  return ScaleTransition(
    scale: CurvedAnimation(
      parent: fabAnimationController,
      curve: Curves.elasticOut,
    ),
    child: Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.purple.shade400, Colors.deepPurple.shade600],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withOpacity(0.4),
            blurRadius: 12,
            spreadRadius: 2,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: FloatingActionButton.extended(
        onPressed: () {
          fabAnimationController.reverse().then((_) {
            eventManager.showAddDialog(context, ref);
            fabAnimationController.forward();
          });
        },
        backgroundColor: Colors.transparent,
        elevation: 0,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          "New Event",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    ),
  );
}
