// lib/business_logic/cubits/nudges_cubit.dart
import 'package:flutter_bloc/flutter_bloc.dart';
// Add these imports at the top
import '../../data/storage/simple_nudges_storage.dart';
import 'package:nudge/data/models/nudge_spec.dart';

import 'package:nudge/business_logic/states/nudges_state.dart';
import 'package:nudge/data/models/nudge_model.dart';
import 'package:nudge/data/premade_nudges_data.dart';

class NudgesCubit extends Cubit<NudgesState> {
  NudgesCubit() : super(const NudgesState());
bool _mocksAdded = false;
  // ─────────────────────────────────────────────────────────────────────────────
  // Initialization
  // ─────────────────────────────────────────────────────────────────────────────

  /// Load premade nudges and attach simple default schedules (heuristic).
  /// Load premade nudges and attach simple default schedules (heuristic).
void loadInitial() {
  // Get templates
final templates = PremadeNudgesData.allNudges;

// Convert PremadeNudge -> Nudge
final all = templates.map<Nudge>((p) {
  return NudgeFactory.createPersonal(
    id: p.id,
    title: p.title,
    description: p.description,
    category: 'Personal',
    icon: '⭐️',
    createdBy: 'system',
  );
}).toList();

// Default schedules
final Map<String, NudgeScheduleSimple> scheds = {
  for (final n in all) n.id: _defaultScheduleFor(n),
};

// Demo group/friend nudges (unchanged)
_addMockGroupAndFriendNudges(all, scheds);

    emit(state.copyWith(
      allNudges: all,
      schedules: scheds,
      error: null,
    ));
  }
  /// Load both premade nudges and AI-generated nudges
  Future<void> loadWithAINudges() async {
    try {
      // Start with existing loadInitial logic
      final all = List<Nudge>.from(PremadeNudgesData.allNudges);

      final Map<String, NudgeScheduleSimple> scheds = {};
      for (final n in all) {
        scheds[n.id] = _defaultScheduleFor(n);
      }

      // Add mock group and friend nudges
      _addMockGroupAndFriendNudges(all, scheds);

// (keep your AI-nudges section exactly as you have it)


    // Load AI nudges (unchanged)
    final aiNudges = await SimpleNudgesStorage.getAllNudges();
    final convertedAINudges = aiNudges
        .map((simple) => SimpleNudgesStorage.convertToComplexNudge(simple, 'current_user'))
        .toList();

    all.addAll(convertedAINudges);
    for (final ai in convertedAINudges) {
      scheds[ai.id] = _defaultScheduleFor(ai);
    }

    emit(state.copyWith(
      allNudges: all,
      schedules: scheds,
      error: null,
    ));
  } catch (e) {
    emit(state.copyWith(error: e.toString()));
  }
}
  /// Add mock group and friend nudges for demonstration
void _addMockGroupAndFriendNudges(
  List<Nudge> allNudges,
  Map<String, NudgeScheduleSimple> schedules,
) {
  // If we've already added mocks in this app run, skip.
  if (_mocksAdded) return;

  // If any of the mock IDs already exist, assume they were added previously.
  const mockIds = {
    'group_school_1',
    'group_work_1',
    'friend_john_1',
    'friend_oliver_1',
  };
  final alreadyPresent = allNudges.any((n) => mockIds.contains(n.id));
  if (alreadyPresent) {
    _mocksAdded = true;
    return;
  }

  // --- your existing mock data (unchanged) ---
  final groupNudge1 = NudgeFactory.createGroup(
    id: 'group_school_1',
    title: 'Submit Assignment',
    description: 'Complete and submit weekly assignment',
    category: 'Academic',
    icon: '📚',
    groupId: 'school_group_1',
    groupName: 'School',
    groupType: GroupType.school,
    createdBy: 'teacher_123',
    participants: ['self', 'student_1', 'student_2', 'student_3'],
    dueDate: DateTime.now().add(const Duration(days: 1)),
  );

  final groupNudge2 = NudgeFactory.createGroup(
    id: 'group_work_1',
    title: 'Team Stand-up',
    description: 'Attend daily team meeting',
    category: 'Work',
    icon: '💼',
    groupId: 'work_team_1',
    groupName: 'Work',
    groupType: GroupType.work,
    createdBy: 'manager_456',
    participants: ['self', 'colleague_1', 'colleague_2'],
  );

  final friendNudge1 = NudgeFactory.createFriend(
    id: 'friend_john_1',
    title: 'Morning Run',
    description: 'Run 3 miles together',
    category: 'Fitness',
    icon: '🏃‍♂️',
    friendId: 'john_123',
    friendName: 'John',
    createdBy: 'self',
    streak: 5,
  );

  final friendNudge2 = NudgeFactory.createFriend(
    id: 'friend_oliver_1',
    title: 'Read Daily',
    description: 'Read for 30 minutes',
    category: 'Learning',
    icon: '📖',
    friendId: 'oliver_456',
    friendName: 'Oliver',
    createdBy: 'self',
    streak: 12,
  );

  allNudges.addAll([groupNudge1, groupNudge2, friendNudge1, friendNudge2]);

  schedules[groupNudge1.id] =
      const NudgeScheduleSimple(kind: ScheduleKind.timesPerDay, dailyTarget: 1);
  schedules[groupNudge2.id] =
      const NudgeScheduleSimple(kind: ScheduleKind.timesPerDay, dailyTarget: 1);
  schedules[friendNudge1.id] =
      const NudgeScheduleSimple(kind: ScheduleKind.timesPerDay, dailyTarget: 1);
  schedules[friendNudge2.id] =
      const NudgeScheduleSimple(kind: ScheduleKind.timesPerDay, dailyTarget: 1);

  // Mark as added so subsequent loads don’t duplicate them.
  _mocksAdded = true;
}

