import 'dart:io';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shetravels/common/data/models/founder_message.dart';

final founderServiceProvider = Provider<FounderService>((ref) {
  return FounderService();
});

class FounderService {
  final FirebaseFirestore firestore;
  final FirebaseStorage storage;

  FounderService({FirebaseFirestore? firestore, FirebaseStorage? storage})
    : firestore = firestore ?? FirebaseFirestore.instance,
      storage = storage ?? FirebaseStorage.instance;

  static const String collectionName = 'founderMessages';

  Future<List<FounderMessage>> getAllFounderMessages() async {
    final snapshot =
        await firestore
            .collection(collectionName)
            .orderBy('createdAt', descending: true)
            .get();

    return snapshot.docs
        .map((doc) => FounderMessage.fromJson({...doc.data(), 'id': doc.id}))
        .toList();
  }

  Future<List<FounderMessage>> getAllFounderMessagesAdmin() async {
    return getAllFounderMessages();
  }

 Future<void> createFounderMessage(
    FounderMessage founderMessage, {
    File? imageFile,
    Uint8List? imageBytes,
    String? fileName,
  }) async {
    try {
      String? imageUrl;

      if (imageFile != null) {
        final ref = storage.ref().child(
          'founder_images/${DateTime.now().millisecondsSinceEpoch}_${imageFile.path.split('/').last}',
        );
        await ref.putFile(imageFile);
        imageUrl = await ref.getDownloadURL();
      } else if (imageBytes != null && fileName != null) {
        final ref = storage.ref().child(
          'founder_images/${DateTime.now().millisecondsSinceEpoch}_$fileName',
        );
        await ref.putData(imageBytes, SettableMetadata(contentType: 'image/png'));
        imageUrl = await ref.getDownloadURL();
      }

      final data = founderMessage.toJson()..remove('id');
      data['createdAt'] = DateTime.now().toIso8601String();
      if (imageUrl != null) {
        data['imageUrl'] = imageUrl;
      }

      await firestore.collection(collectionName).add(data);
    } catch (e) {
      rethrow;
    }
  }
  Future<void> updateFounderMessage(FounderMessage founderMessage) async {
    final data = founderMessage.toJson()..remove('id');
    data['updatedAt'] = DateTime.now().toIso8601String();
    await firestore
        .collection(collectionName)
        .doc(founderMessage.id)
        .update(data);
  }

  Future<void> deleteFounderMessage(String id) async {
    await firestore.collection(collectionName).doc(id).delete();
  }

  Future<void> toggleFounderMessageStatus(String id) async {
    final batch = firestore.batch();

    final allDocs = await firestore.collection(collectionName).get();
    for (var doc in allDocs.docs) {
      batch.update(doc.reference, {
        'isActive': false,
        'updatedAt': DateTime.now().toIso8601String(),
      });
    }

    batch.update(firestore.collection(collectionName).doc(id), {
      'isActive': true,
      'updatedAt': DateTime.now().toIso8601String(),
    });

    await batch.commit();
  }
  Future<String> uploadImage(File imageFile, String fileName) async {
    final ref = storage.ref().child('founder_images/$fileName');
    final uploadTask = await ref.putFile(imageFile);
    return await uploadTask.ref.getDownloadURL();
  }
}
