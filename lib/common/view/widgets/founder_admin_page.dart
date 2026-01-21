import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shetravels/common/data/founder_provider.dart';
import 'package:shetravels/common/data/models/founder_message.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';


import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';



class AdminFounderPage extends ConsumerStatefulWidget {
  const AdminFounderPage({super.key});

  @override
  ConsumerState<AdminFounderPage> createState() => _AdminFounderPageState();
}

class _AdminFounderPageState extends ConsumerState<AdminFounderPage>
    with TickerProviderStateMixin {
  late AnimationController _fabAnimationController;
  late Animation<double> _fabAnimation;
  bool _isGridView = true;

  @override
  void initState() {
    super.initState();
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fabAnimation = CurvedAnimation(
      parent: _fabAnimationController,
      curve: Curves.elasticOut,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(founderProvider.notifier).loadAdminFounderMessages();
      _fabAnimationController.forward();
    });
  }

  @override
  void dispose() {
    _fabAnimationController.dispose();
    super.dispose();
  }

  bool get _isMobile => MediaQuery.of(context).size.width < 600;
  bool get _isTablet => MediaQuery.of(context).size.width >= 600 && 
                       MediaQuery.of(context).size.width < 1200;
  bool get _isDesktop => MediaQuery.of(context).size.width >= 1200;

  int get _crossAxisCount {
    if (_isDesktop) return 4;
    if (_isTablet) return 3;
    return 2;
  }

  double get _cardAspectRatio {
    if (_isDesktop) return 0.85;
    if (_isTablet) return 0.8;
    return 0.75;
  }

  @override
  Widget build(BuildContext context) {
    final founderState = ref.watch(founderProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildAppBar(context, colorScheme),
          if (founderState.isLoading)
            const SliverFillRemaining(
              child: Center(child: _LoadingWidget()),
            )
          else if (founderState.error != null)
            SliverFillRemaining(
              child: _buildErrorWidget(founderState.error!, colorScheme),
            )
          else
            _buildContent(founderState.adminFounderMessages, colorScheme),
        ],
      ),
      floatingActionButton: _buildFAB(context, colorScheme),
    );
  }

  Widget _buildAppBar(BuildContext context, ColorScheme colorScheme) {
    return SliverAppBar(
      expandedHeight: _isMobile ? 120 : 150,
      floating: true,
      pinned: true,
      snap: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                colorScheme.primary,
                colorScheme.primary.withOpacity(0.8),
                colorScheme.secondary,
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.1),
                  Colors.black.withOpacity(0.3),
                ],
              ),
            ),
          ),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Icon(
                Icons.admin_panel_settings_rounded,
                color: Colors.white,
                size: _isMobile ? 20 : 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Founder Messages',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: _isMobile ? 18 : 22,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  if (!_isMobile)
                    Text(
                      'Admin Dashboard',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        if (!_isMobile) ...[
          _buildViewToggleButton(),
          const SizedBox(width: 8),
          _buildAddButton(context, colorScheme),
          const SizedBox(width: 16),
        ],
      ],
    );
  }

  Widget _buildViewToggleButton() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: IconButton(
        onPressed: () {
          setState(() {
            _isGridView = !_isGridView;
          });
        },
        icon: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Icon(
            _isGridView ? Icons.view_list_rounded : Icons.grid_view_rounded,
            key: ValueKey(_isGridView),
            color: Colors.white,
            size: 22,
          ),
        ),
        tooltip: _isGridView ? 'List View' : 'Grid View',
      ),
    );
  }

  Widget _buildAddButton(BuildContext context, ColorScheme colorScheme) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ElevatedButton.icon(
        onPressed: () => _showAddEditDialog(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Message'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: colorScheme.primary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(List<FounderMessage> messages, ColorScheme colorScheme) {
    if (messages.isEmpty) {
      return SliverFillRemaining(
        child: _buildEmptyState(colorScheme),
      );
    }

    return SliverPadding(
      padding: EdgeInsets.all(_isMobile ? 16.0 : 24.0),
      sliver: _isGridView || _isMobile
          ? _buildGridView(messages)
          : _buildListView(messages),
    );
  }

  Widget _buildGridView(List<FounderMessage> messages) {
    return SliverGrid(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          return AnimationConfiguration.staggeredGrid(
            position: index,
            duration: const Duration(milliseconds: 600),
            columnCount: _crossAxisCount,
            child: SlideAnimation(
              verticalOffset: 50.0,
              child: FadeInAnimation(
                child: _buildEnhancedMessageCard(messages[index], index),
              ),
            ),
          );
        },
        childCount: messages.length,
      ),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: _crossAxisCount,
        crossAxisSpacing: _isMobile ? 12 : 16,
        mainAxisSpacing: _isMobile ? 12 : 16,
        childAspectRatio: _cardAspectRatio,
      ),
    );
  }

  Widget _buildListView(List<FounderMessage> messages) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          return AnimationConfiguration.staggeredList(
            position: index,
            duration: const Duration(milliseconds: 600),
            child: SlideAnimation(
              horizontalOffset: 30.0,
              child: FadeInAnimation(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _buildEnhancedListCard(messages[index], index),
                ),
              ),
            ),
          );
        },
        childCount: messages.length,
      ),
    );
  }

  Widget _buildEnhancedMessageCard(FounderMessage message, int index) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
