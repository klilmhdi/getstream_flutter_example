import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:getstream_flutter_example/core/utils/widgets.dart';
import 'package:getstream_flutter_example/features/presentation/manage/call/call_cubit.dart';
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
        outgoingCallBuilder: (context, call, callState) => StreamOutgoingCallContent(
          call: call,
          callState: callState,
        ),
        onAcceptCallTap: () => context.read<CallingsCubit>().acceptCall(context, widget.call.id, widget.call),
        onCancelCallTap: () => context.read<CallingsCubit>().rejectCall(context, widget.call.id, widget.call).then((_){
          showSuccessSnackBar("Call is canceled!", 3, context);
        }),
        onDeclineCallTap: () => context.read<CallingsCubit>().rejectCall(context, widget.call.id, widget.call).then((_){
          showSuccessSnackBar("Call is declined!", 3, context);
        }),
        onLeaveCallTap: () => context.read<CallingsCubit>().rejectCall(context, widget.call.id, widget.call).then((_){
          showSuccessSnackBar("Call is leaved!", 3, context);
        }),
      ),
    );
  }
}
