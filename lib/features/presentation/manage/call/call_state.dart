part of 'call_cubit.dart';

abstract class CallingsState extends Equatable {
  const CallingsState();

  @override
  List<Object?> get props => [];
}

class CallInitial extends CallingsState {}

class CallLoadingState extends CallingsState {}

/// Loading incoming call
class LoadingIncomingCallState extends CallingsState {}

/// Create a call from teacher
class CallCreatedState extends CallingsState {
  final Call call;
  final CallState callState;

  const CallCreatedState({required this.call, required this.callState});

  @override
  List<Object?> get props => [call, callState];
}

/// send and request call
class LoadCallToStudentState extends CallingsState {}

/// Success send call to student
class SuccessSendCallToStudentState extends CallingsState {
  final Call call;
  final CallState callState;
  final CallStatus callStatus = CallStatus.outgoing(acceptedByCallee: true);

  SuccessSendCallToStudentState({required this.call, required this.callState});
}

/// Failed send the outgoing call to student
class FailedSendCallToStudentState extends CallingsState {
  final String error;

  const FailedSendCallToStudentState({required this.error});
}

/// Success receive the call to student and sort states
class IncomingCallState extends CallingsState {
  final Call call;

  // final CallState callState;
  final CallStatus callStatus = CallStatus.incoming(acceptedByMe: true);
  final String teacherName, teacherId;

  IncomingCallState({
    required this.call,
    required this.teacherName,
    required this.teacherId,
    // required this.callState,
    // required this.callStatus,
  });
}

/// Failed receive the incoming call from teacher to student
class FailedReceiveIncomingCallState extends CallingsState {
  final String errorMessage;

  const FailedReceiveIncomingCallState({required this.errorMessage});
}

/// Accept incoming call from teacher
class CallAcceptedState extends CallingsState {
  final String callId;

  const CallAcceptedState({required this.callId});
}

/// Reject the call from teacher
class CallRejectedFromTeacherState extends CallingsState {
  final String callId;

  const CallRejectedFromTeacherState({required this.callId});
}

/// Reject the call from teacher
class CallRejectedFromStudentState extends CallingsState {
  final String callId;

  const CallRejectedFromStudentState({required this.callId});
}

/// End the call
class CallEndedState extends CallingsState {}

/// Leave the call
class CallLeavedState extends CallingsState {}

/// Error in call
class CallErrorState extends CallingsState {
  final String message;

  const CallErrorState(this.message);

  @override
  List<Object?> get props => [message];
}
