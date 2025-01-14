part of 'live_stream_cubit.dart';

abstract class LiveStreamState extends Equatable {
  const LiveStreamState();

  @override
  List<Object> get props => [];
}

final class LiveStreamInitial extends LiveStreamState {}

class LoadingInitLiveStreamState extends LiveStreamState {}

class SuccessInitLiveStreamState extends LiveStreamState {
  final Call liveStream;

  const SuccessInitLiveStreamState(this.liveStream);

  @override
  List<Object> get props => [liveStream];
}

class FailedInitLiveStreamState extends LiveStreamState {
  final String message;

  const FailedInitLiveStreamState(this.message);

  @override
  List<Object> get props => [message];
}

class LoadingJoinLiveStreamState extends LiveStreamState {}

class SuccessJoinLiveStreamState extends LiveStreamState {
  final Call liveStream;
  final CallConnectOptions connectOptions;

  const SuccessJoinLiveStreamState({required this.liveStream, required this.connectOptions});

  @override
  List<Object> get props => [liveStream, connectOptions];
}

class FailedJoinLiveStreamState extends LiveStreamState {
  final String message;

  const FailedJoinLiveStreamState(this.message);

  @override
  List<Object> get props => [message];
}

class LoadingLeaveLiveStreamState extends LiveStreamState {}

class SuccessLeaveLiveStreamState extends LiveStreamState {}

class FailedLeaveLiveStreamState extends LiveStreamState {
  final String message;

  const FailedLeaveLiveStreamState(this.message);

  @override
  List<Object> get props => [message];
}

class LoadingEndLiveStreamState extends LiveStreamState {}

class SuccessEndLiveStreamState extends LiveStreamState {}

class FailedEndLiveStreamState extends LiveStreamState {
  final String message;

  const FailedEndLiveStreamState(this.message);

  @override
  List<Object> get props => [message];
}

class LoadingFetchingLiveStreamState extends LiveStreamState {}

class SuccessFetchingLiveStreamState extends LiveStreamState {
  final List<LiveStreamModel> activeLiveStreams;

  const SuccessFetchingLiveStreamState({required this.activeLiveStreams});

  @override
  List<Object> get props => [activeLiveStreams];
}

class FailedFetchingLiveStreamState extends LiveStreamState {
  final String message;

  const FailedFetchingLiveStreamState(this.message);

  @override
  List<Object> get props => [message];
}

class LiveStreamErrorMessageState extends LiveStreamState {
  final String message;

  const LiveStreamErrorMessageState(this.message);

  @override
  List<Object> get props => [message];
}
