import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  print('🚀 Starting Firebase Setup Script...\n');

  // Load environment variables
  await dotenv.load(fileName: ".env");

  // Initialize Firebase
  await Firebase.initializeApp(
    options: FirebaseOptions(
      apiKey: dotenv.env['FIREBASE_API_KEY'] ?? '',
      authDomain: dotenv.env['FIREBASE_AUTH_DOMAIN'] ?? '',
      projectId: dotenv.env['FIREBASE_PROJECT_ID'] ?? '',
      storageBucket: dotenv.env['FIREBASE_STORAGE_BUCKET'] ?? '',
      messagingSenderId: dotenv.env['FIREBASE_MESSAGING_SENDER_ID'] ?? '',
      appId: dotenv.env['FIREBASE_APP_ID'] ?? '',
      measurementId: dotenv.env['FIREBASE_MEASUREMENT_ID'],
    ),
  );

  print('✅ Firebase initialized successfully\n');

  final firestore = FirebaseFirestore.instance;
  final storage = FirebaseStorage.instance;

  // Upload images and create Firestore collections
  try {
    // 1. Upload founder image and create founder message
    print('📸 Uploading founder image...');
    final founderImageUrl = await uploadImage(
      storage,
      'assets/aleksa_portrait.png',
      'founder_images/aleksa_portrait.png',
    );

    if (founderImageUrl != null) {
      print('✅ Founder image uploaded: $founderImageUrl');

      // Create founder message document
      print('📝 Creating founder message...');
      await firestore.collection('founderMessages').add({
        'name': 'Alexa',
        'title': 'Founder & CEO',
        'message': 'Welcome to SheTravels! Our mission is to empower women through transformative travel experiences. Join us on adventures that inspire, connect, and celebrate the spirit of exploration.',
        'imageUrl': founderImageUrl,
        'isActive': true,
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      });
      print('✅ Founder message created\n');
    }

    // 2. Upload gallery images
    print('🖼️  Uploading gallery images...');
    final galleryImages = [
      {'file': 'assets/hike_1.jpeg', 'title': 'Mountain Adventure', 'description': 'Exploring scenic mountain trails', 'category': 'Hiking'},
      {'file': 'assets/hike_2.jpeg', 'title': 'Summit Success', 'description': 'Reaching new heights together', 'category': 'Hiking'},
      {'file': 'assets/hike_3.jpeg', 'title': 'Trail Discoveries', 'description': 'Finding beauty in every step', 'category': 'Hiking'},
      {'file': 'assets/hike_4.jpeg', 'title': 'Nature Escapes', 'description': 'Connecting with the wilderness', 'category': 'Hiking'},
      {'file': 'assets/hike_5.jpeg', 'title': 'Group Adventures', 'description': 'Making memories with fellow travelers', 'category': 'Hiking'},
    ];

    for (var img in galleryImages) {
      final imageUrl = await uploadImage(
        storage,
        img['file'] as String,
        'gallery/${img['file'].toString().split('/').last}',
      );

      if (imageUrl != null) {
        await firestore.collection('gallery').add({
          'title': img['title'],
          'description': img['description'],
          'imageUrl': imageUrl,
          'category': img['category'],
          'createdAt': Timestamp.now(),
        });
        print('✅ Gallery image uploaded: ${img['title']}');
      }
    }
    print('✅ All gallery images uploaded\n');

    // 3. Upload memories
    print('💭 Uploading memories...');
    final memories = [
      {'file': 'assets/hike_1.jpeg', 'title': 'First Summit', 'description': 'My first mountain peak - an unforgettable experience!', 'location': 'Mount Rainier'},
      {'file': 'assets/hike_2.jpeg', 'title': 'Sunrise Hike', 'description': 'Watching the sunrise from the mountain top', 'location': 'North Cascades'},
      {'file': 'assets/hike_3.jpeg', 'title': 'Trail Friends', 'description': 'Made lifelong friends on this adventure', 'location': 'Olympic National Park'},
      {'file': 'assets/hike_5.jpeg', 'title': 'Alpine Lakes', 'description': 'Crystal clear alpine lakes surrounded by peaks', 'location': 'Alpine Lakes Wilderness'},
      {'file': 'assets/past2.jpeg', 'title': 'Past Adventures', 'description': 'Looking back at amazing journeys', 'location': 'Various Locations'},
    ];

    for (var memory in memories) {
      final imageUrl = await uploadImage(
        storage,
        memory['file'] as String,
        'memories/${memory['file'].toString().split('/').last}',
      );

      if (imageUrl != null) {
        await firestore.collection('memories').add({
          'title': memory['title'],
          'description': memory['description'],
          'imageUrl': imageUrl,
          'location': memory['location'],
          'category': 'Adventure',
          'createdAt': Timestamp.now(),
        });
        print('✅ Memory uploaded: ${memory['title']}');
      }
    }
    print('✅ All memories uploaded\n');

    // 4. Create sample events
    print('📅 Creating sample events...');
    final events = [
      {
        'title': 'Summer Mountain Retreat',
        'date': '2025-07-15',
        'description': 'Join us for a 3-day mountain adventure with hiking, camping, and breathtaking views!',
        'imageFile': 'assets/hike_1.jpeg',
        'location': 'Mount Rainier National Park, WA',
        'price': 350,
        'availableSlots': 15,
      },
      {
        'title': 'Coastal Hiking Experience',
        'date': '2025-08-20',
        'description': 'Explore beautiful coastal trails with ocean views and beach camping.',
        'imageFile': 'assets/hike_5.jpeg',
        'location': 'Olympic Coast, WA',
        'price': 275,
        'availableSlots': 12,
      },
    ];

    for (var event in events) {
      final imageUrl = await uploadImage(
        storage,
        event['imageFile'] as String,
        'events/${event['imageFile'].toString().split('/').last}',
      );

      if (imageUrl != null) {
        await firestore.collection('events').add({
          'title': event['title'],
          'date': event['date'],
          'description': event['description'],
          'imageUrl': imageUrl,
          'location': event['location'],
          'price': event['price'],
          'availableSlots': event['availableSlots'],
          'subscribedUsers': [],
          'createdAt': FieldValue.serverTimestamp(),
          'createdBy': 'admin',
        });
        print('✅ Event created: ${event['title']}');
      }
    }
    print('✅ All events created\n');

    print('🎉 Firebase setup completed successfully!');
    print('\n📊 Summary:');
    print('   - 1 Founder message created');
    print('   - ${galleryImages.length} Gallery images uploaded');
    print('   - ${memories.length} Memories uploaded');
    print('   - ${events.length} Events created');
    print('\n✨ Your app should now display all images correctly!');

  } catch (e) {
    print('❌ Error during setup: $e');
    exit(1);
  }

  exit(0);
}

Future<String?> uploadImage(
  FirebaseStorage storage,
  String localPath,
  String remotePath,
) async {
  try {
    final file = File(localPath);

    if (!await file.exists()) {
      print('⚠️  Warning: File not found: $localPath');
      return null;
    }

    final ref = storage.ref().child(remotePath);
    final uploadTask = await ref.putFile(file);
    final downloadUrl = await uploadTask.ref.getDownloadURL();

    return downloadUrl;
  } catch (e) {
    print('❌ Error uploading $localPath: $e');
    return null;
  }
}
