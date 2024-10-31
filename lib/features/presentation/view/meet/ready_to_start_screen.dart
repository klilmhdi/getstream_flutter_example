import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:getstream_flutter_example/core/di/injector.dart';
import 'package:getstream_flutter_example/core/utils/consts/user_auth_controller.dart';
import 'package:getstream_flutter_example/features/presentation/manage/auth/register/register_cubit.dart';
import 'package:getstream_flutter_example/features/presentation/manage/call/call_cubit.dart';
import 'package:stream_video_flutter/stream_video_flutter.dart';

import '../../manage/fetch_users/fetch_users_cubit.dart';
import '../../widgets/stream_button.dart';

class ReadyToStartScreen extends StatefulWidget {
  const ReadyToStartScreen({super.key, required this.onJoinCallPressed, required this.call});

  final ValueChanged<CallConnectOptions> onJoinCallPressed;
  final Call call;

  @override
  State<ReadyToStartScreen> createState() => _ReadyToStartScreenState();
}

class _ReadyToStartScreenState extends State<ReadyToStartScreen> {
  RtcLocalAudioTrack? _microphoneTrack;
  RtcLocalCameraTrack? _cameraTrack;

  final _userAuthController = locator.get<UserAuthController>();

  void joinCallPressed() {
    var options = const CallConnectOptions();

    final cameraTrack = _cameraTrack;
    if (cameraTrack != null) {
      options = options.copyWith(camera: TrackOption.enabled());
    }

    final microphoneTrack = _microphoneTrack;
    if (microphoneTrack != null) {
      options = options.copyWith(microphone: TrackOption.enabled());
    }

    widget.onJoinCallPressed(options);
  }

  @override
  void dispose() {
    _cameraTrack?.stop();
    _microphoneTrack?.stop();

    _cameraTrack = null;
    _microphoneTrack = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final streamVideoTheme = StreamVideoTheme.of(context);
    final textTheme = streamVideoTheme.textTheme;
    final colorTheme = streamVideoTheme.colorTheme;
    final currentUser = _userAuthController.currentUser;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        leading: Padding(
            padding: const EdgeInsets.all(8),
            child: CircleAvatar(backgroundImage: NetworkImage(currentUser?.image ?? ""))),
        titleSpacing: 4,
        centerTitle: false,
        title: Text(
          currentUser?.name ?? "Empty Name",
          style: const TextStyle(fontSize: 25, color: CupertinoColors.black),
        ),
        actions: [
          CircleAvatar(
            child: BlocBuilder<FetchUsersCubit, FetchUsersState>(
              builder: (context, state) {
                return IconButton(
                  icon: const Icon(Icons.call_end, color: Colors.red),
                  onPressed: () {
                    Navigator.maybePop(context).then((_) {
                      widget.call.reject();
                      widget.call.leave();
                      _cameraTrack?.stop();
                      _microphoneTrack?.stop();

                      if (state is UserLoaded) {
                        final isTeacher =
                            state.users.any((user) => user.uid == currentUser!.id && user.role == "Teacher");
                        if (isTeacher) {
                          context.read<CallingsCubit>().endCall(context, widget.call.id);
                        }
                      }
                    });
                  },
                );
              },
            ),
          )
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                const Icon(Icons.groups),
                const SizedBox(height: 8),
                Text('Check your call settings \nbefore joining',
                    textAlign: TextAlign.center,
                    style: textTheme.title1.copyWith(fontWeight: FontWeight.bold, color: colorTheme.textHighEmphasis)),
                const SizedBox(height: 16),
                Center(
                  // child: StreamLobbyVideo(
                  //     call: widget.call,
                  //     onMicrophoneTrackSet: (track) => _microphoneTrack = track,
                  //     onCameraTrackSet: (track) => _cameraTrack = track)
                  child: StreamLobbyVideo(
                      call: widget.call,
                      onMicrophoneTrackSet: (track) {
                        if (track != null) {
                          _microphoneTrack = track;
                        } else {
                          print("Microphone track is null, cannot proceed.");
                        }
                      },
                      onCameraTrackSet: (track) {
                        if (track != null) {
                          _cameraTrack = track;
                        } else {
                          print("Camera track is null, cannot proceed.");
                        }
                      }),
                ),
                const SizedBox(height: 24),
                Padding(
                    padding: const EdgeInsets.all(16),
                    child: StreamButton.active(label: 'Start a call', onPressed: joinCallPressed)),
                const SizedBox(height: 56),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
