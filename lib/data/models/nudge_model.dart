// lib/data/models/nudge_model.dart

// ——— Your original enums (kept) ———
enum NudgeType { personal, group, friend }
enum GroupType { school, work, family, custom }
enum NudgeStatus { active, pending, completed, paused }

// ——— Small helpers for safe enum parsing ———
T _enumParseOr<T>(Iterable<T> values, String? name, T fallback) {
  if (name == null) return fallback;
  for (final v in values) {
    if (v.toString().split('.').last == name) return v;
  }
  return fallback;
}

class Nudge {
  // Core
  final String id;                 // keep required in app (we can let DB generate if repo omits id)
  final String title;
  final String description;
  final String category;
  final String icon;
  final bool isActive;
  final bool isAIGenerated;
  final DateTime createdAt;
  final String frequency;

  // Ownership / evolution
  final String userId;             // NEW: owner/user scope
  final int schemaVersion;         // NEW: version for evolvability (defaults to 1)

  // Flexible, AI-evolvable fields (go to JSONB in DB)
  final Map<String, dynamic> aiPolicy;  // e.g., {tone: 'gentle', maxPerDay: 2, strategy: 'scale_down'}
  final Map<String, dynamic> schedule;  // e.g., {timesPerDay: 2, windows: [{start:'09:00', end:'12:00'}]}
  final Map<String, dynamic> stats;     // e.g., {streak: 4, completionRate7d: 0.42}
  final Map<String, dynamic> ext;       // future experiments/flags

  // Your categorization
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
    // required core
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.icon,
    required this.isActive,
    required this.createdAt,
        required this.frequency,


    // ownership/evolution
    this.userId = '',                     // set when signed-in; can be empty pre-auth
    this.schemaVersion = 1,

    // flexible blobs
    this.aiPolicy = const {},
    this.schedule = const {},
    this.stats = const {},
    this.ext = const {},

    // categorization
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

  // —— Helper getters (kept) ——
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

  // —— copyWith extended to new fields ——
  Nudge copyWith({
    String? id,
    String? title,
    String? description,
    String? category,
    String? icon,
    bool? isActive,
    DateTime? createdAt,

    String? userId,
    int? schemaVersion,
    Map<String, dynamic>? aiPolicy,
    Map<String, dynamic>? schedule,
    Map<String, dynamic>? stats,
    Map<String, dynamic>? ext,

    NudgeType? type,
    bool? isAIGenerated,
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
      

      userId: userId ?? this.userId,
      schemaVersion: schemaVersion ?? this.schemaVersion,
      aiPolicy: aiPolicy ?? this.aiPolicy,
      schedule: schedule ?? this.schedule,
      stats: stats ?? this.stats,
      ext: ext ?? this.ext,

      type: type ?? this.type,
      isAIGenerated: isAIGenerated ?? this.isAIGenerated,
      groupId: groupId ?? this.groupId,
      groupName: groupName ?? this.groupName,
      groupType: groupType ?? this.groupType,
      friendId: friendId ?? this.friendId,
      friendName: friendName ?? this.friendName,
      participants: participants ?? this.participants,
      createdBy: createdBy ?? this.createdBy,
      status: status ?? this.status,
      streak: streak ?? this.streak,
      dueDate: dueDate ?? this.dueDate, frequency: '',
    );
  }

