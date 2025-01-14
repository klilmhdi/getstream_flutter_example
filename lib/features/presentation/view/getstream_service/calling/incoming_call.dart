import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:getstream_flutter_example/core/utils/consts/assets.dart';
import 'package:getstream_flutter_example/features/presentation/manage/call/call_cubit.dart';
import 'package:stream_video_flutter/stream_video_flutter.dart';

class CustomIncomingCallScreen extends StatelessWidget {
  final Call call;
  final String senderId, senderName;

  const CustomIncomingCallScreen(
    this.call, {
    super.key,
    required this.senderId,
    required this.senderName,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => CallingsCubit(),
      child: BlocBuilder<CallingsCubit, CallingsState>(
        builder: (context, state) => StreamIncomingCallContent(
            call: call,
            participantsAvatarBuilder: (context, call, callState, participants) => CircleAvatar(
                  radius: 140,
                  backgroundImage: const NetworkImage(AppConsts.teacherNetworkImage),
                  onBackgroundImageError: (error, stackTrace) =>
                      const Icon(Icons.person, size: 80, color: Colors.white),
                  backgroundColor: Colors.transparent,
                ),
            onAcceptCallTap: () => context.read<CallingsCubit>().acceptCall(context, call.id, call),
            onDeclineCallTap: () => context.read<CallingsCubit>().rejectCallFromStudent(context, call.id, call),
            participantsDisplayNameBuilder: (context, call, callState, participants) => Text(participants.firstOrNull?.name ?? "Empty Name"),
          callState: CallState(
            currentUserId: senderId,
            callCid: call.callCid
          ),
        ),
      ),
    );
  }
}
