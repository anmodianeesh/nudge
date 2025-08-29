import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class DailyCompletionStore {
  static const _keyCompletedSet = 'completed_today_set_v1';
  static const _keyDay = 'completed_today_day_v1';

  static String _dayKey(DateTime dt) {
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '${dt.year}-$m-$d';
  }

  static Future<void> _rolloverIfNeeded(SharedPreferences prefs) async {
    final todayKey = _dayKey(DateTime.now());
    final storedDay = prefs.getString(_keyDay);
    if (storedDay != todayKey) {
      await prefs.setString(_keyDay, todayKey);
      await prefs.setString(_keyCompletedSet, jsonEncode(<String>[]));
    }
  }

  static Future<Set<String>> load() async {
    final prefs = await SharedPreferences.getInstance();
    await _rolloverIfNeeded(prefs);
    final raw = prefs.getString(_keyCompletedSet);
    if (raw == null || raw.isEmpty) return <String>{};
    try {
      final list = (jsonDecode(raw) as List).cast<String>();
      return list.toSet();
    } catch (_) {
      await prefs.setString(_keyCompletedSet, jsonEncode(<String>[]));
      return <String>{};
    }
  }

  static Future<Set<String>> markCompleted(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await _rolloverIfNeeded(prefs);
    final set = await load();
    set.add(id);
    await prefs.setString(_keyCompletedSet, jsonEncode(set.toList()));
    return set;
  }
}
