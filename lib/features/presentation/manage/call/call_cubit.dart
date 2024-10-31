import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:getstream_flutter_example/core/di/injector.dart';
import 'package:getstream_flutter_example/core/utils/consts/functions.dart';
import 'package:getstream_flutter_example/features/data/services/firebase_services.dart';
import 'package:getstream_flutter_example/features/presentation/view/meet/meet_screen.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:stream_video_flutter/stream_video_flutter.dart';

part 'call_state.dart';

class CallingsCubit extends Cubit<CallingsState> {
  CallingsCubit() : super(CallInitial());

  static CallingsCubit get(BuildContext context) => BlocProvider.of(context, listen: false);

  // final _streamVideo = locator.get<StreamVideo>();
  // final String _callId = generateCallId(10);

  // final call = locator.get<StreamVideo>().makeCall(callType: StreamCallType.defaultType(), id: generateCallId(10));

  Call _makeCall(callId) {
    final call = locator.get<StreamVideo>().makeCall(callType: StreamCallType.defaultType(), id: callId);
    return call;
  }

  Future<void> initiateCall(BuildContext context, teacherId) async {
    emit(CallLoadingState());
    try {
      final call = _makeCall(generateCallId(10));
      await call.getOrCreate(ringing: false, video: true).then((value) {
        debugPrint("Call state after creation: ${call.state.value.status}");
        debugPrint("Call session ID: ${call.state.value.sessionId}");
        if (value.isSuccess) {
          debugPrint("Call successfully connected!");
          FirebaseServices().firestore.collection("users").doc(teacherId).update({
            'callId': call.id,
            'teacherId': teacherId,
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

  Future<void> fetchActiveCalls() async {
    emit(CallLoadingState());
    try {
      final querySnapshot = await FirebaseServices()
          .firestore
          .collection("users")
          .where("isActive", isEqualTo: true)
          .where("role", isEqualTo: "Teacher")
          .get();

      final activeCalls = querySnapshot.docs
          .where((doc) => doc.data().containsKey("callId"))
          .map((doc) => {
                "teacherId": doc.id,
                "callId": doc["callId"],
                "teacherName": doc["name"],
                "rule": doc["role"],
                "email": doc["email"],
              })
          .toList();

      if (activeCalls.isEmpty) {
        emit(const CallErrorState("No active calls with callId found for teachers."));
      } else {
        emit(ActiveCallsFetchedState(activeCalls: activeCalls));
      }
    } catch (e) {
      emit(CallErrorState("Failed to fetch active calls: $e"));
    }
  }

  Future<void> endCall(BuildContext context, callId) async {
    try {
      final querySnapshot =
          await FirebaseServices().firestore.collection("users").where("callId", isEqualTo: callId).limit(1).get();

      if (querySnapshot.docs.isNotEmpty) {
        final teacherId = querySnapshot.docs.first.id;
        await FirebaseServices().firestore.collection("users").doc(teacherId).update({
          'callId': FieldValue.delete(),
          'isActive': false,
        });

        emit(CallEndedState());
        Navigator.pop(context);
      } else {
        emit(const CallErrorState("Teacher ID not found for the current call."));
      }
    } catch (e) {
      emit(CallErrorState("Failed to end call: $e"));
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
