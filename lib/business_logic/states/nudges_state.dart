import 'package:equatable/equatable.dart';
import '../../data/models/nudge_model.dart';

abstract class NudgesState extends Equatable {
  const NudgesState();

  @override
  List<Object> get props => [];
}

class NudgesInitial extends NudgesState {}

class NudgesLoading extends NudgesState {}

class NudgesLoaded extends NudgesState {
  final List<Nudge> nudges;

  const NudgesLoaded(this.nudges);

  @override
  List<Object> get props => [nudges];
}

class NudgesError extends NudgesState {
  final String message;

  const NudgesError(this.message);

  @override
  List<Object> get props => [message];
}