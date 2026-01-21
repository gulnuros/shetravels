import 'package:auto_route/auto_route.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shetravels/booking/views/admin_booking_widgets.dart';

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
  final Map<String, bool> _updatingStatus = {};

  Future<void> _handleExport() async {
    setState(() => _isExporting = true);

    await exportBookingsToCSV(_allBookings, context);

    setState(() => _isExporting = false);
  }

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

  Future<void> _updatePaymentStatus(String bookingId, String newStatus) async {
    setState(() {
      _updatingStatus[bookingId] = true;
    });

    try {
      await FirebaseFirestore.instance
          .collection('bookings')
          .doc(bookingId)
          .update({'status': newStatus});

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Payment status updated to $newStatus'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update status: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    } finally {
      setState(() {
        _updatingStatus[bookingId] = false;
      });
    }
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
      body: Container(
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

              _buildSearchAndFilterBar(isMobile),

              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: bookingsRef.snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return buildErrorState();
                    }

                    if (!snapshot.hasData) {
                      return _buildLoadingState();
                    }

                    final docs = snapshot.data!.docs;
                    _allBookings = docs;

                    final filteredDocs = filterBookings(
                      docs,
                      _searchQuery,
                      _selectedFilter,
                    );

                    if (filteredDocs.isEmpty) {
                      return buildEmptyState(_searchQuery);
                    }

                    return _buildBookingsList(filteredDocs, isMobile, isTablet);
                  },
                ),
              ),
            ],
          ),
        ),
      ),

      floatingActionButton: buildExportFAB(
        isExporting: _isExporting,
        onPressed: _handleExport,
      ),
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
        childAspectRatio: 1.0, 
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
    final status = data['status'] ?? 'pending';
    final bookingId = doc.id;
    final isUpdating = _updatingStatus[bookingId] ?? false;

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
                      const SizedBox(height: 12),
                      _buildStatusSection(status, bookingId, isUpdating),
                    ],
                  )
                  : Column(
                    children: [
                      IntrinsicHeight(
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
                              child: _buildAmountAndDateSection(
                                amount,
                                timestamp,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildStatusSection(status, bookingId, isUpdating),
                    ],
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

  Widget _buildStatusSection(String status, String bookingId, bool isUpdating) {
    final statusOptions = ['pending', 'paid', 'failed', 'refunded'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.orange.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            "PAYMENT STATUS",
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.orange.shade700,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: _getStatusColor(status).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _getStatusColor(status).withOpacity(0.3),
              width: 1,
            ),
          ),
          child:
              isUpdating
                  ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            _getStatusColor(status),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Updating...',
                        style: TextStyle(
                          color: _getStatusColor(status),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  )
                  : DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: status,
                      isDense: true,
                      style: TextStyle(
                        color: _getStatusColor(status),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                      onChanged: (String? newStatus) {
                        if (newStatus != null && newStatus != status) {
                          _updatePaymentStatus(bookingId, newStatus);
                        }
                      },
                      items:
                          statusOptions.map<DropdownMenuItem<String>>((
                            String value,
                          ) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: _getStatusColor(value),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    value.toUpperCase(),
                                    style: TextStyle(
                                      color: _getStatusColor(value),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                    ),
                  ),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'failed':
        return Colors.red;
      case 'refunded':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}
