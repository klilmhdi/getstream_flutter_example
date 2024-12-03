import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:getstream_flutter_example/core/utils/widgets.dart';
import 'package:getstream_flutter_example/features/data/services/firebase_services.dart';
import 'package:getstream_flutter_example/features/presentation/manage/call/call_cubit.dart';
import 'package:getstream_flutter_example/features/presentation/widgets/call_duration_title.dart';
import 'package:getstream_flutter_example/features/presentation/widgets/settings_menu.dart';
import 'package:stream_chat_flutter/stream_chat_flutter.dart';
import 'package:stream_video_flutter/stream_video_flutter.dart' hide User;
import '../../../../core/di/injector.dart';
import '../../../../core/utils/controllers/user_auth_controller.dart';
import '../../../data/repo/user_chat_repository.dart';
import '../home/layout.dart';

class CallScreen extends StatefulWidget {
  const CallScreen({
    super.key,
    required this.call,
    this.connectOptions,
  });

  final Call call;
  final CallConnectOptions? connectOptions;

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> with WidgetsBindingObserver {
  late final _userChatRepo = locator.get<UserChatRepository>();
  final userAuthController = locator.get<UserAuthController>();

  bool _moreMenuVisible = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);
    // Use the connectOptions to configure the call
    final options = widget.connectOptions ?? const CallConnectOptions();
    if (options.camera == TrackOption.enabled()) {
      widget.call.setCameraEnabled(enabled: true);
    } else {
      widget.call.setCameraEnabled(enabled: false);
    }

