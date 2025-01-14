import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:getstream_flutter_example/core/di/injector.dart';
import 'package:getstream_flutter_example/core/utils/controllers/user_auth_controller.dart';
import 'package:getstream_flutter_example/features/data/repo/app_preferences.dart';
import 'package:getstream_flutter_example/features/presentation/manage/live_stream/live_stream_cubit.dart';
import 'package:getstream_flutter_example/features/presentation/widgets/badged_call_option.dart';
import 'package:getstream_flutter_example/features/presentation/widgets/call_participants_list.dart';
import 'package:stream_chat_flutter/stream_chat_flutter.dart';
import 'package:stream_video_flutter/stream_video_flutter.dart' hide User;

import '../../../../data/repo/user_chat_repository.dart';
import '../../../widgets/call_duration_title.dart';
import '../../home/layout.dart';

class LiveStreamScreen extends StatefulWidget {
  const LiveStreamScreen({
    super.key,
    required this.livestreamCall,
  });

  final Call livestreamCall;

  @override
  State<LiveStreamScreen> createState() => _LiveStreamScreenState();
}

class _LiveStreamScreenState extends State<LiveStreamScreen> with WidgetsBindingObserver {
  final userAuthController = locator.get<UserAuthController>();
  late final _userChatRepo = locator.get<UserChatRepository>();
  Channel? _channel;

  @override
  void initState() {
    _connectChatChannel();
    WidgetsBinding.instance.addObserver(this);
    super.initState();
  }

  @override
  void dispose() {
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

      _channel = await _userChatRepo.createChannel(widget.livestreamCall.id).catchError((error) {
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
    return SafeArea(
      child: BlocProvider(
        create: (context) => LiveStreamCubit(),
        child: BlocBuilder<LiveStreamCubit, LiveStreamState>(builder: (context, state) {
          return StreamBuilder(
            stream: widget.livestreamCall.state.valueStream,
            initialData: widget.livestreamCall.state.value,
            builder: (context, snapshot) {
              final callState = snapshot.data!;
              final participant = callState.callParticipants.isNotEmpty ? callState.callParticipants.first : null;
              final localParticipant = callState.localParticipant!;
              if (snapshot.hasData && callState.status.isDisconnected) {
                // const Center(child: Text('Stream not live')),
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  print("><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><");
                  Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                              Layout(type: userAuthController.currentUser?.role == 'admin' ? "Teacher" : 'Student')),
                      (route) => false);
                });
              }
              return Scaffold(
                body: Stack(
                  children: [
                    if (snapshot.hasData && participant != null)
                      StreamVideoRenderer(
                        call: widget.livestreamCall,
                        videoTrackType: SfuTrackType.video,
                        participant: participant,
                      ),
                    if (!snapshot.hasData) const Center(child: CircularProgressIndicator()),
                    Positioned(
                      top: 12.0,
                      left: 12.0,
                      // child: ElevatedButton(
                      //   onPressed: () => _channel != null ? () => _showParticipants(context) : null,
                      //   child: Positioned(
                      //     top: 12.0,
                      //     left: 12.0,
                      //     child: Center(
                      //       child: Padding(
                      //         padding: const EdgeInsets.all(8.0),
                      //         child: Container(
                      //           decoration: const BoxDecoration(
                      //             color: Colors.deepPurple,
                      //           ),
                      //           child: Text(
                      //             'Viewers: ${callState.callParticipants.length}',
                      //             style: const TextStyle(
                      //               fontSize: 14,
                      //               color: Colors.white,
                      //               fontWeight: FontWeight.bold,
                      //             ),
                      //           ),
                      //         ),
                      //       ),
                      //     ),
                      //   ),
                      // ),
                      child: BadgedCallOption(
                        callControlOption: CallControlOption(
                          icon: const Icon(Icons.groups),
                          onPressed: _channel != null ? () => _showParticipants(context) : null,
                        ),
                        badgeCount: callState.callParticipants.length,
                      ),
                    ),
                    Positioned(
                      top: 20,
                      right: 165,
                      left: 165,
                      child: LivestreamTimer(
                        startedAt: callState.liveStartedAt ?? callState.createdAt,
                      ),
                    ),
                    Positioned(
                        top: 12.0,
                        right: 12.0,
                        child: LeaveCallOption(
                          call: widget.livestreamCall,
                          icon: Icons.call_end,
                          onLeaveCallTap: () =>
                              context.read<LiveStreamCubit>().endLiveStream(widget.livestreamCall, context),
                        )),
                    Positioned(
                      bottom: 20,
                      right: 130,
                      left: 130,
                      child: Center(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ToggleMicrophoneOption(
                              call: widget.livestreamCall,
                              localParticipant: localParticipant,
                              disabledMicrophoneBackgroundColor: Colors.red,
                              disabledMicrophoneIconColor: Colors.white,
                            ),
                            // ToggleCameraOption(
                            //   call: widget.livestreamCall,
                            //   localParticipant: localParticipant,
                            //   disabledCameraBackgroundColor: Colors.red,
                            //   disabledCameraIconColor: Colors.white,
                            // ),
                            FlipCameraOption(
                                call: widget.livestreamCall, localParticipant: callState.localParticipant!),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        }),
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
              CallParticipantsList(call: widget.livestreamCall, scrollController: scrollController)));
}
