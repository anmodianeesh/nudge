import 'package:collection/collection.dart';
import 'package:nudge/data/models/nudge_model.dart';

enum ScheduleKind { hourly, timesPerDay, specificTimes, continuous }

class NudgeScheduleSimple {
  final ScheduleKind kind;
  final int dailyTarget; // e.g., 8 glasses of water; for hourly use awake-hours
  const NudgeScheduleSimple({required this.kind, required this.dailyTarget});
}

/// Helper: yyyy-mm-dd key (local time).
String dateKey(DateTime dt) {
  final local = dt.toLocal();
  final y = local.year.toString().padLeft(4, '0');
  final m = local.month.toString().padLeft(2, '0');
  final d = local.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}

class NudgesState {
  final Map<String, NudgeScheduleSimple> schedules; // nudgeId -> schedule
  final Map<String, Map<String, int>> dailyLogs;    // dateKey -> {nudgeId -> count}

  /// All available nudges (premade/custom merged later if needed).
  final List<Nudge> allNudges;

  /// User-selected nudges (their "My Nudges").
  final Set<String> myNudgeIds;

  /// Paused (not used on UI right now, but kept for future).
  final Set<String> pausedIds;

  /// Quick toggle cache for "completed today" (derived from [completionsByDate]).
  final Set<String> completedTodayIds;

  /// Snoozed-until map.
  final Map<String, DateTime> snoozedUntil;

  /// History log: dateKey -> set of nudgeIds completed on that date.
  /// Example: { '2025-08-28': {'n1','n2'} }
  final Map<String, Set<String>> completionsByDate;

  final String? error;

  const NudgesState({
    this.allNudges = const [],
    this.myNudgeIds = const {},
    this.pausedIds = const {},
    this.completedTodayIds = const {},
    this.snoozedUntil = const {},
    this.completionsByDate = const {},
    this.schedules = const {},
    this.dailyLogs = const {},
    this.error,
  });

