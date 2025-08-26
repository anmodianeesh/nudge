class Nudge {
  final String id;
  final String title;
  final String description;
  final String frequency;
  final String category;
  final bool isActive;
  final int streak;
  final DateTime createdAt;
  final String userId;

  const Nudge({
    required this.id,
    required this.title,
    required this.description,
    required this.frequency,
    required this.category,
    required this.isActive,
    required this.streak,
    required this.createdAt,
    required this.userId,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'frequency': frequency,
      'category': category,
      'isActive': isActive,
      'streak': streak,
      'createdAt': createdAt.toIso8601String(),
      'userId': userId,
    };
  }

  factory Nudge.fromJson(Map<String, dynamic> json) {
    return Nudge(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      frequency: json['frequency'] ?? '',
      category: json['category'] ?? '',
      isActive: json['isActive'] ?? false,
      streak: json['streak'] ?? 0,
      createdAt: DateTime.parse(json['createdAt']),
      userId: json['userId'] ?? '',
    );
  }
}