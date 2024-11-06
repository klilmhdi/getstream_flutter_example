part of 'call_cubit.dart';

abstract class CallingsState extends Equatable {
  const CallingsState();

  @override
  List<Object?> get props => [];
}

class CallInitial extends CallingsState {}

class CallLoadingState extends CallingsState {}

class CallCreatedState extends CallingsState {
  final Call call;

  const CallCreatedState({required this.call});

  @override
  List<Object?> get props => [call];
}

class CallJoinedState extends CallingsState {
  final Call call;

  const CallJoinedState({required this.call});

  @override
  List<Object?> get props => [call];
}

class CallEndedState extends CallingsState {}

class CallErrorState extends CallingsState {
  final String message;

  const CallErrorState(this.message);

  @override
  List<Object?> get props => [message];
}

class ActiveCallsLoadingState extends CallingsState {}

class ActiveCallsFetchedState extends CallingsState {
  final List<Map<String, dynamic>> activeCalls;

  const ActiveCallsFetchedState({required this.activeCalls});

  @override
  List<Object> get props => [activeCalls];
}

class ActiveCallsFailedState extends CallingsState {
  final String error;

  const ActiveCallsFailedState({required this.error});

  @override
  List<Object> get props => [error];
}
