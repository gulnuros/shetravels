import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shetravels/news_letter/data/model/news_letter_model.dart';
import 'package:shetravels/news_letter/data/repository/news_letter_repository.dart';

final newsletterRepositoryProvider = Provider<NewsletterRepository>((ref) {
  return NewsletterRepository();
});

final newsletterControllerProvider =
    StateNotifierProvider<NewsletterController, AsyncValue<void>>((ref) {
      return NewsletterController(ref.watch(newsletterRepositoryProvider));
    });

final subscribersProvider = StreamProvider<List<NewsletterSubscriber>>((ref) {
  return ref.watch(newsletterRepositoryProvider).getAllSubscribers();
});

final newslettersProvider = StreamProvider<List<Newsletter>>((ref) {
  return ref.watch(newsletterRepositoryProvider).getAllNewsletters();
});

final subscribersCountProvider = FutureProvider<int>((ref) {
  return ref.watch(newsletterRepositoryProvider).getActiveSubscribersCount();
});

class NewsletterController extends StateNotifier<AsyncValue<void>> {
  final NewsletterRepository _repository;

  NewsletterController(this._repository) : super(const AsyncValue.data(null));

  Future<void> subscribeToNewsletter({
    required String email,
    String? firstName,
    String? lastName,
    Map<String, String>? preferences,
  }) async {
    state = const AsyncValue.loading();
    try {
      final isSubscribed = await _repository.isEmailSubscribed(email);
      if (isSubscribed) {
        state = AsyncValue.error(
          'Email is already subscribed to our newsletter',
          StackTrace.current,
        );
        return;
      }

      await _repository.subscribeToNewsletter(
        email: email,
        firstName: firstName,
        lastName: lastName,
        preferences: preferences,
      );

      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> createNewsletter(Newsletter newsletter) async {
    state = const AsyncValue.loading();
    try {
      await _repository.createNewsletter(newsletter);
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> updateNewsletter(String id, Map<String, dynamic> updates) async {
    state = const AsyncValue.loading();
    try {
      await _repository.updateNewsletter(id, updates);
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> deleteNewsletter(String id) async {
    state = const AsyncValue.loading();
    try {
      await _repository.deleteNewsletter(id);
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> unsubscribeEmail(String email) async {
    state = const AsyncValue.loading();
    try {
      await _repository.unsubscribeEmail(email);
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}
