import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:getstream_flutter_example/features/data/services/firebase_services.dart';
import 'package:getstream_flutter_example/features/presentation/manage/call/call_cubit.dart';
import 'package:getstream_flutter_example/features/presentation/view/home/layout.dart';
import 'package:getstream_flutter_example/features/presentation/widgets/badged_call_option.dart';
import 'package:getstream_flutter_example/features/presentation/widgets/call_duration_title.dart';
import 'package:getstream_flutter_example/features/presentation/widgets/call_participants_list.dart';
import 'package:getstream_flutter_example/features/presentation/widgets/chat_sheet.dart';
import 'package:getstream_flutter_example/features/presentation/widgets/settings_menu.dart';
import 'package:getstream_flutter_example/features/presentation/widgets/share_call_card.dart';
import 'package:stream_chat_flutter/stream_chat_flutter.dart';
import 'package:stream_video_flutter/stream_video_flutter.dart' hide User;

import '../../../../core/di/injector.dart';
import '../../../../core/utils/controllers/user_auth_controller.dart';
import '../../../data/repo/app_preferences.dart';
import '../../../data/repo/user_chat_repository.dart';

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

class _MeetScreenState extends State<MeetScreen> {
  late final _userChatRepo = locator.get<UserChatRepository>();

  Channel? _channel;
  ParticipantLayoutMode _currentLayoutMode = ParticipantLayoutMode.grid;
  bool _moreMenuVisible = false;

  @override
  void initState() {
    super.initState();
    _connectChatChannel();
    // _checkUserRoleAndNavigate();
  }

  @override
  void dispose() {
    widget.call.leave();
    _userChatRepo.disconnectUser();
    super.dispose();
  }

