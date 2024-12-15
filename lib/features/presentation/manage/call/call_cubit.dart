import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:getstream_flutter_example/core/di/injector.dart';
import 'package:getstream_flutter_example/core/utils/consts/functions.dart';
import 'package:getstream_flutter_example/features/data/models/calling_model.dart';
import 'package:getstream_flutter_example/features/data/services/firebase_services.dart';
import 'package:getstream_flutter_example/features/presentation/view/meet/call_canceled_screen.dart';
import 'package:getstream_flutter_example/features/presentation/view/meet/call_screen.dart';
import 'package:stream_chat_flutter/stream_chat_flutter.dart' hide Event;
import 'package:stream_video_flutter/stream_video_flutter.dart';

import '../../view/meet/incoming_call.dart';

part 'call_state.dart';

class CallingsCubit extends Cubit<CallingsState> {
  CallingsCubit() : super(CallInitial());

  static CallingsCubit get(BuildContext context) => BlocProvider.of(context, listen: false);

  final callType = StreamCallType.defaultType();
  final streamVideo = locator.get<StreamVideo>();
  Call? call;

  /// Basic function to (create / make) a  call in general
  Call _makeCall(callId) {
    return call = locator.get<StreamVideo>().makeCall(callType: callType, id: callId);
    // return call;
  }

  // Initial call from teacher
  Future<void> initiateCall(BuildContext context, teacherId, teacherName, teacherImage,
      {studentId, studentName}) async {
    emit(CallLoadingState());
    if (teacherId.isEmpty || studentId.isEmpty) {
      debugPrint('Teacher or student ID is missing.');
      emit(const CallErrorState('Invalid member IDs.'));
      return;
    }
    try {
      final call = _makeCall(generateCallId(4));
      checkAndRequestPermissions(context).then((value) async {
        await call.getOrCreate(
          ringing: true,
          video: true,

          memberIds: [teacherId, studentId],
          // limits: const StreamLimitsSettings(
          //   maxDurationSeconds: 3600,
          // ),
        ).then((value) async {
          print("?>>>>>>>>>>>>>>>>>>>>>>>>>Student name: $studentName");
          print("?>>>>>>>>>>>>>>>>>>>>>>>>>Student name: $studentId");
          debugPrint("Call state after creation: ${call.state.value.status}");
          debugPrint("?>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>CallID: ${call.id}");
          debugPrint("Call session ID: ${call.state.value.sessionId}");
          if (value.isSuccess) {
            debugPrint(">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>Call successfully connected!");
            final calling = CallingModel(
                callID: call.id,
                callerID: teacherId,
                callerName: teacherName,
                callingID: studentId,
                callingName: studentName,
                isAccepted: false,
                isActiveCall: true,
                isRinging: true);
            print(
                ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>Callings: ${calling.toMap()}");
            FirebaseServices().firestore.collection("calls").doc(call.id).set(calling.toMap());
            emit(CallCreatedState(
                call: call,
                callState: CallState(
                    currentUserId: studentId, callCid: StreamCallCid.from(type: callType, id: call.id.toString()))));
            sendCallToStudent(
              context,
              studentId,
              studentName,
              teacherName,
              teacherId,
              teacherImage,
              call,
              CallState(currentUserId: studentId, callCid: StreamCallCid.from(id: call.id, type: callType)),
            );
          } else if (call.state.value.status.isIdle) {
            debugPrint(
                ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>Call Status: ${call.state.value.status}");
            emit(const CallErrorState("Call is IDLE"));
          } else {
            debugPrint(
                ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>else Call failed: ${call.state.value.status}");
            emit(const CallErrorState("Call is failed"));
          }
        }).catchError((onError, stackTrace) {
          debugPrint(
              '*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>on catch error Error joining or creating call: $onError');
          debugPrint(
              '*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>on catch error Error joining or creating call: $stackTrace');
          emit(const CallErrorState("Catch Error"));
        }).onError((e, stk) {
          debugPrint(
              '>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>on error Error joining or creating call: $e');
          debugPrint(
              ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>on error Error joining or creating call: ${stk.toString()}");
          emit(const CallErrorState("On Error"));
        });
      });
    } catch (e, s) {
      debugPrint(
          ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>on catch Call initiation error: ${e.toString()}");
      debugPrint(
          ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>on catch Stack trace: ${s.toString()}");
      emit(CallErrorState("Failed to initiate call: ${s.toString()}"));
    }
  }

  // Send a call with ringtone from teacher to student
  Future<void> sendCallToStudent(
    context,
    String studentId,
    String studentName,
    String teacherName,
    String teacherId,
    String teacherImage,
    Call call,
    CallState callState,
  ) async {
    emit(LoadCallToStudentState());

    try {
      const OutgoingState.sending();
      final studentDoc = await FirebaseFirestore.instance.collection('users').doc(studentId).get();

      
      if (!studentDoc.exists) {
        print("Student does not exist in the database.");
        return;
      }

      await streamVideo.state.setOutgoingCall(call);
      emit(SuccessSendCallToStudentState(
        call: call,
        callState: callState,
      ));
      listenForIncomingCalls(context, studentId,
          teacherName: teacherName, teacherId: teacherId, teacherImage: teacherImage);

      print("Incoming call notification sent successfully.");
    } catch (e) {
      print("Error creating call: $e");
      emit(FailedSendCallToStudentState(error: '$e'));
    }
  }

  // Listen to call coming from teacher
  // void listenForIncomingCalls(BuildContext context, String studentId, {String? teacherName, String? teacherId}) {
  //   emit(LoadingIncomingCallState());
  //   streamVideo.state.incomingCall.listen((incomingCall) async {
  //     await streamVideo.getCallRingingState(callType: callType, id: incomingCall!.callCid.id).then((value) {
  //       switch (value) {
  //         case CallRingingState.ringing:
  //           print(">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>Call state is ringing");
  //           // streamVideo.pushNotificationManager!.showIncomingCall(uuid: studentId, callCid: incomingCall.callCid.id);
  //           streamVideo.consumeIncomingCall(uuid: studentId, cid: incomingCall.callCid.id);
  //           streamVideo.handleVoipPushNotification({
  //             'created_by_display_name': teacherName,
  //             'call_cid': incomingCall.id,
  //             'video': false,
  //           }, handleMissedCall: true);
  //           // streamVideo.onCallKitEvent((_) =>
  //           //     Navigator.push(
  //           //       context,
  //           //       MaterialPageRoute(
  //           //         builder: (context) => CustomIncomingCallScreen(
  //           //           call: incomingCall,
  //           //         ),
  //           //       ),
  //           //     ));
  //           Navigator.push(
  //             context,
  //             MaterialPageRoute(
  //               builder: (context) => CustomIncomingCallScreen(
  //                 call: incomingCall,
  //               ),
  //             ),
  //           );
  //           emit(IncomingCallState(call: incomingCall, teacherName: teacherName!, teacherId: teacherId!));
  //           break;
  //
  //         case CallRingingState.ended:
  //           print(">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>Call state is ended");
  //           endCall(context, incomingCall.id, incomingCall);
  //           emit(CallEndedState());
  //           break;
  //         case CallRingingState.rejected:
  //           print(">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>Call state is rejected");
  //           rejectCallFromStudent(context, incomingCall.id, incomingCall);
  //           emit(CallRejectedFromStudentState(callId: incomingCall.id));
  //           break;
  //         case CallRingingState.accepted:
  //           print(">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>Call state is accepted");
  //           acceptCall(context, incomingCall.id, incomingCall);
  //           emit(CallAcceptedState(callId: incomingCall.id));
  //           break;
  //         default:
  //           emit(LoadingIncomingCallState());
  //       }
  //     });
  //     // streamVideo.consumeIncomingCall(uuid: studentId, cid: incomingCall!.callCid.id);
  //     //   await streamVideo.pushNotificationManager!.showIncomingCall(uuid: studentId, callCid: incomingCall.callCid.id);
  //     //   // await streamVideo.consumeIncomingCall(uuid: studentId, cid: incomingCall.callCid.id);
  //     //   await streamVideo.handleVoipPushNotification({
  //     //     'created_by_display_name': teacherName,
  //     //     'call_cid': incomingCall.id,
  //     //     'video': false,
  //     //   }, handleMissedCall: true);
  //   });
  // }

  /// in 96% this is successful function
  void listenForIncomingCalls(BuildContext context, String studentId,
      {String? teacherName, String? teacherId, String? teacherImage}) {
    streamVideo.state.incomingCall.listen((incomingCall) async {
      if (incomingCall != null) {
        await streamVideo.getCallRingingState(callType: callType, id: incomingCall.callCid.id).then((value) {
          if (value == CallRingingState.ringing) {
            streamVideo.pushNotificationManager!
                .showIncomingCall(uuid: studentId, callCid: incomingCall.callCid.toString());
            WidgetsBinding.instance.addPostFrameCallback((_) async {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CustomIncomingCallScreen(
                    call: incomingCall,
                    senderName: teacherName,
                    senderImageUrl: teacherImage,
                    // callState: CallState(
                    //   currentUserId: studentId,
                    //   callCid: StreamCallCid(cid: incomingCall.callCid.id),
                    // ),
                  ),
                ),
              );
            });
            emit(IncomingCallState(call: incomingCall, teacherId: teacherId!, teacherName: teacherName!));
          } else if (value == CallRingingState.ended) {
            endCall(context, incomingCall.id, incomingCall);
            emit(CallEndedState());
          } else if (value == CallRingingState.accepted) {
            acceptCall(context, incomingCall.id, incomingCall);
            emit(CallAcceptedState(callId: incomingCall.id));
          } else if (value == CallRingingState.rejected) {
            rejectCallFromStudent(context, incomingCall.id, incomingCall);
            emit(CallRejectedFromStudentState(callId: incomingCall.id));
          }
        });
      } else {
        emit(const CallErrorState("state is null"));
      }
    });
  }

  // Accept the call coming from teacher
  Future<void> acceptCall(context, String callId, Call call) async {
    try {
      await call.accept().then((value) async {
        print("?>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>Call Accepted");
        await FirebaseFirestore.instance.collection('calls').doc(callId).update({
          'isRinging': false,
          'isAccepted': true,
        });
        Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CallScreen(call: call),
            ));
        emit(CallAcceptedState(callId: callId));
      });
    } catch (e, s) {
      print(">?>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>Error: ${e.toString()}");
      print(">?>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>StackError: ${s.toString()}");
      emit(CallErrorState("Failed to accept call: $e"));
    }
  }

  // Reject or cancel the call coming from teacher
  Future<void> rejectCallFromTeacher(context, String callId, Call call) async {
    try {
      await call.end();
      await call.reject(reason: CallRejectReason.cancel()).then((value) async {
        print("?>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>Call Rejected");
        await FirebaseFirestore.instance.collection('calls').doc(callId).update({
          'isRinging': false,
        });
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const CallCancelledScreen()),
        );
        emit(CallRejectedFromTeacherState(callId: callId));
      });
    } catch (e, s) {
      print(">?>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>Error: ${e.toString()}");
      print(">?>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>StackError: ${s.toString()}");
      emit(CallErrorState("Failed to reject call: $e"));
    }
  }

  // Reject or cancel the call coming from student
  Future<void> rejectCallFromStudent(context, String callId, Call call) async {
    try {
      await call.end();
      await call.reject(reason: CallRejectReason.cancel()).then((value) async {
        print("?>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>Call Rejected");
        await FirebaseFirestore.instance.collection('calls').doc(callId).update({
          'isRinging': false,
        });
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const CallCancelledScreen()),
        );
        emit(CallRejectedFromStudentState(callId: callId));
      });
    } catch (e, s) {
      print(">?>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>Error: ${e.toString()}");
      print(">?>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>StackError: ${s.toString()}");
      emit(CallErrorState("Failed to reject call: $e"));
    }
  }

  // End call via set isActive to false
  Future<void> endCall(BuildContext context, String callId, Call call) async {
    try {
      // Query the call document by its 'callId' field
      final querySnapshot =
          await FirebaseServices().firestore.collection("calls").where("callId", isEqualTo: callId).limit(1).get();

      if (querySnapshot.docs.isNotEmpty) {
        final documentId = querySnapshot.docs.first.id;

        // Update the document: set 'isActive' to false and remove 'callId' field
        await FirebaseServices().firestore.collection("calls").doc(documentId).update({
          'isActive': false,
          'callId': FieldValue.delete(),
        });
        await call.end();
        await call.reject(reason: CallRejectReason.cancel());
        await call.leave(reason: DisconnectReason.ended());
        await streamVideo.pushNotificationManager?.endCall(callId);
        await streamVideo.pushNotificationManager?.endAllCalls();

        Navigator.pop(context);
        emit(CallEndedState());
      } else {
        emit(const CallErrorState("Call not found."));
      }
    } catch (e) {
      emit(CallErrorState("Failed to end call: $e"));
    }
  }

// void callKitEvents() async {
//   FlutterCallkitIncoming.onEvent.listen((event) async {
//     debugPrint("*********>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>Listen to event: ${event!.event.name.toString()}");
//     switch (event!.event) {
//       case Event.actionCallIncoming:
//         debugPrint("*********>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>Incoming");
//
//         break;
//
//       case Event.actionCallDecline:
//         debugPrint("*********>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>Call declined");
//         break;
//
//       case Event.actionCallTimeout:
//         debugPrint("*********>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>Missed call");
//         break;
//
//       case Event.actionCallAccept:
//         debugPrint("*********>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>Accept");
//         break;
//       default:
//         debugPrint("*********>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>Did not listen");
//
//         break;
//     }
//   });
// }
}
