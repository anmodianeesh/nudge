// lib/business_logic/cubits/nudges_cubit.dart
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:nudge/business_logic/states/nudges_state.dart';
import 'package:nudge/data/models/nudge_model.dart';
import 'package:nudge/data/premade_nudges_data.dart';

class NudgesCubit extends Cubit<NudgesState> {
  NudgesCubit() : super(const NudgesState());

  // ─────────────────────────────────────────────────────────────────────────────
  // Initialization
  // ─────────────────────────────────────────────────────────────────────────────

  /// Load premade nudges and attach simple default schedules (heuristic).
  void loadInitial() {
    final all = List<Nudge>.from(PremadeNudgesData.allNudges);

    final Map<String, NudgeScheduleSimple> scheds = {};
    for (final n in all) {
      scheds[n.id] = _defaultScheduleFor(n);
    }

    emit(state.copyWith(
      allNudges: all,
      schedules: scheds,
      error: null,
    ));
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // My Nudges – add / remove / pause / snooze
  // ─────────────────────────────────────────────────────────────────────────────

  /// Add an existing nudge (by id) to "My Nudges".
  void addToMyNudges(String id) {
    if (state.myNudgeIds.contains(id)) return;

    final updatedMy = {...state.myNudgeIds, id};

    // Ensure there's at least a default schedule for it
    final n = state.allNudges.firstWhere(
      (x) => x.id == id,
      orElse: () => throw StateError('Nudge not found: $id'),
    );
    final scheds = {...state.schedules};
    scheds.putIfAbsent(id, () => _defaultScheduleFor(n));

    emit(state.copyWith(
      myNudgeIds: updatedMy,
      schedules: scheds,
    ));
  }

  /// Remove from "My Nudges" and clean associated state.
  void removeFromMyNudges(String id) {
    if (!state.myNudgeIds.contains(id)) return;

    final my = {...state.myNudgeIds}..remove(id);
    final paused = {...state.pausedIds}..remove(id);
    final completed = {...state.completedTodayIds}..remove(id);
    final snoozed = {...state.snoozedUntil}..remove(id);

    // Clean from history logs
    final history = <String, Set<String>>{};
    state.completionsByDate.forEach((k, v) {
      final nv = {...v}..remove(id);
      history[k] = nv;
    });

    // Clean from daily logs
    final daily = <String, Map<String, int>>{};
    state.dailyLogs.forEach((k, v) {
      final nv = Map<String, int>.from(v)..remove(id);
      daily[k] = nv;
    });

    // Optionally keep schedule (so if user re-adds, we remember). Here we keep it.
    emit(state.copyWith(
      myNudgeIds: my,
      pausedIds: paused,
      completedTodayIds: completed,
      snoozedUntil: snoozed,
      completionsByDate: history,
      dailyLogs: daily,
    ));
  }

  /// Pause/unpause a nudge in "My Nudges".
  void togglePaused(String id) {
    if (!state.myNudgeIds.contains(id)) return;
    final paused = {...state.pausedIds};
    if (paused.contains(id)) {
      paused.remove(id);
    } else {
      paused.add(id);
    }
    emit(state.copyWith(pausedIds: paused));
  }

  /// Snooze for [minutes] (default 30).
  void snoozeForMinutes(String id, {int minutes = 30}) {
    if (!state.myNudgeIds.contains(id)) return;
    final until = DateTime.now().add(Duration(minutes: minutes));
    final map = {...state.snoozedUntil}..[id] = until;
    emit(state.copyWith(snoozedUntil: map));
  }

  /// Clear snooze.
  void clearSnooze(String id) {
    if (!state.snoozedUntil.containsKey(id)) return;
    final map = {...state.snoozedUntil}..remove(id);
    emit(state.copyWith(snoozedUntil: map));
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Completion (binary) – legacy toggle for “done today”
  // ─────────────────────────────────────────────────────────────────────────────

  /// Toggle "done today" (used by older UI; Action Hub now prefers logNow/undoLog).
  void markDoneToday(String id) {
    if (!state.myNudgeIds.contains(id)) return;

    final todayKey = dateKey(DateTime.now());
    final setToday = {...(state.completionsByDate[todayKey] ?? <String>{})};

    final completed = {...state.completedTodayIds};
    if (completed.contains(id)) {
      // Undo
      completed.remove(id);
      setToday.remove(id);
    } else {
      completed.add(id);
      setToday.add(id);
    }

    final history = {...state.completionsByDate}..[todayKey] = setToday;

    emit(state.copyWith(
      completedTodayIds: completed,
      completionsByDate: history,
    ));
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Quantified logging for today (Action Hub)
  // ─────────────────────────────────────────────────────────────────────────────

  /// Increment per-day counter for a nudge (used by "Log now").
  /// Also updates completedTodayIds when target is met.
  void logNow(String id) {
    if (!state.myNudgeIds.contains(id)) return;

    final today = dateKey(DateTime.now());
    final dl = <String, Map<String, int>>{...state.dailyLogs};
    final map = <String, int>{...(dl[today] ?? const {})};

    final current = map[id] ?? 0;
    map[id] = current + 1;
    dl[today] = map;

    final schedule = state.schedules[id];
    final target = schedule?.dailyTarget ?? 1;

    final completed = {...state.completedTodayIds};
    if ((map[id] ?? 0) >= target) {
      completed.add(id);
    } else {
      completed.remove(id);
    }

    // Keep binary completion history in sync as well
    final comp = <String, Set<String>>{...state.completionsByDate};
    final todaySet = <String>{...(comp[today] ?? <String>{})};
    if (completed.contains(id)) {
      todaySet.add(id);
    } else {
      todaySet.remove(id);
    }
    comp[today] = todaySet;

    emit(state.copyWith(
      dailyLogs: dl,
      completedTodayIds: completed,
      completionsByDate: comp,
    ));
  }

  /// Decrement per-day counter (undo last log).
  void undoLog(String id) {
    if (!state.myNudgeIds.contains(id)) return;

    final today = dateKey(DateTime.now());
    if (!state.dailyLogs.containsKey(today)) return;

    final dl = <String, Map<String, int>>{...state.dailyLogs};
    final map = <String, int>{...(dl[today] ?? const {})};

    final current = map[id] ?? 0;
    if (current <= 0) return;
    map[id] = current - 1;
    dl[today] = map;

    final schedule = state.schedules[id];
    final target = schedule?.dailyTarget ?? 1;

    final completed = {...state.completedTodayIds};
    if ((map[id] ?? 0) >= target) {
      completed.add(id);
    } else {
      completed.remove(id);
    }

    // Sync binary history
    final comp = <String, Set<String>>{...state.completionsByDate};
    final todaySet = <String>{...(comp[today] ?? <String>{})};
    if (completed.contains(id)) {
      todaySet.add(id);
    } else {
      todaySet.remove(id);
    }
    comp[today] = todaySet;

    emit(state.copyWith(
      dailyLogs: dl,
      completedTodayIds: completed,
      completionsByDate: comp,
    ));
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Schedules
  // ─────────────────────────────────────────────────────────────────────────────

  /// Set/replace a schedule for a nudge.
  void setSchedule(String nudgeId, NudgeScheduleSimple schedule) {
    final m = {...state.schedules}..[nudgeId] = schedule;

    // When schedule changes, re-evaluate today's completed flag based on dailyLogs.
    final today = dateKey(DateTime.now());
    final count = state.dailyLogs[today]?[nudgeId] ?? 0;
    final completed = {...state.completedTodayIds};
    if (count >= schedule.dailyTarget) {
      completed.add(nudgeId);
    } else {
      completed.remove(nudgeId);
    }

    emit(state.copyWith(
      schedules: m,
      completedTodayIds: completed,
    ));
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Create customized nudge from a premade template (Customize → Add flow)
  // ─────────────────────────────────────────────────────────────────────────────

  /// Create a user-owned copy from a premade template with edits,
  /// add it to allNudges + myNudgeIds, and assign its schedule.
  /// (No external deps; id uses a high-entropy timestamp.)
  void addCustomFromTemplate(
    Nudge template, {
    required String title,
    required String description,
    required String category,
    required String icon,
    required NudgeScheduleSimple schedule,
  }) {
    final String newId = _generateId();

    final newNudge = Nudge(
      id: newId,
      title: title.trim().isEmpty ? template.title : title.trim(),
      description:
          description.trim().isEmpty ? template.description : description.trim(),
      category: category.trim().isEmpty ? template.category : category.trim(),
      icon: icon.trim().isEmpty ? template.icon : icon.trim(),
      isActive: true,
      createdAt: DateTime.now(),
    );

    final updatedAll = List<Nudge>.from(state.allNudges)..add(newNudge);
    final updatedMy = Set<String>.from(state.myNudgeIds)..add(newId);
    final updatedSchedules =
        Map<String, NudgeScheduleSimple>.from(state.schedules)
          ..[newId] = schedule;

    emit(state.copyWith(
      allNudges: updatedAll,
      myNudgeIds: updatedMy,
      schedules: updatedSchedules,
    ));
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Helpers
  // ─────────────────────────────────────────────────────────────────────────────

  /// Simple id generator (timestamp-based). No external dependency.
  String _generateId() =>
      'nudge_${DateTime.now().microsecondsSinceEpoch}_${(DateTime.now().millisecondsSinceEpoch % 1000)}';

  /// Heuristic default schedules for premade nudges.
  NudgeScheduleSimple _defaultScheduleFor(Nudge n) {
    final t = n.title.toLowerCase();
    if (t.contains('water') ||
        t.contains('drink') && t.contains('water') ||
        t.contains('hydrate')) {
      return const NudgeScheduleSimple(
        kind: ScheduleKind.timesPerDay,
        dailyTarget: 8, // 8 check-ins/glasses
      );
    }
    if (t.contains('walk') || t.contains('steps')) {
      return const NudgeScheduleSimple(
        kind: ScheduleKind.timesPerDay,
        dailyTarget: 2, // e.g., 2 walks per day
      );
    }
    if (t.contains('meditat') || t.contains('mindful')) {
      return const NudgeScheduleSimple(
        kind: ScheduleKind.timesPerDay,
        dailyTarget: 1,
      );
    }
    // Default to continuous (won't show on Home Action Hub)
    return const NudgeScheduleSimple(
      kind: ScheduleKind.continuous,
      dailyTarget: 1,
    );
  }
}
