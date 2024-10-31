import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:getstream_flutter_example/features/presentation/widgets/badged_call_option.dart';
import 'package:getstream_flutter_example/features/presentation/widgets/call_duration_title.dart';
import 'package:getstream_flutter_example/features/presentation/widgets/call_participants_list.dart';
import 'package:getstream_flutter_example/features/presentation/widgets/settings_menu.dart';
import 'package:getstream_flutter_example/features/presentation/widgets/share_call_card.dart';
import 'package:stream_chat_flutter/stream_chat_flutter.dart';
import 'package:stream_video_flutter/stream_video_flutter.dart' hide User;

import '../../../../core/di/injector.dart';
import '../../../../core/utils/consts/user_auth_controller.dart';
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

  void showChat(BuildContext context) {
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

  void showParticipants(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => CallParticipantsList(call: widget.call)));
  }

  void toggleMoreMenu(BuildContext context) {
    setState(() {
      _moreMenuVisible = !_moreMenuVisible;
    });
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
          onCancelCallTap: () async {
            await widget.call.reject(reason: CallRejectReason.cancel());
            await widget.call.leave();
          },
          callContentBuilder: (BuildContext context, Call call, CallState callState) {
            return StreamCallContent(
              call: call,
              // onLeaveCallTap: () async => await widget.call.leave(),
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
              callAppBarBuilder: (context, call, callState) => CallAppBar(
                  call: call,
                  leadingWidth: 180,
                  leading: Row(children: [
                    ToggleLayoutOption(
                      onLayoutModeChanged: (layout) {
                        setState(() {
                          _currentLayoutMode = layout;
                        });
                      },
                    ),
                    if (call.state.valueOrNull?.localParticipant != null)
                      FlipCameraOption(call: call, localParticipant: call.state.value.localParticipant!),
                    ShareCallCard(callId: call.id)
                  ]),
                  title: CallDurationTitle(call: call)),
              callControlsBuilder: (BuildContext context, Call call, CallState callState) {
                final localParticipant = callState.localParticipant!;
                return Container(
                  padding: const EdgeInsets.only(
                    top: 16,
                    left: 8,
                  ),
                  color: Colors.black,
                  child: SafeArea(
                    child: Row(children: [
                      CallControlOption(
                          icon: const Icon(Icons.more_vert),
                          backgroundColor: _moreMenuVisible ? Colors.deepPurple : Colors.deepOrange,
                          onPressed: () {
                            toggleMoreMenu(context);
                          }),
                      ToggleScreenShareOption(
                        call: call,
                        localParticipant: localParticipant,
                        screenShareConstraints: const ScreenShareConstraints(
                          useiOSBroadcastExtension: true,
                        ),
                        enabledScreenShareBackgroundColor: Colors.deepPurple,
                        disabledScreenShareIcon: Icons.screen_share,
                      ),
                      ToggleMicrophoneOption(
                        call: call,
                        localParticipant: localParticipant,
                        disabledMicrophoneBackgroundColor: Colors.red,
                      ),
                      ToggleCameraOption(
                        call: call,
                        localParticipant: localParticipant,
                        disabledCameraBackgroundColor: Colors.red,
                      ),
                      const Spacer(),
                      BadgedCallOption(
                        callControlOption: CallControlOption(
                          icon: const Icon(Icons.people),
                          onPressed: _channel != null //
                              ? () => showParticipants(context)
                              : null,
                        ),
                        badgeCount: callState.callParticipants.length,
                      ),
                      BadgedCallOption(
                        callControlOption: CallControlOption(
                          icon: const Icon(Icons.question_answer),
                          onPressed: _channel != null //
                              ? () => showChat(context)
                              : null,
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
}

class ChatBottomSheet extends StatelessWidget {
  const ChatBottomSheet({super.key, required this.channel});

  final Channel channel;

  @override
  Widget build(BuildContext context) {
    return StreamChannel(
      channel: channel,
      child: const Column(
        children: [Flexible(child: StreamMessageListView()), StreamMessageInput()],
      ),
    );
  }
}
