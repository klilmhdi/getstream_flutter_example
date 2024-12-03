import 'package:flutter_callkit_incoming/entities/call_kit_params.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:stream_video_flutter/stream_video_flutter.dart';
import 'package:stream_video_push_notification/stream_video_push_notification.dart';

class CallKitServices {
  // send call
  Future<void> sendCallToStudent(String callId, String studentName, String studentId) async {
    final params = CallKitParams(
      id: callId,
      nameCaller: studentName,
      appName: 'GetStream',
      type: 0,
      textAccept: 'Accept',
      textDecline: 'Decline',
      extra: <String, dynamic>{'userId': studentId},
      headers: <String, dynamic>{'apiKey': 'Abc@123!', 'platform': 'flutter'},
      android: const AndroidParams(
          isShowFullLockedScreen: true,
          ringtonePath: 'assets/ring.mp3',
          actionColor: "#640D5F",
          backgroundUrl:
              'https://static.wikia.nocookie.net/dragonball/images/b/ba/Goku_anime_profile.png/revision/latest?cb=20240723150655',
          textColor: '#000000'),
      ios: const IOSParams(
        iconName: 'CallKitLogo',
        handleType: '',
        supportsVideo: true,
        maximumCallGroups: 2,
        maximumCallsPerCallGroup: 1,
        audioSessionMode: 'default',
        audioSessionActive: true,
        audioSessionPreferredSampleRate: 44100.0,
        audioSessionPreferredIOBufferDuration: 0.005,
        supportsDTMF: true,
        supportsHolding: true,
        supportsGrouping: false,
        supportsUngrouping: false,
        ringtonePath: 'assets/ring.mp3',
      ),
    );

    // Show incoming call notification
    await FlutterCallkitIncoming.startCall(params);
  }

  // recieve call
  Future<void> recieveCallFromTeacher(String callId, String studentName, String studentId) async {
    final params = CallKitParams(
      id: callId,
      nameCaller: studentName,
      appName: 'GetStream',
      type: 0,
      textAccept: 'Accept',
      textDecline: 'Decline',
      missedCallNotification: const NotificationParams(
        showNotification: true,
        isShowCallback: true,
        subtitle: 'Missed call',
        callbackText: 'Call back',
      ),
      extra: <String, dynamic>{'userId': studentId},
      headers: <String, dynamic>{'apiKey': 'Abc@123!', 'platform': 'flutter'},
      android: const AndroidParams(
          isShowFullLockedScreen: true,
          isCustomNotification: true,
          ringtonePath: 'assets/ring.mp3',
          actionColor: "#640D5F",
          backgroundUrl: 'https://d26oc3sg82pgk3.cloudfront.net/files/media/edit/image/56073/article_full%401x.jpg',
          textColor: '#000000'),
      ios: const IOSParams(
        iconName: 'CallKitLogo',
        handleType: '',
        supportsVideo: true,
        maximumCallGroups: 2,
        maximumCallsPerCallGroup: 1,
        audioSessionMode: 'default',
        audioSessionActive: true,
        audioSessionPreferredSampleRate: 44100.0,
        audioSessionPreferredIOBufferDuration: 0.005,
        supportsDTMF: true,
        supportsHolding: true,
        supportsGrouping: false,
        supportsUngrouping: false,
        ringtonePath: 'assets/ring.mp3',
      ),
    );

    // Show incoming call notification
    await FlutterCallkitIncoming.showCallkitIncoming(params);
  }

//   listen to callKit
  Future<void> listenCall(String callId, String studentName, String studentId) async {
    try {} catch (e) {}
  }
}
