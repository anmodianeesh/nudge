// lib/data/models/premade_nudge.dart
class PremadeNudge {
  final String id;
  final String title;
  final String description;
  final bool isCustom; // true if user-created
  final DateTime createdAt;

  const PremadeNudge({
    required this.id,
    required this.title,
    required this.description,
    this.isCustom = false,
    required this.createdAt,
  });

  factory PremadeNudge.fromJson(Map<String, dynamic> json) {
    return PremadeNudge(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      isCustom: (json['isCustom'] as bool?) ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'isCustom': isCustom,
        'createdAt': createdAt.toIso8601String(),
      };

  PremadeNudge copyWith({
    String? id,
    String? title,
    String? description,
    bool? isCustom,
    DateTime? createdAt,
  }) {
    return PremadeNudge(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      isCustom: isCustom ?? this.isCustom,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

