import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:getstream_flutter_example/core/utils/widgets.dart';
import 'package:getstream_flutter_example/features/presentation/widgets/badged_call_option.dart';
import 'package:getstream_flutter_example/features/presentation/widgets/call_duration_title.dart';
import 'package:getstream_flutter_example/features/presentation/widgets/call_participants_list.dart';
import 'package:stream_chat_flutter/stream_chat_flutter.dart';
import 'package:stream_video_flutter/stream_video_flutter.dart' hide User;

import '../../../../core/app/app_consumers.dart';
import '../../../../core/di/injector.dart';
import '../../../../core/utils/controllers/user_auth_controller.dart';
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
  final userAuthController = locator.get<UserAuthController>();

  final ParticipantLayoutMode _currentLayoutMode = ParticipantLayoutMode.grid;
  Channel? _channel;

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
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        body: StreamCallContainer(
          call: widget.call,
          callConnectOptions: widget.connectOptions,
          // outgoingCallBuilder: (context, call, callState) => CustomOutgoingCallScreen(call: call, callState: callState),
          // incomingCallBuilder: (context, call, callState) => CustomIncomingCallScreen(call: call),
          // outgoingCallBuilder: (context, call, callState) => const Center(child: Text("Connecting...")),
          // incomingCallBuilder: (context, call, callState) => const Center(child: Text("Incoming Call...")),
          pictureInPictureConfiguration: const PictureInPictureConfiguration(enablePictureInPicture: true),
          callContentBuilder: (BuildContext context, Call call, CallState callState) {
            if (callState.status.isDisconnected) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  // const CircularProgressIndicator();
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (context) => Layout(
                        type: userAuthController.currentUser?.role == 'admin' ? "Teacher" : 'Student',
                      ),
                    ),
                    (route) => false,
                  );
                  showSuccessSnackBar("Calling finished successfully!", 3, context);
                }
              });
            }
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
                    if (callState.status.isDisconnected) {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                Layout(type: userAuthController.currentUser!.role == 'admin' ? "Teacher" : 'Student')),
                        (route) => false,
                      );
                      // Navigator.pop(context);
                      showSuccessSnackBar("Meeting finished successful!", 3, context);
                    }

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
                  // appbar controllers
                  callAppBarBuilder: (context, call, callState) => CallAppBar(
                    backgroundColor: Colors.transparent,
                    call: call,
                    elevation: 0,
                    showLeaveCallAction: false,
                    // onLeaveCallTap: () => context.read<MeetingsCubit>().endMeet(context, call, call.id),
                    leadingWidth: 60,
                    leading: !kIsWeb
                        ? FlipCameraOption(call: call, localParticipant: call.state.value.localParticipant!)
                        : const SizedBox.shrink(),
                    title: Text(call.id),
                    actions: [
                      BadgedCallOption(
                        callControlOption: CallControlOption(
                          icon: const Icon(Icons.people),
                          onPressed: _channel != null ? () => _showParticipants(context) : null,
                        ),
                        badgeCount: callState.callParticipants.length,
                      ),
                    ],
                  ),
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
                                      onLeaveCallTap: () => call.end(),
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
      ),
    );
  }

  void _showParticipants(BuildContext context) => showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) => DraggableScrollableSheet(
          initialChildSize: 0.4,
          minChildSize: 0.2,
          maxChildSize: 0.8,
          expand: false,
          builder: (context, scrollController) =>
              CallParticipantsList(call: widget.call, scrollController: scrollController)));
}
