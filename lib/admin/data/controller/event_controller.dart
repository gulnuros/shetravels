import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shetravels/admin/data/event_model.dart';
import 'package:shetravels/admin/data/event_repository/event_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:shetravels/admin/views/widgets/create_or_edit_dialog.dart';
import 'package:shetravels/admin/views/widgets/error_success_snack_bar.dart';
import 'package:universal_io/io.dart';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';

final eventRepositoryProvider = Provider((ref) => EventRepository());

final upcomingEventsProvider = FutureProvider<List<Event>>((ref) async {
  final repo = ref.watch(eventRepositoryProvider);
  return await repo.fetchEvents();
});

final eventManagerDashboardProvider =
    ChangeNotifierProvider<EventDashboardNotifier>((ref) {
      return EventDashboardNotifier(ref);
    });

class EventDashboardNotifier extends ChangeNotifier {
  final Ref ref;

  EventDashboardNotifier(this.ref);
  bool _loading = false;
  bool get loading => _loading;

  set loading(bool state) {
    _loading = state;
    notifyListeners();
  }

  List<Event> events = [];

  User? currentUser;
  final _eventsRef = FirebaseFirestore.instance.collection('events');
  final _auth = FirebaseAuth.instance;

  bool isLoading = false;

  void _setLoading(bool value) {
    isLoading = value;
    notifyListeners();
  }

  void _setEvents(List<Event> newEvents) {
    events = newEvents;
    notifyListeners();
  }

  Future<void> checkAuthAndLoadEvents(BuildContext context) async {
    _setLoading(true);

    currentUser = _auth.currentUser;

    if (currentUser == null) {
      await _signInUser(context);
    }

    if (currentUser != null) {
      await loadEvents(context);
    }

    _setLoading(false);
  }

  Future<void> _signInUser(BuildContext context) async {
    try {
      final userCredential = await _auth.signInAnonymously();
      currentUser = userCredential.user;
      debugPrint('Signed in user: ${currentUser?.uid}');
    } catch (e) {
      debugPrint('Sign in error: $e');
      showErrorSnackBar('Authentication failed: $e', context);
    }
  }

  Future<void> loadEvents(BuildContext context) async {
    if (currentUser == null) return;

    try {
      _setLoading(true);
      final snapshot = await _eventsRef.get();
      final fetched =
          snapshot.docs.map((doc) => Event.fromFirestore(doc)).toList();
      _setEvents(fetched);
    } catch (e) {
      debugPrint('Load events error: $e');
      showErrorSnackBar('Failed to load events: $e', context);
    } finally {
      _setLoading(false);
    }
  }




// 🆕 Updated addEvent method to include creator info
Future<void> addEvent(Event event, BuildContext context) async {
  if (currentUser == null) {
    showErrorSnackBar('Please authenticate first', context);
    return;
  }

  try {
    final eventData = Event(
      title: event.title,
      date: event.date,
      description: event.description,
      imageUrl: event.imageUrl,
      location: event.location,
      price: event.price,
      availableSlots: event.availableSlots,
      subscribedUsers: [], // Start with empty list
      createdAt: DateTime.now(),
      createdBy: currentUser!.uid,
    );
    
    await _eventsRef.add(eventData.toJson());
    await loadEvents(context);
    showSuccessSnackBar('Event added successfully', context);
  } catch (e) {
    debugPrint('Add event error: $e');
    showErrorSnackBar('Failed to add event: $e', context);
  }
}



  // Future<void> addEvent(Event event, BuildContext context) async {
  //   if (currentUser == null) {
  //     showErrorSnackBar('Please authenticate first', context);
  //     return;
  //   }

  //   try {
  //     await _eventsRef.add(event.toJson());
  //     await loadEvents(context);
  //     showSuccessSnackBar('Event added successfully', context);
  //   } catch (e) {
  //     debugPrint('Add event error: $e');
  //     showErrorSnackBar('Failed to add event: $e', context);
  //   }
  // }

  // NEW: Edit event method
  Future<void> editEvent(Event event, BuildContext context) async {
    if (currentUser == null) {
      showErrorSnackBar('Please authenticate first', context);
      return;
    }

    if (event.id == null) {
      showErrorSnackBar('Event ID is missing', context);
      return;
    }

    try {
      await _eventsRef.doc(event.id).update(event.toJson());
      await loadEvents(context);
      showSuccessSnackBar('Event updated successfully', context);
    } catch (e) {
      debugPrint('Edit event error: $e');
      showErrorSnackBar('Failed to update event: $e', context);
    }
  }

  Future<void> removeEvent(String id, BuildContext context) async {
    if (currentUser == null) {
      showErrorSnackBar('Please authenticate first', context);
      return;
    }

    try {
      await _eventsRef.doc(id).delete();
      await loadEvents(context);
      showSuccessSnackBar('Event deleted successfully', context);
    } catch (e) {
      debugPrint('Remove event error: $e');
      showErrorSnackBar('Failed to remove event: $e', context);
    }
  }