  /// yyyy-mm-dd key in local time
  static String dateKey(DateTime dt) {
    final local = dt.toLocal();
    final y = local.year.toString().padLeft(4, '0');
    final m = local.month.toString().padLeft(2, '0');
    final d = local.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  int dailyCountFor(String nudgeId, DateTime day) {
    final key = dateKey(day);
    final m = dailyLogs[key];
    if (m == null) return 0;
    return m[nudgeId] ?? 0;
  }

  bool isActionable(String nudgeId) {
    final s = schedules[nudgeId];
    if (s == null) return false;
    return s.kind != ScheduleKind.continuous;
  }

  /// Actionable nudges only (hourly / timesPerDay / specificTimes), excluding paused/snoozed
  List<Nudge> get actionableNudges {
    final now = DateTime.now();
    return activeMyNudges.where((n) {
      if (!isActionable(n.id)) return false;
      final until = snoozedUntil[n.id];
      if (until != null && now.isBefore(until)) return false;
      return true;
    }).toList()
      ..sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
  }

  // ---------- Derived getters for all nudges ----------
  List<Nudge> get myNudges =>
      allNudges.where((n) => myNudgeIds.contains(n.id)).toList();

  List<Nudge> get activeMyNudges {
    final now = DateTime.now();
    return myNudges.where((n) {
      if (pausedIds.contains(n.id)) return false;
      final until = snoozedUntil[n.id];
      if (until != null && now.isBefore(until)) return false;
      return true;
    }).sortedBy((n) => n.title.toLowerCase());
  }

  List<Nudge> get pausedMyNudges =>
      myNudges.where((n) => pausedIds.contains(n.id)).toList();

  // ---------- NEW: Categorized nudge getters ----------
  
  /// Personal nudges only (user's individual habits)
  List<Nudge> get personalNudges =>
      myNudges.where((n) => n.isPersonal).toList()
        ..sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));

  /// Active personal nudges (not paused/snoozed)
  List<Nudge> get activePersonalNudges {
    final now = DateTime.now();
    return personalNudges.where((n) {
      if (pausedIds.contains(n.id)) return false;
      final until = snoozedUntil[n.id];
      if (until != null && now.isBefore(until)) return false;
      return true;
    }).toList();
  }

  /// Group nudges the user participates in
  List<Nudge> get groupNudges =>
      allNudges.where((n) => n.isGroup && n.participants.contains('self')).toList()
        ..sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));

  /// Group nudges by group type
  List<Nudge> groupNudgesForType(GroupType groupType) =>
      groupNudges.where((n) => n.groupType == groupType).toList();

  /// Group nudges for school
  List<Nudge> get schoolNudges => groupNudgesForType(GroupType.school);
  
  /// Group nudges for work
  List<Nudge> get workNudges => groupNudgesForType(GroupType.work);
  
  /// Group nudges for family
  List<Nudge> get familyNudges => groupNudgesForType(GroupType.family);

  /// Friend nudges (accountability with specific friends)
  List<Nudge> get friendNudges =>
      allNudges.where((n) => n.isFriend && n.participants.contains('self')).toList()
        ..sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));

  /// Friend nudges with a specific friend
  List<Nudge> friendNudgesWith(String friendId) =>
      friendNudges.where((n) => n.friendId == friendId).toList();

  /// Get all unique friends from friend nudges
  List<String> get friendsList =>
      friendNudges
          .where((n) => n.friendName != null)
          .map((n) => n.friendName!)
          .toSet()
          .toList()
        ..sort();

  /// Get all unique groups from group nudges
  List<String> get groupsList =>
      groupNudges
          .where((n) => n.groupName != null)
          .map((n) => n.groupName!)
          .toSet()
          .toList()
        ..sort();

  // ---------- Legacy methods (preserved) ----------
  bool isCompletedToday(String id) => completedTodayIds.contains(id);
  bool isPaused(String id) => pausedIds.contains(id);
  bool isSnoozed(String id) {
    final until = snoozedUntil[id];
    return until != null && DateTime.now().isBefore(until);
  }

  /// Count how many of the user's active nudges were completed on the given date.
  int completedCountOn(DateTime day) {
    final key = dateKey(day);
    final set = completionsByDate[key];
    if (set == null) return 0;
    // Only count nudges that are (or were) part of myNudgeIds; we keep it simple for now
    return set.length;
  }

  /// Returns a list of doubles (0..1) for the last [days] days, oldest→newest.
  /// Denominator = current activeMyNudges length (simple & stable for now).
  List<double> weeklyCompletionRates({int days = 7}) {
    final total = activeMyNudges.length;
    if (total == 0) {
      return List<double>.filled(days, 0.0);
    }
    final today = DateTime.now();
    final List<double> rates = [];
    for (int i = days - 1; i >= 0; i--) {
      final day = DateTime(today.year, today.month, today.day).subtract(Duration(days: i));
      final c = completedCountOn(day);
      rates.add((c / total).clamp(0.0, 1.0));
    }
    return rates;
  }

  /// Completion rates for personal nudges only
  List<double> personalCompletionRates({int days = 7}) {
    final total = activePersonalNudges.length;
    if (total == 0) {
      return List<double>.filled(days, 0.0);
    }
    final today = DateTime.now();
    final List<double> rates = [];
    for (int i = days - 1; i >= 0; i--) {
      final day = DateTime(today.year, today.month, today.day).subtract(Duration(days: i));
      final key = dateKey(day);
      final completedSet = completionsByDate[key] ?? {};
      final personalCompleted = completedSet.where((id) {
        final nudge = allNudges.firstWhereOrNull((n) => n.id == id);
        return nudge?.isPersonal == true;
      }).length;
      rates.add((personalCompleted / total).clamp(0.0, 1.0));
    }
    return rates;
  }

  NudgesState copyWith({
    List<Nudge>? allNudges,
    Set<String>? myNudgeIds,
    Set<String>? pausedIds,
    Set<String>? completedTodayIds,
    Map<String, DateTime>? snoozedUntil,
    Map<String, Set<String>>? completionsByDate,
    Map<String, NudgeScheduleSimple>? schedules,
    Map<String, Map<String, int>>? dailyLogs,
    String? error,
  }) {
    return NudgesState(
      allNudges: allNudges ?? this.allNudges,
      myNudgeIds: myNudgeIds ?? this.myNudgeIds,
      pausedIds: pausedIds ?? this.pausedIds,
      completedTodayIds: completedTodayIds ?? this.completedTodayIds,
      snoozedUntil: snoozedUntil ?? this.snoozedUntil,
      completionsByDate: completionsByDate ?? this.completionsByDate,
      schedules: schedules ?? this.schedules,
      dailyLogs: dailyLogs ?? this.dailyLogs,
      error: error,
    );
  }
}