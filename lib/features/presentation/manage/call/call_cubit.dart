import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:flutter_callkit_incoming/entities/call_kit_params.dart';
// import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:getstream_flutter_example/core/di/injector.dart';
import 'package:getstream_flutter_example/core/utils/consts/functions.dart';
import 'package:getstream_flutter_example/core/utils/widgets.dart';
import 'package:getstream_flutter_example/features/data/models/calling_model.dart';
import 'package:getstream_flutter_example/features/data/models/meetings_model.dart';
import 'package:getstream_flutter_example/features/data/services/firebase_services.dart';
import 'package:getstream_flutter_example/features/presentation/view/meet/meet_screen.dart';
import 'package:getstream_flutter_example/features/presentation/view/meet/ready_to_start_screen.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:stream_video_flutter/stream_video_flutter.dart';

import '../../view/home/layout.dart';

part 'call_state.dart';

class CallingsCubit extends Cubit<CallingsState> {
  CallingsCubit() : super(CallInitial());

  static CallingsCubit get(BuildContext context) => BlocProvider.of(context, listen: false);

  StreamSubscription? callkitSubscription;

  /// Basic function to (create / make) a (call / meet) in general
  Call _makeCall(callId) {
    final call = locator.get<StreamVideo>().makeCall(callType: StreamCallType.defaultType(), id: callId);
    return call;
  }

  /// General settings (For student and teacher)
  // 1- in lobby screen (navigate for ready to start screen)
  Future<void> readyToStartMeet(BuildContext context, String meetId, String studentId, String studentName) async {
    emit(CallLoadingState());
    final call = _makeCall(meetId);
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

    final call = _makeCall(callId);
    try {
      await _checkAndRequestPermissions(context).then((value) async {
        await call.join(connectOptions: connectOptions).then((_) {
          if (context.mounted) {
            emit(MeetingJoinedState(call: call, connectOptions: connectOptions!));
            Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => MeetScreen(call: call, connectOptions: connectOptions)),
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

  /// Teacher settings
  // 1- initial meet
  Future<void> initiateMeet(BuildContext context, String teacherId, String teacherName) async {
    emit(MeetingLoadingState());
    try {
      final meet = _makeCall(generateCallId(8));
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
      }).catchError((onError) {
        debugPrint('Error joining or creating Meeting: $onError');
        emit(const MeetingErrorState("Catch Error"));
      }).onError((e, stk) {
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
  Future<void> initiateCall(BuildContext context, teacherId, teacherName, studentId, studentName) async {
    emit(CallLoadingState());
    try {
      final call = _makeCall(generateCallId(4));
      // call.state.value.isRingingFlow;
      await call.getOrCreate(ringing: true, video: true, memberIds: [teacherId, studentId]).then((value) async {
        debugPrint("Call state after creation: ${call.state.value.status}");
        debugPrint("Call session ID: ${call.state.value.sessionId}");
        if (value.isSuccess) {
          debugPrint("Call successfully connected!");
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

          final Map<String, dynamic> params = {
            'id': call.id,
            'nameCaller': teacherName,
            // Replace with actual teacher name
            'appName': 'My App',
            'avatar': 'https://d26oc3sg82pgk3.cloudfront.net/files/media/edit/image/56073/article_full%401x.jpg',
            // URL of the teacher's avatar
            'handle': teacherName,
            'type': 0,
            // 0 => audio call, 1 => video call
            'duration': 300,
            // Call duration in seconds
            'textAccept': 'Accept',
            'textDecline': 'Decline',
            'textMissedCall': 'Missed call',
            'textCallback': 'Call back',
            'extra': {teacherId: studentId},
            // 'headers': {'apiKey': 'your-api-key'},
          };

          // await FlutterCallkitIncoming.showCallkitIncoming(CallKitParams.fromJson(params));
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
        debugPrint("Error joining or creating call: ${stk.toString()}");
        emit(const CallErrorState("On Error"));
      });
    } catch (e, s) {
      debugPrint("Call initiation error: ${e.toString()}");
      debugPrint("Stack trace: ${s.toString()}");
      emit(CallErrorState("Failed to initiate call: ${s.toString()}"));
    }
  }

  // 3- create a call with ringtone
  Future<void> createCall(String teacherId, String studentId, String teacherName) async {
    try {

    } catch (e) {
      print("Error creating call: $e");
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
      // } else {
      //   emit(const CallErrorState("Meet not found."));
      // }

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
      // Ensure the student cleanly leaves without affecting the teacher
      // await call.leave();
      // await FirebaseServices().firestore.collection("meets").doc(meetId).update({
      //   'receiverID': '',
      //   'receiverName': '',
      // });

      // Check if the teacher has ended the call by verifying the `isActiveMeet` status in Firestore
      final docSnapshot = await FirebaseServices().firestore.collection("meets").doc(meetId).get();

      if (docSnapshot.exists) {
        final data = docSnapshot.data();
        final isActiveMeet = data?['isActiveMeet'] ?? true;

        // If the teacher has already ended the meet, end the call
        print(">>>>>>>>????????>>>>>>>>>>??????????>>>>>>>>>>>>>>?????????????>>>>>>>???????>>>>>$isActiveMeet");
        if (isActiveMeet == false) {
          print("Teacher has already ended the meet. Ending the call for the student.");
          // await call.end();
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
  void listenForIncomingCalls(String receiverId, Call call) {
    print("?>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>Call Listening!!");
    FirebaseFirestore.instance
        .collection('calls')
        .where('receiverId', isEqualTo: receiverId)
        .where('isRinging', isEqualTo: true)
        .snapshots()
        .listen((snapshot) {
      for (var doc in snapshot.docs) {
        emit(IncomingCallState(callData: doc.data()));
      }
    });
  }

  // 4- accept the call
  Future<void> acceptCall(String callId, Call call) async {
    try {
      await call.accept().then((value) async {
        print("?>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>Call Accepted");
        await FirebaseFirestore.instance.collection('calls').doc(callId).update({
          'isRinging': false,
          'isAccepted': true,
        });
        emit(CallAcceptedState(callId: callId));
      });
    } catch (e, s) {
      print(">?>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>Error: ${e.toString()}");
      print(">?>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>StackError: ${s.toString()}");
      emit(CallErrorState("Failed to accept call: $e"));
    }
  }

  // 5- reject call
  Future<void> rejectCall(String callId, Call call) async {
    try {
      await call.reject(reason: CallRejectReason.cancel()).then((value) async {
        print("?>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>Call Rejected");
        await FirebaseFirestore.instance.collection('calls').doc(callId).update({
          'isRinging': false,
        });
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
}
