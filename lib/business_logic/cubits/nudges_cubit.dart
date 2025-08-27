import 'package:flutter_bloc/flutter_bloc.dart';
import '../states/nudges_state.dart';
import '../../data/models/nudge.dart';

class NudgesCubit extends Cubit<NudgesState> {
  NudgesCubit() : super(NudgesInitial());

  void loadNudges() {
    emit(NudgesLoading());
    
    // Mock data - replace with actual API call later
    final mockNudges = [
      Nudge(
        id: '1',
        title: 'Drink Water',
        description: 'Drink a glass of water every hour',
        category: 'Health & Wellness',
        icon: 'water_drop',
        isActive: true,
        createdAt: DateTime.now(),
      ),
      Nudge(
        id: '2',
        title: 'Take Breaks',
        description: 'Take a 5-minute break every 30 minutes',
        category: 'Productivity',
        icon: 'pause_circle',
        isActive: true,
        createdAt: DateTime.now(),
      ),
      Nudge(
        id: '3',
        title: 'Deep Breathing',
        description: 'Practice 3 deep breaths when stressed',
        category: 'Mindfulness',
        icon: 'air',
        isActive: true,
        createdAt: DateTime.now(),
      ),
    ];

    // Simulate API delay
    Future.delayed(const Duration(seconds: 1), () {
      emit(NudgesLoaded(mockNudges));
    });
  }

  void addNudge(Nudge nudge) {
    if (state is NudgesLoaded) {
      final currentNudges = (state as NudgesLoaded).nudges;
      final updatedNudges = [...currentNudges, nudge];
      emit(NudgesLoaded(updatedNudges));
    }
  }

  void removeNudge(String id) {
    if (state is NudgesLoaded) {
      final currentNudges = (state as NudgesLoaded).nudges;
      final updatedNudges = currentNudges.where((nudge) => nudge.id != id).toList();
      emit(NudgesLoaded(updatedNudges));
    }
  }

  void toggleNudgeActive(String id) {
    if (state is NudgesLoaded) {
      final currentNudges = (state as NudgesLoaded).nudges;
      final updatedNudges = currentNudges.map((nudge) {
        if (nudge.id == id) {
          return nudge.copyWith(isActive: !nudge.isActive);
        }
        return nudge;
      }).toList();
      emit(NudgesLoaded(updatedNudges));
    }
  }
}