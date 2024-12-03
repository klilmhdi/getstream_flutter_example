import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:flutter_callkit_incoming/entities/call_kit_params.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:getstream_flutter_example/core/di/injector.dart';
import 'package:getstream_flutter_example/core/utils/consts/functions.dart';
import 'package:getstream_flutter_example/core/utils/controllers/user_auth_controller.dart';
import 'package:getstream_flutter_example/core/utils/flutter_incoming_callkit.dart';
import 'package:getstream_flutter_example/core/utils/widgets.dart';
import 'package:getstream_flutter_example/features/data/models/calling_model.dart';
import 'package:getstream_flutter_example/features/data/models/meetings_model.dart';
import 'package:getstream_flutter_example/features/data/services/firebase_services.dart';
import 'package:getstream_flutter_example/features/presentation/view/meet/call_canceled_screen.dart';
import 'package:getstream_flutter_example/features/presentation/view/meet/call_screen.dart';
import 'package:getstream_flutter_example/features/presentation/view/meet/incoming_call.dart';
import 'package:getstream_flutter_example/features/presentation/view/meet/meet_screen.dart';
import 'package:getstream_flutter_example/features/presentation/view/meet/ready_to_start_screen.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:stream_chat_flutter/stream_chat_flutter.dart';
import 'package:stream_video_flutter/stream_video_flutter.dart';
import 'package:stream_video_push_notification/stream_video_push_notification.dart';

import '../../view/home/layout.dart';

part 'call_state.dart';

class CallingsCubit extends Cubit<CallingsState> {
  CallingsCubit() : super(CallInitial());

  static CallingsCubit get(BuildContext context) => BlocProvider.of(context, listen: false);

  StreamSubscription? callkitSubscription;

  /// Basic function to (create / make) a (call / meet) in general
  Call _makeMeet(meetId) {
    final call = locator.get<StreamVideo>().makeCall(callType: StreamCallType.defaultType(), id: meetId);
    return call;
  }

  Call _makeCall(callId) {
    final call = locator.get<StreamVideo>().makeCall(callType: StreamCallType.defaultType(), id: callId);
    return call;
  }