  Future<void> _connectChatChannel() async {
    final userAuthController = locator.get<UserAuthController>();
    final appPreferences = locator.get<AppPreferences>();

    final currentUser = userAuthController.currentUser;
    if (currentUser == null) return;

    if (_userChatRepo.currentUser == null) {
      final chatUID = md5.convert(utf8.encode(currentUser.id));
      await _userChatRepo.connectUser(
        User(
          id: chatUID.toString(),
          name: currentUser.name,
          image: currentUser.image,
        ),
        appPreferences.environment,
      );
    }

    _channel = await _userChatRepo.createChannel(widget.call.id);

    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    // ignore: deprecated_member_use
    return WillPopScope(
      onWillPop: () async {
        return !Navigator.of(context).userGestureInProgress;
      },
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        body: StreamCallContainer(
          call: widget.call,
          callConnectOptions: widget.connectOptions,
          // onCancelCallTap: () async {
          //   print("I'm in cancel call tap in call appbar");
          //   await widget.call.end();
          //   await widget.call.leave();
          //   await widget.call.reject(reason: CallRejectReason.cancel()).then((_) async {
          //     final isTeacher = await FirebaseServices().checkIfCurrentUserIsTeacher();
          //     if (isTeacher) {
          //       print("Is teacher = true");
          //       if (!mounted) return;
          //       await context.read<CallingsCubit>().endCall(context, widget.call.id);
          //       print("Call successfully ended in Firestore");
          //       Navigator.pushAndRemoveUntil(
          //           context, MaterialPageRoute(builder: (context) => const Layout(type: 'Teacher')), (route) {
          //         return false;
          //       });
          //     } else {
          //       print("Is teacher = false");
          //       Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const Layout(type: 'Student')),
          //               (route) {
          //             return false;
          //           });
          //     }
          //     await widget.call.leave();
          //   });
          // },
          pictureInPictureConfiguration: PictureInPictureConfiguration(
              enablePictureInPicture: true,
              androidPiPConfiguration: AndroidPictureInPictureConfiguration(
                callPictureInPictureBuilder: (context, call, callState) {
                  final currentUser = locator.get<UserAuthController>().currentUser;
                  return Container(
                    color: Colors.black,
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            "In Call",
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            currentUser?.name ?? "Unknown Caller",
                            style: const TextStyle(color: Colors.white, fontSize: 14),
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: () {
                              // Example: add code to end the call
                              call.end();
                            },
                            child: const Text("End Call"),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              )),
          callContentBuilder: (BuildContext context, Call call, CallState callState) {
            return StreamCallContent(
              call: call,
              onLeaveCallTap: () async {
                print("Initiating onLeaveCallTap...");

                // Check the user role first and decide navigation
                try {
                  final isTeacher = await FirebaseServices().checkIfCurrentUserIsTeacher();
                  print("User role checked: Is teacher? $isTeacher");

                  if (isTeacher) {
                    print("Navigating to Teacher layout...");
                    if (!mounted) return;
                    await context.read<CallingsCubit>().endCall(context, widget.call.id);
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => const Layout(type: 'Teacher')),
                      (route) => false,
                    );
                  } else {
                    print("Navigating to Student layout...");
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => const Layout(type: 'Student')),
                      (route) => false,
                    );
                  }

                  // End and leave call after navigation decision
                  await widget.call.end();
                  await widget.call.leave();
                } catch (e) {
                  print("Error in onLeaveCallTap: $e");
                }
              },
              callState: callState,
              layoutMode: _currentLayoutMode,
              pictureInPictureConfiguration: const PictureInPictureConfiguration(enablePictureInPicture: true),
              callParticipantsBuilder: (context, call, callState) {
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
              // calling appbar
              callAppBarBuilder: (context, call, callState) => CallAppBar(
                  backgroundColor: Colors.black,
                  call: call,
                  showLeaveCallAction: true,
                  // onLeaveCallTap: () async {
                  //   print("I'm in cancel call tap in call appbar");
                  //
                  //   // Wrap endAllCalls method to prevent MissingPluginException
                  //   await widget.call.end();
                  //   await widget.call.leave();
                  //   try {
                  //     await widget.call.reject(reason: CallRejectReason.cancel()).then((_) async {
                  //       final isTeacher = await FirebaseServices().checkIfCurrentUserIsTeacher();
                  //       if (isTeacher) {
                  //         print("Is teacher = true");
                  //         if (!mounted) return;
                  //         await context.read<CallingsCubit>().endCall(context, widget.call.id);
                  //         Navigator.pushAndRemoveUntil(
                  //             context, MaterialPageRoute(builder: (context) => const Layout(type: 'Teacher')), (route) {
                  //           return false;
                  //         });
                  //       } else {
                  //         print("Is teacher = false");
                  //         await widget.call.leave();
                  //         Navigator.pushAndRemoveUntil(
                  //             context, MaterialPageRoute(builder: (context) => const Layout(type: 'Student')), (route) {
                  //           return false;
                  //         });
                  //       }
                  //     });
                  //   } catch (e, s) {
                  //     print("Error ending call or navigating: $e");
                  //     print("Error ending call or navigating: ${s.toString()}");
                  //   }
                  // },
                  onLeaveCallTap: () async {
                    print("Initiating onLeaveCallTap...");

                    // Step 1: Check user role and decide navigation
                    try {
                      final isTeacher = await FirebaseServices().checkIfCurrentUserIsTeacher();
                      print("User role checked: Is teacher? $isTeacher");

                      if (isTeacher) {
                        print("Navigating to Teacher layout...");
                        if (!mounted) return;
                        await context.read<CallingsCubit>().endCall(context, widget.call.id);
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (context) => const Layout(type: 'Teacher')),
                          (route) => false,
                        );
                      } else {
                        print("Navigating to Student layout...");
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (context) => const Layout(type: 'Student')),
                          (route) => false,
                        );
                      }
                    } catch (e) {
                      print("Error in role check or navigation: $e");
                    }

                    // Step 2: Reject call if it's active
                    try {
                      if (widget.call.state.value.status.isActive) {
                        await widget.call.reject(reason: CallRejectReason.cancel());
                      }
                    } catch (e) {
                      print("Error rejecting the call: $e");
                    }

                    // Step 3: End and leave the call safely
                    try {
                      await widget.call.end();
                      await widget.call.leave();
                    } catch (e) {
                      print("Error ending or leaving the call: $e");
                    }
                  },
                  leadingWidth: 180,
                  leading: Row(children: [
                    ToggleLayoutOption(onLayoutModeChanged: (layout) => setState(() => _currentLayoutMode = layout)),
                    if (call.state.valueOrNull?.localParticipant != null)
                      FlipCameraOption(call: call, localParticipant: call.state.value.localParticipant!),
                    ShareCallCard(callId: call.id)
                  ]),
                  title: CallDurationTitle(call: call)),
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
                      ToggleScreenShareOption(
                        call: call,
                        localParticipant: localParticipant,
                        screenShareConstraints: const ScreenShareConstraints(
                          useiOSBroadcastExtension: true,
                        ),
                        enabledScreenShareBackgroundColor: Colors.deepPurple,
                        disabledScreenShareIcon: Icons.screen_share,
                        enabledScreenShareIconColor: Colors.white,
                      ),
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
            );
          },
        ),
      ),
    );
  }

  void _showChat(BuildContext context) {
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

  Future<void> _checkUserRoleAndNavigate() async {
    final isTeacher = await FirebaseServices().checkIfCurrentUserIsTeacher();
    if (isTeacher) {
      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const Layout(type: 'Teacher')),
          (route) {
        return false;
      });
    } else {
      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const Layout(type: 'Student')),
          (route) {
        return false;
      });
    }
  }

  void _handleTeacherDialog(context) {}

  void _handleStudentDialog(context) {}
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
