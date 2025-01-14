import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:getstream_flutter_example/core/utils/widgets.dart';
import 'package:getstream_flutter_example/features/presentation/manage/call/call_cubit.dart';
import 'package:getstream_flutter_example/features/presentation/view/getstream_service/calling/call_screen.dart';
import 'package:stream_video_flutter/stream_video_flutter.dart';

class CustomOutgoingCallScreen extends StatefulWidget {
  const CustomOutgoingCallScreen({required this.call, required this.callState});

  final Call call;
  final CallState callState;

  @override
  State<CustomOutgoingCallScreen> createState() => _CustomOutgoingCallScreenState();
}

class _CustomOutgoingCallScreenState extends State<CustomOutgoingCallScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamCallContainer(
        call: widget.call,
        pictureInPictureConfiguration: const PictureInPictureConfiguration(enablePictureInPicture: true),
        callContentBuilder: (context, call, callState) => CallScreen(
          call: call,
          connectOptions: call.connectOptions,
        ),
        // incomingCallBuilder: (context, call, callState) => CustomIncomingCallScreen(call: call),
        outgoingCallBuilder: (context, call, callState) => Stack(
          children: [
            StreamPictureInPictureUiKitView(call: widget.call),
            StreamOutgoingCallContent(
              call: call,
              callState: callState,
              singleParticipantTextStyle: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
              callingLabelTextStyle: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w300,
              ),
            ),
          ],
        ),
        onAcceptCallTap: () => context.read<CallingsCubit>().acceptCall(context, widget.call.id, widget.call),
        onDeclineCallTap: () => context.read<CallingsCubit>().rejectCallFromTeacher(context, widget.call.id, widget.call),
      ),
    );
  }
}