return Hero(
  tag: 'founder_${message.id}',
  child: Card(
    elevation: 0,
    margin: EdgeInsets.zero,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(24),
      side: BorderSide(
        color: colorScheme.outline.withOpacity(0.08),
        width: 1,
      ),
    ),
    child: Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.surface,
            colorScheme.surface.withOpacity(0.95),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: colorScheme.primary.withOpacity(0.04),
            blurRadius: 40,
            offset: const Offset(0, 16),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildCardHeader(message, colorScheme),
          
          Flexible(
            flex: 2,
            child: _buildCardContent(message, colorScheme),
          ),
          
          _buildCardActions(message, colorScheme),
        ],
      ),
    ),
  ),
);

  }






Widget _buildCardActions(FounderMessage message, ColorScheme colorScheme) {
  final bool isMobile = MediaQuery.of(context).size.width < 600;
  
  return Container(
    padding: EdgeInsets.all(isMobile ? 12 : 16),
    decoration: BoxDecoration(
      color: colorScheme.surfaceContainerHighest.withOpacity(0.1),
      borderRadius: const BorderRadius.only(
        bottomLeft: Radius.circular(24),
        bottomRight: Radius.circular(24),
      ),
      border: Border(
        top: BorderSide(
          color: colorScheme.outline.withOpacity(0.06),
          width: 1,
        ),
      ),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildActionButton(
          icon: message.isActive ? Icons.visibility_off_rounded : Icons.visibility_rounded,
          color: message.isActive ? Colors.orange : Colors.green,
          onPressed: () => _toggleMessageStatus(message),
          tooltip: message.isActive ? 'Deactivate' : 'Activate',
          isMobile: isMobile,
        ),
        _buildActionButton(
          icon: Icons.edit_rounded,
          color: Colors.blue,
          onPressed: () => _showAddEditDialog(context, message),
          tooltip: 'Edit',
          isMobile: isMobile,
        ),
        _buildActionButton(
          icon: Icons.delete_rounded,
          color: Colors.red,
          onPressed: () => _showDeleteDialog(context, message),
          tooltip: 'Delete',
          isMobile: isMobile,
        ),
      ],
    ),
  );
}




