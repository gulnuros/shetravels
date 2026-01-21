import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class BookingHistoryScreen extends StatelessWidget {
  const BookingHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Center(child: Text("Please log in to view bookings."));
    }

    final bookingsRef = FirebaseFirestore.instance
        .collection('bookings')
        .where('userId', isEqualTo: user.uid)
        .orderBy('timestamp', descending: true);

    return Scaffold(
      appBar: AppBar(title: const Text("My Bookings")),
      body: StreamBuilder<QuerySnapshot>(
        stream: bookingsRef.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return const Center(child: Text("No bookings yet."));
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final eventName = data['eventName'];
              final amount = (data['amount'] / 100).toStringAsFixed(2);
              final timestamp = data['timestamp']?.toDate();

              return ListTile(
                title: Text(eventName),
                subtitle: Text("Paid: \$$amount"),
                trailing:
                    timestamp != null
                        ? Text("${timestamp.toLocal()}".split(' ')[0])
                        : null,
              );
            },
          );
        },
      ),
    );
  }
}
