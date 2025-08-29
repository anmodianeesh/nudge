// lib/data/storage/my_nudges_storage.dart
import 'dart:convert';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/premade_nudge.dart';

class MyNudgesStorage {
  static const _key = 'my_nudges_v1';
  static final _rnd = Random();

  static Future<List<PremadeNudge>> loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = (jsonDecode(raw) as List)
          .map((e) => PremadeNudge.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      return list;
    } catch (_) {
      await prefs.remove(_key);
      return [];
    }
  }

  static Future<void> _saveAll(List<PremadeNudge> items) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(items.map((e) => e.toJson()).toList());
    await prefs.setString(_key, encoded);
  }

  static Future<void> addFromLibrary(PremadeNudge n) async {
    final all = await loadAll();
    // Avoid duplicate ids in "My Nudges" — if exists, do nothing.
    if (all.any((x) => x.id == n.id && !n.isCustom)) return;
    all.add(n.copyWith(createdAt: DateTime.now()));
    await _saveAll(all);
  }

  static Future<void> addCustom({required String title, required String description}) async {
    final all = await loadAll();
    final id = _genId();
    all.add(PremadeNudge(
      id: id,
      title: title,
      description: description,
      isCustom: true,
      createdAt: DateTime.now(),
    ));
    await _saveAll(all);
  }

  static Future<void> remove(String id) async {
    final all = await loadAll();
    all.removeWhere((e) => e.id == id);
    await _saveAll(all);
  }

  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }

  static String _genId() {
    final ts = DateTime.now().microsecondsSinceEpoch;
    final salt = _rnd.nextInt(1 << 32).toRadixString(36);
    return 'u_${ts}_$salt';
  }
}
