part of 'call_cubit.dart';

abstract class CallingsState extends Equatable {
  const CallingsState();

  @override
  List<Object?> get props => [];
}

class CallInitial extends CallingsState {}

// calling states
class CallLoadingState extends CallingsState {}

class CallCreatedState extends CallingsState {
  final Call call;

  const CallCreatedState({required this.call});

  @override
  List<Object?> get props => [call];
}

class IncomingCallState extends CallingsState {
  final Map<String, dynamic> callData;

  const IncomingCallState({required this.callData});
}

class CallAcceptedState extends CallingsState {
  final String callId;

  const CallAcceptedState({required this.callId});
}

class CallRejectedState extends CallingsState {
  final String callId;

  const CallRejectedState({required this.callId});
}

class CallEndedState extends CallingsState {}

class CallErrorState extends CallingsState {
  final String message;

  const CallErrorState(this.message);

  @override
  List<Object?> get props => [message];
}

// meeting states
class MeetingLoadingState extends CallingsState {}

class MeetingCreatedState extends CallingsState {
  final Call meet;

  const MeetingCreatedState({required this.meet});

  @override
  List<Object?> get props => [meet];
}

class MeetingJoinedState extends CallingsState {
  final Call call;
  final CallConnectOptions? connectOptions;

  const MeetingJoinedState({required this.call, required this.connectOptions});

  @override
  List<Object?> get props => [call, connectOptions];
}

class MeetingEndedState extends CallingsState {}

class MeetingErrorState extends CallingsState {
  final String message;

  const MeetingErrorState(this.message);

  @override
  List<Object?> get props => [message];
}

// active meets states
class ActiveMeetsLoadingState extends CallingsState {}

class ActiveMeetsFetchedState extends CallingsState {
  final List<MeetingModel> activeMeets;

  const ActiveMeetsFetchedState({required this.activeMeets});

  @override
  List<Object> get props => [activeMeets];
}

class ActiveMeetsFailedState extends CallingsState {
  final String error;

  const ActiveMeetsFailedState({required this.error});

  @override
  List<Object> get props => [error];
}
