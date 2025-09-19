// ====================
// ADMIN NEWSLETTER DASHBOARD (UI Completed)
// ====================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shetravels/news_letter/data/controller/news_letter_controller.dart';
import 'package:shetravels/news_letter/data/model/news_letter_model.dart';

class AdminNewsletterDashboard extends ConsumerStatefulWidget {
  const AdminNewsletterDashboard({Key? key}) : super(key: key);

  @override
  ConsumerState<AdminNewsletterDashboard> createState() =>
      _AdminNewsletterDashboardState();
}

class _AdminNewsletterDashboardState
    extends ConsumerState<AdminNewsletterDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final subscribersAsync = ref.watch(subscribersProvider);
    final newslettersAsync = ref.watch(newslettersProvider);
    final subscribersCountAsync = ref.watch(subscribersCountProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Newsletter Management',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade800,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Subscribers'),
            Tab(text: 'Newsletters'),
          ],
          labelColor: Colors.pink.shade400,
          unselectedLabelColor: Colors.grey.shade600,
          indicatorColor: Colors.pink.shade400,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(
            subscribersCountAsync,
            subscribersAsync,
            newslettersAsync,
          ),
          _buildSubscribersTab(subscribersAsync),
          _buildNewslettersTab(newslettersAsync),
        ],
      ),
      floatingActionButton:
          _tabController.index == 2
              ? FloatingActionButton.extended(
                onPressed: () => _showCreateNewsletterDialog(),
                backgroundColor: Colors.pink.shade400,
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text("Create Newsletter"),
              )
              : null,
    );
  }

  // ========================
  // OVERVIEW TAB
  // ========================
  Widget _buildOverviewTab(
    AsyncValue<int> subscribersCount,
    AsyncValue<List<NewsletterSubscriber>> subscribers,
    AsyncValue<List<Newsletter>> newsletters,
  ) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: ListView(
        children: [
          subscribersCount.when(
            data:
                (count) => _buildStatCard(
                  title: "Active Subscribers",
                  value: count.toString(),
                  color: Colors.pink.shade300,
                  icon: Icons.people,
                ),
            loading: () => const CircularProgressIndicator(),
            error: (e, _) => Text("Error: $e"),
          ),
          const SizedBox(height: 16),
          newsletters.when(
            data:
                (list) => _buildStatCard(
                  title: "Total Newsletters",
                  value: list.length.toString(),
                  color: Colors.orange.shade300,
                  icon: Icons.email,
                ),
            loading: () => const CircularProgressIndicator(),
            error: (e, _) => Text("Error: $e"),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [color.withOpacity(0.8), color]),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(icon, size: 40, color: Colors.white),
            const SizedBox(width: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                ),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ========================
  // SUBSCRIBERS TAB
  // ========================
  Widget _buildSubscribersTab(
    AsyncValue<List<NewsletterSubscriber>> subscribers,
  ) {
    return subscribers.when(
      data:
          (list) => ListView.builder(
            itemCount: list.length,
            itemBuilder: (context, index) {
              final subscriber = list[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.pink.shade100,
                    child: Icon(Icons.person, color: Colors.pink.shade600),
                  ),
                  title: Text(subscriber.email),
                  subtitle: Text(
                    "Joined on ${DateFormat.yMMMd().format(subscriber.subscribedAt)}",
                  ),
                  trailing: IconButton(
                    icon: Icon(Icons.delete, color: Colors.red.shade400),
                    onPressed: () {
                      ref
                          .read(newsletterControllerProvider.notifier)
                          .unsubscribeEmail(subscriber.email);
                    },
                  ),
                ),
              );
            },
          ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text("Error: $e")),
    );
  }

  // ========================
  // NEWSLETTERS TAB
  // ========================
  Widget _buildNewslettersTab(AsyncValue<List<Newsletter>> newsletters) {
    return newsletters.when(
      data:
          (list) => ListView.builder(
            itemCount: list.length,
            itemBuilder: (context, index) {
              final newsletter = list[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  leading: Icon(
                    Icons.email_outlined,
                    color: Colors.pink.shade400,
                    size: 30,
                  ),
                  title: Text(
                    newsletter.title,
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    "Created on ${DateFormat.yMMMd().format(newsletter.createdAt)}",
                  ),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == "edit") {
                        // TODO: Add edit dialog
                      } else if (value == "delete") {
                        ref
                            .read(newsletterControllerProvider.notifier)
                            .deleteNewsletter(newsletter.id);
                      }
                    },
                    itemBuilder:
                        (context) => [
                          const PopupMenuItem(
                            value: "edit",
                            child: Text("Edit"),
                          ),
                          const PopupMenuItem(
                            value: "delete",
                            child: Text("Delete"),
                          ),
                        ],
                  ),
                ),
              );
            },
          ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text("Error: $e")),
    );
  }

  // ========================
  // CREATE NEWSLETTER DIALOG
  // ========================
  Future<void> _showCreateNewsletterDialog() async {
    final titleController = TextEditingController();
    final contentController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text("Create Newsletter"),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: "Title"),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: contentController,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    labelText: "Content",
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: const Text("Cancel"),
              onPressed: () => Navigator.pop(context),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.pink.shade400,
              ),
              child: const Text("Save"),
              onPressed: () {
                final newsletter = Newsletter(
                  id: "",
                  title: titleController.text,
                  content: contentController.text,
                  createdAt: DateTime.now(),
                  createdBy: '',
                );
                ref
                    .read(newsletterControllerProvider.notifier)
                    .createNewsletter(newsletter);
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }
}
