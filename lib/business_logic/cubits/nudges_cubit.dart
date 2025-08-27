import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nudge/business_logic/states/nudges_state.dart';
import 'package:nudge/data/models/nudge_model.dart';
import 'package:nudge/data/premade_nudges_data.dart';

class NudgesCubit extends Cubit<NudgesState> {
  NudgesCubit() : super(const NudgesState());

  void loadInitial() {
    // Load premade nudges (extend later with custom nudges).
    final all = List<Nudge>.from(PremadeNudgesData.allNudges);
    emit(state.copyWith(allNudges: all, error: null));
  }

  void addToMyNudges(String id) {
    if (state.myNudgeIds.contains(id)) return;
    final updated = {...state.myNudgeIds, id};
    emit(state.copyWith(myNudgeIds: updated));
  }

  void removeFromMyNudges(String id) {
    if (!state.myNudgeIds.contains(id)) return;
    final updated = {...state.myNudgeIds}..remove(id);
    final paused = {...state.pausedIds}..remove(id);
    final completed = {...state.completedTodayIds}..remove(id);

    // Also clean from history sets
    final history = <String, Set<String>>{};
    state.completionsByDate.forEach((k, v) {
      final nv = {...v}..remove(id);
      history[k] = nv;
    });

    final snoozed = {...state.snoozedUntil}..remove(id);

    emit(state.copyWith(
      myNudgeIds: updated,
      pausedIds: paused,
      completedTodayIds: completed,
      completionsByDate: history,
      snoozedUntil: snoozed,
    ));
  }

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

  /// Toggle "done today" and log in history.
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

  void snoozeForMinutes(String id, {int minutes = 30}) {
    if (!state.myNudgeIds.contains(id)) return;
    final until = DateTime.now().add(Duration(minutes: minutes));
    final map = {...state.snoozedUntil}..[id] = until;
    emit(state.copyWith(snoozedUntil: map));
  }

  void clearSnooze(String id) {
    if (!state.snoozedUntil.containsKey(id)) return;
    final map = {...state.snoozedUntil}..remove(id);
    emit(state.copyWith(snoozedUntil: map));
  }
}
