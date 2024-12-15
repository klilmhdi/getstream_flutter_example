import 'package:flutter_callkit_incoming/entities/call_kit_params.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:getstream_flutter_example/core/utils/consts/assets.dart';
import 'package:stream_video_push_notification/stream_video_push_notification.dart';

class CallKitServices {
  // send call
  Future<void> sendCallToStudent(String callId, String studentName, String studentId) async {
    final params = CallKitParams(
      id: callId,
      nameCaller: studentName,
      appName: 'GetStream',
      handle: callId,
      type: 0,
      extra: <String, dynamic>{'userId': studentId},
      headers: <String, dynamic>{'apiKey': 'Abc@123!', 'platform': 'flutter'},
      android: const AndroidParams(
          isShowFullLockedScreen: true,
          // ringtonePath: 'assets/ring.mp3',
          actionColor: "#640D5F",
          backgroundUrl: AppConsts.studentNetworkImage,
          isCustomNotification: true,
          isShowCallID: true,
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

    await FlutterCallkitIncoming.startCall(params);
  }

  // receive a call from teacher
  Future<void> incomingCallFromTeacher(String callId, String teacherName, String teacherId) async {
    final params = CallKitParams(
      id: callId,
      nameCaller: teacherName,
      appName: 'GetStream',
      handle: callId,
      type: 0,
      textAccept: 'Accept',
      textDecline: 'Decline',
      extra: <String, dynamic>{'userId': teacherId},
      headers: <String, dynamic>{
        'apiKey': 'Abc@123!',
        'platform': 'flutter',
      },
      missedCallNotification: const NotificationParams(
        showNotification: true,
        isShowCallback: true,
        subtitle: 'Missed call',
        callbackText: 'Call back',
      ),
      android: const AndroidParams(
          // isCustomNotification: true,
          isShowFullLockedScreen: true,
          actionColor: "#640D5F",
          backgroundUrl: AppConsts.teacherNetworkImage,
          isShowCallID: true,
          textColor: '#000000'),
      ios: IOSParams(
        iconName: 'CallKitLogo',
        handleType: callId,
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
        // ringtonePath: 'assets/ring.mp3',
      ),
    );

    // Show incoming call notification
    await FlutterCallkitIncoming.showCallkitIncoming(params);
  }

  // listen to callKit
  listenCall() async => FlutterCallkitIncoming.activeCalls();

  Future<void> getDevicePushTokenVoIP() async {
    var devicePushTokenVoIP = await FlutterCallkitIncoming.getDevicePushTokenVoIP();
    print(devicePushTokenVoIP);
  }
}
