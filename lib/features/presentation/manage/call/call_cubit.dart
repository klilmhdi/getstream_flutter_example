import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:getstream_flutter_example/core/di/injector.dart';
import 'package:getstream_flutter_example/core/utils/consts/functions.dart';
import 'package:getstream_flutter_example/features/data/services/firebase_services.dart';
import 'package:getstream_flutter_example/features/presentation/view/meet/meet_screen.dart';
import 'package:getstream_flutter_example/features/presentation/view/meet/ready_to_start_screen.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:stream_video_flutter/stream_video_flutter.dart';

part 'call_state.dart';

class CallingsCubit extends Cubit<CallingsState> {
  CallingsCubit() : super(CallInitial());

  static CallingsCubit get(BuildContext context) => BlocProvider.of(context, listen: false);

  Call _makeCall(callId) {
    final call = locator.get<StreamVideo>().makeCall(callType: StreamCallType.defaultType(), id: callId);
    return call;
  }

  // initial call
  Future<void> initiateCall(BuildContext context, teacherId) async {
    emit(CallLoadingState());
    try {
      final call = _makeCall(generateCallId(10));
      await call.getOrCreate(ringing: false, video: true).then((value) {
        debugPrint("Call state after creation: ${call.state.value.status}");
        debugPrint("Call session ID: ${call.state.value.sessionId}");
        if (value.isSuccess) {
          debugPrint("Call successfully connected!");
          FirebaseServices().firestore.collection("calls").doc(call.id).set({
            'callId': call.id,
            'teacherId': teacherId,
            'studentId': null,
            'isActive': true,
          });
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

  Future<void> readyToStartMeet(BuildContext context, String callId, String studentId) async {
    emit(CallLoadingState());
    final call = _makeCall(callId);

    try {
      FirebaseServices().firestore.collection("calls").doc(callId).update({
        'studentId': studentId,
      }).then((_) {
        print("Firestore updated successfully for call ID: $callId");
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                ReadyToStartScreen(
                  onJoinCallPressed: (_) => context.read<CallingsCubit>().joinMeet(context, callId),
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

  // join to meet
  Future<void> joinMeet(BuildContext context, callId) async {
    emit(CallLoadingState());

    final call = _makeCall(callId);
    try {
      await _checkAndRequestPermissions(context).then((value) async {
        await call.join().then((_) {
          if (context.mounted) {
            emit(CallJoinedState(call: call));
            Navigator.push(context, MaterialPageRoute(builder: (context) => MeetScreen(call: call)));
          }
        });
      });
    } catch (e, s) {
      debugPrint("Failed to join call: ${e.toString()}");
      debugPrint("Stack trace: ${s.toString()}");
      emit(CallErrorState(e.toString()));
    }
  }

  // available calls from teacher
  // Future<void> fetchActiveCalls() async {
  //   emit(ActiveCallsLoadingState());
  //   try {
  //     final querySnapshot =
  //         await FirebaseServices().firestore.collection("calls").where("isActiveNow", isEqualTo: true).get();
  //
  //     final activeCalls = querySnapshot.docs
  //         .map((doc) => {
  //               "callId": doc.id,
  //               "teacherId": doc["teacherId"],
  //               "studentId": doc["studentId"] ?? "No student assigned",
  //               "isActiveNow": doc["isActiveNow"]
  //             })
  //         .toList();
  //
  //     if (activeCalls.isEmpty) {
  //       emit(const CallErrorState("No active calls with callId found for teachers."));
  //     } else {
  //       emit(ActiveCallsFetchedState(activeCalls: activeCalls));
  //     }
  //   } catch (e) {
  //     emit(ActiveCallsFailedState(error: "Failed to fetch active calls: $e"));
  //   }
  // }

  Future<void> fetchActiveCalls() async {
    emit(ActiveCallsLoadingState());
    try {
      final querySnapshot =
      await FirebaseServices().firestore.collection("calls").where("isActive", isEqualTo: true).get();

      final activeCalls = querySnapshot.docs.map((doc) {
        return {
          "callId": doc.get("callId") ?? doc.id,
          "teacherId": doc.get("teacherId") ?? "Unknown Teacher",
          "studentId": doc.get("studentId") ?? "No student assigned",
          "isActive": doc.get("isActive"),
        };
      }).toList();

      if (activeCalls.isEmpty) {
        emit(const CallErrorState("No active calls with callId found for teachers."));
      } else {
        emit(ActiveCallsFetchedState(activeCalls: activeCalls));
      }
    } catch (e) {
      emit(CallErrorState("Failed to fetch active calls: ${e.toString()}"));
    }
  }

  // end call via set isActive to false
  // Future<void> endCall(BuildContext context, callId) async {
  //   try {
  //     final querySnapshot =
  //     await FirebaseServices().firestore.collection("calls").where("callId", isEqualTo: callId).limit(1).get();
  //
  //     if (querySnapshot.docs.isNotEmpty) {
  //       await FirebaseServices().firestore.collection("calls").doc(callId).update({
  //         'callId': FieldValue.delete(),
  //         'isActive': false,
  //       });
  //
  //       emit(CallEndedState());
  //       Navigator.pop(context);
  //     } else {
  //       emit(const CallErrorState("Teacher ID not found for the current call."));
  //     }
  //   } catch (e) {
  //     emit(CallErrorState("Failed to end call: $e"));
  //   }
  // }
  Future<void> endCall(BuildContext context, String callId) async {
    try {
      // Query the call document by its 'callId' field
      final querySnapshot = await FirebaseServices().firestore
          .collection("calls")
          .where("callId", isEqualTo: callId)
          .limit(1)
          .get();

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

  // need camera, microphone, and notifications permissions
  Future<void> _checkAndRequestPermissions(BuildContext context) async {
    final cameraStatus = await Permission.camera.request();
    final micStatus = await Permission.microphone.request();
    final notifStatus = await Permission.notification.request();

    if (cameraStatus.isDenied || micStatus.isDenied || notifStatus.isDenied) {
      _showPermissionDialog(context, "Permissions required");
    }
  }

  // permission dialog
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
