import 'package:cloud_firestore/cloud_firestore.dart';


class Event {
  final String? id;
  final String title;
  final String date;
  final String description;
  final String imageUrl;
  final String location;
  final int price; 
  final int availableSlots; 
  final List<String>? subscribedUsers; 
  final DateTime? createdAt; 
  final String? createdBy; 

  Event({
    this.id,
    required this.title,
    required this.date,
    required this.description,
    required this.imageUrl,
    required this.location,
    required this.price,
    required this.availableSlots,
    this.subscribedUsers,
    this.createdAt,
    this.createdBy,
  });

  factory Event.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Event(
      id: doc.id,
      title: data['title'],
      date: data['date'],
      description: data['description'],
      imageUrl: data['imageUrl'],
      location: data['location'],
      price: data['price'] ?? 0,
      availableSlots: data['availableSlots'] ?? 1,
      subscribedUsers: data['subscribedUsers'] != null 
          ? List<String>.from(data['subscribedUsers']) 
          : [],
      createdAt: data['createdAt'] != null 
          ? (data['createdAt'] as Timestamp).toDate() 
          : null,
      createdBy: data['createdBy'],
    );
  }

  Map<String, dynamic> toJson() => {
        'title': title,
        'date': date,
        'description': description,
        'imageUrl': imageUrl,
        'location': location,
        'price': price,
        'availableSlots': availableSlots,
        'subscribedUsers': subscribedUsers ?? [],
        'createdAt': createdAt ?? FieldValue.serverTimestamp(),
        'createdBy': createdBy,
      };


  int get remainingSlots => availableSlots - (subscribedUsers?.length ?? 0);
  bool get isSoldOut => remainingSlots <= 0;
  bool get isLowStock => remainingSlots <= 5 && remainingSlots > 0;
}