    if (options.microphone == TrackOption.enabled()) {
      widget.call.setMicrophoneEnabled(enabled: true);
    } else {
      widget.call.setMicrophoneEnabled(enabled: false);
    }
  }

  @override
  void dispose() {
    widget.call.leave();
    _userChatRepo.disconnectUser();
    WidgetsBinding.instance.removeObserver(this);
    StreamVideo.instance.pushNotificationManager?.endAllCalls();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ignore: deprecated_member_use
    return WillPopScope(
      onWillPop: () async => !Navigator.of(context).userGestureInProgress,
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        body: StreamCallContainer(
          call: widget.call,
          callConnectOptions: widget.connectOptions,
          pictureInPictureConfiguration: const PictureInPictureConfiguration(enablePictureInPicture: true),
          callContentBuilder: (BuildContext context, Call call, CallState callState) {
            return Stack(
              children: [
                // Able PIP
                StreamPictureInPictureUiKitView(call: widget.call),
                // Stream Call Content
                StreamCallContent(
                  call: call,
                  onBackPressed: () => StreamPictureInPictureUiKitView(call: widget.call),
                  callState: callState,
                  pictureInPictureConfiguration: const PictureInPictureConfiguration(
                      enablePictureInPicture: true,
                      iOSPiPConfiguration: IOSPictureInPictureConfiguration(
                        ignoreLocalParticipantVideo: false,
                      ),
                      androidPiPConfiguration: AndroidPictureInPictureConfiguration()),
                  callParticipantsBuilder: (context, call, callState) {
                    if (callState.status.isDisconnected) {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                Layout(type: userAuthController.currentUser!.role == 'admin' ? "Teacher" : 'Student')),
                            (route) => false,
                      );
                      showSuccessSnackBar("Meeting finished successful!", 3, context);
                    }

                    return Stack(
                      children: [
                        StreamCallParticipants(
                          call: call,
                          participants: callState.callParticipants,
                        ),
                        if (_moreMenuVisible) ...[
                          GestureDetector(
                              onTap: () => setState(() => _moreMenuVisible = false),
                              child: Container(color: Colors.black12)),
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: SettingsMenu(
                              call: call,
                              onAudioOutputChange: (_) => setState(() => _moreMenuVisible = false),
                              onAudioInputChange: (_) => setState(() => _moreMenuVisible = false),
                            ),
                          ),
                        ],
                      ],
                    );
                  },
                  // appbar controllers
                  callAppBarBuilder: (context, call, callState) => CallAppBar(
                    backgroundColor: Colors.black,
                    call: call,
                    showLeaveCallAction: true,
                    onLeaveCallTap: () => context.read<CallingsCubit>().endMeet(context, call, call.id),
                    leadingWidth: 120,
                    leading: Row(children: [
                      if (!kIsWeb) FlipCameraOption(call: call, localParticipant: call.state.value.localParticipant!),
                    ]),
                    title: call.state.valueOrNull!.callParticipants.length > 1
                        ? CallDurationTitle(
                      call: widget.call,
                    )
                        : const WaitingJoinMeetWidget(),
                  ),
                  // bottom buttons controllers
                  callControlsBuilder: (BuildContext context, Call call, CallState callState) {
                    final localParticipant = callState.localParticipant!;
                    return Container(
                      padding: const EdgeInsets.only(top: 16, left: 8),
                      color: Colors.black,
                      child: SafeArea(
                        child: Row(children: [
                          // options
                          CallControlOption(
                              icon: Icon(Icons.more_vert, color: _moreMenuVisible ? Colors.white : Colors.black),
                              backgroundColor: _moreMenuVisible ? Colors.deepPurple : Colors.white,
                              onPressed: () => _toggleMoreMenu(context)),
                          ToggleMicrophoneOption(
                            call: call,
                            localParticipant: localParticipant,
                            disabledMicrophoneBackgroundColor: Colors.red,
                            disabledMicrophoneIconColor: Colors.white,
                          ),
                          ToggleCameraOption(
                            call: call,
                            localParticipant: localParticipant,
                            disabledCameraBackgroundColor: Colors.red,
                            disabledCameraIconColor: Colors.white,
                          ),
                        ]),
                      ),
                    );
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _toggleMoreMenu(BuildContext context) => setState(() => _moreMenuVisible = !_moreMenuVisible);
}

// import 'dart:convert';
// import 'dart:async';
//
// import 'package:flutter/material.dart';
// import 'package:flutter_callkit_incoming/entities/entities.dart';
// import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
// import 'package:http/http.dart';
//
// class CallingPage extends StatefulWidget {
//   const CallingPage({super.key});
//
//   @override
//   State<StatefulWidget> createState() {
//     return CallingPageState();
//   }
// }
//
// class CallingPageState extends State<CallingPage> {
//   late CallKitParams? calling;
//
//   Timer? _timer;
//   int _start = 0;
//
//   void startTimer() {
//     const oneSec = Duration(seconds: 1);
//     _timer = Timer.periodic(
//       oneSec,
//           (Timer timer) {
//         setState(() {
//           _start++;
//         });
//       },
//     );
//   }
//
//   String intToTimeLeft(int value) {
//     int h, m, s;
//     h = value ~/ 3600;
//     m = ((value - h * 3600)) ~/ 60;
//     s = value - (h * 3600) - (m * 60);
//     String hourLeft = h.toString().length < 2 ? '0$h' : h.toString();
//     String minuteLeft = m.toString().length < 2 ? '0$m' : m.toString();
//     String secondsLeft = s.toString().length < 2 ? '0$s' : s.toString();
//     String result = "$hourLeft:$minuteLeft:$secondsLeft";
//     return result;
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final params = jsonDecode(jsonEncode(
//         ModalRoute.of(context)!.settings.arguments as Map<dynamic, dynamic>));
//     print(ModalRoute.of(context)!.settings.arguments);
//     calling = CallKitParams.fromJson(params);
//
//     var timeDisplay = intToTimeLeft(_start);
//
//     return Scaffold(
//       body: SizedBox(
//         height: MediaQuery.of(context).size.height,
//         width: double.infinity,
//         child: Center(
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             crossAxisAlignment: CrossAxisAlignment.center,
//             children: [
//               Text(timeDisplay),
//               const Text('Calling...'),
//               TextButton(
//                 style: ButtonStyle(
//                   foregroundColor:
//                   MaterialStateProperty.all<Color>(Colors.blue),
//                 ),
//                 onPressed: () async {
//                   if (calling != null) {
//                     await makeFakeConnectedCall(calling!.id!);
//                     startTimer();
//                   }
//                 },
//                 child: const Text('Fake Connected Call'),
//               ),
//               TextButton(
//                 style: ButtonStyle(
//                   foregroundColor:
//                   MaterialStateProperty.all<Color>(Colors.blue),
//                 ),
//                 onPressed: () async {
//                   if (calling != null) {
//                     await makeEndCall(calling!.id!);
//                     calling = null;
//                   }
//                   NavigationService.instance.goBack();
//                   await requestHttp('END_CALL');
//                 },
//                 child: const Text('End Call'),
//               )
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//
//   Future<void> makeFakeConnectedCall(id) async {
//     await FlutterCallkitIncoming.setCallConnected(id);
//   }
//
//   Future<void> makeEndCall(id) async {
//     await FlutterCallkitIncoming.endCall(id);
//   }
//
//   //check with https://webhook.site/#!/2748bc41-8599-4093-b8ad-93fd328f1cd2
//   Future<void> requestHttp(content) async {
//     get(Uri.parse(
//         'https://webhook.site/2748bc41-8599-4093-b8ad-93fd328f1cd2?data=$content'));
//   }
//
//   @override
//   void dispose() {
//     super.dispose();
//     _timer?.cancel();
//     if (calling != null) FlutterCallkitIncoming.endCall(calling!.id!);
//   }
// }
