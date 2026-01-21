

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shetravels/news_letter/data/controller/news_letter_controller.dart';
import 'package:shetravels/news_letter/data/model/news_letter_model.dart';

class AdminNewsletterDashboard extends ConsumerStatefulWidget {
  const AdminNewsletterDashboard({super.key});

  @override
  ConsumerState<AdminNewsletterDashboard> createState() => _AdminNewsletterDashboardState();
}

class _AdminNewsletterDashboardState extends ConsumerState<AdminNewsletterDashboard>
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
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Subscribers'),
            Tab(text: 'Newsletters'),
          ],
          labelColor: Colors.purple.shade400,
          unselectedLabelColor: Colors.grey.shade600,
          indicatorColor: Colors.purple.shade400,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(subscribersCountAsync, subscribersAsync, newslettersAsync),
          _buildSubscribersTab(subscribersAsync),
          _buildNewslettersTab(newslettersAsync),
        ],
      ),
      floatingActionButton: _tabController.index == 2
          ? FloatingActionButton.extended(
              onPressed: () => _showCreateNewsletterDialog(),
              backgroundColor: Colors.purple.shade400,
              icon: const Icon(Icons.add, color: Colors.white),
              label: Text(
                'Create Newsletter',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildOverviewTab(
    AsyncValue<int> subscribersCountAsync,
    AsyncValue<List<NewsletterSubscriber>> subscribersAsync,
    AsyncValue<List<Newsletter>> newslettersAsync,
  ) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Newsletter Analytics',
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 24),
          
          Row(
            children: [
              Expanded(
                child: _buildStatsCard(
                  'Total Subscribers',
                  subscribersCountAsync.when(
                    data: (count) => count.toString(),
                    loading: () => '...',
                    error: (_, __) => '0',
                  ),
                  Icons.people,
                  Colors.blue.shade400,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatsCard(
                  'Active Newsletters',
                  newslettersAsync.when(
                    data: (newsletters) => newsletters.where((n) => !n.isDraft).length.toString(),
                    loading: () => '...',
                    error: (_, __) => '0',
                  ),
                  Icons.email,
                  Colors.green.shade400,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatsCard(
                  'Draft Newsletters',
                  newslettersAsync.when(
                    data: (newsletters) => newsletters.where((n) => n.isDraft).length.toString(),
                    loading: () => '...',
                    error: (_, __) => '0',
                  ),
                  Icons.drafts,
                  Colors.orange.shade400,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 32),
          Text(
            'Recent Activity',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 16),
          
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: subscribersAsync.when(
                data: (subscribers) {
                  final recentSubscribers = subscribers.take(5).toList();
                  return ListView.builder(
                    itemCount: recentSubscribers.length,
                    itemBuilder: (context, index) {
                      final subscriber = recentSubscribers[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.purple.shade50,
                          child: Text(
                            subscriber.firstName?.isNotEmpty == true 
                                ? subscriber.firstName![0].toUpperCase()
                                : subscriber.email[0].toUpperCase(),
                            style: GoogleFonts.poppins(
                              color: Colors.purple.shade400,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        title: Text(
                          subscriber.firstName?.isNotEmpty == true
                              ? '${subscriber.firstName} ${subscriber.lastName ?? ''}'.trim()
                              : subscriber.email,
                          style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                        ),
                        subtitle: Text(
                          'Subscribed ${DateFormat.yMd().format(subscriber.subscribedAt)}',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: subscriber.isActive ? Colors.green.shade100 : Colors.red.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            subscriber.isActive ? 'Active' : 'Inactive',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: subscriber.isActive ? Colors.green.shade700 : Colors.red.shade700,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Center(
                  child: Text(
                    'Error loading recent activity: $error',
                    style: GoogleFonts.poppins(color: Colors.red),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubscribersTab(AsyncValue<List<NewsletterSubscriber>> subscribersAsync) {
    return subscribersAsync.when(
      data: (subscribers) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Newsletter Subscribers',
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  const Spacer(),
                  ElevatedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Export functionality coming soon!'),
                        ),
                      );
                    },
                    icon: const Icon(Icons.download),
                    label: const Text('Export CSV'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade400,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: subscribers.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.people_outline,
                                size: 64,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No subscribers yet',
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          itemCount: subscribers.length,
                          separatorBuilder: (context, index) => Divider(
                            color: Colors.grey.shade200,
                            height: 1,
                          ),
                          itemBuilder: (context, index) {
                            final subscriber = subscribers[index];
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.purple.shade50,
                                child: Text(
                                  subscriber.firstName?.isNotEmpty == true 
                                      ? subscriber.firstName![0].toUpperCase()
                                      : subscriber.email[0].toUpperCase(),
                                  style: GoogleFonts.poppins(
                                    color: Colors.purple.shade400,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              title: Text(
                                subscriber.firstName?.isNotEmpty == true
                                    ? '${subscriber.firstName} ${subscriber.lastName ?? ''}'.trim()
                                    : 'No name provided',
                                style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    subscriber.email,
                                    style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  Text(
                                    'Subscribed: ${DateFormat.yMd().add_jm().format(subscriber.subscribedAt)}',
                                    style: GoogleFonts.poppins(
                                      fontSize: 11,
                                      color: Colors.grey.shade500,
                                    ),
                                  ),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: subscriber.isActive 
                                          ? Colors.green.shade100 
                                          : Colors.red.shade100,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      subscriber.isActive ? 'Active' : 'Inactive',
                                      style: GoogleFonts.poppins(
                                        fontSize: 11,
                                        color: subscriber.isActive 
                                            ? Colors.green.shade700 
                                            : Colors.red.shade700,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  PopupMenuButton(
                                    itemBuilder: (context) => [
                                      if (subscriber.isActive)
                                        PopupMenuItem(
                                          value: 'deactivate',
                                          child: Row(
                                            children: [
                                              Icon(Icons.block, size: 16, color: Colors.red.shade600),
                                              const SizedBox(width: 8),
                                              const Text('Deactivate'),
                                            ],
                                          ),
                                        )
                                      else
                                        PopupMenuItem(
                                          value: 'activate',
                                          child: Row(
                                            children: [
                                              Icon(Icons.check_circle, size: 16, color: Colors.green.shade600),
                                              const SizedBox(width: 8),
                                              const Text('Activate'),
                                            ],
                                          ),
                                        ),
                                      PopupMenuItem(
                                        value: 'delete',
                                        child: Row(
                                          children: [
                                            Icon(Icons.delete, size: 16, color: Colors.red.shade600),
                                            const SizedBox(width: 8),
                                            const Text('Delete'),
                                          ],
                                        ),
                                      ),
                                    ],
                                    onSelected: (value) {
                                      if (value == 'deactivate') {
                                        ref.read(newsletterControllerProvider.notifier)
                                            .unsubscribeEmail(subscriber.email);
                                      } else if (value == 'delete') {
                                        _showDeleteConfirmation(subscriber);
                                      }
                                    },
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Text(
          'Error loading subscribers: $error',
          style: GoogleFonts.poppins(color: Colors.red),
        ),
      ),
    );
  }

  Widget _buildNewslettersTab(AsyncValue<List<Newsletter>> newslettersAsync) {
    return newslettersAsync.when(
      data: (newsletters) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Newsletters',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
              const SizedBox(height: 24),
              
              Expanded(
                child: newsletters.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.email_outlined,
                              size: 64,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No newsletters created yet',
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _showCreateNewsletterDialog(),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.purple.shade400,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Create Your First Newsletter'),
                            ),
                          ],
                        ),
                      )
                    : GridView.builder(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          childAspectRatio: 0.8,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                        itemCount: newsletters.length,
                        itemBuilder: (context, index) {
                          final newsletter = newsletters[index];
                          return _buildNewsletterCard(newsletter);
                        },
                      ),
              ),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Text(
          'Error loading newsletters: $error',
          style: GoogleFonts.poppins(color: Colors.red),
        ),
      ),
    );
  }

  Widget _buildNewsletterCard(Newsletter newsletter) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: newsletter.isDraft ? Colors.orange.shade200 : Colors.green.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: newsletter.isDraft ? Colors.orange.shade100 : Colors.green.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                newsletter.isDraft ? 'DRAFT' : 'SENT',
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: newsletter.isDraft ? Colors.orange.shade700 : Colors.green.shade700,
                ),
              ),
            ),
            
            const SizedBox(height: 12),
            Text(
              newsletter.title,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            
            const SizedBox(height: 8),
            Text(
              newsletter.content,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: Text(
                    DateFormat.yMd().format(newsletter.createdAt),
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ),
                PopupMenuButton(
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 16, color: Colors.blue.shade600),
                          const SizedBox(width: 8),
                          const Text('Edit'),
                        ],
                      ),
                    ),
                    if (newsletter.isDraft)
                      PopupMenuItem(
                        value: 'send',
                        child: Row(
                          children: [
                            Icon(Icons.send, size: 16, color: Colors.green.shade600),
                            const SizedBox(width: 8),
                            const Text('Send'),
                          ],
                        ),
                      ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 16, color: Colors.red.shade600),
                          const SizedBox(width: 8),
                          const Text('Delete'),
                        ],
                      ),
                    ),
                  ],
                  onSelected: (value) {
                    if (value == 'edit') {
                      _showEditNewsletterDialog(newsletter);
                    } else if (value == 'send') {
                      _showSendConfirmation(newsletter);
                    } else if (value == 'delete') {
                      _showDeleteNewsletterConfirmation(newsletter);
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateNewsletterDialog() {
    showDialog(
      context: context,
      builder: (context) => const CreateNewsletterDialog(),
    );
  }

  void _showEditNewsletterDialog(Newsletter newsletter) {
    showDialog(
      context: context,
      builder: (context) => CreateNewsletterDialog(newsletter: newsletter),
    );
  }

  void _showSendConfirmation(Newsletter newsletter) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Send Newsletter'),
        content: Text('Are you sure you want to send "${newsletter.title}" to all subscribers?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ref.read(newsletterControllerProvider.notifier).updateNewsletter(
                newsletter.id,
                {
                  'isDraft': false,
                  'sentAt': DateTime.now().toIso8601String(),
                },
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: Text('Send'),
          ),
        ],
      ),
    );
  }

  void _showDeleteNewsletterConfirmation(Newsletter newsletter) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Newsletter'),
        content: Text('Are you sure you want to delete "${newsletter.title}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ref.read(newsletterControllerProvider.notifier).deleteNewsletter(newsletter.id);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(NewsletterSubscriber subscriber) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Subscriber'),
        content: Text('Are you sure you want to delete ${subscriber.email}? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Delete'),
          ),
        ],
      ),
    );
  }
}