  Future<String?> uploadImage({
    Uint8List? bytes,
    String? filePath,
    BuildContext? context,
  }) async {
    if (currentUser == null) {
      showErrorSnackBar('Please authenticate first', context!);
      return null;
    }

    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final ref = FirebaseStorage.instance.ref('events/$timestamp.jpg');

      UploadTask uploadTask;

      if (kIsWeb && bytes != null) {
        final metadata = SettableMetadata(
          contentType: 'image/jpeg',
          customMetadata: {'uploadedBy': currentUser!.uid},
        );
        uploadTask = ref.putData(bytes, metadata);
      } else if (!kIsWeb && filePath != null) {
        final metadata = SettableMetadata(
          contentType: 'image/jpeg',
          customMetadata: {'uploadedBy': currentUser!.uid},
        );
        uploadTask = ref.putFile(File(filePath), metadata);
      } else {
        throw Exception("Invalid image data provided");
      }

      final snapshot = await uploadTask;
      final downloadURL = await snapshot.ref.getDownloadURL();
      debugPrint('Image uploaded successfully: $downloadURL');

      return downloadURL;
    } catch (e) {
      debugPrint('Image upload error: $e');
      showErrorSnackBar('Image upload failed: $e', context!);
      return null;
    }
  }

  void showAddDialog(BuildContext context, WidgetRef ref) {
    _showEventDialog(context: context, ref: ref);
  }

  void showEditDialog(BuildContext context, Event event, WidgetRef ref) {
    _showEventDialog(context: context, existingEvent: event, ref: ref);
  }

  void _showEventDialog({
    Event? existingEvent,
    required BuildContext context,
    required WidgetRef ref,
  }) {
    final isEditing = existingEvent != null;

    final titleController = TextEditingController(
      text: existingEvent?.title ?? '',
    );
    final dateController = TextEditingController(
      text: existingEvent?.date ?? '',
    );
    final descController = TextEditingController(
      text: existingEvent?.description ?? '',
    );
    final slotsController = TextEditingController(
      text: existingEvent?.availableSlots.toString() ?? '1',
    );
    final locationController = TextEditingController(
      text: existingEvent?.location ?? '',
    );
    final priceController = TextEditingController(
      text:
          existingEvent != null
              ? "\$${(existingEvent.price / 100).toStringAsFixed(2)}"
              : '',
    );

    Uint8List? imageBytes;
    String? imageUrl = existingEvent?.imageUrl;
    bool isUploading = false;

    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.7),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        return createOrEditDialog(
          animation,
          isEditing,
          titleController,
          existingEvent, // 👈 safe nullable pass
          dateController,
          locationController,
          priceController,
          descController,
          slotsController,
          imageBytes,
          imageUrl,
          isUploading,
          ref,
        );
      },
    );
  }
  // Add these methods to your EventManagerDashboard class

Future<void> subscribeToEvent(String eventId, BuildContext context) async {
  if (currentUser == null) {
    showErrorSnackBar('Please authenticate first', context);
    return;
  }

  try {
    final eventDoc = await _eventsRef.doc(eventId).get();
    if (!eventDoc.exists) {
      showErrorSnackBar('Event not found', context);
      return;
    }

    final event = Event.fromFirestore(eventDoc);
    
    // Check if user is already subscribed
    if (event.subscribedUsers?.contains(currentUser!.uid) == true) {
      showErrorSnackBar('You are already subscribed to this event', context);
      return;
    }
    
    // Check if slots are available
    if (event.isSoldOut) {
      showErrorSnackBar('Sorry, this event is sold out', context);
      return;
    }

    // Add user to subscribers list
    await _eventsRef.doc(eventId).update({
      'subscribedUsers': FieldValue.arrayUnion([currentUser!.uid]),
    });

    await loadEvents(context);
    showSuccessSnackBar('Successfully joined the event!', context);
    
  } catch (e) {
    debugPrint('Subscribe to event error: $e');
    showErrorSnackBar('Failed to join event: $e', context);
  }
}

Future<void> unsubscribeFromEvent(String eventId, BuildContext context) async {
  if (currentUser == null) {
    showErrorSnackBar('Please authenticate first', context);
    return;
  }

  try {
    // Remove user from subscribers list
    await _eventsRef.doc(eventId).update({
      'subscribedUsers': FieldValue.arrayRemove([currentUser!.uid]),
    });

    await loadEvents(context);
    showSuccessSnackBar('Successfully left the event', context);
    
  } catch (e) {
    debugPrint('Unsubscribe from event error: $e');
    showErrorSnackBar('Failed to leave event: $e', context);
  }
}


// 🆕 Check if current user is subscribed to an event
bool isUserSubscribed(Event event) {
  if (currentUser == null) return false;
  return event.subscribedUsers?.contains(currentUser!.uid) ?? false;
}

// 🆕 Get subscribed events for current user
List<Event> getUserSubscribedEvents() {
  if (currentUser == null) return [];
  return events.where((event) => isUserSubscribed(event)).toList();
}
}