  /// General settings (For student and teacher)
  // 1- in lobby screen (navigate for ready to start screen)
  Future<void> readyToStartMeet(BuildContext context, String meetId, String studentId, String studentName) async {
    emit(CallLoadingState());
    final call = _makeMeet(meetId);
    try {
      FirebaseServices()
          .firestore
          .collection("meets")
          .doc(meetId)
          .update({'receiverID': studentId, 'receiverName': studentName}).then((_) {
        print("Firestore updated successfully for call ID: $meetId");
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ReadyToStartScreen(
              onJoinCallPressed: (_) => context.read<CallingsCubit>().joinMeet(context, meetId),
              call: call,
            ),
          ),
        );
      }).catchError((error) {
        print("Error updating Firestore: $error");
      });
    } catch (e, s) {
      debugPrint("Failed to join call: ${e.toString()}");
      debugPrint("Stack trace: ${s.toString()}");
      emit(CallErrorState(e.toString()));
    }
  }

  // 2- join to meet
  Future<void> joinMeet(BuildContext context, callId, {CallConnectOptions? connectOptions}) async {
    emit(CallLoadingState());

    final call = _makeMeet(callId);
    try {
      await _checkAndRequestPermissions(context).then((value) async {
        await call.join(connectOptions: connectOptions).then((_) {
          if (context.mounted) {
            emit(MeetingJoinedState(call: call, connectOptions: connectOptions!));
            Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => CallScreen(call: call, connectOptions: connectOptions)),
                (route) => false);
          }
        });
      });
    } catch (e, s) {
      debugPrint("Failed to join call: ${e.toString()}");
      debugPrint("Stack trace: ${s.toString()}");
      emit(CallErrorState(e.toString()));
    }
  }

  // 3- End the meeting
  Future<void> endMeet(context, Call call, String meetId) async {
    final isAdmin = locator.get<UserAuthController>().currentUser!.role == 'admin';
    try {
      if (isAdmin) {
        await call.end();
        await call.reject(reason: CallRejectReason.cancel());
        StreamVideo.instance.pushNotificationManager?.endAllCalls();
        await FirebaseServices().firestore.collection("meets").doc(meetId).update({
          'creatorID': '',
          'isActiveMeet': false,
          'receiverID': '',
          'receiverName': '',
        }).then((value) {
          print("?>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>The value is set false");
          showSuccessSnackBar("Change values success", 3, context);
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const Layout(type: 'Teacher')),
            (route) => false,
          );
        });

        emit(CallEndedState());
        print("?>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>End call and change the active meets to false success");
      } else {
        await call.leave();
        if (!call.isActiveCall) {
          await FirebaseServices().firestore.collection("meets").doc(meetId).update({
            'receiverID': '',
            'receiverName': '',
          }).then((value) {
            print("?>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>The value is set false");
            showSuccessSnackBar("Leaved the call successful!", 3, context);
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const Layout(type: 'Student')),
              (route) => false,
            );
          });
          emit(CallLeavedState());
        }
      }
    } catch (e) {
      print("Error end call: $e");
    }
  }

  /// Teacher settings
  // 1- initial meet
  Future<void> initiateMeet(BuildContext context, String teacherId, String teacherName) async {
    emit(MeetingLoadingState());
    try {
      final meet = _makeMeet(generateCallId(8));
      await meet.getOrCreate(ringing: false, video: true).then((value) {
        debugPrint("Meet state after creation: ${meet.state.value.status}");
        debugPrint("Meet session ID: ${meet.state.value.sessionId}");
        if (value.isSuccess) {
          debugPrint("Meet successfully connected!");
          final meeting = MeetingModel(
              meetID: meet.id,
              creatorID: teacherId,
              creatorName: teacherName,
              receiverID: "",
              receiverName: "",
              isActiveMeet: true);
          // FirebaseServices().firestore.collection("meets").doc().set();
          FirebaseServices().uploadMeetDataToFirebase(meeting);
          emit(MeetingCreatedState(meet: meet));
        } else if (meet.state.value.status.isIdle) {
          debugPrint("Meeting Status: ${meet.state.value.status}");
          emit(const MeetingErrorState("Meeting is IDLE"));
        } else {
          debugPrint("Meeting failed: ${meet.state.value.status}");
          emit(const MeetingErrorState("Call is failed"));
        }
      })
          .catchError((onError) {
        debugPrint('Error joining or creating Meeting: $onError');
        emit(const MeetingErrorState("Catch Error"));
      })
          .onError((e, stk) {
        debugPrint('Error joining or creating Meeting: $e');
        debugPrint("Error joining or creating Meeting: ${stk.toString()}");
        emit(const MeetingErrorState("On Error"));
      });
    } catch (e, s) {
      debugPrint("Meeting initiation error: ${e.toString()}");
      debugPrint("Stack trace: ${s.toString()}");
      emit(MeetingErrorState("Failed to initiate Meeting: ${s.toString()}"));
    }
  }

  // 2- initial call
  Future<void> initiateCall(BuildContext context, teacherId, teacherName, {studentId, studentName}) async {
    emit(CallLoadingState());
    if (teacherId.isEmpty || studentId.isEmpty) {
      debugPrint('Teacher or student ID is missing.');
      emit(const CallErrorState('Invalid member IDs.'));
      return;
    }
    try {
      final call = _makeCall(generateCallId(4));
      _checkAndRequestPermissions(context).then((value) async {
        await call.getOrCreate(ringing: true, video: true, memberIds: [teacherId, studentId]).then((value) async {
          print("?>>>>>>>>>>>>>>>>>>>>>>>>>Student name: $studentName");
          print("?>>>>>>>>>>>>>>>>>>>>>>>>>Student name: $studentId");
          debugPrint("Call state after creation: ${call.state.value.status}");
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
            emit(CallCreatedState(call: call));
          } else if (call.state.value.status.isIdle) {
            debugPrint(
                ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>Call Status: ${call.state.value.status}");
            emit(const CallErrorState("Call is IDLE"));
          } else {
            debugPrint(
                ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>Call failed: ${call.state.value.status}");
            emit(const CallErrorState("Call is failed"));
          }
        })
            .catchError((onError) {
          debugPrint('Error joining or creating call: $onError');
          emit(const CallErrorState("Catch Error"));
        })
            .onError((e, stk) {
          debugPrint(
              '>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>Error joining or creating call: $e');
          debugPrint(
              ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>Error joining or creating call: ${stk.toString()}");
          emit(const CallErrorState("On Error"));
        });
      });
    } catch (e, s) {
      debugPrint(
          ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>Call initiation error: ${e.toString()}");
      debugPrint(">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>Stack trace: ${s.toString()}");
      emit(CallErrorState("Failed to initiate call: ${s.toString()}"));
    }
  }

  // 3- create a call with ringtone
  Future<void> createCall(context, String teacherId, String studentId, String teacherName) async {
    emit(LoadCallToStudentState());

    try {
      final studentDoc = await FirebaseFirestore.instance.collection('calls').doc(studentId).get();

      if (!studentDoc.exists) {
        print("Student does not exist in the database.");
        return;
      }

      final studentData = studentDoc.data();
      final callId = generateCallId(4);
      final studentName = studentData?['name'] ?? 'Student';

      // CallKitServices().sendCallToStudent(callId, studentName, studentId);
      // Navigate to the Incoming Call Screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => StreamOutgoingCallContent(
            call: _makeCall(callId),
            callState: CallState(currentUserId: teacherName, callCid: StreamCallCid(cid: callId)),
          ),
        ),
      );
      emit(SuccessSendCallToStudentState());

      print("Incoming call notification sent successfully.");
    } catch (e) {
      print("Error creating call: $e");
      emit(FailedSendCallToStudentState());
    }
  }

  // 4- end call via set isActive to false
  Future<void> endCall(BuildContext context, String callId) async {
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

        emit(CallEndedState());
        Navigator.pop(context);
      } else {
        emit(const CallErrorState("Call not found."));
      }
    } catch (e) {
      emit(CallErrorState("Failed to end call: $e"));
    }
  }

  // 5- end meet via set isActive to false
  Future<void> endMeetFromTeacher(BuildContext context, String meetId, Call call) async {
    try {
      // End the call first
      if (call.state.value.status.isActive) {
        print("?>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>The call is ended");
        await call.end();
        await call.reject(reason: CallRejectReason.cancel());
      }

      await FirebaseServices().firestore.collection("meets").doc(meetId).update({
        'creatorID': '',
        'isActiveMeet': false,
        'receiverID': '',
        'receiverName': '',
      }).then(
        (value) {
          print("?>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>The value is set false");
          showSuccessSnackBar("Change values success", 3, context);
        },
      );
      emit(CallEndedState());
      print("?>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>End call and change the active meets to false success");
      // Navigate back to the teacher's layout after the Firestore update
      if (context.mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const Layout(type: 'Teacher')),
          (route) => false,
        );
      }
    } catch (e) {
      emit(CallErrorState("Failed to end meet: $e"));
    }
  }

  /// Student settings
  // 1- fetch active meets
  Future<void> fetchActiveMeets() async {
    emit(ActiveMeetsLoadingState());
    try {
      final querySnapshot =
          // await FirebaseFirestore.instance.collection("meets").where("isActiveMeet", isEqualTo: true).get();
          await FirebaseFirestore.instance.collection("meets").get();

      final activeMeets = querySnapshot.docs.map((doc) {
        return MeetingModel.fromMap(doc.data());
      }).toList();

      if (activeMeets.isEmpty) {
        emit(const CallErrorState("No active meets found."));
      } else {
        emit(ActiveMeetsFetchedState(activeMeets: activeMeets));
      }
    } catch (e) {
      emit(CallErrorState("Failed to fetch active meets: ${e.toString()}"));
    }
  }

  // 2- leave meet in student side
  Future<void> leaveMeetForStudent(context, String meetId, Call call) async {
    try {
      // Check if the teacher has ended the call by verifying the `isActiveMeet` status in Firestore
      final docSnapshot = await FirebaseServices().firestore.collection("meets").doc(meetId).get();

      if (docSnapshot.exists) {
        final data = docSnapshot.data();
        final isActiveMeet = data?['isActiveMeet'] ?? true;

        // If the teacher has already ended the meet, end the call
        print(">>>>>>>>????????>>>>>>>>>>??????????>>>>>>>>>>>>>>?????????????>>>>>>>???????>>>>>$isActiveMeet");
        if (isActiveMeet == false && call.state.value.status.isActive) {
          print("Teacher has already ended the meet. Ending the call for the student.");
          // await call.end();
          // Ensure call is left and ended
          await call.end();
          await call.leave();
          // await call.reject(reason: CallRejectReason.cancel());
          emit(CallEndedState());
        } else {
          print("Teacher has not ended the meet. Student will leave the call.");
          await call.leave();
          await FirebaseServices().firestore.collection("meets").doc(meetId).update({
            'receiverID': '',
            'receiverName': '',
          });
          emit(CallEndedState());
        }
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const Layout(type: 'Student')),
          (route) => false,
        );
      }
    } catch (e) {
      emit(CallErrorState("Failed to leave meet: $e"));
    }
  }

  // 3- listen incoming calls:
  void listenForIncomingCalls(String receiverId, BuildContext context) {
    FirebaseFirestore.instance
        .collection('calls')
        .where('receiverID', isEqualTo: receiverId)
        .where('isRinging', isEqualTo: true)
        .snapshots()
        .listen((snapshot) {
      for (var doc in snapshot.docs) {
        final callData = doc.data();
        emit(IncomingCallState(callData: callData));

        // Navigate to the Incoming Call Screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => StreamIncomingCallContent(
              call: _makeCall(callData['callId']),
              onAcceptCallTap: () => acceptCall(context, callData['callId'], _makeCall(callData['callId'])),
              onDeclineCallTap: () => rejectCall(context, callData['callId'], _makeCall(callData['callId'])),
              callState: CallState(
                  currentUserId: receiverId,
                  callCid: StreamCallCid.from(type: StreamCallType.defaultType(), id: callData['callId'])),
            ),
          ),
        );
      }
    });
  }

  // 4- accept the call
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

  // 5- reject call
  Future<void> rejectCall(context, String callId, Call call) async {
    try {
      await call.reject(reason: CallRejectReason.cancel()).then((value) async {
        print("?>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>Call Rejected");
        await FirebaseFirestore.instance.collection('calls').doc(callId).update({
          'isRinging': false,
        });
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => CallCancelledScreen()),
        );
        emit(CallRejectedState(callId: callId));
      });
    } catch (e, s) {
      print(">?>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>Error: ${e.toString()}");
      print(">?>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>StackError: ${s.toString()}");
      emit(CallErrorState("Failed to reject call: $e"));
    }
  }

  /// private functions
  // * need camera, microphone, and notifications permissions
  Future<void> _checkAndRequestPermissions(BuildContext context) async {
    final cameraStatus = await Permission.camera.request();
    final micStatus = await Permission.microphone.request();
    final notifStatus = await Permission.notification.request();

    if (cameraStatus.isDenied || micStatus.isDenied || notifStatus.isDenied) {
      _showPermissionDialog(context, "Permissions required");
    }
  }

  // * permission dialog
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

  Future<void> _checkAndNavigationCallingPage(context, call) async {
    var currentCall = await FlutterCallkitIncoming.activeCalls();
    if (currentCall != null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => CallScreen(call: call)),
      );
    }
  }
}
