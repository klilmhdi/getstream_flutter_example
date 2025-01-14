import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:getstream_flutter_example/core/app/app_consumers.dart';
import 'package:getstream_flutter_example/core/di/injector.dart';
import 'package:getstream_flutter_example/core/utils/consts/functions.dart';
import 'package:getstream_flutter_example/core/utils/controllers/user_auth_controller.dart';
import 'package:getstream_flutter_example/core/utils/widgets.dart';
import 'package:getstream_flutter_example/features/data/models/calling_model.dart';
import 'package:getstream_flutter_example/features/data/services/firebase_services.dart';
import 'package:getstream_flutter_example/features/presentation/view/getstream_service/calling/outgoing_call.dart';
import 'package:getstream_flutter_example/features/presentation/view/home/layout.dart';
import 'package:stream_chat_flutter/stream_chat_flutter.dart' hide Event;
import 'package:stream_video_flutter/stream_video_flutter.dart';

part 'call_state.dart';

class CallingsCubit extends Cubit<CallingsState> {
  CallingsCubit() : super(CallInitial());

  static CallingsCubit get(BuildContext context) => BlocProvider.of(context, listen: false);

  final callType = StreamCallType.defaultType();
  final streamVideo = locator.get<StreamVideo>();
  final FirebaseServices firebaseServices = FirebaseServices();
  Call? call;
  // RtcLocalAudioTrack? _microphoneTrack;
  // RtcLocalCameraTrack? _cameraTrack;
  // Timer? _durationTimer;

  /// Basic function to (create / make) a  call in general
  Call _makeCall(String callId) => call = locator.get<StreamVideo>().makeCall(callType: callType, id: callId);

  // Initial call from teacher
  Future<void> initiateCall(
    BuildContext context,
    String teacherId,
    String teacherName,
    String teacherImage, {
    required String studentId,
    required String studentName,
  }) async {
    if (!isClosed) emit(CallLoadingState());
    if (teacherId.isEmpty || studentId.isEmpty) {
      debugPrint('Teacher or student ID is missing.');
      if (!isClosed) emit(const CallErrorState('Invalid member IDs.'));
      return;
    }

    try {
      final newCallId = generateCallId(4);
      final call = _makeCall(newCallId);
      checkAndRequestPermissions(context).then((value) async {
        await call
            .getOrCreate(
          ringing: true,
          video: true,
          memberIds: [teacherId, studentId],
          limits: const StreamLimitsSettings(maxParticipants: 2, maxDurationSeconds: 3600),
          custom: {'senderName': teacherName, 'receiverName': studentName},
          // backstage: const StreamBackstageSettings(enabled: true)
        )
            .then((value) async {
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
              isRinging: true,
              startAt: DateTime.now(),
            );
            print(
                ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>Callings: ${calling.toMap()}");
            firebaseServices.firestore.collection("calls").doc(call.id).set(calling.toMap());
            if (!isClosed) {
              emit(CallCreatedState(
                  call: call,
                  callState: CallState(
                      currentUserId: studentId, callCid: StreamCallCid.from(type: callType, id: call.id.toString()))));
            }
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
            if (!isClosed) {
              debugPrint(
                  ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>Call Status: ${call.state.value.status}");
              emit(const CallErrorState("Call is IDLE"));
            } else {
              debugPrint(
                  ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>else Call failed: ${call.state.value.status}");
              emit(const CallErrorState("Call is failed"));
            }
          }
        }).catchError((onError, stackTrace) {
          if (!isClosed) {
            debugPrint(
                '*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>on catch error Error joining or creating call: $onError');
            debugPrint(
                '*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>on catch error Error joining or creating call: $stackTrace');
            emit(const CallErrorState("Catch Error"));
          }
        }).onError((e, stk) {
          if (!isClosed) {
            debugPrint(
                '>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>on error Error joining or creating call: $e');
            debugPrint(
                ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>on error Error joining or creating call: ${stk.toString()}");
            emit(const CallErrorState("On Error"));
          }
        });
      });
    } catch (e, s) {
      if (!isClosed) {
        debugPrint(
            ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>on catch Call initiation error: ${e.toString()}");
        debugPrint(
            ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>on catch Stack trace: ${s.toString()}");
        emit(CallErrorState("Failed to initiate call: ${s.toString()}"));
      }
    }
  }

  // Send a call with ringtone from teacher to student
  Future<void> sendCallToStudent(
    BuildContext context,
    String studentId,
    String studentName,
    String teacherName,
    String teacherId,
    String teacherImage,
    Call call,
    CallState callState,
  ) async {
    if (!isClosed) emit(LoadCallToStudentState());

    try {
      const OutgoingState.sending();
      final studentDoc = await FirebaseFirestore.instance.collection('users').doc(studentId).get();

      if (!studentDoc.exists) {
        print("Student does not exist in the database.");
        return;
      }

      print("?>>>>>>>>>>>>>>>?>>>>>>> teacher name: $teacherName");
      print("?>>>>>>>>>>>>>>>?>>>>>>> teacher id: $teacherId");
      print("?>>>>>>>>>>>>>>>?>>>>>>> teacher image: $teacherImage");
      print("?>>>>>>>>>>>>>>>?>>>>>>> student name: $studentName");
      print("?>>>>>>>>>>>>>>>?>>>>>>> student image: $teacherImage");

      await streamVideo.state.setOutgoingCall(call);

      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CustomOutgoingCallScreen(
              call: call,
              callState: callState,
            ),
          ),
        );
      });

      if (!isClosed) {
        emit(SuccessSendCallToStudentState(
          call: call,
          callState: callState,
        ));
      }
      listenForIncomingCalls(context, studentId,
          teacherName: teacherName, teacherId: teacherId, teacherImage: teacherImage);

      print("Incoming call notification sent successfully.");
    } catch (e) {
      if (!isClosed) {
        print("Error creating call: $e");
        emit(FailedSendCallToStudentState(error: '$e'));
      }
    }
  }