  // —— App/Local JSON (camelCase), keeps your existing shape ——
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'description': description,
      'category': category,
      'icon': icon,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),

      'schemaVersion': schemaVersion,
      'aiPolicy': aiPolicy,
      'schedule': schedule,
      'stats': stats,
      'ext': ext,

      'type': type.name,
      'is_ai_generated': isAIGenerated,
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
    };
  }

  factory Nudge.fromJson(Map<String, dynamic> json) {
    return Nudge(
      id: json['id'],
      userId: json['userId'] ?? '',
      title: json['title'],
      description: json['description'],
      category: json['category'],
      icon: json['icon'],
      isActive: json['isActive'],
      frequency: json['frequency'] as String? ?? 'daily',
      createdAt: DateTime.parse(json['createdAt']),
      schemaVersion: json['schemaVersion'] ?? 1,
      aiPolicy: Map<String, dynamic>.from(json['aiPolicy'] ?? {}),
      schedule: Map<String, dynamic>.from(json['schedule'] ?? {}),
      stats: Map<String, dynamic>.from(json['stats'] ?? {}),
      ext: Map<String, dynamic>.from(json['ext'] ?? {}),
      type: _enumParseOr(NudgeType.values, json['type'], NudgeType.personal),
      isAIGenerated: json['is_ai_generated'] ?? false,
      groupId: json['groupId'],
      groupName: json['groupName'],
      groupType: json['groupType'] != null
          ? _enumParseOr(GroupType.values, json['groupType'], GroupType.custom)
          : null,
      friendId: json['friendId'],
      friendName: json['friendName'],
      participants: List<String>.from(json['participants'] ?? []),
      createdBy: json['createdBy'] ?? 'self',
      status: _enumParseOr(NudgeStatus.values, json['status'], NudgeStatus.active),
      streak: json['streak'],
      dueDate: json['dueDate'] != null ? DateTime.parse(json['dueDate']) : null,
    );
  }

  // —— DB JSON (snake_case) for Supabase tables ——
  Map<String, dynamic> toDbJson({bool includeId = true}) {
    final map = <String, dynamic>{
      'user_id': userId,
      'title': title,
      'description': description,
      'category': category,
      'icon': icon,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'schema_version': schemaVersion,
      'ai_policy': aiPolicy,
      'schedule': schedule,
      'stats': stats,
      'ext': ext,
      'type': type.name,
      'is_ai_generated': isAIGenerated,
      'group_id': groupId,
      'group_name': groupName,
      'group_type': groupType?.name,
      'friend_id': friendId,
      'friend_name': friendName,
      'participants': participants,
      'created_by': createdBy,
      'status': status.name,
      'streak': streak,
      'due_date': dueDate?.toIso8601String(),
    };
    if (includeId) map['id'] = id;
    return map;
  }

  factory Nudge.fromDb(Map<String, dynamic> j) {
    return Nudge(
      id: (j['id'] ?? '') as String,
      userId: (j['user_id'] ?? '') as String,
      title: (j['title'] ?? '') as String,
      description: (j['description'] ?? '') as String,
      category: (j['category'] ?? '') as String,
      icon: (j['icon'] ?? '') as String,
      isActive: (j['is_active'] ?? true) as bool,
      createdAt: j['created_at'] != null ? DateTime.parse(j['created_at']) : DateTime.now(),
      schemaVersion: (j['schema_version'] ?? 1) as int,
      aiPolicy: Map<String, dynamic>.from(j['ai_policy'] ?? {}),
      schedule: Map<String, dynamic>.from(j['schedule'] ?? {}),
      stats: Map<String, dynamic>.from(j['stats'] ?? {}),
      ext: Map<String, dynamic>.from(j['ext'] ?? {}),
      type: _enumParseOr(NudgeType.values, j['type'], NudgeType.personal),
      isAIGenerated: (j['is_ai_generated'] ?? false) as bool,
      groupId: j['group_id'],
      groupName: j['group_name'],
      groupType: j['group_type'] != null
          ? _enumParseOr(GroupType.values, j['group_type'], GroupType.custom)
          : null,
      friendId: j['friend_id'],
      friendName: j['friend_name'],
      participants: List<String>.from(j['participants'] ?? []),
      createdBy: (j['created_by'] ?? 'self') as String,
      status: _enumParseOr(NudgeStatus.values, j['status'], NudgeStatus.active),
      streak: j['streak'],
      dueDate: j['due_date'] != null ? DateTime.parse(j['due_date']) : null, frequency: '',
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
        _listEquals(other.participants, participants) &&
        other.createdBy == createdBy &&
        other.status == status &&
        other.streak == streak &&
        other.dueDate == dueDate &&
        other.userId == userId &&
        other.schemaVersion == schemaVersion &&
        _mapEquals(other.aiPolicy, aiPolicy) &&
        _mapEquals(other.schedule, schedule) &&
        _mapEquals(other.stats, stats) &&
        _mapEquals(other.ext, ext) &&
        other.isAIGenerated == isAIGenerated;
  }

  @override
  int get hashCode => Object.hashAll([
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
        Object.hashAll(participants),
        createdBy,
        status,
        streak,
        dueDate,
        userId,
        schemaVersion,
        _deepMapHash(aiPolicy),
        _deepMapHash(schedule),
        _deepMapHash(stats),
        _deepMapHash(ext),
        isAIGenerated,
      ]);

  @override
  String toString() => 'Nudge(id: $id, title: $title, type: $type, category: $category, isActive: $isActive)';
}

// ——— Lightweight deep equals/hash for maps/lists ———
bool _mapEquals(Map a, Map b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (final k in a.keys) {
    if (!b.containsKey(k)) return false;
    final av = a[k], bv = b[k];
    if (av is Map && bv is Map) {
      if (!_mapEquals(av, bv)) return false;
    } else if (av is List && bv is List) {
      if (!_listEquals(av, bv)) return false;
    } else if (av != bv) {
      return false;
    }
  }
  return true;
}

bool _listEquals(List a, List b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    final av = a[i], bv = b[i];
    if (av is Map && bv is Map) {
      if (!_mapEquals(av, bv)) return false;
    } else if (av is List && bv is List) {
      if (!_listEquals(av, bv)) return false;
    } else if (av != bv) {
      return false;
    }
  }
  return true;
}

int _deepMapHash(Map m) {
  final entries = m.entries.toList()..sort((a, b) => a.key.toString().compareTo(b.key.toString()));
  return Object.hashAll(entries.map((e) {
    final v = e.value;
    if (v is Map) return _deepMapHash(v);
    if (v is List) return Object.hashAll(v.map((x) => x is Map ? _deepMapHash(x) : x));
    return Object.hash(e.key, v);
  }));
}

// ——— Helper factories (kept, but now set userId/schema if you want) ———
extension NudgeFactory on Nudge {
  static Nudge createPersonal({
    required String id,
    required String title,
    required String description,
    required String category,
    required String icon,
    required String createdBy,
    String userId = '',
    bool isActive = true,
    Map<String, dynamic> aiPolicy = const {},
    Map<String, dynamic> schedule = const {},
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
      userId: userId,
      aiPolicy: aiPolicy,
      schedule: schedule, frequency: '',
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
    String userId = '',
    DateTime? dueDate,
    bool isActive = true,
    Map<String, dynamic> aiPolicy = const {},
    Map<String, dynamic> schedule = const {},
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
      userId: userId,
      aiPolicy: aiPolicy,
      schedule: schedule, frequency: '',
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
    String userId = '',
    bool isActive = true,
    int? streak,
    Map<String, dynamic> aiPolicy = const {},
    Map<String, dynamic> schedule = const {},
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
      userId: userId,
      aiPolicy: aiPolicy,
      schedule: schedule, frequency: '',
    );
  }
}
