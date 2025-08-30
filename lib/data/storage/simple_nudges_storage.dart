// lib/data/storage/simple_nudges_storage.dart
import 'dart:convert';
import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/simple_nudge.dart';
import '../models/nudge_spec.dart';
import '../models/nudge_model.dart';

/// Lightweight local persistence for AI/custom nudges created from chat.
/// Uses SharedPreferences under a single JSON list key.
/// Safe to replace later with Hive/Drift behind the same public API.
class SimpleNudgesStorage {
  static const String _key = 'chat_nudges';
  static final _rnd = Random();

  /// Read all saved nudges (tolerant to missing/bad data).
  static Future<List<SimpleNudge>> getAllNudges() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return [];

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return [];
      final result = <SimpleNudge>[];
      for (final item in decoded) {
        try {
          final n = SimpleNudge.fromJson(Map<String, dynamic>.from(item));

          // Minimal migration: ensure spec has a valid tz string.
          final spec = n.spec;
          final needsTz = (spec.tz.isEmpty) ||
              !RegExp(r'^[A-Za-z]+\/[A-Za-z_]+$').hasMatch(spec.tz);

          if (needsTz) {
            final fixedSpec = NudgeSpec(
              title: spec.title,
              microStep: spec.microStep,
              tone: spec.tone,
              channels: spec.channels,
              tz: 'Europe/Madrid', // default; adjust if you track user tz
              rrule: spec.rrule,
              reminderCopy: spec.reminderCopy, // ✅ pass through
            );

            result.add(SimpleNudge(
              id: n.id,
              spec: fixedSpec,
              createdAt: n.createdAt,
              status: n.status,
              streak: n.streak,
              category: n.category,
              isAIGenerated: n.isAIGenerated,
            ));
          } else {
            result.add(n);
          }
        } catch (_) {
          // Skip bad entries instead of crashing
        }
      }
      return result;
    } catch (_) {
      // If storage is corrupted, reset it.
      await _saveNudges(const []);
      return [];
    }
  }

  /// Get one nudge by id (null if not found).
  static Future<SimpleNudge?> getById(String id) async {
    final all = await getAllNudges();
    for (final n in all) {
      if (n.id == id) return n;
    }
    return null; // ✅ avoid firstWhere(null)
  }

  /// Save a new nudge (no return id).
  static Future<void> addNudgeWithCategory(
    NudgeSpec spec,
    NudgeCategory category, {
    bool isAIGenerated = true,
  }) async {
    final all = await getAllNudges();
    final id = _generateId();
    final n = SimpleNudge(
      id: id,
      spec: spec,
      createdAt: DateTime.now().toUtc(),
      status: SimpleNudgeStatus.active,
      streak: 0,
      category: category,
      isAIGenerated: isAIGenerated,
    );
    all.add(n);
    await _saveNudges(all);
  }

  /// Save a new nudge and return the created id.
  static Future<String> addNudgeWithCategoryReturningId(
    NudgeSpec spec,
    NudgeCategory category, {
    bool isAIGenerated = true,
  }) async {
    final id = _generateId();
    final all = await getAllNudges();
    final n = SimpleNudge(
      id: id,
      spec: spec,
      createdAt: DateTime.now().toUtc(),
      status: SimpleNudgeStatus.active,
      streak: 0,
      category: category,
      isAIGenerated: isAIGenerated,
    );
    all.add(n);
    await _saveNudges(all);
    return id;
  }

  /// Update/replace a nudge by id (no-op if not found).
  static Future<void> upsert(SimpleNudge updated) async {
    final all = await getAllNudges();
    final i = all.indexWhere((n) => n.id == updated.id);
    if (i >= 0) {
      all[i] = updated;
    } else {
      all.add(updated);
    }
    await _saveNudges(all);
  }

  /// Delete a nudge by id.
  static Future<void> deleteNudge(String id) async {
    final all = await getAllNudges();
    all.removeWhere((n) => n.id == id);
    await _saveNudges(all);
  }

  /// Convert a stored SimpleNudge into your richer Nudge model for UI.
  static Nudge convertToComplexNudge(SimpleNudge simpleNudge, String userId) {
    return Nudge(
      id: simpleNudge.id,
      title: simpleNudge.spec.title,
      description: simpleNudge.spec.microStep,
      category: _categoryString(simpleNudge.category),
      icon: _iconFor(simpleNudge.spec.title),
      isActive: simpleNudge.status == SimpleNudgeStatus.active,
      createdAt: simpleNudge.createdAt,
      type: _typeFor(simpleNudge.category),
      createdBy: userId,
      status: _statusFor(simpleNudge.status),
      streak: simpleNudge.streak,
      isAIGenerated: simpleNudge.isAIGenerated, frequency: '',
      // If your Nudge model later adds dueDate/schedule, derive it from spec.rrule in a scheduler service.
    );
  }

  // ---- helpers ----

  static String _categoryString(NudgeCategory c) {
    switch (c) {
      case NudgeCategory.personal:
        return 'Personal';
      case NudgeCategory.family:
        return 'Family';
      case NudgeCategory.friends:
        return 'Friends';
      case NudgeCategory.work:
        return 'Work';
    }
  }

  static String _iconFor(String title) {
    final t = title.toLowerCase();
    if (t.contains('water') || t.contains('drink')) return '💧';
    if (t.contains('walk') || t.contains('steps')) return '🚶';
    if (t.contains('study')) return '📚';
    if (t.contains('sleep')) return '😴';
    if (t.contains('meditat') || t.contains('mindful')) return '🧘';
    return '🔔';
  }

  static NudgeType _typeFor(NudgeCategory c) {
    switch (c) {
      case NudgeCategory.personal:
        return NudgeType.personal;
      case NudgeCategory.family:
        return NudgeType.group;
      case NudgeCategory.friends:
        return NudgeType.friend;
      case NudgeCategory.work:
        return NudgeType.group;
    }
  }

  static NudgeStatus _statusFor(SimpleNudgeStatus s) {
    switch (s) {
      case SimpleNudgeStatus.active:
        return NudgeStatus.active;
      case SimpleNudgeStatus.paused:
        return NudgeStatus.paused;
      case SimpleNudgeStatus.completed:
        return NudgeStatus.completed;
    }
  }

  static String _generateId() {
  final ts = DateTime.now().microsecondsSinceEpoch;
  final salt = _rnd.nextInt(1 << 32).toRadixString(36);
  return 'n_${ts}_$salt'; // <-- FIXED
}


  static Future<void> _saveNudges(List<SimpleNudge> items) async {
    final prefs = await SharedPreferences.getInstance();
    final list = items.map((e) => e.toJson()).toList();
    await prefs.setString(_key, jsonEncode(list));
  }
}