  // listen to incoming calls from teacher
  void listenForIncomingCalls(
    BuildContext context,
    String studentId, {
    required String teacherName,
    required String teacherId,
    required String teacherImage,
  }) async {
    print("?>>>>>>>>>>>>>>>?>>>>>>> Incoming call");

    print("?>>>>>>>>>>>>>>>?>>>>>>>?>>>>>>> teacher name: $teacherName");
    print("?>>>>>>>>>>>>>>>?>>>>>>>?>>>>>>> teacher name: $teacherId");
    print("?>>>>>>>>>>>>>>>?>>>>>>>?>>>>>>> teacher name: $teacherImage");
    streamVideo.state.incomingCall.listen((incomingCall) async {
      if (incomingCall != null) {
        await streamVideo.getCallRingingState(callType: callType, id: incomingCall.callCid.id).then((value) {
          debugPrint("+++++++++++++++++++++++++++++++++++++++++++++++++ CallRingingState: $value +++++++++++++++++++++++++++++++++++++++++++++++++ "); // Add this line for debugging

          if (value == CallRingingState.ringing) {
            streamVideo.pushNotificationManager!
                .showIncomingCall(uuid: studentId, callCid: incomingCall.callCid.toString());
            // WidgetsBinding.instance.addPostFrameCallback((_) async {
            // Future.delayed(const Duration(milliseconds: 300), () {
            //   Navigator.pushAndRemoveUntil(
            //       context,
            //       MaterialPageRoute(
            //           builder: (context) => CustomIncomingCallScreen(
            //                 incomingCall,
            //                 senderId: teacherId,
            //                 senderName: teacherName,
            //               )),
            //       (route) => false);
            // });
            AppConsumers().consumeIncomingCall(context);
            if (!isClosed) {
              emit(IncomingCallState(
                call: incomingCall,
                teacherId: teacherId,
                teacherName: teacherName,
                teacherImage: teacherImage,
              ));
            }
          } else if (value == CallRingingState.ended) {
            showSuccessSnackBar("Call ended from student", 3, context);
            endCall(
              incomingCall,
              locator.get<UserAuthController>().currentUser?.id ?? "Empty ID",
              locator.get<UserAuthController>().currentUser?.name ?? "Empty Name",
              context,
              locator.get<UserAuthController>(),
            );
            if (!isClosed) emit(SuccessCallEndedState());
          }
        });
      } else {
        if (!isClosed) emit(const CallErrorState("state is null"));
      }
    });
  }

  // Accept the incoming call from teacher
  Future<void> acceptCall(BuildContext context, String callId, Call call) async {
    try {
      await call.accept().then((value) async {
        print("?>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>Call Accepted");
        AppConsumers().observeCallKitEvents(context);
        await FirebaseFirestore.instance.collection('calls').doc(callId).update({
          'isRinging': false,
          'isAccepted': true,
        });
        if (!isClosed) emit(CallAcceptedState(callId: callId));
      });
    } catch (e, s) {
      if (!isClosed) {
        print(">?>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>Error: ${e.toString()}");
        print(">?>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>StackError: ${s.toString()}");
        emit(CallErrorState("Failed to accept call: $e"));
      }
    }
  }

