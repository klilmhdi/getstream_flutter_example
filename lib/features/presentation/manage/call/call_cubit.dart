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
import 'package:stream_video_flutter/stream_video_flutter.dart';

part 'call_state.dart';

class CallingsCubit extends Cubit<CallingsState> {
  CallingsCubit() : super(CallInitial());

  static CallingsCubit get(BuildContext context) => BlocProvider.of(context, listen: false);

  // StreamSubscription? callkitSubscription;
  final callType = StreamCallType.defaultType();

  /// Basic function to (create / make) a  call in general
  Call? call;

  Call _makeCall(callId) {
    return call = locator.get<StreamVideo>().makeCall(callType: callType, id: callId);
    // return call;
  }

  /// Teacher behaviors
  // 1- initial call
  Future<void> initiateCall(BuildContext context, teacherId, teacherName, {studentId, studentName}) async {
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
            FirebaseServices().firestore.collection("calls").doc(call.id).set(calling.toMap());
            emit(CallCreatedState(
                call: call,
                callState: CallState(
                    currentUserId: studentId, callCid: StreamCallCid.from(type: callType, id: call.id.toString()))));
            sendCallToStudent(
              context,
              studentId,
              studentName,
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

  // 2- create a call with ringtone
  Future<void> sendCallToStudent(context, String studentId, String studentName, Call call, CallState callState) async {
    emit(LoadCallToStudentState());

    try {
      final studentDoc = await FirebaseFirestore.instance.collection('users').doc(studentId).get();

      if (!studentDoc.exists) {
        print("Student does not exist in the database.");
        return;
      }

      // const OutgoingState.sending();
      // CallStatus.outgoing(acceptedByCallee: true);
      emit(SuccessSendCallToStudentState(
        call: call,
        callState: callState,
      ));

      print("Incoming call notification sent successfully.");
    } catch (e) {
      print("Error creating call: $e");
      emit(FailedSendCallToStudentState(error: '$e'));
    }
  }

  // 3- end call via set isActive to false
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
        await call.leave(reason: DisconnectReasonEnded());

        emit(CallEndedState());
        Navigator.pop(context);
      } else {
        emit(const CallErrorState("Call not found."));
      }
    } catch (e) {
      emit(CallErrorState("Failed to end call: $e"));
    }
  }

  /// Student behaviors
  // 1- listen incoming calls:
  // void listenForIncomingCalls(String receiverId, String callId, BuildContext context) {
  //   try {
  //     FirebaseFirestore.instance
  //         .collection('calls')
  //         .where('receiverID', isEqualTo: receiverId)
  //         .where('isRinging', isEqualTo: true)
  //         .snapshots()
  //         .listen((snapshot) async {
  //       if (snapshot.docs.isEmpty) {
  //         debugPrint("No incoming calls found for receiverID: $receiverId");
  //       }
  //       StreamVideo.instance.getCallRingingState(callType: callType, id: callId).then((value) {
  //         debugPrint(">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>${value.runtimeType.toString()}");
  //         for (var doc in snapshot.docs) {
  //           final callData = doc.data();
  //           print(callData);
  //           emit(IncomingCallState(
  //             call: _makeCall(callData['callId']),
  //             senderId: callData['callerId'],
  //             senderName: callData['callerName'],
  //             callState: CallState(currentUserId: callData['userId'], callCid: StreamCallCid(cid: callData['callId'])),
  //             callStatus: CallStatus.incoming(acceptedByMe: true),
  //           ));
  //         }
  //       }).catchError((onError, StackTrace stk) {
  //         debugPrint('*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>on catch error in general listen: $onError');
  //         debugPrint('*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>on catch error in general listen: $stk');
  //         emit(FailedReceiveIncomingCallState(errorMessage: onError));
  //       });
  //     });
  //   } catch (e, s) {
  //     debugPrint('*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>on catch in general listen: $e');
  //     debugPrint('*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>on catch in general listen: $s');
  //     emit(FailedReceiveIncomingCallState(errorMessage: "Error in general: ${e.toString()}"));
  //   }
  // }
  Future<void> listenForIncomingCalls(String receiverId, BuildContext context, String callId) async{
    emit(LoadingIncomingCallState());
    try {
      if (state is SuccessSendCallToStudentState) {
        await StreamVideo.instance.getCallRingingState(id: callId, callType: callType).then((value) async {
          debugPrint("*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>*<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< I'm here");
          await StreamVideo.instance.consumeIncomingCall(uuid: receiverId, cid: callId).then(
            (value) {
              debugPrint("*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>* I'm here");
              if (value is CallRingEvent || value is CoordinatorCallRingingEvent || value.isSuccess) {
                debugPrint("Incoming call done");
                emit(IncomingCallState(call: call!));
              } else if (state is FailedReceiveIncomingCallState) {
                debugPrint("Incoming call failed");
                debugPrint('*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>on catch error in general listen: ${state}');
                debugPrint('*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>on catch error in general listen: ${value.isFailure}');
                emit(const FailedReceiveIncomingCallState(errorMessage: "Failed"));
              }
            },
          );
        }).catchError((onError, StackTrace stk) {
          debugPrint("Error fetching call ringing state: $onError");
          debugPrint("Error fetching call ringing state: $stk");
        });
      }
    } catch (e, stk) {
      debugPrint("Error fetching call ringing state: $e");
      debugPrint("Error fetching call ringing state: $stk");
    }
  }

  // void listenForIncomingCalls(String receiverId, BuildContext context) {
  //   try {
  //     FirebaseFirestore.instance
  //         .collection('calls')
  //         .where('receiverID', isEqualTo: receiverId)
  //         .where('isRinging', isEqualTo: true)
  //         .snapshots()
  //         .listen((snapshot) async {
  //       debugPrint("?>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>Snapshot: ${snapshot.docs}");
  //       debugPrint("?>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>Snapshot: ${snapshot.metadata}");
  //       debugPrint("?>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>Snapshot: ${snapshot.runtimeType}");
  //
  //       // if (snapshot.docs.isEmpty) {
  //       //   debugPrint("No incoming calls found for receiverID: $receiverId");
  //       //   return;
  //       // }
  //
  //       for (var doc in snapshot.docs) {
  //         final callData = doc.data();
  //         final callId = callData['callId'];
  //         debugPrint("?>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>Snapshot docs${snapshot.docs}");
  //
  //         // if (callId == null || callId.isEmpty) {
  //         //   debugPrint("Invalid callId found in Firestore: $callId");
  //         //   continue;
  //         // }
  //
  //         debugPrint("????>>>>>>>>>>>>>>>>>>>>>>>Fetching call ringing state for callId: $callId");
  //
  //         debugPrint("Ringing state fetched successfully for callId: $callId");
  //
  //         emit(IncomingCallState(
  //           call: call!,
  //           // senderId: callData['callerId'],
  //           // senderName: callData['callerName'],
  //           callState: CallState(
  //             currentUserId: callData['receiverID'],
  //             callCid: StreamCallCid(cid: callId),
  //           ),
  //         ));
  //       }
  //     });
  //   } catch (e, s) {
  //     debugPrint("General exception in listenForIncomingCalls: $e");
  //     debugPrint("General exception in listenForIncomingCalls: $s");
  //     emit(FailedReceiveIncomingCallState(errorMessage: "Error: ${e.toString()}"));
  //   }
  // }

  // 2- accept the call
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

  // 3- reject call
  Future<void> rejectCall(context, String callId, Call call) async {
    try {
      await call.reject(reason: CallRejectReason.cancel()).then((value) async {
        print("?>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>Call Rejected");
        await FirebaseFirestore.instance.collection('calls').doc(callId).update({
          'isRinging': false,
        });
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const CallCancelledScreen()),
        );
        emit(CallRejectedState(callId: callId));
      });
    } catch (e, s) {
      print(">?>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>Error: ${e.toString()}");
      print(">?>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>StackError: ${s.toString()}");
      emit(CallErrorState("Failed to reject call: $e"));
    }
  }
}
