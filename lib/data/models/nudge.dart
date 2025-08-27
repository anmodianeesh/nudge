class Nudge {
  final String id;
  final String title;
  final String description;
  final String category;
  final String icon;
  final bool isActive;
  final DateTime createdAt;

  const Nudge({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.icon,
    required this.isActive,
    required this.createdAt,
  });

  Nudge copyWith({
    String? id,
    String? title,
    String? description,
    String? category,
    String? icon,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return Nudge(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      icon: icon ?? this.icon,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category,
      'icon': icon,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Nudge.fromJson(Map<String, dynamic> json) {
    return Nudge(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      category: json['category'],
      icon: json['icon'],
      isActive: json['isActive'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Nudge &&
        other.id == id &&
        other.title == title &&
        other.description == description &&
        other.category == category &&
        other.icon == icon &&
        other.isActive == isActive &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        title.hashCode ^
        description.hashCode ^
        category.hashCode ^
        icon.hashCode ^
        isActive.hashCode ^
        createdAt.hashCode;
  }

  @override
  String toString() {
    return 'Nudge(id: $id, title: $title, category: $category, isActive: $isActive)';
  }
}