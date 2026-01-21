import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shetravels/admin/data/controller/event_controller.dart';
import 'package:shetravels/admin/data/event_model.dart';
import 'package:shetravels/common/data/provider/payment_provider.dart';

Widget buildEventDetails(
  Event event, {
  required bool isMobile,
  required WidgetRef ref,
  required BuildContext context,
  required EventDashboardNotifier eventManager,
}) {
  final paymentNotifier = ref.watch(paymentNotifierProvider);

  return FutureBuilder<int>(
    future: paymentNotifier.getBookedCount(event.title),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Center(child: CircularProgressIndicator());
      }

      final bookedCount = snapshot.data ?? 0;
      final remainingSlots = event.availableSlots - bookedCount;
      final isSoldOut = remainingSlots <= 0;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            event.title,
            style: TextStyle(
              fontSize: isMobile ? 18 : 22,
              fontWeight: FontWeight.bold,
              color: Colors.purple.shade800,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.people_outline,
                size: 16,
                color: isSoldOut ? Colors.red.shade600 : Colors.teal.shade600,
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color:
                      isSoldOut
                          ? Colors.red.shade50
                          : remainingSlots <= 5
                          ? Colors.orange.shade50
                          : Colors.teal.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color:
                        isSoldOut
                            ? Colors.red.shade200
                            : remainingSlots <= 5
                            ? Colors.orange.shade200
                            : Colors.teal.shade200,
                  ),
                ),
                child: Text(
                  isSoldOut
                      ? 'Sold Out'
                      : '$remainingSlots of ${event.availableSlots} slots left',
                  style: TextStyle(
                    fontSize: isMobile ? 12 : 13,
                    fontWeight: FontWeight.w600,
                    color:
                        isSoldOut
                            ? Colors.red.shade700
                            : remainingSlots <= 5
                            ? Colors.orange.shade700
                            : Colors.teal.shade700,
                  ),
                ),
              ),
            ],
          ),
          if (event.price > 0) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(
                  Icons.attach_money,
                  size: 16,
                  color: Colors.green.shade600,
                ),
                const SizedBox(width: 6),
                Text(
                  '\$${(event.price / 100).toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: isMobile ? 13 : 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.green.shade600,
                  ),
                ),
              ],
            ),
          ],
          if (event.description.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              event.description,
              style: TextStyle(
                fontSize: isMobile ? 13 : 14,
                color: Colors.grey.shade600,
              ),
              maxLines: isMobile ? 3 : 4,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          SizedBox(height: 10),

          ElevatedButton(
            onPressed: () {
              ref.watch(eventManagerDashboardProvider).isLoading
                  ? null
                  : eventManager.showEditDialog(context, event, ref);
            },
            child: Text('Edit'),
          ),
        ],
      );
    },
  );
}