class CreateNewsletterDialog extends ConsumerStatefulWidget {
  final Newsletter? newsletter; 

  const CreateNewsletterDialog({super.key, this.newsletter});

  @override
  ConsumerState<CreateNewsletterDialog> createState() => _CreateNewsletterDialogState();
}

class _CreateNewsletterDialogState extends ConsumerState<CreateNewsletterDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _tagsController = TextEditingController();
  
  bool _isCreating = false;

  @override
  void initState() {
    super.initState();
    if (widget.newsletter != null) {
      _titleController.text = widget.newsletter!.title;
      _contentController.text = widget.newsletter!.content;
      _tagsController.text = widget.newsletter!.tags.join(', ');
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  Future<void> _saveNewsletter({bool isDraft = true}) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isCreating = true;
    });

    try {
      final newsletter = Newsletter(
        id: widget.newsletter?.id ?? '',
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
        createdAt: widget.newsletter?.createdAt ?? DateTime.now(),
        createdBy: 'admin',
        isDraft: isDraft,
        tags: _tagsController.text
            .split(',')
            .map((tag) => tag.trim())
            .where((tag) => tag.isNotEmpty)
            .toList(),
      );

      if (widget.newsletter != null) {
        await ref.read(newsletterControllerProvider.notifier).updateNewsletter(
          widget.newsletter!.id,
          newsletter.toJson(),
        );
      } else {
        await ref.read(newsletterControllerProvider.notifier).createNewsletter(newsletter);
      }

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.newsletter != null 
                  ? 'Newsletter updated successfully!'
                  : isDraft 
                      ? 'Newsletter saved as draft!'
                      : 'Newsletter sent successfully!',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCreating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 600,
        height: 700,
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    widget.newsletter != null ? 'Edit Newsletter' : 'Create Newsletter',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Newsletter Title',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Title is required';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 16),
              
              Expanded(
                child: TextFormField(
                  controller: _contentController,
                  decoration: const InputDecoration(
                    labelText: 'Newsletter Content',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Content is required';
                    }
                    return null;
                  },
                ),
              ),
              
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _tagsController,
                decoration: const InputDecoration(
                  labelText: 'Tags (comma-separated)',
                  border: OutlineInputBorder(),
                  hintText: 'travel, community, events',
                ),
              ),
              
              const SizedBox(height: 24),
              
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isCreating ? null : () => _saveNewsletter(isDraft: true),
                      child: _isCreating
                          ? const CircularProgressIndicator()
                          : const Text('Save as Draft'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isCreating ? null : () => _saveNewsletter(isDraft: false),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple.shade400,
                        foregroundColor: Colors.white,
                      ),
                      child: _isCreating
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('Send Now'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }}