import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:getstream_flutter_example/core/di/injector.dart';
import 'package:getstream_flutter_example/core/utils/consts/functions.dart';
import 'package:getstream_flutter_example/features/presentation/view/meet/meet_screen.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:stream_chat_flutter/stream_chat_flutter.dart';
import 'package:stream_video_flutter/stream_video_flutter.dart';

part 'call_state.dart';

class CallingsCubit extends Cubit<CallingsState> {
  CallingsCubit() : super(CallInitial());

  static CallingsCubit get(BuildContext context) => BlocProvider.of(context, listen: false);

  final _streamVideo = locator.get<StreamVideo>();
  final String _callId = generateCallId(10);

  Future<void> initiateCall(BuildContext context, List<String> members) async {
    emit(CallLoadingState());
    final call = _streamVideo.makeCall(callType: StreamCallType.defaultType(), id: _callId);
    try {
      await call.getOrCreate(ringing: false, video: true).then((value) {
        debugPrint("Call state after creation: ${call.state.value.status}");
        debugPrint("Call session ID: ${call.state.value.sessionId}");
        if (value.isSuccess) {
          debugPrint("Call successfully connected!");
          emit(CallCreatedState(call: call));
        } else if (call.state.value.status.isIdle) {
          debugPrint("Call Status: ${call.state.value.status}");
          emit(const CallErrorState("Call is IDLE"));
        } else {
          debugPrint("Call failed: ${call.state.value.status}");
          emit(const CallErrorState("Call is failed"));
        }
      }).catchError((onError) {
        debugPrint('Error joining or creating call: $onError');
        emit(const CallErrorState("Catch Error"));
      }).onError((e, stk) {
        debugPrint('Error joining or creating call: $e');
        debugPrint(stk.toString());
        emit(const CallErrorState("On Error"));
      });
    } catch (e, s) {
      debugPrint("Call initiation error: ${e.toString()}");
      debugPrint("Stack trace: ${s.toString()}");
      emit(CallErrorState("Failed to initiate call: ${s.toString()}"));
    }
  }

  Future<void> joinMeet(BuildContext context) async {
    emit(CallLoadingState());

    try {
      final streamVideo = locator.get<StreamVideo>();
      final call = streamVideo.makeCall(callType: StreamCallType.defaultType(), id: _callId);

      await _checkAndRequestPermissions(context).then((value) async {
        await call.join().then((_) {
          emit(CallJoinedState(call: call));
          Navigator.push(context, MaterialPageRoute(builder: (context) => MeetScreen(call: call)));
        });
      });
    } catch (e, s) {
      debugPrint("Failed to join call: ${e.toString()}");
      debugPrint("Stack trace: ${s.toString()}");
      emit(CallErrorState(e.toString()));
    }
  }

  Future<void> _retryIfSessionIdMissing(Call call,
      {int maxRetries = 3, Duration delay = const Duration(seconds: 2)}) async {
    int retries = 0;
    while (call.state.value.sessionId.isEmpty && retries < maxRetries) {
      debugPrint("Session ID is missing, retrying (${retries + 1}/$maxRetries)...");

      // Wait before retrying
      await Future.delayed(delay);
      retries++;
    }
  }

  Future<void> _checkAndRequestPermissions(BuildContext context) async {
    final cameraStatus = await Permission.camera.request();
    final micStatus = await Permission.microphone.request();
    final notifStatus = await Permission.notification.request();

    if (cameraStatus.isDenied || micStatus.isDenied || notifStatus.isDenied) {
      _showPermissionDialog(context, "Permissions required");
    }
  }

  void _showPermissionDialog(BuildContext context, String permission) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("$permission Permission Required"),
          content: Text("Please allow access to $permission for the call to proceed."),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            TextButton(onPressed: () => openAppSettings(), child: const Text('Go to Settings')),
          ],
        );
      },
    );
  }
}

// import 'package:bloc/bloc.dart';
// import 'package:equatable/equatable.dart';
// import 'package:flutter/cupertino.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:getstream_flutter_example/core/di/injector.dart';
// import 'package:getstream_flutter_example/core/utils/consts/functions.dart';
// import 'package:getstream_flutter_example/features/presentation/view/meet/meet_screen.dart';
// import 'package:permission_handler/permission_handler.dart';
// import 'package:stream_chat_flutter/stream_chat_flutter.dart';
// import 'package:stream_video_flutter/stream_video_flutter.dart';
//
// part 'call_state.dart';
//
// class CallingsCubit extends Cubit<CallingsState> {
//   CallingsCubit() : super(CallInitial());
//
//   static CallingsCubit get(context) => BlocProvider.of(context, listen: false);
//
//   // final FirebaseServices firebaseServices = FirebaseServices();
//   // await firebaseServices.firestore.collection('calls').doc(callId).set({
//   //   'callerId': teacherId,
//   //   'callingId': studentId,
//   //   'status': 'pending', // 'pending', 'accepted', 'rejected'
//   //   'createdAt': FieldValue.serverTimestamp(),
//   // }).then((onValue) async {
//   // });
//
//   String callId = generateCallId(10);
//
//   final _streamVideo = locator.get<StreamVideo>();
//   final _callId = generateCallId(10);
//
//   // Future<void> initiateCall(BuildContext context, String teacherId, {String? studentId}) async {
//   //   final call = _streamVideo.makeCall(callType: StreamCallType.defaultType(), id: _callId);
//   //   emit(CallLoadingState());
//   //   try {
//   //     await call.getOrCreate(ringing: false, video: true, memberIds: [teacherId]);
//   //   } catch (e, s) {
//   //     debugPrint("Failed Call initial error: ${e.toString()}");
//   //     debugPrint("Stack Trace: ${s.toString()}");
//   //     emit(CallErrorState(e.toString()));
//   //   }
//   //   final sessionId = call.state.value.sessionId;
//   //   debugPrint("????>>>>>>>>>>>>>>>sessionId: $sessionId");
//   //   if (sessionId.isEmpty) {
//   //     print("Session ID is missing, unable to proceed.");
//   //     emit(const CallErrorState("Missing Session ID"));
//   //     return;
//   //   }
//   //   if (call.state.value.status.isConnected) {
//   //     print("Call successfully connected!");
//   //     emit(CallCreatedState(call: call));
//   //   } else {
//   //     print("Call connection failed. Status: ${call.state.value.status}");
//   //     emit(const CallErrorState("Call failed to connect"));
//   //   }
//   // }
//   Future<void> initiateCall(BuildContext context, String teacherId, {String? studentId}) async {
//     emit(CallLoadingState());
//
//     try {
//       final call = _streamVideo.makeCall(callType: StreamCallType.defaultType(), id: _callId);
//       debugPrint("Call state after creation: ${call.state.value.status}");
//       debugPrint("Call session ID: ${call.state.value.sessionId}");
//
//       // Ensure that teacherId is not null or empty
//       if (teacherId.isEmpty) {
//         emit(const CallErrorState("Teacher ID is missing"));
//         return;
//       }
//
//       await call.getOrCreate(ringing: false, video: true, memberIds: [teacherId]);
//
//       // Check for session ID
//       final sessionId = call.state.value.sessionId;
//       debugPrint("Session ID: $sessionId");
//       if (sessionId.isEmpty) {
//         print("Session ID is missing, unable to proceed.");
//         emit(const CallErrorState("Missing Session ID"));
//         return;
//       }
//
//       // Check call connection status
//       if (call.state.value.status.isConnected) {
//         print("Call successfully connected!");
//         emit(CallCreatedState(call: call));
//       } else {
//         print("Call connection failed. Status: ${call.state.value.status}");
//         emit(const CallErrorState("Call failed to connect"));
//       }
//     } catch (e, s) {
//       debugPrint("Call initiation error: ${e.toString()}");
//       emit(CallErrorState("Failed to initiate call: ${e.toString()}"));
//     }
//   }
//
//
//   Future<void> joinMeet(BuildContext context) async {
//     emit(CallLoadingState());
//
//     try {
//       final streamVideo = locator.get<StreamVideo>();
//       final call = streamVideo.makeCall(callType: StreamCallType.defaultType(), id: callId);
//
//       // Request permissions and then attempt to join the call
//       await _checkAndRequestPermissions(context).then((value) async {
//         await call.join().then((_) {
//           emit(CallJoinedState(call: call));
//           Navigator.push(context, MaterialPageRoute(builder: (context) => MeetScreen(call: call)));
//         });
//       });
//     } catch (e, s) {
//       print(">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>Failed Call initial error: ${e.toString()}");
//       print(">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>Stack Trace: ${s.toString()}");
//       emit(CallErrorState(e.toString()));
//     }
//   }
//
//   /// connect call when the call state is IDLE
//   // Future<void> _connectCall() async {
//   //   late final streamVideo = locator.get<StreamVideo>();
//   //   await streamVideo.connect(includeUserDetails: true);
//   // }
//
//   /// Check and request permissions
//   Future<void> _checkAndRequestPermissions(BuildContext context) async {
//     final cameraStatus = await Permission.camera.request();
//     final micStatus = await Permission.microphone.request();
//     final notifStatus = await Permission.notification.request();
//
//     if (cameraStatus.isDenied) {
//       _showPermissionDialog(context, "Camera");
//     }
//     if (micStatus.isDenied) {
//       _showPermissionDialog(context, "Microphone");
//     }
//     if (notifStatus.isDenied) {
//       _showPermissionDialog(context, "Notification");
//     }
//   }
//
//   /// Show a dialog to request permissions
//   void _showPermissionDialog(BuildContext context, String permission) {
//     showDialog(
//       context: context,
//       builder: (context) {
//         return AlertDialog(
//           title: Text("$permission Permission Required"),
//           content: Text("Please allow access to $permission for the call to proceed."),
//           actions: [
//             TextButton(
//               onPressed: () => Navigator.pop(context),
//               child: const Text('Cancel'),
//             ),
//             TextButton(
//               onPressed: () => openAppSettings(),
//               child: const Text('Go to Settings'),
//             ),
//           ],
//         );
//       },
//     );
//   }
// }
