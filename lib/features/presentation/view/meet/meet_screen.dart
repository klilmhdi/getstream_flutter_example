import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:getstream_flutter_example/core/utils/widgets.dart';
import 'package:getstream_flutter_example/features/presentation/widgets/badged_call_option.dart';
import 'package:getstream_flutter_example/features/presentation/widgets/call_duration_title.dart';
import 'package:getstream_flutter_example/features/presentation/widgets/call_participants_list.dart';
import 'package:getstream_flutter_example/features/presentation/widgets/chat_sheet.dart';
import 'package:getstream_flutter_example/features/presentation/widgets/settings_menu.dart';
import 'package:stream_chat_flutter/stream_chat_flutter.dart';
import 'package:stream_video_flutter/stream_video_flutter.dart' hide User;

import '../../../../core/di/injector.dart';
import '../../../../core/utils/controllers/user_auth_controller.dart';
import '../../../data/repo/app_preferences.dart';
import '../../../data/repo/user_chat_repository.dart';
import '../../manage/meet/meet_cubit.dart';
import '../home/layout.dart';

class MeetScreen extends StatefulWidget {
  const MeetScreen({
    super.key,
    required this.call,
    this.connectOptions,
  });

  final Call call;
  final CallConnectOptions? connectOptions;

  @override
  State<MeetScreen> createState() => _MeetScreenState();
}

class _MeetScreenState extends State<MeetScreen> with WidgetsBindingObserver {
  late final _userChatRepo = locator.get<UserChatRepository>();
  final userAuthController = locator.get<UserAuthController>();

  Channel? _channel;
  ParticipantLayoutMode _currentLayoutMode = ParticipantLayoutMode.grid;
  bool _moreMenuVisible = false;

  // RtcLocalAudioTrack? _microphoneTrack;
  // RtcLocalCameraTrack? _cameraTrack;
  // final _isTeacher = FirebaseServices().checkIfCurrentUserIsTeacher();

