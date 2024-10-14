import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:getstream_flutter_example/core/utils/consts/call_consts.dart';
import 'package:getstream_flutter_example/core/utils/consts/functions.dart';
import 'package:getstream_flutter_example/features/data/services/firebase_services.dart';
import 'package:getstream_flutter_example/features/presentation/view/meet/meet_screen.dart';
import 'package:stream_video_flutter/stream_video_flutter.dart';

part 'call_state.dart';

class CallingsCubit extends Cubit<CallingsState> {
  CallingsCubit() : super(CallInitial());

  static CallingsCubit get(context) => BlocProvider.of(context, listen: false);

  // final FirebaseServices firebaseServices = FirebaseServices();
  // await firebaseServices.firestore.collection('calls').doc(callId).set({
  //   'callerId': teacherId,
  //   'callingId': studentId,
  //   'status': 'pending', // 'pending', 'accepted', 'rejected'
  //   'createdAt': FieldValue.serverTimestamp(),
  // }).then((onValue) async {
  // });

  String callId = generateCallId(10);

  Call? call;

  Future<void> initiateCall(String teacherId, context, {String? studentId}) async {
    emit(CallLoadingState());
    try {
      // Check if StreamVideo is initialized
      if (!StreamVideo.isInitialized()) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('StreamVideo is not initialized...'),
          backgroundColor: CupertinoColors.destructiveRed,
        ));
        emit(const CallErrorState("StreamVideo is not initialized"));
        return;
      }
      call = StreamVideo.instance.makeCall(callType: StreamCallType.defaultType(), id: callId);
      print(">>>>>>>>>>>>>>>Call created with id: $callId");
      print(">>>>>>>>>>>>>>>Call type: ${call!.type.value}");
      print(">>>>>>>>>>>>>>>Call cid value: ${call!.callCid.value}");
      print(">>>>>>>>>>>>>>>Call cid id: ${call!.callCid.id}");
      print(">>>>>>>>>>>>>>>Call cid type: ${call!.callCid.type.value}");

      call!.state.listen((callState) async {
        if (callState.status.isConnecting || callState.status.isConnected) {
          print("Call is connecting or connected, now creating/getting call...");
          await call!.getOrCreate(memberIds: [teacherId, studentId ?? ""], video: true).then((value) {
            print("??>>>>>>>>>>>>>Call success: ${value.isSuccess}");
            if (value.isSuccess) {
              Navigator.push(context, MaterialPageRoute(builder: (context) => MeetScreen(call: call!)));
              print(
                  "Call successfully created or retrieved, checking state: ${call!.state.value.status.toStatusString()}");
              emit(CallCreatedState(call!));
            } else {
              emit(const CallErrorState("Failed to create or retrieve the call"));
            }
          });
        } else if (callState.status.isDisconnected) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Call is disconnected, please check connection...'),
            backgroundColor: CupertinoColors.destructiveRed,
          ));
          print("Call disconnected, attempting reconnection...");
          _attemptReconnection(context);
        } else if (callState.status.isIdle) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Call is in idle state, please check connection...'),
            backgroundColor: CupertinoColors.destructiveRed,
          ));
          print("Call is in idle state, attempting connection...");
          await StreamVideo.instance.connect().then((value) async {
            if (value.isSuccess) {
              print("Call successfully connected from idle state.");
              await call!.getOrCreate(memberIds: [teacherId, studentId ?? ""], video: true).then((value) {
                print("??>>>>>>>>>>>>>Call success: ${value.isSuccess}");
                if (value.isSuccess) {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => MeetScreen(call: call!)));
                  print(
                      "Call successfully created or retrieved, checking state: ${call!.state.value.status.toStatusString()}");
                  emit(CallCreatedState(call!));
                } else {
                  emit(const CallErrorState("Failed to create or retrieve the call"));
                }
              }).catchError((e, s) {
                print("??>>>>>>>>>>>>>Call failed: ${e.toString()}");
                print("??>>>>>>>>>>>>>Call StackTrace: ${s.toString()}");
                emit(const CallErrorState("Failed call"));
              });
            } else {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('Call could not connect from idle state.'),
                backgroundColor: CupertinoColors.destructiveRed,
              ));
            }
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Unexpected call state: ${callState.status.toStatusString()}'),
            backgroundColor: CupertinoColors.destructiveRed,
          ));
          _attemptReconnection(context);
          print("Unexpected call state: ${callState.status.toStatusString()}");
          emit(const CallErrorState("Closed or null!!!"));
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text('Something went wrong during the call initiation!')));
        }
      }, onError: (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error during call setup: $e')));
        emit(CallErrorState(e.toString()));
      });
    } catch (e, s) {
      print("Failed Call initial error: ${e.toString()}");
      print("Failed Call initial stack: ${s.toString()}");
      emit(CallErrorState(e.toString()));
    }
  }

  Future<void> _attemptReconnection(context) async {
    try {
      await call!.join();
      print("Reconnected to the call.");
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Reconnected to the call successfully.')));
    } catch (e) {
      print("Reconnection failed: $e");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to reconnect: $e')));
    }
  }
}
