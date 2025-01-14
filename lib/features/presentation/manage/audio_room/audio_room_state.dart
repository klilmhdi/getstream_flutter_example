part of 'audio_room_cubit.dart';

sealed class AudioRoomState extends Equatable {
  const AudioRoomState();

  @override
  List<Object> get props => [];
}

final class AudioRoomInitial extends AudioRoomState {}

class LoadingInitAudioRoomState extends AudioRoomState {}

class SuccessInitAudioRoomState extends AudioRoomState {
  final Call audioRoom;

  const SuccessInitAudioRoomState(this.audioRoom);

  @override
  List<Object> get props => [audioRoom];
}

class FailedInitAudioRoomState extends AudioRoomState {
  final String message;

  const FailedInitAudioRoomState(this.message);

  @override
  List<Object> get props => [message];
}

class LoadingJoinAudioRoomState extends AudioRoomState {}

class SuccessJoinAudioRoomState extends AudioRoomState {}

class FailedJoinAudioRoomState extends AudioRoomState {
  final String message;

  const FailedJoinAudioRoomState(this.message);

  @override
  List<Object> get props => [message];
}

class LoadingLeaveAudioRoomState extends AudioRoomState {}

class SuccessLeaveAudioRoomState extends AudioRoomState {}

class FailedLeaveAudioRoomState extends AudioRoomState {}

class LoadingEndAudioRoomState extends AudioRoomState {}

class SuccessEndAudioRoomState extends AudioRoomState {}

class FailedEndAudioRoomState extends AudioRoomState {}

class AudioRoomErrorMessageState extends AudioRoomState {
  final String message;

  const AudioRoomErrorMessageState(this.message);

  @override
  List<Object> get props => [message];
}
