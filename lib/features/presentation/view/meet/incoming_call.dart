import 'dart:ui';

import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:getstream_flutter_example/core/utils/widgets.dart';
// import 'package:getstream_flutter_example/features/presentation/manage/call/call_cubit.dart';
// import 'package:getstream_flutter_example/features/presentation/view/meet/outgoing_call.dart';
import 'package:stream_video_flutter/stream_video_flutter.dart';

import 'call_screen.dart';

// class CustomIncomingCallScreen extends StatefulWidget {
//   // final Call call;
//   // final CallState callState = CallState;
//
//   // const CustomIncomingCallScreen({super.key, required this.call});
//   const CustomIncomingCallScreen({super.key});
//
//   @override
//   State<CustomIncomingCallScreen> createState() => _IncomingCallScreenState();
// }
//
// class _IncomingCallScreenState extends State<CustomIncomingCallScreen> {
//
//   @override
//   Widget build(BuildContext context) {
//     return BlocProvider(
//       create: (context) => CallingsCubit(),
//       child: BlocBuilder<CallingsCubit, CallingsState>(
//         builder: (context, state) => Scaffold(
//           body: StreamCallContainer(
//             call: _makeCall('hello'),
//             pictureInPictureConfiguration: const PictureInPictureConfiguration(enablePictureInPicture: true),
//             callContentBuilder: (context, call, callState) => CallScreen(
//               call: call,
//               connectOptions: call.connectOptions,
//             ),
//             // outgoingCallBuilder: (context, call, callState) => CustomOutgoingCallScreen(call: call, callState: callState),
//             incomingCallBuilder: (context, call, callState) {
//               return Stack(
//                 children: [
//                   StreamPictureInPictureUiKitView(call: call),
//                   StreamIncomingCallContent(
//                     call: call,
//                     callState: callState,
//                     onAcceptCallTap: () => context.read<CallingsCubit>().acceptCall(context, _makeCall('hello').id, _makeCall('hello')),
//                     onDeclineCallTap: () => _makeCall('hello').reject(reason: CallRejectReason.decline()).then((_) {
//                           showSuccessSnackBar("Call is declined!", 3, context);
//                         }),
//                   ),
//                 ],
//               );
//             },
//           ),
//         ),
//       ),
//     );
//   }
//   Call _makeCall(callId) {
//     return locator.get<StreamVideo>().makeCall(callType: StreamCallType.defaultType(), id: callId);
//     // return call;
//   }
// }

class CustomIncomingCallScreen extends StatelessWidget {
  final Call call;
  final String? senderName, senderImageUrl;

  const CustomIncomingCallScreen({required this.call, this.senderName, this.senderImageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("Incoming Call"),
            ElevatedButton(
              onPressed: () async {
                await call.accept();
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => CallScreen(call: call)),
                );
              },
              child: const Text("Accept"),
            ),
            ElevatedButton(
              onPressed: () async {
                await call.reject();
                Navigator.pop(context);
              },
              child: const Text("Decline"),
            ),
          ],
        ),
      ),
    );
  }
}
