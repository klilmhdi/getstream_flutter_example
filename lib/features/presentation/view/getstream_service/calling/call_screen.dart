import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:getstream_flutter_example/features/presentation/manage/call/call_cubit.dart';
import 'package:getstream_flutter_example/features/presentation/widgets/call_duration_title.dart';
import 'package:stream_chat_flutter/stream_chat_flutter.dart';
import 'package:stream_video_flutter/stream_video_flutter.dart' hide User;

import '../../../../../core/app/app_consumers.dart';
import '../../../../../core/di/injector.dart';
import '../../../../../core/utils/controllers/user_auth_controller.dart';

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
  final userAuthController = locator.get<UserAuthController>();

  final ParticipantLayoutMode _currentLayoutMode = ParticipantLayoutMode.grid;
  Channel? _channel;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    widget.call.state.valueStream.listen((callState) {
      if (callState.localParticipant != null) {
        debugPrint(
            "//////////////////////////////////////////////////////////////////////////////////////////////////// Local participant updated: ${callState.localParticipant}");
      }
    });

    widget.call.setCameraEnabled(enabled: false);

    final options = widget.connectOptions ?? const CallConnectOptions();
    if (options.camera == TrackOption.enabled()) {
      widget.call.setCameraEnabled(enabled: true);
    } else {
      return;
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
    WidgetsBinding.instance.removeObserver(this);
    AppConsumers().compositeSubscription.cancel();
    StreamVideo.instance.pushNotificationManager?.endAllCalls();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ignore: deprecated_member_use
    return WillPopScope(
      onWillPop: () async => !Navigator.of(context).userGestureInProgress,
      child: BlocProvider(
        create: (context) => CallingsCubit(),
        child: BlocBuilder<CallingsCubit, CallingsState>(
          builder: (context, state) {
            return StreamBuilder<CallState>(
                stream: widget.call.state.valueStream,
                builder: (context, snapshot) {
                  return Scaffold(
                    resizeToAvoidBottomInset: false,
                    body: StreamCallContainer(
                      call: widget.call,
                      callConnectOptions: widget.connectOptions,
                      pictureInPictureConfiguration: const PictureInPictureConfiguration(enablePictureInPicture: true),
                      onCancelCallTap: () {
                        widget.call.reject(reason: CallRejectReason.cancel());
                      },
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
                              layoutMode: _currentLayoutMode,
                              pictureInPictureConfiguration: const PictureInPictureConfiguration(
                                  enablePictureInPicture: true,
                                  iOSPiPConfiguration: IOSPictureInPictureConfiguration(
                                    ignoreLocalParticipantVideo: false,
                                  ),
                                  androidPiPConfiguration: AndroidPictureInPictureConfiguration()),
                              callParticipantsBuilder: (context, call, callState) {
                                return Stack(
                                  children: [
                                    StreamCallParticipants(
                                      call: call,
                                      participants: callState.callParticipants,
                                      layoutMode: _currentLayoutMode,
                                    ),
                                  ],
                                );
                              },
                              callAppBarBuilder: (context, call, callState) {
                                return CallAppBar(
                                  backgroundColor: Colors.transparent,
                                  call: call,
                                  elevation: 0,
                                  showLeaveCallAction: false,
                                  leadingWidth: 60,
                                  leading: !kIsWeb
                                      ? call.state.valueOrNull?.localParticipant != null
                                          ? FlipCameraOption(call: call, localParticipant: callState.localParticipant!)
                                          : null
                                      : const SizedBox.shrink(),
                                  title: Text(call.id),
                                  actions: const [],
                                );
                              },
                              // bottom buttons controllers
                              callControlsBuilder: (BuildContext context, Call call, CallState callState) {
                                final localParticipant = callState.localParticipant!;
                                return Container(
                                  padding: const EdgeInsets.only(top: 4),
                                  color: Colors.transparent,
                                  child: SafeArea(
                                    child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        crossAxisAlignment: CrossAxisAlignment.center,
                                        children: [
                                          ToggleMicrophoneOption(
                                            call: call,
                                            localParticipant: localParticipant,
                                            disabledMicrophoneBackgroundColor: Colors.indigo,
                                            disabledMicrophoneIconColor: Colors.white,
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.only(bottom: 4.0),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.end,
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                ToggleSpeakerphoneOption(call: call),
                                                const SizedBox(height: 20),
                                                LeaveCallOption(
                                                  call: call,
                                                  onLeaveCallTap: () => context.read<CallingsCubit>().endCall(
                                                      call,
                                                      localParticipant.userId,
                                                      localParticipant.name,
                                                      context,
                                                      userAuthController),
                                                ),
                                              ],
                                            ),
                                          ),
                                          ToggleCameraOption(
                                            call: call,
                                            localParticipant: callState.localParticipant!,
                                            disabledCameraBackgroundColor: Colors.indigo,
                                            disabledCameraIconColor: Colors.white,
                                          ),
                                        ]),
                                  ),
                                );
                              },
                            ),
                            Center(
                                heightFactor: 5,
                                child: CallDurationTitle(
                                  call: widget.call,
                                )),
                          ],
                        );
                      },
                    ),
                  );
                });
          },
        ),
      ),
    );
  }
}