  // Reject or cancel the incoming call from teacher
  Future<void> rejectCallFromTeacher(BuildContext context, String callId, Call call) async {
    try {
      await call.reject(reason: CallRejectReason.decline()).then((value) async {
        await call.end();
        streamVideo.observeCallDeclinedCallKitEvent();
        AppConsumers().compositeSubscription.cancel();
        streamVideo.pushNotificationManager!.endAllCalls();
        print("?>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>Call Rejected from teacher");
        await FirebaseFirestore.instance.collection('calls').doc(callId).update({
          'isRinging': false,
          'isAccepted': false,
          'isActiveCall': false,
        });
        showSuccessSnackBar("The call canceled form Teacher", 3, context);
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => const Layout(type: "Teacher")), (route) => false);
        });
        if (!isClosed) emit(CallRejectedFromTeacherState(callId: callId));
      });
    } catch (e, s) {
      if (!isClosed) {
        print(">?>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>Error: ${e.toString()}");
        print(">?>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>StackError: ${s.toString()}");
        emit(CallErrorState("Failed to reject call: $e"));
      }
    }
  }

  // Reject or cancel the incoming call from student
  Future<void> rejectCallFromStudent(BuildContext context, String callId, Call call) async {
    try {
      await call.reject(reason: CallRejectReason.decline()).then((value) async {
        AppConsumers().compositeSubscription.cancel();
        streamVideo.observeCallDeclinedCallKitEvent();
        streamVideo.pushNotificationManager!.endAllCalls();
        streamVideo.pushNotificationManager!.dispose();
        print("?>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>Call Rejected from student");
        await FirebaseFirestore.instance.collection('calls').doc(callId).update({
          'isRinging': false,
          'isAccepted': false,
          'isActiveCall': false,
        });
        // showSuccessSnackBar("The call canceled form Student", 3, context);
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          showSuccessSnackBar("Call rejected from student", 3, context);
          Navigator.of(context, rootNavigator: true).pop();
        });
        if (!isClosed) emit(CallRejectedFromStudentState(callId: callId));
      });
    } catch (e, s) {
      if (!isClosed) {
        print(">?>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>Error: ${e.toString()}");
        print(">?>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>StackError: ${s.toString()}");
        emit(CallErrorState("Failed to reject call: $e"));
      }
    }
  }

  // Start Call Timer to Update Duration
  // void startCallTimer(String callID) {
  //   _durationTimer?.cancel();
  //   var duration = Duration.zero;
  //
  //   _durationTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
  //     duration += const Duration(minutes: 1);
  //     firebaseServices.updateCallDuration(callID, duration);
  //   });
  // }

  // End the call
  Future<void> endCall(
    Call call,
    String userId,
    String userName,
    context,
    UserAuthController userAuthController,
  ) async {
    print("----------- Call canceled from: $userId -----------, name: $userName");
    emit(LoadingCallEndedState());
    await call.leave().then(
      (value) {
        print("----------- ----------- ----------- ----------- ----------- -----------");
        if (value.isSuccess) {
          print("************* ************* ************* ************* ************* *************");
          AppConsumers().compositeSubscription.cancel();
          streamVideo.pushNotificationManager!.endAllCalls();
          streamVideo.pushNotificationManager!.dispose();
          streamVideo.observeCallEndedCallKitEvent()!.cancel();
          // _durationTimer?.cancel();
          WidgetsBinding.instance.addPostFrameCallback((_) {
            print("><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><");
            Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
                MaterialPageRoute(
                    builder: (context) =>
                        Layout(type: userAuthController.currentUser?.role == 'admin' ? "Teacher" : 'Student')),
                (route) => false);
            if (!isClosed) emit(SuccessCallEndedState());
          });
        } else {
          if (!isClosed) {
            print(
                "-----------***********************----------- ${value.isFailure} -----------***********************-----------");
            emit(CallErrorState("Call canceled Failed: ${value.isFailure}!!"));
          }
        }
      },
    ).catchError((onError, StackTrace stk) {
      if (!isClosed) {
        print("----------- Call Failed: ${onError.toString()} -----------");
        print("----------- Call Failed: ${stk.toString()} -----------");
        showErrorSnackBar("Failed", 3, context);
        emit(FailedCallEndedState(onError));
      }
    });
  }

  @override
  Future<void> close() {
    // _cameraTrack!.stop();
    // _microphoneTrack!.stop();
    // _durationTimer!.cancel();
    streamVideo.pushNotificationManager!.endAllCalls();
    return super.close();
  }
}
