import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shetravels/admin/data/controller/event_controller.dart';
import 'package:shetravels/admin/data/event_model.dart';
import 'package:shetravels/admin/views/widgets/build_event.dart';

/// Mobile: stacked layout
Widget buildMobileLayout(
  Event event,
  BuildContext context,
  WidgetRef ref,
  EventDashboardNotifier eventManager,
) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _buildEventImage(event),
      Padding(
        padding: const EdgeInsets.all(16),
        child: buildEventDetails(
          event,
          isMobile: true,
          context: context,
          ref: ref,
          eventManager: eventManager,
        ),
      ),
    ],
  );
}

/// Desktop/Tablet: side-by-side layout
Widget buildDesktopLayout(
  Event event,
  BuildContext context,
  WidgetRef ref,
  EventDashboardNotifier eventManager,
) {
  return Row(
    children: [
      Expanded(flex: 2, child: _buildEventImage(event)),
      Expanded(
        flex: 3,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: buildEventDetails(
            event,
            isMobile: false,
            context: context,
            ref: ref,
            eventManager: eventManager,
          ),
        ),
      ),
    ],
  );
}

/// Event image with shimmer loading & fallback
Widget _buildEventImage(Event event) {
  return Stack(
    children: [
      AspectRatio(
        aspectRatio: 16 / 9,
        child: Image.network(
          event.imageUrl,
          fit: BoxFit.cover,
          width: double.infinity,
          errorBuilder:
              (context, error, stack) => Container(
                color: Colors.purple.shade100,
                child: const Icon(Icons.event, size: 60, color: Colors.purple),
              ),
          loadingBuilder: (context, child, loading) {
            if (loading == null) return child;
            return Container(
              color: Colors.purple.shade50,
              child: const Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.purple,
                ),
              ),
            );
          },
        ),
      ),
      Positioned(
        right: 12,
        top: 12,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.green.shade600,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.green.shade200,
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Text(
            "\$${(event.price / 100).toStringAsFixed(2)}",
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    ],
  );
}

Widget buildEventCard(
  Event event,
  int index,
  BuildContext context,
  WidgetRef ref,
  EventDashboardNotifier eventManager,
) {
  final size = MediaQuery.of(context).size;
  final isMobile = size.width < 600;

  return AnimatedContainer(
    duration: Duration(milliseconds: 400 + (index * 120)),
    curve: Curves.easeOutCubic,
    margin: const EdgeInsets.only(bottom: 20),
    child: Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.85),
            Colors.purple.shade50.withOpacity(0.6),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child:
            isMobile
                ? buildMobileLayout(event, context, ref, eventManager)
                : buildDesktopLayout(event, context, ref, eventManager),
      ),
    ),
  );
}

Widget buildStatCard(String title, String value, IconData icon, Color color) {
  return Expanded(
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 12,
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
