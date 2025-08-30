// lib/data/repositories/nudge_repository.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';
import '../models/nudge_model.dart';
import 'dart:convert';


class NudgeRepository {
  final SupabaseClient _c = SupabaseService.client;

/// Upsert a nudge row using the app's existing id (so local & cloud match).
/// Pass a small schedule JSON like {'kind':'timesPerDay','timesPerDay': 3}
Future<void> upsertNudgeWithId({
  required Nudge nudge,
  Map<String, dynamic>? scheduleJson,
}) async {
  final uid = _c.auth.currentUser?.id;
  if (uid == null) throw StateError('No authenticated user');

  await _c
      .from('nudges')
      .upsert({
        // DO NOT send 'id' here (DB will keep its UUID PK)
        'user_id': uid,
        'app_id': nudge.id, // <- your app id (ai_nudge_..., etc.)
        'title': nudge.title,
        'description': nudge.description,
        'category': nudge.category.toLowerCase(),
        'frequency': nudge.frequency,
        'is_active': nudge.isActive,
        'streak': nudge.streak ?? 0,
        'spec': <String, dynamic>{},
        'schedule': scheduleJson ?? <String, dynamic>{},
        'stats': <String, dynamic>{},
        'ext': <String, dynamic>{},
      }, onConflict: 'user_id,app_id'); // unique index we created
}

/// Update just the schedule JSON for a nudge
Future<void> updateScheduleJson(
  String id,
  Map<String, dynamic> scheduleJson,
) async {
  await _c.from('nudges').update({'schedule': scheduleJson}).eq('app_id', id);
}

  /* ---------------------------- READ (one-shot) ---------------------------- */

  /// Fetch all nudges for a user as raw maps (handy for Cubit loaders).
  Future<List<Map<String, dynamic>>> fetchUserNudgesRaw(String uid) async {
    final rows = await _c
        .from('nudges')
        .select()
        .eq('user_id', uid)
        .order('created_at', ascending: false);
    return (rows as List).cast<Map<String, dynamic>>();
  }
/// Fetch all nudges for a user and map to your Nudge model.
Future<List<Nudge>> listUserNudges(String userId) async {
  final rows = await _c
      .from('nudges')
      .select()
      .eq('user_id', userId)
      .order('created_at', ascending: false);

  final list = (rows as List).cast<Map<String, dynamic>>();
  return list.map<Nudge>(_mapRowToNudge).toList();
}

  /* ---------------------------- READ (realtime) ---------------------------- */

  /// Realtime stream of nudges for a user, mapped to your Nudge model.
  Stream<List<Nudge>> streamUserNudges(String userId) {
    final stream = _c
        .from('nudges')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return stream.map((rows) => rows
        .cast<Map<String, dynamic>>()
        .map<Nudge>(_mapRowToNudge)
        .toList());
  }

  /* --------------------------------- CREATE -------------------------------- */

  Future<Map<String, dynamic>> createCustomNudge({
  required String title,
  String? description,
  String frequency = 'daily',
  String category = 'personal',
}) async {
  final uid = _c.auth.currentUser?.id;
  if (uid == null) {
    // If this ever triggers, you're not signed in when tapping "+"
    throw StateError('No authenticated user in createCustomNudge()');
  }

  // Insert and RETURN the row so we can see success/failure clearly.
  final rows = await _c
      .from('nudges')
      .insert({
        'user_id': uid,
        'title': title,
        'description': description ?? '',
        'frequency': frequency,
        'category': category,
        'is_active': true,
        'streak': 0,
        // send empty JSONs — prevents NOT NULL issues if defaults get removed
        'spec': <String, dynamic>{},
        'schedule': <String, dynamic>{},
        'stats': <String, dynamic>{},
        'ext': <String, dynamic>{},
      })
      .select('id, user_id, title')
      .limit(1);

  // PostgREST returns a List; if empty, treat as a failure
  if (rows is! List || rows.isEmpty) {
    throw StateError('Insert returned no rows');
  }
  return (rows.first as Map<String, dynamic>);
}

  /// Recreate a row with a fixed payload (used for Undo flow).
  Future<void> recreateWithId(Map<String, dynamic> payload) async {
  // Expect payload to contain 'app_id', not 'id'
  await _c.from('nudges').upsert(payload, onConflict: 'user_id,app_id');
}


  /* --------------------------------- UPDATE -------------------------------- */

