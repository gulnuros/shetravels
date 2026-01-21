import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

/// Helper class to set up Firebase with initial data
/// Run this once from your admin panel or as a one-time setup
class FirebaseSetupHelper {
  final FirebaseFirestore firestore;
  final FirebaseStorage storage;

  FirebaseSetupHelper({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  })  : firestore = firestore ?? FirebaseFirestore.instance,
        storage = storage ?? FirebaseStorage.instance;

  /// Main setup method - call this to populate Firebase
  Future<void> setupFirebase() async {
    try {
      print('🚀 Starting Firebase Setup...\n');

      // Check if already set up
      final founderDocs =
          await firestore.collection('founderMessages').limit(1).get();
      if (founderDocs.docs.isNotEmpty) {
        print('⚠️  Firebase already has data. Skipping setup.');
        print(
            '   If you want to re-run setup, delete collections manually first.');
        return;
      }

      await _createSampleData();

      print('\n🎉 Firebase setup completed successfully!');
      print(
          '\n✨ Your app should now display data. Upload images manually via admin panel.');
    } catch (e) {
      print('❌ Error during setup: $e');
      rethrow;
    }
  }

  Future<void> _createSampleData() async {
    // 1. Create founder message (without image initially)
    print('📝 Creating founder message...');
    await firestore.collection('founderMessages').add({
      'name': 'Alexa',
      'title': 'Founder & CEO',
      'message':
          'Welcome to SheTravels! Our mission is to empower women through transformative travel experiences. Join us on adventures that inspire, connect, and celebrate the spirit of exploration.',
      'imageUrl':
          '', // You'll upload via admin panel
      'isActive': true,
      'createdAt': DateTime.now().toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),
    });
    print('✅ Founder message created (add image via admin panel)\n');

    // 2. Create sample gallery entries
    print('🖼️  Creating gallery entries...');
    final galleryEntries = [
      {
        'title': 'Mountain Adventure',
        'description': 'Exploring scenic mountain trails',
        'category': 'Hiking'
      },
      {
        'title': 'Summit Success',
        'description': 'Reaching new heights together',
        'category': 'Hiking'
      },
      {
        'title': 'Trail Discoveries',
        'description': 'Finding beauty in every step',
        'category': 'Hiking'
      },
      {
        'title': 'Nature Escapes',
        'description': 'Connecting with the wilderness',
        'category': 'Hiking'
      },
      {
        'title': 'Group Adventures',
        'description': 'Making memories with fellow travelers',
        'category': 'Hiking'
      },
    ];

    for (var entry in galleryEntries) {
      await firestore.collection('gallery').add({
        'title': entry['title'],
        'description': entry['description'],
        'imageUrl': '', // Upload via admin panel
        'category': entry['category'],
        'createdAt': Timestamp.now(),
      });
    }
    print('✅ ${galleryEntries.length} gallery entries created\n');

    // 3. Create sample memories
    print('💭 Creating memories...');
    final memories = [
      {
        'title': 'First Summit',
        'description': 'My first mountain peak - an unforgettable experience!',
        'location': 'Mount Rainier'
      },
      {
        'title': 'Sunrise Hike',
        'description': 'Watching the sunrise from the mountain top',
        'location': 'North Cascades'
      },
      {
        'title': 'Trail Friends',
        'description': 'Made lifelong friends on this adventure',
        'location': 'Olympic National Park'
      },
      {
        'title': 'Alpine Lakes',
        'description': 'Crystal clear alpine lakes surrounded by peaks',
        'location': 'Alpine Lakes Wilderness'
      },
    ];

    for (var memory in memories) {
      await firestore.collection('memories').add({
        'title': memory['title'],
        'description': memory['description'],
        'imageUrl': '', // Upload via admin panel
        'location': memory['location'],
        'category': 'Adventure',
        'createdAt': Timestamp.now(),
      });
    }
    print('✅ ${memories.length} memories created\n');

    // 4. Create sample events
    print('📅 Creating sample events...');
    final events = [
      {
        'title': 'Summer Mountain Retreat',
        'date': '2025-07-15',
        'description':
            'Join us for a 3-day mountain adventure with hiking, camping, and breathtaking views!',
        'location': 'Mount Rainier National Park, WA',
        'price': 350,
        'availableSlots': 15,
      },
      {
        'title': 'Coastal Hiking Experience',
        'date': '2025-08-20',
        'description':
            'Explore beautiful coastal trails with ocean views and beach camping.',
        'location': 'Olympic Coast, WA',
        'price': 275,
        'availableSlots': 12,
      },
    ];

    for (var event in events) {
      await firestore.collection('events').add({
        'title': event['title'],
        'date': event['date'],
        'description': event['description'],
        'imageUrl': '', // Upload via admin panel
        'location': event['location'],
        'price': event['price'],
        'availableSlots': event['availableSlots'],
        'subscribedUsers': [],
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': 'admin',
      });
    }
    print('✅ ${events.length} events created\n');
  }

  /// Upload a single image to Firebase Storage
  Future<String?> uploadImageFromFile(
    File imageFile,
    String storagePath,
  ) async {
    if (kIsWeb) {
      print('⚠️  File uploads not supported on web. Use admin panel instead.');
      return null;
    }

    try {
      final ref = storage.ref().child(storagePath);
      final uploadTask = await ref.putFile(imageFile);
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print('❌ Error uploading image: $e');
      return null;
    }
  }
}