  // ─────────────────────────────────────────────────────────────────────────────
  // My Nudges – add / remove / pause / snooze (UPDATED)
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
  // NEW: Personal Nudge Creation
  // ─────────────────────────────────────────────────────────────────────────────

  /// Create a personal nudge from scratch
  void createPersonalNudge({
    required String title,
    required String description,
    required String category,
    required String icon,
    required NudgeScheduleSimple schedule,
  }) {
    final newId = _generateId();
    
    final newNudge = NudgeFactory.createPersonal(
      id: newId,
      title: title.trim(),
      description: description.trim(),
      category: category.trim(),
      icon: icon.trim(),
      createdBy: 'self',
    );

    final updatedAll = List<Nudge>.from(state.allNudges)..add(newNudge);
    final updatedMy = Set<String>.from(state.myNudgeIds)..add(newId);
    final updatedSchedules = Map<String, NudgeScheduleSimple>.from(state.schedules)
      ..[newId] = schedule;

    emit(state.copyWith(
      allNudges: updatedAll,
      myNudgeIds: updatedMy,
      schedules: updatedSchedules,
    ));
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // NEW: Group Nudge Management
  // ─────────────────────────────────────────────────────────────────────────────

  /// Create a new group nudge
  void createGroupNudge({
    required String title,
    required String description,
    required String category,
    required String icon,
    required String groupName,
    required GroupType groupType,
    required List<String> participants,
    required NudgeScheduleSimple schedule,
    DateTime? dueDate,
  }) {
    final newId = _generateId();
    final groupId = _generateId();

    final newNudge = NudgeFactory.createGroup(
      id: newId,
      title: title.trim(),
      description: description.trim(),
      category: category.trim(),
      icon: icon.trim(),
      groupId: groupId,
      groupName: groupName.trim(),
      groupType: groupType,
      createdBy: 'self',
      participants: ['self', ...participants],
      dueDate: dueDate,
    );

    final updatedAll = List<Nudge>.from(state.allNudges)..add(newNudge);
    final updatedSchedules = Map<String, NudgeScheduleSimple>.from(state.schedules)
      ..[newId] = schedule;

    emit(state.copyWith(
      allNudges: updatedAll,
      schedules: updatedSchedules,
    ));
  }

  /// Join an existing group nudge
  void joinGroupNudge(String nudgeId) {
    final nudge = state.allNudges.firstWhere(
      (n) => n.id == nudgeId,
      orElse: () => throw StateError('Group nudge not found: $nudgeId'),
    );

    if (!nudge.isGroup) return;
    if (nudge.participants.contains('self')) return;

    // Update nudge to include user in participants
    final updatedNudge = nudge.copyWith(
      participants: [...nudge.participants, 'self'],
    );

    final updatedAll = state.allNudges.map((n) => 
      n.id == nudgeId ? updatedNudge : n
    ).toList();

    emit(state.copyWith(allNudges: updatedAll));
  }

  /// Leave a group nudge
  void leaveGroupNudge(String nudgeId) {
    final nudge = state.allNudges.firstWhere(
      (n) => n.id == nudgeId,
      orElse: () => throw StateError('Group nudge not found: $nudgeId'),
    );

    if (!nudge.isGroup) return;
    if (!nudge.participants.contains('self')) return;

    // Update nudge to remove user from participants
    final updatedParticipants = nudge.participants.where((p) => p != 'self').toList();
    final updatedNudge = nudge.copyWith(participants: updatedParticipants);

    final updatedAll = state.allNudges.map((n) => 
      n.id == nudgeId ? updatedNudge : n
    ).toList();

    // Also remove from myNudges if present
    final updatedMy = Set<String>.from(state.myNudgeIds)..remove(nudgeId);

    emit(state.copyWith(
      allNudges: updatedAll,
      myNudgeIds: updatedMy,
    ));
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // NEW: Friend Nudge Management
  // ─────────────────────────────────────────────────────────────────────────────

  /// Create a friend nudge (accountability with a friend)
  void createFriendNudge({
    required String title,
    required String description,
    required String category,
    required String icon,
    required String friendId,
    required String friendName,
    required NudgeScheduleSimple schedule,
  }) {
    final newId = _generateId();

    final newNudge = NudgeFactory.createFriend(
      id: newId,
      title: title.trim(),
      description: description.trim(),
      category: category.trim(),
      icon: icon.trim(),
      friendId: friendId,
      friendName: friendName.trim(),
      createdBy: 'self',
      streak: 0,
    );

    final updatedAll = List<Nudge>.from(state.allNudges)..add(newNudge);
    final updatedSchedules = Map<String, NudgeScheduleSimple>.from(state.schedules)
      ..[newId] = schedule;

    emit(state.copyWith(
      allNudges: updatedAll,
      schedules: updatedSchedules,
    ));
  }

  /// Accept a friend nudge invitation
  void acceptFriendNudge(String nudgeId) {
    final nudge = state.allNudges.firstWhere(
      (n) => n.id == nudgeId,
      orElse: () => throw StateError('Friend nudge not found: $nudgeId'),
    );

    if (!nudge.isFriend) return;

    // Update status to active and add to myNudges
    final updatedNudge = nudge.copyWith(status: NudgeStatus.active);
    
    final updatedAll = state.allNudges.map((n) => 
      n.id == nudgeId ? updatedNudge : n
    ).toList();

    final updatedMy = Set<String>.from(state.myNudgeIds)..add(nudgeId);

    emit(state.copyWith(
      allNudges: updatedAll,
      myNudgeIds: updatedMy,
    ));
  }

  /// End a friend nudge
  void endFriendNudge(String nudgeId) {
    final nudge = state.allNudges.firstWhere(
      (n) => n.id == nudgeId,
      orElse: () => throw StateError('Friend nudge not found: $nudgeId'),
    );

    if (!nudge.isFriend) return;

    // Update status to completed
    final updatedNudge = nudge.copyWith(status: NudgeStatus.completed);
    
    final updatedAll = state.allNudges.map((n) => 
      n.id == nudgeId ? updatedNudge : n
    ).toList();

    // Remove from myNudges
    final updatedMy = Set<String>.from(state.myNudgeIds)..remove(nudgeId);

    emit(state.copyWith(
      allNudges: updatedAll,
      myNudgeIds: updatedMy,
    ));
  }

  /// Update friend nudge streak
  void updateFriendStreak(String nudgeId, int newStreak) {
    final nudge = state.allNudges.firstWhere(
      (n) => n.id == nudgeId,
      orElse: () => throw StateError('Friend nudge not found: $nudgeId'),
    );

    if (!nudge.isFriend) return;

    final updatedNudge = nudge.copyWith(streak: newStreak);
    
    final updatedAll = state.allNudges.map((n) => 
      n.id == nudgeId ? updatedNudge : n
    ).toList();

    emit(state.copyWith(allNudges: updatedAll));
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Completion (binary) – legacy toggle for "done today"
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
  // Create customized nudge from a premade template (UPDATED)
  // ─────────────────────────────────────────────────────────────────────────────

  /// Create a user-owned copy from a premade template with edits,
  /// add it to allNudges + myNudgeIds, and assign its schedule.
  void addCustomFromTemplate(
    Nudge template, {
    required String title,
    required String description,
    required String category,
    required String icon,
    required NudgeScheduleSimple schedule,
  }) {
    final String newId = _generateId();

    final newNudge = NudgeFactory.createPersonal(
      id: newId,
      title: title.trim().isEmpty ? template.title : title.trim(),
      description: description.trim().isEmpty ? template.description : description.trim(),
      category: category.trim().isEmpty ? template.category : category.trim(),
      icon: icon.trim().isEmpty ? template.icon : icon.trim(),
      createdBy: 'self',
    );

    final updatedAll = List<Nudge>.from(state.allNudges)..add(newNudge);
    final updatedMy = Set<String>.from(state.myNudgeIds)..add(newId);
    final updatedSchedules = Map<String, NudgeScheduleSimple>.from(state.schedules)
      ..[newId] = schedule;

    emit(state.copyWith(
      allNudges: updatedAll,
      myNudgeIds: updatedMy,
      schedules: updatedSchedules,
    ));
  }
/// Add a personal nudge to state using an existing id + NudgeSpec.
/// This makes it appear under "My Nudges" instantly with a default schedule.
void addPersonalFromSpec(String id, NudgeSpec spec) {
  final newNudge = NudgeFactory.createPersonal(
    id: id,
    title: spec.title,
    description: spec.microStep,
    // Keep categories free-form; Personal screen uses NudgeType anyway.
    category: 'Personal',
    icon: '⭐️',
    createdBy: 'self',
  );

  final updatedAll = List<Nudge>.from(state.allNudges)..add(newNudge);
  final updatedMy = Set<String>.from(state.myNudgeIds)..add(id);
  final updatedSchedules = Map<String, NudgeScheduleSimple>.from(state.schedules)
    ..[id] = _defaultScheduleFor(newNudge);

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