import 'package:auto_route/auto_route.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:csv/csv.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';

@RoutePage()
class AdminBookingDashboardScreen extends StatefulWidget {
  const AdminBookingDashboardScreen({super.key});

  @override
  State<AdminBookingDashboardScreen> createState() =>
      _AdminBookingDashboardScreenState();
}

class _AdminBookingDashboardScreenState
    extends State<AdminBookingDashboardScreen>
    with TickerProviderStateMixin {
  late AnimationController _headerAnimationController;
  late AnimationController _cardAnimationController;
  String _searchQuery = '';
  String _selectedFilter = 'All';
  bool _isExporting = false;
  List<QueryDocumentSnapshot> _allBookings = [];

  @override
  void initState() {
    super.initState();
    _headerAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _cardAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _headerAnimationController.forward();
    _cardAnimationController.forward();
  }

  @override
  void dispose() {
    _headerAnimationController.dispose();
    _cardAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    final isTablet =
        MediaQuery.of(context).size.width > 600 &&
        MediaQuery.of(context).size.width < 1024;

    final bookingsRef = FirebaseFirestore.instance
        .collection('bookings')
        .orderBy('timestamp', descending: true);

    return Scaffold(
      body: 
      Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.indigo.shade50,
              Colors.purple.shade50,
              Colors.blue.shade50,
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
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
                child: _buildModernHeader(isMobile),
              ),
          
              // Search and Filter Bar
              _buildSearchAndFilterBar(isMobile),
          
              // Content Area - FIXED: Added Expanded wrapper
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: bookingsRef.snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return _buildErrorState();
                    }
          
                    if (!snapshot.hasData) {
                      return _buildLoadingState();
                    }
          
                    final docs = snapshot.data!.docs;
                    _allBookings = docs;
          
                    final filteredDocs = _filterBookings(docs);
          
                    if (filteredDocs.isEmpty) {
                      return _buildEmptyState();
                    }
          
                    return _buildBookingsList(filteredDocs, isMobile, isTablet);
                  },
                ),
              ),
            ],
          ),
        ),
      ),

      // Floating Action Button for Export
      floatingActionButton: _buildExportFAB(),
    );
  }

  Widget _buildModernHeader(bool isMobile) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: EdgeInsets.all(isMobile ? 20 : 28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.indigo.shade600,
            Colors.purple.shade600,
            Colors.deepPurple.shade700,
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.indigo.withOpacity(0.3),
            blurRadius: 20,
            spreadRadius: 5,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.analytics,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Booking Analytics",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isMobile ? 22 : 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      "Monitor and manage all bookings",
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: isMobile ? 14 : 16,
                      ),
                    ),
                  ],
                ),
              ),
              if (!isMobile)
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.refresh, color: Colors.white),
                    onPressed: () {
                      setState(() {});
                    },
                  ),
                ),
            ],
          ),

          if (!isMobile) ...[
            const SizedBox(height: 24),
            StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance.collection('bookings').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const SizedBox();

                final docs = snapshot.data!.docs;
                final totalBookings = docs.length;
                final totalRevenue = docs.fold<double>(0, (sum, doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return sum + (data['amount'] ?? 0) / 100;
                });
                final todayBookings =
                    docs.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final timestamp = data['timestamp']?.toDate();
                      if (timestamp == null) return false;
                      final now = DateTime.now();
                      return timestamp.year == now.year &&
                          timestamp.month == now.month &&
                          timestamp.day == now.day;
                    }).length;

                return Row(
                  children: [
                    _buildStatCard(
                      "Total Bookings",
                      "$totalBookings",
                      Icons.event_seat,
                      Colors.orange,
                    ),
                    const SizedBox(width: 16),
                    _buildStatCard(
                      "Revenue",
                      "\$${totalRevenue.toStringAsFixed(2)}",
                      Icons.attach_money,
                      Colors.green,
                    ),
                    const SizedBox(width: 16),
                    _buildStatCard(
                      "Today",
                      "$todayBookings",
                      Icons.today,
                      Colors.blue,
                    ),
                  ],
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
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

  Widget _buildSearchAndFilterBar(bool isMobile) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child:
          isMobile
              ? Column(
                children: [
                  _buildSearchField(),
                  const SizedBox(height: 12),
                  _buildFilterChips(),
                ],
              )
              : Row(
                children: [
                  Expanded(flex: 2, child: _buildSearchField()),
                  const SizedBox(width: 16),
                  Expanded(child: _buildFilterChips()),
                ],
              ),
    );
  }

  Widget _buildSearchField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: TextField(
        onChanged: (value) {
          setState(() {
            _searchQuery = value.toLowerCase();
          });
        },
        decoration: InputDecoration(
          hintText: "Search bookings...",
          prefixIcon: Icon(Icons.search, color: Colors.grey.shade400),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(16),
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    final filters = ['All', 'Today', 'This Week', 'This Month'];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children:
            filters.map((filter) {
              final isSelected = _selectedFilter == filter;
              return Container(
                margin: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(filter),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      _selectedFilter = filter;
                    });
                  },
                  backgroundColor: Colors.grey.shade100,
                  selectedColor: Colors.indigo.shade100,
                  labelStyle: TextStyle(
                    color:
                        isSelected
                            ? Colors.indigo.shade700
                            : Colors.grey.shade700,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              );
            }).toList(),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.indigo.shade100, Colors.purple.shade100],
              ),
              shape: BoxShape.circle,
            ),
            child: const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.indigo),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            "Loading bookings...",
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(32),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.red.withOpacity(0.1),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline,
                size: 48,
                color: Colors.red.shade600,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Error Loading Data',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Please check your connection and try again',
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(10),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.shade100, Colors.indigo.shade100],
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.event_seat,
                size: 20,
                color: Colors.indigo,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'No Bookings Found',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.indigo,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _searchQuery.isEmpty
                  ? 'No bookings available yet'
                  : 'Try adjusting your search or filters',
              style: const TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingsList(
    List<QueryDocumentSnapshot> docs,
    bool isMobile,
    bool isTablet,
  ) {
    return AnimatedBuilder(
      animation: _cardAnimationController,
      builder: (context, child) {
        return Container(
          margin: const EdgeInsets.all(16),
          child:
              isTablet || !isMobile
                  ? _buildGridView(docs)
                  : _buildListView(docs, isMobile),
        );
      },
    );
  }

  Widget _buildGridView(List<QueryDocumentSnapshot> docs) {
    return GridView.builder(
      shrinkWrap: true,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.2,
      ),
      itemCount: docs.length,
      itemBuilder: (context, index) {
        return _buildBookingCard(docs[index], index, false);
      },
    );
  }

  Widget _buildListView(List<QueryDocumentSnapshot> docs, bool isMobile) {
    return ListView.builder(
      shrinkWrap: true,
      itemCount: docs.length,
      itemBuilder: (context, index) {
        return _buildBookingCard(docs[index], index, isMobile);
      },
    );
  }

  Widget _buildBookingCard(
    QueryDocumentSnapshot doc,
    int index,
    bool isMobile,
  ) {
    final data = doc.data() as Map<String, dynamic>;
    final email = data['userEmail'] ?? 'Unknown';
    final eventName = data['eventName'] ?? 'Unknown Event';
    final amount = (data['amount'] ?? 0) / 100;
    final timestamp = data['timestamp']?.toDate();
    final userId = data['userId'] ?? 'Unknown';

    return AnimatedContainer(
      duration: Duration(milliseconds: 300 + (index * 100)),
      curve: Curves.easeOutBack,
      margin: const EdgeInsets.only(bottom: 16),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, Colors.indigo.shade50.withOpacity(0.3)],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.indigo.withOpacity(0.1),
              blurRadius: 15,
              spreadRadius: 2,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child:
              isMobile
                  ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildEventNameSection(eventName),
                      const SizedBox(height: 12),
                      _buildUserInfoSection(email, userId),
                      const SizedBox(height: 12),
                      _buildAmountAndDateSection(amount, timestamp),
                    ],
                  )
                  : IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          flex: 2,
                          child: _buildEventNameSection(eventName),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 2,
                          child: _buildUserInfoSection(email, userId),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 2,
                          child: _buildAmountAndDateSection(amount, timestamp),
                        ),
                      ],
                    ),
                  ),
        ),
      ),
    );
  }

  Widget _buildEventNameSection(String eventName) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.indigo.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            "EVENT",
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.indigo.shade700,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Flexible(
          child: Text(
            eventName,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.indigo,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildUserInfoSection(String email, String userId) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.purple.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            "USER",
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.purple.shade700,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Flexible(
          child: Row(
            children: [
              const Icon(Icons.person, size: 16, color: Colors.grey),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  email,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Flexible(
          child: Row(
            children: [
              const Icon(Icons.badge, size: 16, color: Colors.grey),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  "ID: ${userId.substring(0, userId.length > 8 ? 8 : userId.length)}...",
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAmountAndDateSection(double amount, DateTime? timestamp) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.green.shade400, Colors.green.shade600],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            "\$${amount.toStringAsFixed(2)}",
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
        const SizedBox(height: 8),
        if (timestamp != null) ...[
          Flexible(
            child: Row(
              children: [
                const Icon(Icons.access_time, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    DateFormat('MMM dd, yyyy').format(timestamp),
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 2),
          Flexible(
            child: Row(
              children: [
                const Icon(Icons.schedule, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    DateFormat('HH:mm').format(timestamp),
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildExportFAB() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.orange.shade400, Colors.deepOrange.shade600],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.4),
            blurRadius: 12,
            spreadRadius: 2,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: FloatingActionButton.extended(
        onPressed:
            _isExporting ? null : () => _exportBookingsToCSV(_allBookings),
        backgroundColor: Colors.transparent,
        elevation: 0,
        icon:
            _isExporting
                ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
                : const Icon(Icons.file_download, color: Colors.white),
        label: Text(
          _isExporting ? "Exporting..." : "Export CSV",
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  List<QueryDocumentSnapshot> _filterBookings(
    List<QueryDocumentSnapshot> docs,
  ) {
    List<QueryDocumentSnapshot> filtered = docs;

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered =
          filtered.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final eventName =
                (data['eventName'] ?? '').toString().toLowerCase();
            final email = (data['userEmail'] ?? '').toString().toLowerCase();
            return eventName.contains(_searchQuery) ||
                email.contains(_searchQuery);
          }).toList();
    }

    // Apply date filter
    if (_selectedFilter != 'All') {
      final now = DateTime.now();
      filtered =
          filtered.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final timestamp = data['timestamp']?.toDate();
            if (timestamp == null) return false;

            switch (_selectedFilter) {
              case 'Today':
                return timestamp.year == now.year &&
                    timestamp.month == now.month &&
                    timestamp.day == now.day;
              case 'This Week':
                final weekStart = now.subtract(Duration(days: now.weekday - 1));
                return timestamp.isAfter(weekStart);
              case 'This Month':
                return timestamp.year == now.year &&
                    timestamp.month == now.month;
              default:
                return true;
            }
          }).toList();
    }

    return filtered;
  }

  Future<void> _exportBookingsToCSV(List<QueryDocumentSnapshot> docs) async {
    setState(() => _isExporting = true);

    try {
      List<List<dynamic>> rows = [
        ['Event Name', 'User Email', 'User ID', 'Amount (USD)', 'Date', 'Time'],
      ];

      for (var doc in docs) {
        final data = doc.data() as Map<String, dynamic>;
        final timestamp = data['timestamp']?.toDate();
        rows.add([
          data['eventName'] ?? 'Unknown',
          data['userEmail'] ?? 'Unknown',
          data['userId'] ?? 'Unknown',
          ((data['amount'] ?? 0) / 100).toStringAsFixed(2),
          timestamp != null ? DateFormat('yyyy-MM-dd').format(timestamp) : '',
          timestamp != null ? DateFormat('HH:mm:ss').format(timestamp) : '',
        ]);
      }

      String csvData = const ListToCsvConverter().convert(rows);

      if (kIsWeb) {
        // For web, download the file
        _downloadCSVWeb(csvData);
      } else {
        // For mobile, save to device
        await _saveCSVMobile(csvData);
      }

      _showSuccessSnackBar('Bookings exported successfully!');
    } catch (e) {
      _showErrorSnackBar('Export failed: $e');
    } finally {
      setState(() => _isExporting = false);
    }
  }

  void _downloadCSVWeb(String csvData) {
    // Web download implementation would go here
    // This is a placeholder for the web download logic
    print("✅ CSV prepared for web download");
  }

  Future<void> _saveCSVMobile(String csvData) async {
    if (await Permission.storage.request().isGranted) {
      final directory = await getExternalStorageDirectory();
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final file = File('${directory!.path}/bookings_$timestamp.csv');
      await file.writeAsString(csvData);
      print("✅ Exported to ${file.path}");
    } else {
      throw Exception('Storage permission denied');
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}
