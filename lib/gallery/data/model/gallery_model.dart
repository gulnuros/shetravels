import 'package:cloud_firestore/cloud_firestore.dart';

class GalleryImage {
  final String? id;
  final String title;
  final String description;
  final String imageUrl;
  final String category;
  final Timestamp createdAt;

  GalleryImage({
    this.id,
    required this.title,
    this.description = '',
    required this.imageUrl,
    this.category = 'Adventures',
    required this.createdAt,
  });

  factory GalleryImage.fromFirestore(QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return GalleryImage(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      category: data['category'] ?? 'Adventures',
      createdAt: data['createdAt'] ?? Timestamp.now(),
    );
  }

  factory GalleryImage.fromJson(Map<String, dynamic> json) {
    return GalleryImage(
      title: json['title'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      description: json['description'] ?? '',
      category: json['category'] ?? 'Adventures',
      createdAt:
          json['createdAt'] != null
              ? Timestamp.fromMillisecondsSinceEpoch(json['createdAt'])
              : Timestamp.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'category': category,
      'createdAt': createdAt,
    };
  }

  GalleryImage copyWith({
    String? id,
    String? title,
    String? imageUrl,
    String? description,
    String? category,
    Timestamp? createdAt,
  }) {
    return GalleryImage(
      id: id ?? this.id,
      title: title ?? this.title,
      imageUrl: imageUrl ?? this.imageUrl,
      description: this.description,
      category: this.category,
      createdAt: this.createdAt,
    );
  }
}
