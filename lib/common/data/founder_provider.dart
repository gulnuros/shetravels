import 'dart:io';

import 'package:shetravels/common/data/founder_services.dart';
import 'package:shetravels/common/data/models/founder_message.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FounderState {
  final List<FounderMessage> founderMessages;
  final List<FounderMessage> adminFounderMessages;
  final bool isLoading;
  final String? error;

  FounderState({
    this.founderMessages = const [],
    this.adminFounderMessages = const [],
    this.isLoading = false,
    this.error,
  });

  FounderState copyWith({
    List<FounderMessage>? founderMessages,
    List<FounderMessage>? adminFounderMessages,
    bool? isLoading,
    String? error,
  }) {
    return FounderState(
      founderMessages: founderMessages ?? this.founderMessages,
      adminFounderMessages: adminFounderMessages ?? this.adminFounderMessages,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class FounderNotifier extends StateNotifier<FounderState> {
  FounderNotifier(this.ref) : super(FounderState());

  Ref ref;

  


  Future<void> loadFounderMessages() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final messages =
          await ref.read(founderServiceProvider).getAllFounderMessages();
      state = state.copyWith(founderMessages: messages, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  Future<void> loadAdminFounderMessages() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final messages =
          await ref.read(founderServiceProvider).getAllFounderMessagesAdmin();
      state = state.copyWith(adminFounderMessages: messages, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }
Future<void> createFounderMessage(FounderMessage message, {File? imageFile}) async {
  try {
    await ref.read(founderServiceProvider)
        .createFounderMessage(message, imageFile: imageFile);

    await loadAdminFounderMessages();
    await loadFounderMessages();
  } catch (e) {
    state = state.copyWith(error: e.toString());
  }
}

  Future<void> updateFounderMessage(FounderMessage message) async {
    try {
      await ref.read(founderServiceProvider).updateFounderMessage(message);
      await loadAdminFounderMessages();
      await loadFounderMessages();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> deleteFounderMessage(String id) async {
    try {
      await ref.read(founderServiceProvider).deleteFounderMessage(id);
      await loadAdminFounderMessages();
      await loadFounderMessages();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> toggleFounderMessageStatus(String id) async {
    try {
      await ref.read(founderServiceProvider).toggleFounderMessageStatus(id);
      await loadAdminFounderMessages();
      await loadFounderMessages();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
}

final founderProvider = StateNotifierProvider<FounderNotifier, FounderState>((
  ref,
) {
  return FounderNotifier(ref);
});
