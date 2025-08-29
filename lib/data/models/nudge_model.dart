// Add these enums at the top of your nudge_model.dart file
enum NudgeType { personal, group, friend }
enum GroupType { school, work, family, custom }
enum NudgeStatus { active, pending, completed, paused }

class Nudge {
  final String id;
  final String title;
  final String description;
  final String category;
  final String icon;
  final bool isActive;
  final bool isAIGenerated;
  final DateTime createdAt;
  
  
  // New fields for categorization
  final NudgeType type;
  final String? groupId;
  final String? groupName;
  final GroupType? groupType;
  final String? friendId;
  final String? friendName;
  final List<String> participants;
  final String createdBy;
  final NudgeStatus status;
  final int? streak;
  final DateTime? dueDate;

  const Nudge({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.icon,
    required this.isActive,
    required this.createdAt,
    this.type = NudgeType.personal,
    this.isAIGenerated = false,
    this.groupId,
    this.groupName,
    this.groupType,
    this.friendId,
    this.friendName,
    this.participants = const [],
    required this.createdBy,
    this.status = NudgeStatus.active,
    this.streak,
    this.dueDate,
  });

  // Helper getters
  bool get isPersonal => type == NudgeType.personal;
  bool get isGroup => type == NudgeType.group;
  bool get isFriend => type == NudgeType.friend;
  
  String get displayName {
    switch (type) {
      case NudgeType.personal:
        return title;
      case NudgeType.group:
        return '$title (${groupName ?? 'Group'})';
      case NudgeType.friend:
        return '$title (with ${friendName ?? 'Friend'})';
    }
  }

  Nudge copyWith({
    String? id,
    String? title,
    String? description,
    String? category,
    String? icon,
    bool? isActive,
    DateTime? createdAt,
    NudgeType? type,
    String? groupId,
    String? groupName,
    GroupType? groupType,
    String? friendId,
    String? friendName,
    List<String>? participants,
    String? createdBy,
    NudgeStatus? status,
    int? streak,
    DateTime? dueDate,
  }) {
    return Nudge(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      icon: icon ?? this.icon,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      type: type ?? this.type,
      groupId: groupId ?? this.groupId,
      groupName: groupName ?? this.groupName,
      groupType: groupType ?? this.groupType,
      friendId: friendId ?? this.friendId,
      friendName: friendName ?? this.friendName,
      participants: participants ?? this.participants,
      createdBy: createdBy ?? this.createdBy,
      status: status ?? this.status,
      streak: streak ?? this.streak,
      dueDate: dueDate ?? this.dueDate,
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
      'type': type.name,
      'groupId': groupId,
      'groupName': groupName,
      'groupType': groupType?.name,
      'friendId': friendId,
      'friendName': friendName,
      'participants': participants,
      'createdBy': createdBy,
      'status': status.name,
      'streak': streak,
      'dueDate': dueDate?.toIso8601String(),
      'is_ai_generated': isAIGenerated,
    };
  }

  factory Nudge.fromJson(Map<String, dynamic> json) {
    return Nudge(
      id: json['id'],
      isAIGenerated: json['is_ai_generated'] ?? false,
      title: json['title'],
      description: json['description'],
      category: json['category'],
      icon: json['icon'],
      isActive: json['isActive'],
      createdAt: DateTime.parse(json['createdAt']),
      type: NudgeType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => NudgeType.personal,
      ),
      groupId: json['groupId'],
      groupName: json['groupName'],
      groupType: json['groupType'] != null
          ? GroupType.values.firstWhere((e) => e.name == json['groupType'])
          : null,
      friendId: json['friendId'],
      friendName: json['friendName'],
      participants: List<String>.from(json['participants'] ?? []),
      createdBy: json['createdBy'] ?? 'self',
      status: NudgeStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => NudgeStatus.active,
      ),
      streak: json['streak'],
      dueDate: json['dueDate'] != null 
          ? DateTime.parse(json['dueDate']) 
          : null,
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
        other.createdAt == createdAt &&
        other.type == type &&
        other.groupId == groupId &&
        other.groupName == groupName &&
        other.groupType == groupType &&
        other.friendId == friendId &&
        other.friendName == friendName &&
        other.participants == participants &&
        other.createdBy == createdBy &&
        other.status == status &&
        other.streak == streak &&
        other.dueDate == dueDate;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      title,
      description,
      category,
      icon,
      isActive,
      createdAt,
      type,
      groupId,
      groupName,
      groupType,
      friendId,
      friendName,
      participants,
      createdBy,
      status,
      streak,
      dueDate,
    );
  }

  @override
  String toString() {
    return 'Nudge(id: $id, title: $title, type: $type, category: $category, isActive: $isActive)';
  }
}

// Helper factory methods for creating different nudge types
extension NudgeFactory on Nudge {
  static Nudge createPersonal({
    required String id,
    required String title,
    required String description,
    required String category,
    required String icon,
    required String createdBy,
    bool isActive = true,
  }) {
    return Nudge(
      id: id,
      title: title,
      description: description,
      category: category,
      icon: icon,
      isActive: isActive,
      createdAt: DateTime.now(),
      type: NudgeType.personal,
      createdBy: createdBy,
    );
  }

  static Nudge createGroup({
    required String id,
    required String title,
    required String description,
    required String category,
    required String icon,
    required String groupId,
    required String groupName,
    required GroupType groupType,
    required String createdBy,
    required List<String> participants,
    DateTime? dueDate,
    bool isActive = true,
  }) {
    return Nudge(
      id: id,
      title: title,
      description: description,
      category: category,
      icon: icon,
      isActive: isActive,
      createdAt: DateTime.now(),
      type: NudgeType.group,
      groupId: groupId,
      groupName: groupName,
      groupType: groupType,
      createdBy: createdBy,
      participants: participants,
      dueDate: dueDate,
    );
  }

  static Nudge createFriend({
    required String id,
    required String title,
    required String description,
    required String category,
    required String icon,
    required String friendId,
    required String friendName,
    required String createdBy,
    bool isActive = true,
    int? streak,
  }) {
    return Nudge(
      id: id,
      title: title,
      description: description,
      category: category,
      icon: icon,
      isActive: isActive,
      createdAt: DateTime.now(),
      type: NudgeType.friend,
      friendId: friendId,
      friendName: friendName,
      createdBy: createdBy,
      participants: [createdBy, friendId],
      streak: streak,
    );
  }
}