  @override
  void initState() {
    super.initState();
    // initialize chat channel connection
    _connectChatChannel();

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

  // @override
  // void didChangeAppLifecycleState(AppLifecycleState state) {
  //   if (state == AppLifecycleState.paused ||
  //       state == AppLifecycleState.inactive ||
  //       state == AppLifecycleState.detached) {
  //   } else if (state == AppLifecycleState.resumed) {}
  //
  //   super.didChangeAppLifecycleState(state);
  // }

  @override
  void dispose() {
    widget.call.leave();
    _userChatRepo.disconnectUser();
    WidgetsBinding.instance.removeObserver(this);
    StreamVideo.instance.pushNotificationManager?.endAllCalls();
    super.dispose();
  }

  Future<void> _connectChatChannel() async {
    try {
      final appPreferences = locator.get<AppPreferences>();

      final currentUser = userAuthController.currentUser;
      if (currentUser == null) {
        debugPrint("No current user found");
        return;
      }

      if (_userChatRepo.currentUser == null) {
        final chatUID = md5.convert(utf8.encode(currentUser.id));
        await _userChatRepo
            .connectUser(
          User(
            id: chatUID.toString(),
            name: currentUser.name,
            image: currentUser.image,
          ),
          appPreferences.environment,
        )
            .then((_) {
          debugPrint("User connected successfully");
        }).catchError((error, stacktrace) {
          debugPrint("Error connecting user: $error\n$stacktrace");
        });
      }

      _channel = await _userChatRepo.createChannel(widget.call.id).catchError((error) {
        debugPrint("Error creating channel: $error");
      });

      if (_channel == null) {
        debugPrint("Channel creation failed");
      } else {
        debugPrint("Channel successfully created: ${_channel!.id}");
      }

      if (mounted) setState(() {});
    } catch (e, stacktrace) {
      debugPrint("Error in _connectChatChannel: $e\n$stacktrace");
    }
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
                  showSuccessSnackBar("Meeting finished successfully!", 3, context);
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
                              onReactionSend: (_) => setState(() => _moreMenuVisible = false),
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
                    leadingWidth: 120,
                    leading: Row(children: [
                      ToggleLayoutOption(onLayoutModeChanged: (layout) => setState(() => _currentLayoutMode = layout)),
                      if (!kIsWeb) FlipCameraOption(call: call, localParticipant: call.state.value.localParticipant!),
                    ]),
                    title: call.state.valueOrNull!.callParticipants.length > 1
                        ? MeetDurationTitle(
                            call: widget.call,
                            // onJoinCall: () async => callState.callParticipants.length > 1
                          )
                        : const WaitingJoinMeetWidget(),
                    actions: [
                      LeaveCallOption(
                        call: call,
                        icon: userAuthController.currentUser!.role == 'admin' ? Icons.call_end : Icons.logout,
                        onLeaveCallTap: () => context.read<MeetingsCubit>().endMeet(context, call, call.id),
                      )
                    ],
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
                          userAuthController.currentUser!.role == "admin"
                              ? ToggleScreenShareOption(
                                  call: call,
                                  localParticipant: localParticipant,
                                  screenShareConstraints: const ScreenShareConstraints(
                                    useiOSBroadcastExtension: true,
                                  ),
                                  enabledScreenShareBackgroundColor: Colors.deepPurple,
                                  disabledScreenShareIcon: Icons.screen_share,
                                  enabledScreenShareIconColor: Colors.white,
                                )
                              : const SizedBox.shrink(),
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
                          const Spacer(),
                          BadgedCallOption(
                            callControlOption: CallControlOption(
                              icon: const Icon(Icons.people),
                              onPressed: _channel != null ? () => _showParticipants(context) : null,
                            ),
                            badgeCount: callState.callParticipants.length,
                          ),
                          BadgedCallOption(
                            callControlOption: CallControlOption(
                              icon: const Icon(Icons.question_answer),
                              onPressed: _channel != null ? () => _showChat(context) : null,
                            ),
                            badgeCount: _channel?.state?.unreadCount ?? 0,
                          )
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

  // void _leaveCall() async {
  //   print("Initiating onLeaveCallTap...");
  //   await _cameraTrack?.stop();
  //   await _microphoneTrack?.stop();
  //   try {
  //     if (widget.call.state.value.status.isActive) {
  //       if (await _isTeacher) {
  //         print(">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>Navigating to Teacher layout...");
  //         await context
  //             .read<MeetingsCubit>()
  //             .endMeetFromTeacher(context, widget.call.id, widget.call)
  //             .then((value) async {
  //           print(">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>Leave from student...");
  //           await context.read<MeetingsCubit>().leaveMeetForStudent(context, widget.call.id, widget.call);
  //         });
  //       } else {
  //         print("Navigating to Student layout...");
  //         if (!mounted) return;
  //         await context.read<MeetingsCubit>().leaveMeetForStudent(context, widget.call.id, widget.call);
  //       }
  //     }
  //   } catch (e) {
  //     print("Error in role check or navigation: $e");
  //   }
  //
  //   try {
  //     if (widget.call.state.value.status.isActive) {
  //       await widget.call.reject(reason: CallRejectReason.cancel());
  //     }
  //   } catch (e) {
  //     print("Error rejecting the call: $e");
  //   }
  //
  //   try {
  //     await widget.call.end();
  //     await widget.call.leave();
  //   } catch (e) {
  //     print("Error ending or leaving the call: $e");
  //   }
  // }

  void _showChat(BuildContext context) {
    if (_channel == null || _channel!.state == null) {
      debugPrint("Chat channel is not initialized or state is null");
      return;
    }
    showModalBottomSheet<dynamic>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(16),
        ),
      ),
      builder: (_) {
        final size = MediaQuery.sizeOf(context);
        final viewInsets = MediaQuery.viewInsetsOf(context);

        return AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: size.height * 0.6 + viewInsets.bottom,
          padding: EdgeInsets.only(bottom: viewInsets.bottom),
          child: ChatBottomSheet(channel: _channel!),
        );
      },
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

  void _toggleMoreMenu(BuildContext context) => setState(() => _moreMenuVisible = !_moreMenuVisible);
}

/*
this function use it after fetch students (users) in admin as current user and send VOIP in web platform and incoming call for student
                if (kIsWeb) {
                  html.Notification.requestPermission().then((permission) async {
                    if (permission == 'granted') {
                      // Show notification
                      // await Future.delayed(const Duration(seconds: 5));
                      String title = "Said is ringing";
                      js.context.callMethod('showCallNotification', [title]);
                    } else {
                      print('Flutter: Notification permission denied');
                    }
                  });
                }
 */