  Future<void> updateNudge({
    required String id,
    String? title,
    String? description,
    String? frequency,
    String? category,
    bool? isActive,
    int? streak,
  }) async {
    final data = <String, dynamic>{
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (frequency != null) 'frequency': frequency,
      if (category != null) 'category': category,
      if (isActive != null) 'is_active': isActive,
      if (streak != null) 'streak': streak,
    };
    if (data.isEmpty) return;
    await _c.from('nudges').update(data).eq('app_id', id);
  }

  Future<void> toggleActive(String id, bool value) async {
    await _c.from('nudges').update({'is_active': value}).eq('app_id', id);
  }

  /// Used by Home "Log now" to bump streak + set last_done_at.
  Future<void> updateStreakAndLastDone({
    required String id,
    required int newStreak,
  }) async {
    await _c.from('nudges').update({
      'streak': newStreak,
      'last_done_at': DateTime.now().toIso8601String(),
    }).eq('app_id', id);
  }

  /// Used by Personal list's "Mark done" button.
  /// NOTE: increments the passed value by 1 in the DB.
  Future<void> markDone({
    required String id,
    required int newCountAsStreak,
  }) async {
    await _c.from('nudges').update({
      'streak': newCountAsStreak + 1,
      'last_done_at': DateTime.now().toIso8601String(),
    }).eq('app_id', id);
  }

  /* --------------------------------- DELETE -------------------------------- */

  Future<void> deleteNudge(String id) async {
    await _c.from('nudges').delete().eq('app_id', id);
  }

  /* ------------------------------- MAPPERS --------------------------------- */

Nudge _mapRowToNudge(Map<String, dynamic> r) {
  String _str(dynamic v, [String fallback = '']) =>
      v == null ? fallback : v.toString();

  bool _toBool(dynamic v, [bool fallback = false]) {
    if (v is bool) return v;
    if (v is int) return v != 0;
    if (v is String) return v.toLowerCase() == 'true';
    return fallback;
  }

  int? _toInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is double) return v.toInt();
    if (v is String) return int.tryParse(v);
    return null;
  }

  DateTime _toDate(dynamic v) {
    if (v == null) return DateTime.now();
    if (v is DateTime) return v;
    return DateTime.tryParse(v.toString()) ?? DateTime.now();
  }

  DateTime? _toDateOrNull(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    return DateTime.tryParse(v.toString());
  }

  Map<String, dynamic> _toJsonMap(dynamic v) {
    if (v == null) return <String, dynamic>{};
    if (v is Map<String, dynamic>) return v;
    if (v is Map) return Map<String, dynamic>.from(v);
    if (v is String) {
      try { final x = json.decode(v); return x is Map ? Map<String, dynamic>.from(x) : <String, dynamic>{}; }
      catch (_) { return <String, dynamic>{}; }
    }
    return <String, dynamic>{};
  }

  String _iconForCategory(String category) {
    switch (category.toLowerCase()) {
      case 'health': return 'favorite_outline';
      case 'fitness': return 'fitness_center_outlined';
      case 'mindfulness': return 'self_improvement_outlined';
      case 'productivity': return 'trending_up_outlined';
      case 'social': return 'people_outline';
      case 'learning': return 'school_outlined';
      default: return 'psychology_outlined';
    }
  }

  final id        = _str(r['app_id'] ?? r['id']); // prefer your app_id
  final title     = _str(r['title']);
  final desc      = _str(r['description']);
  final category  = _str(r['category'], 'personal');
  final userId    = _str(r['user_id']);
  final isActive  = _toBool(r['is_active'], true);
  final createdAt = _toDate(r['created_at']);
  final frequency = _str(r['frequency'], 'daily');
  final streak    = _toInt(r['streak']);
  final schedule  = _toJsonMap(r['schedule']);
  final extMap    = _toJsonMap(r['ext']);
  final lastDone  = _toDateOrNull(r['last_done_at']);

  // Put last_done_at into ext so Cubit can read it without changing your model
  final mergedExt = {
    ...extMap,
    if (lastDone != null) 'last_done_at': lastDone.toIso8601String(),
  };

  return Nudge(
    id: id,
    title: title,
    description: desc,
    category: category,
    icon: _iconForCategory(category),
    isActive: isActive,
    createdAt: createdAt,
    frequency: frequency,
    userId: userId,
    createdBy: userId,
    streak: streak,
    schedule: schedule,
    ext: mergedExt,
  );
}

}