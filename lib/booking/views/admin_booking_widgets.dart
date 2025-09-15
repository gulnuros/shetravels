import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:csv/csv.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'package:flutter/foundation.dart'; 
 

Widget buildExportFAB({
  required bool isExporting,
  required VoidCallback onPressed,
}) {
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
      onPressed: isExporting ? null : onPressed,
      backgroundColor: Colors.transparent,
      elevation: 0,
      icon: isExporting
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
        isExporting ? "Exporting..." : "Export CSV",
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    ),
  );
}



  List<QueryDocumentSnapshot> filterBookings(
    List<QueryDocumentSnapshot> docs,
    String searchQuery,
     String selectedFilter 
  ) {
    List<QueryDocumentSnapshot> filtered = docs;

    // Apply search filter
    if (searchQuery.isNotEmpty) {
      filtered =
          filtered.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final eventName =
                (data['eventName'] ?? '').toString().toLowerCase();
            final email = (data['userEmail'] ?? '').toString().toLowerCase();
            return eventName.contains(searchQuery) ||
                email.contains(searchQuery);
          }).toList();
    }

    // Apply date filter
    if (selectedFilter != 'All') {
      final now = DateTime.now();
      filtered =
          filtered.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final timestamp = data['timestamp']?.toDate();
            if (timestamp == null) return false;

            switch (selectedFilter) {
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

Future<void> exportBookingsToCSV(
  List<QueryDocumentSnapshot> docs,
  BuildContext context,
) async {
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
      downloadCSVWeb(csvData);
    } else {
      // For mobile, save to device
      await saveCSVMobile(csvData);
    }

    showSuccessSnackBar('Bookings exported successfully!', context);
  } catch (e) {
    showErrorSnackBar('Export failed: $e', context);
  }
}


  void downloadCSVWeb(String csvData) {
    // Web download implementation would go here
    // This is a placeholder for the web download logic
    print("✅ CSV prepared for web download");
  }

  Future<void> saveCSVMobile(String csvData) async {
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

  void showSuccessSnackBar(String message, BuildContext context) {
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

  void showErrorSnackBar(String message, BuildContext context) {
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




  Widget buildEmptyState(    String searchQuery,) {
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
              searchQuery.isEmpty
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





  Widget buildErrorState() {
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
