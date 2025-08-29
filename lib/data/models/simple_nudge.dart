// lib/data/models/simple_nudge.dart
import 'nudge_spec.dart';

enum SimpleNudgeStatus { active, paused, completed }
enum NudgeCategory { personal, family, friends, work }

class SimpleNudge {
  final String id;
  final NudgeSpec spec;
  final DateTime createdAt;
  final SimpleNudgeStatus status;
  final int streak;
  final NudgeCategory category;
  final bool isAIGenerated;

  const SimpleNudge({
    required this.id,
    required this.spec,
    required this.createdAt,
    required this.status,
    this.streak = 0,
    this.category = NudgeCategory.personal,
    this.isAIGenerated = true,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'spec': spec.toJson(),
    'created_at': createdAt.toIso8601String(),
    'status': status.name,
    'streak': streak,
    'category': category.name,
    'is_ai_generated': isAIGenerated,
  };

  factory SimpleNudge.fromJson(Map<String, dynamic> json) {
    return SimpleNudge(
      id: json['id'],
      spec: NudgeSpec.fromJson(json['spec']),
      createdAt: DateTime.parse(json['created_at']),
      status: SimpleNudgeStatus.values.byName(json['status']),
      streak: json['streak'] ?? 0,
      category: NudgeCategory.values.byName(json['category'] ?? 'personal'),
      isAIGenerated: json['is_ai_generated'] ?? true,
    );
  }
}