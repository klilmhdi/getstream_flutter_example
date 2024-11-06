// import 'dart:async';
//
// import 'package:flutter/cupertino.dart';
// import 'package:flutter/material.dart';
// import 'package:getstream_flutter_example/core/di/injector.dart';
// import 'package:getstream_flutter_example/core/utils/controllers/user_auth_controller.dart';
// import 'package:getstream_flutter_example/features/data/repo/app_preferences.dart';
// import 'package:stream_video_flutter/stream_video_flutter.dart';
//
// class CallConsts {
//
//   static const int appID = 0;
//
//   static const String appName = 'GetStream Example App';
//
//   static const String appSign = '';
//
//   static const String secretServer = '';
//
//   static StreamCallType callType = StreamCallType.defaultType();
//
//   static const String messageChannelType = 'videocall';
//
//   static StreamVideo streamVideo = locator.get<StreamVideo>();
//
//   static AppPreferences appPreferences = locator.get<AppPreferences>();
//
//   static UserAuthController userAuthController = locator.get<UserAuthController>();
//
//   Call? call;
//
//   Future<void> getOrCreateCall({List<String> memberIds = const [], required String callId}) async {
//
//     unawaited(const CircularProgressIndicator() as Future<void>?);
//     call = streamVideo.makeCall(callType: callType, id: callId);
//
//     bool isRinging = memberIds.isNotEmpty;
//
//     try {
//       await call!.getOrCreate(
//         memberIds: memberIds,
//         ringing: isRinging,
//         video: true,
//       );
//     } catch (e, stk) {
//       debugPrint('Error joining or creating call: $e');
//       debugPrint(stk.toString());
//     }
//   }
// }
