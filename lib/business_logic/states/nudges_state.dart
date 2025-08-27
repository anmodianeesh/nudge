import 'package:collection/collection.dart';
import 'package:nudge/data/models/nudge_model.dart';

/// Helper: yyyy-mm-dd key (local time).
String dateKey(DateTime dt) {
  final local = dt.toLocal();
  final y = local.year.toString().padLeft(4, '0');
  final m = local.month.toString().padLeft(2, '0');
  final d = local.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}

class NudgesState {
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
    this.error,
  });

  // ---------- Derived ----------
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

  NudgesState copyWith({
    List<Nudge>? allNudges,
    Set<String>? myNudgeIds,
    Set<String>? pausedIds,
    Set<String>? completedTodayIds,
    Map<String, DateTime>? snoozedUntil,
    Map<String, Set<String>>? completionsByDate,
    String? error,
  }) {
    return NudgesState(
      allNudges: allNudges ?? this.allNudges,
      myNudgeIds: myNudgeIds ?? this.myNudgeIds,
      pausedIds: pausedIds ?? this.pausedIds,
      completedTodayIds: completedTodayIds ?? this.completedTodayIds,
      snoozedUntil: snoozedUntil ?? this.snoozedUntil,
      completionsByDate: completionsByDate ?? this.completionsByDate,
      error: error,
    );
  }
}