Widget _buildCardHeader(FounderMessage message, ColorScheme colorScheme) {
  final bool isMobile = MediaQuery.of(context).size.width < 600;
  
  return Container(
    padding: EdgeInsets.all(isMobile ? 16 : 20),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: message.isActive
            ? [
                Colors.green.withOpacity(0.08),
                Colors.red.withOpacity(0.04),
              ]
            : [
                Colors.red.withOpacity(0.08),
                Colors.orange.withOpacity(0.04),
              ],
      ),
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(24),
        topRight: Radius.circular(24),
      ),
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          children: [
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    colorScheme.primary.withOpacity(0.15),
                    colorScheme.secondary.withOpacity(0.15),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.primary.withOpacity(0.1),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: isMobile ? 28 : 32,
                backgroundColor: colorScheme.surface,
                backgroundImage: message.imageUrl.isNotEmpty
                    ? NetworkImage(message.imageUrl)
                    : null,
                child: message.imageUrl.isEmpty
                    ? Text(
                        message.name.isNotEmpty
                            ? message.name[0].toUpperCase()
                            : 'F',
                        style: TextStyle(
                          fontSize: isMobile ? 22 : 26,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.primary,
                        ),
                      )
                    : null,
              ),
            ),
            Positioned(
              right: 0,
              top: 0,
              child: _buildStatusBadge(message.isActive),
            ),
          ],
        ),
        
        SizedBox(height: isMobile ? 12 : 16),
        
        Text(
          message.name,
          style: TextStyle(
            fontSize: isMobile ? 15 : 17,
            fontWeight: FontWeight.w700,
            color: colorScheme.onSurface,
            letterSpacing: 0.1,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
        
        SizedBox(height: isMobile ? 4 : 6),
        
        Text(
          message.title,
          style: TextStyle(
            fontSize: isMobile ? 12 : 14,
            fontWeight: FontWeight.w500,
            color: colorScheme.onSurface.withOpacity(0.7),
            letterSpacing: 0.05,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
      ],
    ),
  );
}

