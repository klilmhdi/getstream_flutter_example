part of 'call_cubit.dart';

abstract class CallingsState extends Equatable {
  const CallingsState();

  @override
  List<Object?> get props => [];
}

class CallInitial extends CallingsState {}

class CallLoadingState extends CallingsState {}

class LoadingIncomingCallState extends CallingsState {}

class CallCreatedState extends CallingsState {
  final Call call;
  final CallState callState;

  const CallCreatedState({required this.call, required this.callState});

  @override
  List<Object?> get props => [call, callState];
}

class LoadCallToStudentState extends CallingsState {}

class SuccessSendCallToStudentState extends CallingsState {
  final Call call;
  final CallState callState;
  final CallStatus callStatus = CallStatus.outgoing(acceptedByCallee: true);

  SuccessSendCallToStudentState({required this.call, required this.callState});
}

class FailedSendCallToStudentState extends CallingsState {
  final String error;

  const FailedSendCallToStudentState({required this.error});
}

class IncomingCallState extends CallingsState {
  final Call call;
  // final CallState callState;
  final CallStatus callStatus = CallStatus.incoming(acceptedByMe: true);

  IncomingCallState({
    required this.call,
    // required this.callState,
    // required this.callStatus,
  });
}

class FailedReceiveIncomingCallState extends CallingsState {
  final String errorMessage;

  const FailedReceiveIncomingCallState({required this.errorMessage});
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

class CallLeavedState extends CallingsState {}

class CallErrorState extends CallingsState {
  final String message;

  const CallErrorState(this.message);

  @override
  List<Object?> get props => [message];
}
