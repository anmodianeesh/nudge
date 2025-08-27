import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nudge/business_logic/states/nudges_state.dart';
import 'package:nudge/data/models/nudge_model.dart';
import 'package:nudge/data/premade_nudges_data.dart';

class NudgesCubit extends Cubit<NudgesState> {
  NudgesCubit() : super(const NudgesState());

  // Load premade nudges (can later be replaced by a repo/service call)
  void loadInitial() {
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
    final snoozed = {...state.snoozedUntil}..remove(id);
    emit(state.copyWith(
      myNudgeIds: updated,
      pausedIds: paused,
      completedTodayIds: completed,
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

  void markDoneToday(String id) {
    if (!state.myNudgeIds.contains(id)) return;
    final set = {...state.completedTodayIds};
    if (set.contains(id)) {
      set.remove(id);
    } else {
      set.add(id);
    }
    emit(state.copyWith(completedTodayIds: set));
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
