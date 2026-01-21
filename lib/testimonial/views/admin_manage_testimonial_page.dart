import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:shetravels/testimonial/data/model/testimonial.dart';
import 'package:shetravels/testimonial/data/testimonial_repository.dart';
import 'package:shetravels/utils/route.gr.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

class AdminManageTestimonialsPage extends StatefulWidget {
  const AdminManageTestimonialsPage({super.key});

  @override
  State<AdminManageTestimonialsPage> createState() =>
      _AdminManageTestimonialsPageState();
}

class _AdminManageTestimonialsPageState
    extends State<AdminManageTestimonialsPage>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  String _searchQuery = '';
  bool _isGridView = true;
  final Set<String> _selectedItems = {};
  bool _isSelectionMode = false;
  static const double mobileBreakpoint = 768;
  static const double tabletBreakpoint = 1024;
  static const double desktopBreakpoint = 1440;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.elasticOut),
    );

    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  bool get _isMobile => MediaQuery.of(context).size.width < mobileBreakpoint;
  bool get _isTablet => MediaQuery.of(context).size.width < tabletBreakpoint;
  bool get _isDesktop => MediaQuery.of(context).size.width >= desktopBreakpoint;

  int get _crossAxisCount {
    if (_isMobile) return 1;
    if (_isTablet) return 2;
    return _isDesktop ? 4 : 3;
  }

  EdgeInsets get _contentPadding {
    if (_isMobile) return const EdgeInsets.all(16);
    if (_isTablet) return const EdgeInsets.all(24);
    return const EdgeInsets.all(32);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: CustomScrollView(
            slivers: [
              _buildSliverAppBar(theme, colorScheme),
              _buildSearchAndFilters(theme, colorScheme),
              _buildTestimonialsContent(theme, colorScheme),
            ],
          ),
        ),
      ),
      floatingActionButton: _buildFloatingActionButton(colorScheme),
    );
  }

  Widget _buildSliverAppBar(ThemeData theme, ColorScheme colorScheme) {
    return SliverAppBar(
      expandedHeight: _isMobile ? 120 : 140,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: Colors.transparent,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                colorScheme.primary.withOpacity(0.1),
                colorScheme.secondary.withOpacity(0.1),
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: _contentPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          Icons.rate_review_outlined,
                          color: colorScheme.primary,
                          size: _isMobile ? 24 : 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Manage Testimonials',
                              style: theme.textTheme.headlineMedium?.copyWith(
                                fontSize: _isMobile ? 24 : 28,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onSurface,
                              ),
                            ),
                            Text(
                              'Review and manage customer testimonials',
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: colorScheme.onSurface.withOpacity(0.7),
                                fontSize: _isMobile ? 14 : 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      leading:
          _isMobile
              ? IconButton(
                icon: Icon(Icons.arrow_back_ios, color: colorScheme.onSurface),
                onPressed: () => Navigator.of(context).pop(),
              )
              : null,
      actions: [
        if (_isSelectionMode) ...[
          IconButton(
            icon: Icon(Icons.delete_outline, color: colorScheme.error),
            onPressed: _selectedItems.isEmpty ? null : _deleteSelectedItems,
            tooltip: 'Delete Selected',
          ),
          IconButton(
            icon: Icon(Icons.close, color: colorScheme.onSurface),
            onPressed: _exitSelectionMode,
            tooltip: 'Cancel Selection',
          ),
        ] else ...[
          IconButton(
            icon: Icon(
              _isGridView ? Icons.list : Icons.grid_view,
              color: colorScheme.onSurface,
            ),
            onPressed: _toggleView,
            tooltip: _isGridView ? 'List View' : 'Grid View',
          ),
          IconButton(
            icon: Icon(Icons.more_vert, color: colorScheme.onSurface),
            onPressed: () => _showMoreOptions(context),
            tooltip: 'More Options',
          ),
        ],
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildSearchAndFilters(ThemeData theme, ColorScheme colorScheme) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: _contentPadding,
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: colorScheme.outline.withOpacity(0.2)),
              ),
              child: TextField(
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Search testimonials...',
                  hintStyle: TextStyle(
                    color: colorScheme.onSurface.withOpacity(0.6),
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    color: colorScheme.primary.withOpacity(0.7),
                  ),
                  suffixIcon:
                      _searchQuery.isNotEmpty
                          ? IconButton(
                            icon: Icon(
                              Icons.clear,
                              color: colorScheme.onSurface.withOpacity(0.6),
                            ),
                            onPressed: () {
                              setState(() {
                                _searchQuery = '';
                              });
                            },
                          )
                          : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),
              ),
            ),

            if (_isSelectionMode) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: colorScheme.primary.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: colorScheme.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${_selectedItems.length} item(s) selected',
                      style: TextStyle(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: _selectAll,
                      child: Text('Select All'),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTestimonialsContent(ThemeData theme, ColorScheme colorScheme) {
    return SliverPadding(
      padding: _contentPadding,
      sliver: StreamBuilder<List<Testimonial>>(
        stream: TestimonialRepository.getTestimonialsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildLoadingState(colorScheme);
          }

          if (snapshot.hasError) {
            return _buildErrorState(
              theme,
              colorScheme,
              snapshot.error.toString(),
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _buildEmptyState(theme, colorScheme);
          }

          final testimonials = _filterTestimonials(snapshot.data!);

          if (testimonials.isEmpty && _searchQuery.isNotEmpty) {
            return _buildNoSearchResults(theme, colorScheme);
          }

          return _isGridView
              ? _buildGridView(testimonials, theme, colorScheme)
              : _buildListView(testimonials, theme, colorScheme);
        },
      ),
    );
  }

  List<Testimonial> _filterTestimonials(List<Testimonial> testimonials) {
    if (_searchQuery.isEmpty) return testimonials;

    return testimonials.where((testimonial) {
      return testimonial.name.toLowerCase().contains(
            _searchQuery.toLowerCase(),
          ) ||
          testimonial.comment.toLowerCase().contains(
            _searchQuery.toLowerCase(),
          ) ||
          testimonial.region.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  Widget _buildGridView(
    List<Testimonial> testimonials,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return SliverMasonryGrid(
      delegate: SliverChildBuilderDelegate((context, index) {
        final testimonial = testimonials[index];
        return AnimatedContainer(
          duration: Duration(milliseconds: 300 + (index * 100)),
          child: _buildTestimonialCard(testimonial, theme, colorScheme, index),
        );
      }, childCount: testimonials.length),
      gridDelegate: SliverSimpleGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: _crossAxisCount,
      ),
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
    );
  }

  Widget _buildListView(
    List<Testimonial> testimonials,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        final testimonial = testimonials[index];
        return AnimatedContainer(
          duration: Duration(milliseconds: 300 + (index * 50)),
          margin: const EdgeInsets.only(bottom: 12),
          child: _buildTestimonialListTile(
            testimonial,
            theme,
            colorScheme,
            index,
          ),
        );
      }, childCount: testimonials.length),
    );
  }

  Widget _buildTestimonialCard(
    Testimonial testimonial,
    ThemeData theme,
    ColorScheme colorScheme,
    int index,
  ) {
    final isSelected = _selectedItems.contains(testimonial.id);

    return GestureDetector(
      onTap: () => _handleItemTap(testimonial.id),
      onLongPress: () => _handleItemLongPress(testimonial.id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color:
              isSelected
                  ? colorScheme.primaryContainer.withOpacity(0.3)
                  : colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color:
                isSelected
                    ? colorScheme.primary.withOpacity(0.5)
                    : colorScheme.outline.withOpacity(0.2),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.format_quote,
                          color: colorScheme.primary,
                          size: 16,
                        ),
                      ),
                      const Spacer(),
                      if (_isSelectionMode)
                        AnimatedScale(
                          duration: const Duration(milliseconds: 200),
                          scale: isSelected ? 1.0 : 0.8,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color:
                                  isSelected
                                      ? colorScheme.primary
                                      : colorScheme.outline.withOpacity(0.3),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.check,
                              color:
                                  isSelected
                                      ? colorScheme.onPrimary
                                      : Colors.transparent,
                              size: 16,
                            ),
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 12),
                  Text(
                    testimonial.comment,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurface,
                      height: 1.4,
                    ),
                    maxLines: _isMobile ? 4 : 6,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 16),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: colorScheme.primaryContainer,
                        child: Text(
                          testimonial.name.isNotEmpty
                              ? testimonial.name[0].toUpperCase()
                              : '?',
                          style: TextStyle(
                            color: colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              testimonial.name,
                              style: theme.textTheme.labelMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: colorScheme.onSurface,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              testimonial.region,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: colorScheme.onSurface.withOpacity(0.6),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      if (!_isSelectionMode)
                        PopupMenuButton<String>(
                          icon: Icon(
                            Icons.more_vert,
                            color: colorScheme.onSurface.withOpacity(0.6),
                            size: 18,
                          ),
                          onSelected:
                              (value) => _handleMenuAction(value, testimonial),
                          itemBuilder:
                              (context) => [
                                PopupMenuItem(
                                  value: 'edit',
                                  child: Row(
                                    children: [
                                      Icon(Icons.edit, size: 18),
                                      const SizedBox(width: 8),
                                      Text('Edit'),
                                    ],
                                  ),
                                ),
                                PopupMenuItem(
                                  value: 'delete',
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.delete,
                                        size: 18,
                                        color: colorScheme.error,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Delete',
                                        style: TextStyle(
                                          color: colorScheme.error,
                                        ),
                                      ),
                                    ],
                                  ),
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
    );
  }

  Widget _buildTestimonialListTile(
    Testimonial testimonial,
    ThemeData theme,
    ColorScheme colorScheme,
    int index,
  ) {
    final isSelected = _selectedItems.contains(testimonial.id);

    return GestureDetector(
      onTap: () => _handleItemTap(testimonial.id),
      onLongPress: () => _handleItemLongPress(testimonial.id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color:
              isSelected
                  ? colorScheme.primaryContainer.withOpacity(0.3)
                  : colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color:
                isSelected
                    ? colorScheme.primary.withOpacity(0.5)
                    : colorScheme.outline.withOpacity(0.2),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              if (_isSelectionMode)
                AnimatedScale(
                  duration: const Duration(milliseconds: 200),
                  scale: isSelected ? 1.0 : 0.8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color:
                          isSelected
                              ? colorScheme.primary
                              : colorScheme.outline.withOpacity(0.3),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.check,
                      color:
                          isSelected
                              ? colorScheme.onPrimary
                              : Colors.transparent,
                      size: 16,
                    ),
                  ),
                )
              else
                CircleAvatar(
                  radius: 20,
                  backgroundColor: colorScheme.primaryContainer,
                  child: Text(
                    testimonial.name.isNotEmpty
                        ? testimonial.name[0].toUpperCase()
                        : '?',
                    style: TextStyle(
                      color: colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

              const SizedBox(width: 16),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      testimonial.comment,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurface,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${testimonial.name} • ${testimonial.region}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),

              if (!_isSelectionMode)
                PopupMenuButton<String>(
                  icon: Icon(
                    Icons.more_vert,
                    color: colorScheme.onSurface.withOpacity(0.6),
                  ),
                  onSelected: (value) => _handleMenuAction(value, testimonial),
                  itemBuilder:
                      (context) => [
                        PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit, size: 18),
                              const SizedBox(width: 8),
                              Text('Edit'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(
                                Icons.delete,
                                size: 18,
                                color: colorScheme.error,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Delete',
                                style: TextStyle(color: colorScheme.error),
                              ),
                            ],
                          ),
                        ),
                      ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState(ColorScheme colorScheme) {
    return SliverFillRemaining(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: colorScheme.primary,
              strokeWidth: 3,
            ),
            const SizedBox(height: 16),
            Text(
              'Loading testimonials...',
              style: TextStyle(
                color: colorScheme.onSurface.withOpacity(0.7),
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme, ColorScheme colorScheme) {
    return SliverFillRemaining(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.rate_review_outlined,
                  size: 48,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'No Testimonials Yet',
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Start collecting customer testimonials to showcase your business success.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface.withOpacity(0.7),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: () => _navigateToAddTestimonial(),
                icon: const Icon(Icons.add),
                label: const Text('Add First Testimonial'),
                style: FilledButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNoSearchResults(ThemeData theme, ColorScheme colorScheme) {
    return SliverFillRemaining(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.search_off,
                size: 48,
                color: colorScheme.onSurface.withOpacity(0.4),
              ),
              const SizedBox(height: 16),
              Text(
                'No Results Found',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'No testimonials match "$_searchQuery"',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface.withOpacity(0.7),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(
    ThemeData theme,
    ColorScheme colorScheme,
    String error,
  ) {
    return SliverFillRemaining(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: colorScheme.error),
              const SizedBox(height: 16),
              Text(
                'Something Went Wrong',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                error,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface.withOpacity(0.7),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              TextButton.icon(
                onPressed: () => setState(() {}),
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingActionButton(ColorScheme colorScheme) {
    return AnimatedScale(
      duration: const Duration(milliseconds: 200),
      scale: _isSelectionMode ? 0.0 : 1.0,
      child: FloatingActionButton.extended(
        onPressed: _navigateToAddTestimonial,
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 4,
        icon: const Icon(Icons.add),
        label: Text(_isMobile ? 'Add' : 'Add Testimonial'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  void _handleItemTap(String id) {
    if (_isSelectionMode) {
      _toggleItemSelection(id);
    } else {
  
    }
  }

  void _handleItemLongPress(String id) {
    HapticFeedback.mediumImpact();
    if (!_isSelectionMode) {
      setState(() {
        _isSelectionMode = true;
        _selectedItems.add(id);
      });
    } else {
      _toggleItemSelection(id);
    }
  }

  void _toggleItemSelection(String id) {
    setState(() {
      if (_selectedItems.contains(id)) {
        _selectedItems.remove(id);
        if (_selectedItems.isEmpty) {
          _isSelectionMode = false;
        }
      } else {
        _selectedItems.add(id);
      }
    });
  }

  void _selectAll() {
  }

  void _exitSelectionMode() {
    setState(() {
      _isSelectionMode = false;
      _selectedItems.clear();
    });
  }

  void _deleteSelectedItems() async {
    if (_selectedItems.isEmpty) return;

    final confirmed = await _showDeleteConfirmationDialog();
    if (confirmed) {
      try {
        for (final id in _selectedItems) {
          await TestimonialRepository.removeTestimonial(id);
        }

        _exitSelectionMode();
        _showSuccessSnackBar('Testimonials deleted successfully');
      } catch (e) {
        _showErrorSnackBar('Failed to delete testimonials: $e');
      }
    }
  }

  void _toggleView() {
    setState(() {
      _isGridView = !_isGridView;
    });
    HapticFeedback.selectionClick();
  }

  void _handleMenuAction(String action, Testimonial testimonial) async {
    switch (action) {
      case 'edit':
        _navigateToEditTestimonial(testimonial);
        break;
      case 'delete':
        _deleteTestimonial(testimonial);
        break;
    }
  }

  void _navigateToAddTestimonial() {
    context.router.push(AddTestimonialRoute());
  }

  void _navigateToEditTestimonial(Testimonial testimonial) {
  }

  void _deleteTestimonial(Testimonial testimonial) async {
    final confirmed = await _showDeleteConfirmationDialog(single: true);
    if (confirmed) {
      try {
        await TestimonialRepository.removeTestimonial(testimonial.id);
        _showSuccessSnackBar('Testimonial deleted successfully');
      } catch (e) {
        _showErrorSnackBar('Failed to delete testimonial: $e');
      }
    }
  }

  Future<bool> _showDeleteConfirmationDialog({bool single = false}) async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            final colorScheme = Theme.of(context).colorScheme;
            final count = single ? 1 : _selectedItems.length;

            return AlertDialog(
              backgroundColor: colorScheme.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: colorScheme.error),
                  const SizedBox(width: 12),
                  Text(
                    'Delete Confirmation',
                    style: TextStyle(color: colorScheme.onSurface),
                  ),
                ],
              ),
              content: Text(
                single
                    ? 'Are you sure you want to delete this testimonial? This action cannot be undone.'
                    : 'Are you sure you want to delete $count testimonial${count > 1 ? 's' : ''}? This action cannot be undone.',
                style: TextStyle(color: colorScheme.onSurface.withOpacity(0.8)),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  style: TextButton.styleFrom(
                    foregroundColor: colorScheme.onSurface.withOpacity(0.7),
                  ),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: FilledButton.styleFrom(
                    backgroundColor: colorScheme.error,
                    foregroundColor: colorScheme.onError,
                  ),
                  child: const Text('Delete'),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  void _showMoreOptions(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder:
          (context) => Container(
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: colorScheme.onSurfaceVariant.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),

                  ListTile(
                    leading: Icon(Icons.select_all, color: colorScheme.primary),
                    title: const Text('Select Multiple'),
                    onTap: () {
                      Navigator.pop(context);
                      setState(() {
                        _isSelectionMode = true;
                      });
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.refresh, color: colorScheme.primary),
                    title: const Text('Refresh'),
                    onTap: () {
                      Navigator.pop(context);
                      setState(() {});
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.sort, color: colorScheme.primary),
                    title: const Text('Sort Options'),
                    onTap: () {
                      Navigator.pop(context);
                      _showSortOptions();
                    },
                  ),
                  ListTile(
                    leading: Icon(
                      Icons.filter_list,
                      color: colorScheme.primary,
                    ),
                    title: const Text('Filter Options'),
                    onTap: () {
                      Navigator.pop(context);
                      _showFilterOptions();
                    },
                  ),

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
    );
  }

  void _showSortOptions() {
    final colorScheme = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: colorScheme.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text(
              'Sort Testimonials',
              style: TextStyle(color: colorScheme.onSurface),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: Icon(Icons.access_time, color: colorScheme.primary),
                  title: const Text('Most Recent'),
                  onTap: () {
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  leading: Icon(Icons.person, color: colorScheme.primary),
                  title: const Text('By Name'),
                  onTap: () {
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  leading: Icon(Icons.location_on, color: colorScheme.primary),
                  title: const Text('By Region'),
                  onTap: () {
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
    );
  }

  void _showFilterOptions() {
    final colorScheme = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: colorScheme.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text(
              'Filter Testimonials',
              style: TextStyle(color: colorScheme.onSurface),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: Icon(Icons.today, color: colorScheme.primary),
                  title: const Text('This Week'),
                  onTap: () {
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  leading: Icon(Icons.date_range, color: colorScheme.primary),
                  title: const Text('This Month'),
                  onTap: () {
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  leading: Icon(
                    Icons.location_city,
                    color: colorScheme.primary,
                  ),
                  title: const Text('By Region'),
                  onTap: () {
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
    );
  }

  void _showSuccessSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: EdgeInsets.only(
          bottom: MediaQuery.of(context).size.height - 100,
          left: 16,
          right: 16,
        ),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: EdgeInsets.only(
          bottom: MediaQuery.of(context).size.height - 100,
          left: 16,
          right: 16,
        ),
      ),
    );
  }
}
