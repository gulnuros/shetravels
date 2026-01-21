import 'package:flutter/material.dart';
import 'package:shetravels/she_travel_web.dart';

class TripGalleryPage extends StatelessWidget {
  final PastTrip trip;

  const TripGalleryPage({super.key, required this.trip});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${trip.title} Memories')),
      body: GridView.builder(
        padding: EdgeInsets.all(16),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemCount: trip.galleryImages.length,
        itemBuilder: (context, index) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.asset(trip.galleryImages[index], fit: BoxFit.cover),
          );
        },
      ),
    );
  }
}
