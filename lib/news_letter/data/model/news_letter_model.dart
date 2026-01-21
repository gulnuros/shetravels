
class NewsletterSubscriber {
  final String id;
  final String email;
  final String? firstName;
  final String? lastName;
  final DateTime subscribedAt;
  final bool isActive;
  final Map<String, String>? preferences;

  NewsletterSubscriber({
    required this.id,
    required this.email,
    this.firstName,
    this.lastName,
    required this.subscribedAt,
    this.isActive = true,
    this.preferences,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'subscribedAt': subscribedAt.toIso8601String(),
      'isActive': isActive,
      'preferences': preferences ?? {},
    };
  }

  factory NewsletterSubscriber.fromJson(Map<String, dynamic> json) {
    return NewsletterSubscriber(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      firstName: json['firstName'],
      lastName: json['lastName'],
      subscribedAt: DateTime.parse(json['subscribedAt']),
      isActive: json['isActive'] ?? true,
      preferences: Map<String, String>.from(json['preferences'] ?? {}),
    );
  }

  NewsletterSubscriber copyWith({
    String? id,
    String? email,
    String? firstName,
    String? lastName,
    DateTime? subscribedAt,
    bool? isActive,
    Map<String, String>? preferences,
  }) {
    return NewsletterSubscriber(
      id: id ?? this.id,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      subscribedAt: subscribedAt ?? this.subscribedAt,
      isActive: isActive ?? this.isActive,
      preferences: preferences ?? this.preferences,
    );
  }
}

class Newsletter {
  final String id;
  final String title;
  final String content;
  final String? htmlContent;
  final DateTime createdAt;
  final DateTime? sentAt;
  final String createdBy;
  final bool isDraft;
  final List<String> tags;
  final int recipientCount;
  final String? imageUrl;

  Newsletter({
    required this.id,
    required this.title,
    required this.content,
    this.htmlContent,
    required this.createdAt,
    this.sentAt,
    required this.createdBy,
    this.isDraft = true,
    this.tags = const [],
    this.recipientCount = 0,
    this.imageUrl,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'htmlContent': htmlContent,
      'createdAt': createdAt.toIso8601String(),
      'sentAt': sentAt?.toIso8601String(),
      'createdBy': createdBy,
      'isDraft': isDraft,
      'tags': tags,
      'recipientCount': recipientCount,
      'imageUrl': imageUrl,
    };
  }

  factory Newsletter.fromJson(Map<String, dynamic> json) {
    return Newsletter(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      htmlContent: json['htmlContent'],
      createdAt: DateTime.parse(json['createdAt']),
      sentAt: json['sentAt'] != null ? DateTime.parse(json['sentAt']) : null,
      createdBy: json['createdBy'] ?? '',
      isDraft: json['isDraft'] ?? true,
      tags: List<String>.from(json['tags'] ?? []),
      recipientCount: json['recipientCount'] ?? 0,
      imageUrl: json['imageUrl'],
    );
  }
}
