import 'package:collection/collection.dart';
import 'package:nudge/data/models/nudge_model.dart';

class NudgesState {
  final List<Nudge> allNudges;
  final Set<String> myNudgeIds;           // user’s selected nudges
  final Set<String> pausedIds;            // subset of myNudgeIds
  final Set<String> completedTodayIds;    // ephemeral “done today”
  final Map<String, DateTime> snoozedUntil; // id -> wake time
  final String? error;

  const NudgesState({
    this.allNudges = const [],
    this.myNudgeIds = const {},
    this.pausedIds = const {},
    this.completedTodayIds = const {},
    this.snoozedUntil = const {},
    this.error,
  });

  // --- Derived ---
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

  NudgesState copyWith({
    List<Nudge>? allNudges,
    Set<String>? myNudgeIds,
    Set<String>? pausedIds,
    Set<String>? completedTodayIds,
    Map<String, DateTime>? snoozedUntil,
    String? error,
  }) {
    return NudgesState(
      allNudges: allNudges ?? this.allNudges,
      myNudgeIds: myNudgeIds ?? this.myNudgeIds,
      pausedIds: pausedIds ?? this.pausedIds,
      completedTodayIds: completedTodayIds ?? this.completedTodayIds,
      snoozedUntil: snoozedUntil ?? this.snoozedUntil,
      error: error,
    );
  }
}
