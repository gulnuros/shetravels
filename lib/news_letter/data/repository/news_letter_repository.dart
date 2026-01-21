
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shetravels/news_letter/data/model/news_letter_model.dart';

class NewsletterRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String subscribersCollection = 'newsletter_subscribers';
  static const String newslettersCollection = 'newsletters';

  Future<bool> subscribeToNewsletter({
    required String email,
    String? firstName,
    String? lastName,
    Map<String, String>? preferences,
  }) async {
    try {
      final subscriberId = _firestore.collection(subscribersCollection).doc().id;
      
      final subscriber = NewsletterSubscriber(
        id: subscriberId,
        email: email.toLowerCase().trim(),
        firstName: firstName?.trim(),
        lastName: lastName?.trim(),
        subscribedAt: DateTime.now(),
        preferences: preferences,
      );

      await _firestore
          .collection(subscribersCollection)
          .doc(subscriberId)
          .set(subscriber.toJson());

      return true;
    } catch (e) {
      throw Exception('Failed to subscribe: $e');
    }
  }

  Future<bool> isEmailSubscribed(String email) async {
    try {
      final querySnapshot = await _firestore
          .collection(subscribersCollection)
          .where('email', isEqualTo: email.toLowerCase().trim())
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();

      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  Stream<List<NewsletterSubscriber>> getAllSubscribers() {
    return _firestore
        .collection(subscribersCollection)
        .orderBy('subscribedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => NewsletterSubscriber.fromJson(doc.data()))
          .toList();
    });
  }

  Future<int> getActiveSubscribersCount() async {
    try {
      final querySnapshot = await _firestore
          .collection(subscribersCollection)
          .where('isActive', isEqualTo: true)
          .get();
      
      return querySnapshot.docs.length;
    } catch (e) {
      return 0;
    }
  }
  Future<bool> unsubscribeEmail(String email) async {
    try {
      final querySnapshot = await _firestore
          .collection(subscribersCollection)
          .where('email', isEqualTo: email.toLowerCase().trim())
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        await querySnapshot.docs.first.reference.update({'isActive': false});
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<String> createNewsletter(Newsletter newsletter) async {
    try {
      final docRef = await _firestore
          .collection(newslettersCollection)
          .add(newsletter.toJson());
      
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create newsletter: $e');
    }
  }
  Stream<List<Newsletter>> getAllNewsletters() {
    return _firestore
        .collection(newslettersCollection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Newsletter.fromJson({...doc.data(), 'id': doc.id}))
          .toList();
    });
  }

  Future<bool> updateNewsletter(String id, Map<String, dynamic> updates) async {
    try {
      await _firestore
          .collection(newslettersCollection)
          .doc(id)
          .update(updates);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteNewsletter(String id) async {
    try {
      await _firestore
          .collection(newslettersCollection)
          .doc(id)
          .delete();
      return true;
    } catch (e) {
      return false;
    }
  }
}
