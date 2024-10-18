import 'package:equatable/equatable.dart';
import 'package:stream_video_flutter/stream_video_flutter.dart';

abstract class RegisterState extends Equatable {
  @override
  List<Object?> get props => [];
}

class RegisterInitState extends RegisterState {}

class RegisterLoadingState extends RegisterState {}

class RegisterSuccessState extends RegisterState {
  final User user;

  RegisterSuccessState({required this.user});

  @override
  List<Object?> get props => [user];
}

class RegisterFailedState extends RegisterState {
  final String error;

  RegisterFailedState(this.error);
}
