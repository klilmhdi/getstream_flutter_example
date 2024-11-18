import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:getstream_flutter_example/core/di/injector.dart';
import 'package:getstream_flutter_example/core/utils/controllers/user_auth_controller.dart';
import 'package:getstream_flutter_example/core/utils/widgets.dart';
import 'package:getstream_flutter_example/features/data/services/firebase_services.dart';
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

  // join meet function
  void joinMeetPressed() {
    var options = const CallConnectOptions();

    final cameraTrack = _cameraTrack;
    final microphoneTrack = _microphoneTrack;
    if (cameraTrack != null) {
      options = options.copyWith(camera: TrackOption.enabled());
    } else {
      options = options.copyWith(camera: TrackOption.disabled());
    }

    if (microphoneTrack != null) {
      options = options.copyWith(microphone: TrackOption.enabled());
    } else {
      options = options.copyWith(microphone: TrackOption.disabled());
    }

    context.read<CallingsCubit>().joinMeet(context, widget.call.id, connectOptions: options);
  }

  // end meet function
  Future _endCall() async {
    print("Call end button pressed");

    // Perform navigation, call leave, and track stopping actions in sequence
    // await Navigator.maybePop(context);
    // widget.call.reject();
    // widget.call.leave();

    // Stop the tracks (ensuring they are stopped before checking the state)
    await _cameraTrack?.stop();
    await _microphoneTrack?.stop();

    bool isTeacher = await FirebaseServices().checkIfCurrentUserIsTeacher();
    if (isTeacher) {
      try {
        if (!mounted) return;
        await context.read<CallingsCubit>().endMeetFromTeacher(context, widget.call.id, widget.call);
        print("Call successfully ended in Firestore");
        // showSuccessSnackBar("Success: isActive set to false", 4, context);
      } catch (error) {
        print("Failed to end call in Firestore: $error");
        // showErrorSnackBar("Error ending call: ${error.toString()}", 4, context);
      }
    } else {
      // await context.read<CallingsCubit>().leaveMeetForStudent(widget.call.id);
      Navigator.pop(context);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
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
                  onPressed: () async => _endCall(),
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
                const Icon(Icons.groups, size: 30),
                const SizedBox(height: 8),
                Text('Check your meeting settings \nbefore joining',
                    textAlign: TextAlign.center,
                    style: textTheme.title1.copyWith(fontWeight: FontWeight.bold, color: CupertinoColors.black)),
                const SizedBox(height: 16),
                Center(
                    child: StreamLobbyVideo(
                        call: widget.call,
                        onMicrophoneTrackSet: (track) => _microphoneTrack = track,
                        onCameraTrackSet: (track) => _cameraTrack = track)),
                const SizedBox(height: 24),
                Padding(
                    padding: const EdgeInsets.all(16),
                    child: StreamButton.active(label: 'Start a meeting', onPressed: joinMeetPressed)),
                const SizedBox(height: 56),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
