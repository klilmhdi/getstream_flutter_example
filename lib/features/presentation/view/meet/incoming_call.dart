import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:getstream_flutter_example/core/utils/widgets.dart';
import 'package:getstream_flutter_example/features/presentation/manage/call/call_cubit.dart';
import 'package:stream_video_flutter/stream_video_flutter.dart';

import 'call_screen.dart';

class CustomIncomingCallScreen extends StatefulWidget {
  final Call call;
  final CallState callState;

  const CustomIncomingCallScreen({super.key, required this.call, required this.callState});

  @override
  State<CustomIncomingCallScreen> createState() => _IncomingCallScreenState();
}

class _IncomingCallScreenState extends State<CustomIncomingCallScreen> {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => CallingsCubit(),
      child: BlocBuilder<CallingsCubit, CallingsState>(
        builder: (context, state) => Scaffold(
          body: StreamCallContainer(
            call: widget.call,
            incomingCallBuilder: (context, call, callState) => StreamIncomingCallContent(
              call: call,
              callState: callState,
              onAcceptCallTap: () => context.read<CallingsCubit>().acceptCall(context, call.id, call),
              onDeclineCallTap: () => context.read<CallingsCubit>().rejectCall(context, widget.call.id, widget.call).then((_){
                showSuccessSnackBar("Call is declined!", 3, context);
              }),
            ),
          ),
        ),
      ),
    );
  }
}
