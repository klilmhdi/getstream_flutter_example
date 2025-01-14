import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:getstream_flutter_example/core/di/injector.dart';
import 'package:getstream_flutter_example/core/utils/controllers/user_auth_controller.dart';
import 'package:getstream_flutter_example/core/utils/widgets.dart';
import 'package:getstream_flutter_example/features/data/repo/user_chat_repository.dart';
import 'package:getstream_flutter_example/features/presentation/manage/live_stream/live_stream_cubit.dart';
import 'package:getstream_flutter_example/features/presentation/view/home/layout.dart';
import 'package:stream_chat_flutter/stream_chat_flutter.dart';
import 'package:stream_video_flutter/stream_video_flutter.dart' hide User;

import '../../../../data/repo/app_preferences.dart';
import '../../../widgets/call_participants_list.dart';

class WatchLivestreamScreen extends StatefulWidget {
  const WatchLivestreamScreen({
    super.key,
    required this.livestreamCall,
  });

  final Call livestreamCall;

  @override
  State<WatchLivestreamScreen> createState() => _WatchLivestreamScreenState();
}

class _WatchLivestreamScreenState extends State<WatchLivestreamScreen> with WidgetsBindingObserver {
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
    if (widget.livestreamCall == null) {
      return const Scaffold(body: Center(child: Text('Initialising...')));
    }

    return SafeArea(
      child: BlocProvider(
        create: (context) => LiveStreamCubit(),
        child: BlocBuilder<LiveStreamCubit, LiveStreamState>(
          builder: (context, state) {
            return StreamBuilder(
                stream: widget.livestreamCall.state.valueStream,
                initialData: widget.livestreamCall.state.value,
                builder: (context, snapshot) {
                  final callState = snapshot.data!;
                  final participant = callState.callParticipants.isNotEmpty ? callState.callParticipants.first : null;
                  if (snapshot.hasData && callState.status.isDisconnected) {
                    // const Center(child: Text('Stream not live')),
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      print("><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><");
                      Navigator.pushAndRemoveUntil(context,
                          MaterialPageRoute(builder: (context) => const Layout(type: 'Student')), (route) => false);
                    });
                  }

                  return Scaffold(
                    body: Stack(
                      children: [
                        if (participant != null) LivestreamPlayer(call: widget.livestreamCall),
                        // Positioned(
                        //   top: 12.0,
                        //   left: 12.0,
                        //   child: BadgedCallOption(
                        //     callControlOption: CallControlOption(
                        //       icon: const Icon(Icons.groups),
                        //       onPressed: _channel != null ? () => _showParticipants(context) : null,
                        //     ),
                        //     badgeCount: callState.callParticipants.length,
                        //   ),
                        // ),
                        Positioned(
                            top: 12.0,
                            right: 12.0,
                            child: LeaveCallOption(
                              call: widget.livestreamCall,
                              icon: Icons.logout,
                              onLeaveCallTap: () =>
                                  context.read<LiveStreamCubit>().leaveLiveStream(widget.livestreamCall, context),
                            )),
                      ],
                    ),
                  );
                });
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
              CallParticipantsList(call: widget.livestreamCall, scrollController: scrollController)));
}