Widget _buildActionButton({
  required IconData icon,
  required Color color,
  required VoidCallback onPressed,
  required String tooltip,
  required bool isMobile,
}) {
    final bool isMobile = MediaQuery.of(context).size.width < 600;
  return Tooltip(
    message: tooltip,
    child: Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onPressed,
          child: Padding(
            padding: EdgeInsets.all(isMobile ? 8 : 10),
            child: Icon(
              icon,
              size: isMobile ? 18 : 20,
              color: color,
            ),
          ),
        ),
      ),
    ),
  );
}


  Widget _buildEnhancedListCard(FounderMessage message, int index) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
  final bool isMobile = MediaQuery.of(context).size.width < 600;
  
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: colorScheme.outline.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorScheme.surface,
              colorScheme.surface.withOpacity(0.9),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              _buildListAvatar(message, colorScheme),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            message.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        _buildStatusBadge(message.isActive),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      message.title,
                      style: TextStyle(
                        fontSize: 14,
                        color: colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      message.message,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.4,
                        color: colorScheme.onSurface.withOpacity(0.8),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: colorScheme.primaryContainer.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _formatDate(message.createdAt),
                            style: TextStyle(
                              fontSize: 12,
                              color: colorScheme.onPrimaryContainer,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildActionButton(
                              icon: message.isActive ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                              color: message.isActive ? Colors.orange : Colors.green,
                              onPressed: () => _toggleMessageStatus(message),
                              tooltip: message.isActive ? 'Deactivate' : 'Activate',
                              isMobile: isMobile,
                            ),
                            _buildActionButton(
                              icon: Icons.edit_rounded,
                              color: Colors.blue,
                              onPressed: () => _showAddEditDialog(context, message),
                              tooltip: 'Edit',
                              isMobile: isMobile,
                            ),
                            _buildActionButton(
                              icon: Icons.delete_rounded,
                              color: Colors.red,
                              onPressed: () => _showDeleteDialog(context, message),
                              tooltip: 'Delete',
                              isMobile: isMobile,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }



  Widget _buildCardContent(FounderMessage message, ColorScheme colorScheme) {
  final bool isMobile = MediaQuery.of(context).size.width < 600;
  
  return Padding(
    padding: EdgeInsets.symmetric(
      horizontal: isMobile ? 16 : 20,
      vertical: isMobile ? 8 : 12,
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.all(isMobile ? 12 : 16),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: colorScheme.outline.withOpacity(0.06),
                width: 1,
              ),
            ),
            child: Text(
              message.message,
              style: TextStyle(
                fontSize: isMobile ? 13 : 14,
                height: 1.5,
                color: colorScheme.onSurface.withOpacity(0.85),
                fontWeight: FontWeight.w400,
              ),
              maxLines: isMobile ? 4 : 5,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        
        SizedBox(height: isMobile ? 8 : 12),
        
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 8 : 10,
            vertical: isMobile ? 4 : 6,
          ),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer.withOpacity(0.4),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: colorScheme.primary.withOpacity(0.1),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.schedule_rounded,
                size: isMobile ? 12 : 14,
                color: colorScheme.onPrimaryContainer.withOpacity(0.8),
              ),
              SizedBox(width: isMobile ? 4 : 6),
              Text(
                _formatDate(message.createdAt),
                style: TextStyle(
                  fontSize: isMobile ? 10 : 11,
                  color: colorScheme.onPrimaryContainer.withOpacity(0.9),
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

  Widget _buildListAvatar(FounderMessage message, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            colorScheme.primary,
            colorScheme.secondary,
          ],
        ),
      ),
      child: CircleAvatar(
        radius: 32,
        backgroundColor: colorScheme.surface,
        backgroundImage: message.imageUrl.isNotEmpty
            ? NetworkImage(message.imageUrl)
            : null,
        child: message.imageUrl.isEmpty
            ? Text(
                message.name.isNotEmpty ? message.name[0].toUpperCase() : 'F',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
              )
            : null,
      ),
    );
  }

  Widget _buildEmptyState(ColorScheme colorScheme) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    colorScheme.primary.withOpacity(0.1),
                    colorScheme.secondary.withOpacity(0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(32),
              ),
              child: Icon(
                Icons.message_rounded,
                size: 64,
                color: colorScheme.primary.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Founder Messages Yet',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Create your first message to get started',
              style: TextStyle(
                fontSize: 16,
                color: colorScheme.onSurface.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => _showAddEditDialog(context),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add Your First Message'),
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget(String error, ColorScheme colorScheme) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(32),
        margin: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: colorScheme.errorContainer.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: colorScheme.error.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: colorScheme.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(
                Icons.error_outline_rounded,
                size: 48,
                color: colorScheme.error,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Oops! Something went wrong',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: colorScheme.error,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: TextStyle(
                fontSize: 14,
                color: colorScheme.onErrorContainer,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                ref.read(founderProvider.notifier).loadAdminFounderMessages();
              },
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.error,
                foregroundColor: colorScheme.onError,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFAB(BuildContext context, ColorScheme colorScheme) {
    if (!_isMobile) return const SizedBox.shrink();

    return ScaleTransition(
      scale: _fabAnimation,
      child: FloatingActionButton.extended(
        onPressed: () => _showAddEditDialog(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Message'),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  void _toggleMessageStatus(FounderMessage message) {
    ref.read(founderProvider.notifier).toggleFounderMessageStatus(message.id);
  }

  void _showDeleteDialog(BuildContext context, FounderMessage message) {
    final colorScheme = Theme.of(context).colorScheme;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.delete_rounded,
                color: Colors.red,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Text('Delete Message'),
          ],
        ),
        content: Text(
          'Are you sure you want to delete "${message.name}"\'s message? This action cannot be undone.',
          style: TextStyle(
            color: colorScheme.onSurface.withOpacity(0.8),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ref.read(founderProvider.notifier).deleteFounderMessage(message.id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showAddEditDialog(BuildContext context, [FounderMessage? message]) {
    showDialog(
      context: context,
      builder: (context) => AddEditFounderDialog(message: message),
    );
  }
}


Widget _buildStatusBadge(bool isActive) {
  return Container(
    padding: const EdgeInsets.all(2),
    decoration: BoxDecoration(
      color: Colors.white,
      shape: BoxShape.circle,
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.1),
          blurRadius: 4,
          offset: const Offset(0, 1),
        ),
      ],
    ),
    child: Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: isActive ? Colors.green : Colors.red,
        shape: BoxShape.circle,
        boxShadow: [
          if (isActive)
            BoxShadow(
              color: Colors.green.withOpacity(0.4),
              blurRadius: 4,
              spreadRadius: 1,
            ),
        ],
      ),
    ),
  );
}



class _LoadingWidget extends StatelessWidget {
  const _LoadingWidget();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                colorScheme.primary.withOpacity(0.1),
                colorScheme.secondary.withOpacity(0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: CircularProgressIndicator(
            strokeWidth: 3,
            valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Loading messages...',
          style: TextStyle(
            fontSize: 16,
            color: colorScheme.onSurface.withOpacity(0.7),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}




class AddEditFounderDialog extends ConsumerStatefulWidget {
  final FounderMessage? message;

  const AddEditFounderDialog({super.key, this.message});

  @override
  ConsumerState<AddEditFounderDialog> createState() => _AddEditFounderDialogState();
}

class _AddEditFounderDialogState extends ConsumerState<AddEditFounderDialog>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  final _imageUrlController = TextEditingController();
  
  bool _isActive = true;
  bool _isLoading = false;
  bool _isUploadingImage = false;
  

  File? _selectedImageFile; 
  Uint8List? _selectedImageBytes; 
  String? _selectedImageName;

  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  static const double mobileBreakpoint = 768;
  static const double tabletBreakpoint = 1024;

  bool get _isMobile => MediaQuery.of(context).size.width < mobileBreakpoint;
  bool get _isTablet => MediaQuery.of(context).size.width < tabletBreakpoint;
  bool get _hasSelectedImage => _selectedImageFile != null || _selectedImageBytes != null;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    if (widget.message != null) {
      _nameController.text = widget.message!.name;
      _titleController.text = widget.message!.title;
      _messageController.text = widget.message!.message;
      _imageUrlController.text = widget.message!.imageUrl;
      _isActive = widget.message!.isActive;
    }

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _nameController.dispose();
    _titleController.dispose();
    _messageController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  double _getDialogWidth(double screenWidth) {
    if (_isMobile) return screenWidth * 0.95;
    if (_isTablet) return screenWidth * 0.8;
    return screenWidth * 0.6;
  }

  EdgeInsets _getResponsivePadding() {
    if (_isMobile) return const EdgeInsets.all(16);
    return const EdgeInsets.all(24);
  }

  double get _spacing => _isMobile ? 16.0 : 20.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;
    final dialogWidth = _getDialogWidth(screenWidth);

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Dialog(
              backgroundColor: Colors.transparent,
              child: Container(
                width: dialogWidth.clamp(320.0, 900.0),
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.9,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(_isMobile ? 16 : 24),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.shadow.withOpacity(0.15),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildHeader(theme, colorScheme),
                    Flexible(
                      child: _buildBody(theme, colorScheme),
                    ),
                    _buildFooter(theme, colorScheme),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      padding: _getResponsivePadding(),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.primary.withOpacity(0.1),
            colorScheme.primary.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(_isMobile ? 16 : 24),
          topRight: Radius.circular(_isMobile ? 16 : 24),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.primary.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              widget.message == null ? Icons.add_circle_outline : Icons.edit_outlined,
              color: colorScheme.primary,
              size: _isMobile ? 20 : 24,
            ),
          ),
          SizedBox(width: _spacing),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.message == null ? 'Add New Message' : 'Edit Message',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontSize: _isMobile ? 20 : 24,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                Text(
                  widget.message == null 
                    ? 'Create a new founder message'
                    : 'Update the founder message details',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface.withOpacity(0.7),
                    fontSize: _isMobile ? 14 : 16,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
            icon: Icon(
              Icons.close,
              color: colorScheme.onSurface.withOpacity(0.7),
            ),
            tooltip: 'Close',
          ),
        ],
      ),
    );
  }

  Widget _buildBody(ThemeData theme, ColorScheme colorScheme) {
    return SingleChildScrollView(
      padding: _getResponsivePadding(),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            _buildImageSection(colorScheme),
            SizedBox(height: _spacing),
            _buildFormFields(theme, colorScheme),
            SizedBox(height: _spacing),
            _buildActiveToggle(theme, colorScheme),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSection(ColorScheme colorScheme) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          Container(
            height: _isMobile ? 140 : 180,
            width: _isMobile ? 140 : 180,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: colorScheme.outline.withOpacity(0.3),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.shadow.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: _buildImagePreview(colorScheme),
            ),
          ),
          SizedBox(height: _spacing),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildImageButton(
                icon: Icons.photo_camera_outlined,
                label: 'Pick Image',
                onPressed: _isUploadingImage ? null : _pickImage,
                colorScheme: colorScheme,
              ),
              if (_hasSelectedImage || _imageUrlController.text.isNotEmpty) ...[
                const SizedBox(width: 16),
                _buildImageButton(
                  icon: Icons.delete_outline,
                  label: 'Remove',
                  onPressed: _clearSelectedImage,
                  colorScheme: colorScheme,
                  isDestructive: true,
                ),
              ],
            ],
          ),
          
          if (_isUploadingImage) ...[
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Uploading image...',
                  style: TextStyle(
                    color: colorScheme.onSurface.withOpacity(0.7),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildImageButton({
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
    required ColorScheme colorScheme,
    bool isDestructive = false,
  }) {
    return FilledButton.tonalIcon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: FilledButton.styleFrom(
        backgroundColor: isDestructive 
          ? colorScheme.errorContainer
          : colorScheme.secondaryContainer,
        foregroundColor: isDestructive 
          ? colorScheme.onErrorContainer
          : colorScheme.onSecondaryContainer,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildFormFields(ThemeData theme, ColorScheme colorScheme) {
    if (_isMobile) {
      return Column(
        children: [
          _buildTextField(
            controller: _nameController,
            label: 'Founder Name',
            icon: Icons.person_outline,
            validator: _validateRequired,
            colorScheme: colorScheme,
          ),
          SizedBox(height: _spacing),
          _buildTextField(
            controller: _titleController,
            label: 'Title/Position',
            icon: Icons.work_outline,
            validator: _validateRequired,
            colorScheme: colorScheme,
          ),
          SizedBox(height: _spacing),
          _buildTextField(
            controller: _messageController,
            label: 'Message',
            icon: Icons.message_outlined,
            maxLines: 4,
            validator: _validateRequired,
            colorScheme: colorScheme,
          ),
          SizedBox(height: _spacing),
          _buildTextField(
            controller: _imageUrlController,
            label: 'Image URL (optional)',
            icon: Icons.link_outlined,
            colorScheme: colorScheme,
          ),
        ],
      );
    } else {
      return Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _nameController,
                  label: 'Founder Name',
                  icon: Icons.person_outline,
                  validator: _validateRequired,
                  colorScheme: colorScheme,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: _buildTextField(
                  controller: _titleController,
                  label: 'Title/Position',
                  icon: Icons.work_outline,
                  validator: _validateRequired,
                  colorScheme: colorScheme,
                ),
              ),
            ],
          ),
          SizedBox(height: _spacing),
          _buildTextField(
            controller: _messageController,
            label: 'Message',
            icon: Icons.message_outlined,
            maxLines: 4,
            validator: _validateRequired,
            colorScheme: colorScheme,
          ),
          SizedBox(height: _spacing),
          _buildTextField(
            controller: _imageUrlController,
            label: 'Image URL (optional)',
            icon: Icons.link_outlined,
            colorScheme: colorScheme,
          ),
        ],
      );
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required ColorScheme colorScheme,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: validator,
      style: TextStyle(fontSize: _isMobile ? 16 : 18),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: colorScheme.primary.withOpacity(0.7)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.outline.withOpacity(0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.outline.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.error, width: 2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.error, width: 2),
        ),
        filled: true,
        fillColor: colorScheme.surface,
        contentPadding: EdgeInsets.symmetric(
          horizontal: 16,
          vertical: maxLines > 1 ? 16 : 14,
        ),
      ),
    );
  }

  Widget _buildActiveToggle(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.visibility_outlined,
            color: colorScheme.primary.withOpacity(0.7),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Message Status',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  _isActive 
                    ? 'This message will be visible to users'
                    : 'This message will be hidden from users',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _isActive,
            onChanged: (value) {
              setState(() {
                _isActive = value;
              });
              HapticFeedback.selectionClick();
            },
            activeThumbColor: colorScheme.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      padding: _getResponsivePadding(),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(_isMobile ? 16 : 24),
          bottomRight: Radius.circular(_isMobile ? 16 : 24),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Cancel',
              style: TextStyle(
                fontSize: _isMobile ? 16 : 18,
                color: colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ),
          const SizedBox(width: 12),
          FilledButton(
            onPressed: _isLoading ? null : _saveMessage,
            style: FilledButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
            ),
            child: _isLoading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: colorScheme.onPrimary,
                    ),
                  )
                : Text(
                    widget.message == null ? 'Add Message' : 'Update Message',
                    style: TextStyle(
                      fontSize: _isMobile ? 16 : 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePreview(ColorScheme colorScheme) {
    if (_selectedImageBytes != null) {
      return Image.memory(
        _selectedImageBytes!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildImagePlaceholder(colorScheme),
      );
    } else if (_selectedImageFile != null) {
      return Image.file(
        _selectedImageFile!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildImagePlaceholder(colorScheme),
      );
    } else if (_imageUrlController.text.isNotEmpty) {
      return Image.network(
        _imageUrlController.text,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildImagePlaceholder(colorScheme),
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                  : null,
              color: colorScheme.primary,
            ),
          );
        },
      );
    }
    return _buildImagePlaceholder(colorScheme);
  }

  Widget _buildImagePlaceholder(ColorScheme colorScheme) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.image_outlined,
            size: _isMobile ? 40 : 50,
            color: colorScheme.onSurfaceVariant.withOpacity(0.7),
          ),
          const SizedBox(height: 8),
          Text(
            'No Image',
            style: TextStyle(
              color: colorScheme.onSurfaceVariant.withOpacity(0.7),
              fontSize: _isMobile ? 12 : 14,
            ),
          ),
        ],
      ),
    );
  }

  String? _validateRequired(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'This field is required';
    }
    return null;
  }

  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      
      if (image != null) {
        if (kIsWeb) {
          final bytes = await image.readAsBytes();
          setState(() {
            _selectedImageBytes = bytes;
            _selectedImageName = image.name;
            _selectedImageFile = null;
            _imageUrlController.clear();
          });
        } else {
          setState(() {
            _selectedImageFile = File(image.path);
            _selectedImageName = image.name;
            _selectedImageBytes = null;
            _imageUrlController.clear();
          });
        }
        
        HapticFeedback.selectionClick();
      }
    } catch (e) {
      _showErrorSnackBar('Error picking image: ${e.toString()}');
    }
  }

  void _clearSelectedImage() {
    setState(() {
      _selectedImageFile = null;
      _selectedImageBytes = null;
      _selectedImageName = null;
    });
    HapticFeedback.selectionClick();
  }

  Future<String?> _uploadImageToFirebase() async {
    if (!_hasSelectedImage) return null;
    
    try {
      setState(() {
        _isUploadingImage = true;
      });

      final storageRef = FirebaseStorage.instance
          .ref()
          .child('founder_images')
          .child('${DateTime.now().millisecondsSinceEpoch}_${_selectedImageName ?? 'image.jpg'}');

      UploadTask uploadTask;
      
      if (kIsWeb && _selectedImageBytes != null) {

        uploadTask = storageRef.putData(
          _selectedImageBytes!,
          SettableMetadata(contentType: 'image/jpeg'),
        );
      } else if (!kIsWeb && _selectedImageFile != null) {
  
        uploadTask = storageRef.putFile(
          _selectedImageFile!,
          SettableMetadata(contentType: 'image/jpeg'),
        );
      } else {
        return null;
      }

      final TaskSnapshot taskSnapshot = await uploadTask;
      final String downloadURL = await taskSnapshot.ref.getDownloadURL();
      
      return downloadURL;
    } catch (e) {
      _showErrorSnackBar('Error uploading image: ${e.toString()}');
      return null;
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingImage = false;
        });
      }
    }
  }

  Future<void> _saveMessage() async {
    if (!_formKey.currentState!.validate()) {

      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      String imageUrl = _imageUrlController.text.trim();
      
      if (_hasSelectedImage) {
        final uploadedImageUrl = await _uploadImageToFirebase();
        if (uploadedImageUrl != null) {
          imageUrl = uploadedImageUrl;
        } else {
          imageUrl = widget.message?.imageUrl ?? '';
        }
      }

      final newMessage = FounderMessage(
        id: widget.message?.id ?? '',
        name: _nameController.text.trim(),
        title: _titleController.text.trim(),
        message: _messageController.text.trim(),
        imageUrl: imageUrl,
        isActive: _isActive,
        createdAt: widget.message?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      if (widget.message == null) {
        await ref.read(founderProvider.notifier).createFounderMessage(newMessage);
      } else {
        await ref.read(founderProvider.notifier).updateFounderMessage(newMessage);
      }

      if (mounted) {
   
        Navigator.of(context).pop();
        _showSuccessSnackBar(widget.message == null 
            ? 'Message added successfully!' 
            : 'Message updated successfully!');
      }
    } catch (e) {
      
      _showErrorSnackBar('Error: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}