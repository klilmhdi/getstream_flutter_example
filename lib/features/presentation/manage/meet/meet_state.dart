part of 'meet_cubit.dart';

abstract class MeetingState extends Equatable {
  const MeetingState();

  @override
  List<Object> get props => [];
}

final class MeetInitial extends MeetingState {}

class MeetingLoadingState extends MeetingState {}

class MeetingLoadingJoinStudentState extends MeetingState {}

class MeetingCreatedState extends MeetingState {
  final Call meet;

  const MeetingCreatedState({required this.meet});

  @override
  List<Object> get props => [meet];
}

class MeetingJoinedState extends MeetingState {
  final Call call;
  final CallConnectOptions? connectOptions;

  const MeetingJoinedState({required this.call, required this.connectOptions});

  @override
  List<Object> get props => [call];
}

class MeetingEndedState extends MeetingState {
  final String meetId;
  final Duration duration;

  const MeetingEndedState({required this.meetId, required this.duration});

  @override
  List<Object> get props => [meetId, duration];
}

class MeetingErrorState extends MeetingState {
  final String message;

  const MeetingErrorState(this.message);

  @override
  List<Object> get props => [message];
}

class MeetingDurationUpdatedState extends MeetingState {
  final Duration duration;

  const MeetingDurationUpdatedState({required this.duration});

  @override
  List<Object> get props => [duration];
}

// active meets states
class ActiveMeetsLoadingState extends MeetingState {}

class ActiveMeetsFetchedState extends MeetingState {
  final List<MeetingModel> activeMeets;

  const ActiveMeetsFetchedState({required this.activeMeets});

  @override
  List<Object> get props => [activeMeets];
}

class ActiveMeetsFailedState extends MeetingState {
  final String error;

  const ActiveMeetsFailedState({required this.error});

  @override
  List<Object> get props => [error];
}

class StudentLeavedMeetState extends MeetingState {}