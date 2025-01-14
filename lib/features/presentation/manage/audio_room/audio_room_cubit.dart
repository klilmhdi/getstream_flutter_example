import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:stream_video_flutter/stream_video_flutter.dart';

part 'audio_room_state.dart';

class AudioRoomCubit extends Cubit<AudioRoomState> {
  AudioRoomCubit() : super(AudioRoomInitial());
}
