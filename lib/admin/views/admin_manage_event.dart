import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shetravels/admin/data/controller/event_controller.dart';
import 'package:shetravels/admin/views/widgets/event_empty_widget.dart';
import 'package:shetravels/admin/views/widgets/floating_action_widget.dart';
import 'package:shetravels/admin/views/widgets/loading_event.dart';
import 'package:shetravels/admin/views/widgets/mobile_desktop_layout.dart';
import 'package:shetravels/admin/views/widgets/not_mobile_widget.dart';
import 'package:shetravels/admin/views/widgets/unauthenticated_user_widget.dart';

@RoutePage()
class AdminManageEventScreen extends StatefulHookConsumerWidget {
  const AdminManageEventScreen({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _AdminManageEventScreenState();
}

class _AdminManageEventScreenState extends ConsumerState<AdminManageEventScreen>
    with TickerProviderStateMixin {
  late AnimationController _fabAnimationController;
  late AnimationController _headerAnimationController;

  @override
  void initState() {
    super.initState();
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _headerAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    ref.read(eventManagerDashboardProvider).checkAuthAndLoadEvents(context);
    _headerAnimationController.forward();
  }

  @override
  void dispose() {
    _fabAnimationController.dispose();
    _headerAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final eventManager = ref.watch(eventManagerDashboardProvider);

    final isTablet = MediaQuery.of(context).size.width > 600;
    final isMobile = MediaQuery.of(context).size.width < 500;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.purple.shade50, Colors.blue.shade50, Colors.white],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Custom Header
              SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, -1),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(
                    parent: _headerAnimationController,
                    curve: Curves.easeOutBack,
                  ),
                ),
                child: Container(
                  padding: EdgeInsets.all(isMobile ? 16 : 24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.purple.shade600,
                        Colors.deepPurple.shade700,
                        Colors.indigo.shade800,
                      ],
                    ),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(32),
                      bottomRight: Radius.circular(32),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.purple.withOpacity(0.3),
                        blurRadius: 20,
                        spreadRadius: 5,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    children: notMobileWidget(
                      isMobile,
                      eventManager,
                      ref,
                      context,
                    ),
                  ),
                ),
              ),

              Expanded(
                child:
                    eventManager.isLoading
                        ? loadingEventWidget()
                        : eventManager.currentUser == null
                        ? unauthenticatedUserWidget(eventManager, context)
                        : eventManager.events.isEmpty
                        ? eventEmptyWidget(eventManager, context, ref)
                        : RefreshIndicator(
                          onRefresh: () async {
                            eventManager.loadEvents(context);
                          },
                          color: Colors.purple,
                          child: Padding(
                            padding: EdgeInsets.all(isMobile ? 16 : 24),
                            child:
                                isTablet
                                    ? GridView.builder(
                                      gridDelegate:
                                          const SliverGridDelegateWithFixedCrossAxisCount(
                                            crossAxisCount: 2,
                                            crossAxisSpacing: 16,
                                            mainAxisSpacing: 16,
                                            childAspectRatio: 1.2,
                                          ),
                                      itemCount: eventManager.events.length,
                                      itemBuilder:
                                          (context, index) => buildEventCard(
                                            eventManager.events[index],
                                            index,
                                            context,
                                            ref,
                                          ),
                                    )
                                    : ListView.builder(
                                      itemCount: eventManager.events.length,
                                      itemBuilder:
                                          (context, index) => buildEventCard(
                                            eventManager.events[index],
                                            index,
                                            context,
                                            ref,
                                          ),
                                    ),
                          ),
                        ),
              ),
            ],
          ),
        ),
      ),

      // Floating Action Button
      floatingActionButton:
          eventManager.currentUser != null && !eventManager.isLoading
              ? floatingActionWidget(
                eventManager,
                _fabAnimationController,
                context,
                ref,
              )
              : null,
    );
  }
}
