import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:getstream_flutter_example/core/app/app_consumers.dart';
import 'package:getstream_flutter_example/core/di/injector.dart';
import 'package:getstream_flutter_example/core/utils/consts/functions.dart';
import 'package:getstream_flutter_example/core/utils/controllers/user_auth_controller.dart';
import 'package:getstream_flutter_example/core/utils/widgets.dart';
import 'package:getstream_flutter_example/features/data/models/meetings_model.dart';
import 'package:getstream_flutter_example/features/data/services/firebase_services.dart';
import 'package:getstream_flutter_example/features/presentation/view/getstream_service/meeting/meet_screen.dart';
import 'package:stream_video_flutter/stream_video_flutter.dart';

import '../../view/home/layout.dart';
import '../../view/getstream_service/meeting/ready_to_start_screen.dart';

part 'meet_state.dart';

class MeetingsCubit extends Cubit<MeetingState> {
  MeetingsCubit() : super(MeetInitial());

  static MeetingsCubit get(context) => BlocProvider.of(context, listen: false);
  final streamVideo = locator.get<StreamVideo>();

  /// Basic function to (create / make) a  meet in general
  Call _makeMeet(meetId) => locator.get<StreamVideo>().makeCall(callType: StreamCallType.defaultType(), id: meetId);

  /// Teacher settings
  // 1- initial meet
  Future<void> initiateMeet(BuildContext context, String teacherId, String teacherName) async {
    emit(MeetingLoadingState());
    try {
      final meet = _makeMeet(generateCallId(8));
      await meet.getOrCreate(ringing: false, video: true).then((value) {
        if (value.isSuccess) {
          final meeting = MeetingModel(
            meetID: meet.id,
            creatorID: teacherId,
            creatorName: teacherName,
            receiverID: "",
            receiverName: "",
            isActiveMeet: true,
            startMeetAt: DateTime.now(),
            meetDuration: Duration.zero
          );
          FirebaseServices().uploadMeetDataToFirebase(meeting).then((value) {
            debugPrint("________________________ Success to upload to firebase ________________________");
          },).catchError((error, StackTrace stk){
            debugPrint("________________________ Failed to upload to firebase ${error.toString()} ________________________");
            debugPrint("________________________ Failed to upload to firebase ${stk.toString()} ________________________");
          });
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => ReadyToStartScreen(
                      onJoinCallPressed: (_) => context.read<MeetingsCubit>().joinMeet(context, meet.id), call: meet)));
          if (!isClosed) emit(MeetingCreatedState(meet: meet));
        } else if (meet.state.value.status.isIdle) {
          debugPrint("Meeting Status: ${meet.state.value.status}");
          if (!isClosed) emit(const MeetingErrorState("Meeting is IDLE"));
        } else {
          debugPrint("Meeting failed: ${meet.state.value.status}");
          if (!isClosed) emit(const MeetingErrorState("Call is failed"));
        }
      }).catchError((onError) {
        debugPrint('Error joining or creating Meeting: $onError');
        if (!isClosed) emit(const MeetingErrorState("Catch Error"));
      }).onError((e, stk) {
        debugPrint('Error joining or creating Meeting: $e');
        debugPrint("Error joining or creating Meeting: ${stk.toString()}");
        if (!isClosed) emit(const MeetingErrorState("On Error"));
      });
    } catch (e, s) {
      debugPrint("Meeting initiation error: ${e.toString()}");
      debugPrint("Stack trace: ${s.toString()}");
      if (!isClosed) emit(MeetingErrorState("Failed to initiate Meeting: ${s.toString()}"));
    }
  }

  // 2- join to meet
  Future<void> joinMeet(BuildContext context, callId, {CallConnectOptions? connectOptions}) async {
    if (!isClosed) emit(MeetingLoadingState());

    final call = _makeMeet(callId);
    try {
      await checkAndRequestPermissions(context).then((value) async {
        await call.join(connectOptions: connectOptions).then((_) {
          if (context.mounted) {
            if (!isClosed) emit(MeetingJoinedState(call: call, connectOptions: connectOptions!));
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
      if (!isClosed) emit(MeetingErrorState(e.toString()));
    }
  }

  // 3- in lobby screen (navigate for ready to start screen)
  Future<void> readyToStartMeet(BuildContext context, String meetId, String studentId, String studentName) async {
    emit(MeetingLoadingState());
    final call = _makeMeet(meetId);
    try {
      FirebaseServices().firestore.collection("meets").doc(meetId).update({
        'receiverID': studentId,
        'receiverName': studentName,
      }).then((_) {
        print("Firestore updated successfully for call ID: $meetId");
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ReadyToStartScreen(
              onJoinCallPressed: (_) => context.read<MeetingsCubit>().joinMeet(context, meetId),
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
      if (!isClosed) emit(MeetingErrorState(e.toString()));
    }
  }

  // 4- End the meeting
  Future<void> endMeet(context, Call call, String meetId) async {
    final isAdmin = locator.get<UserAuthController>().currentUser!.role == 'admin';
    try {
      AppConsumers().compositeSubscription.cancel();
      streamVideo.pushNotificationManager!.endAllCalls();
      streamVideo.pushNotificationManager!.dispose();
      if (isAdmin) {
        _endMeetFromTeacher(context, meetId, call);
        if (!isClosed) emit(MeetingEndedState(meetId: meetId, duration: const Duration(minutes: 60)));
      } else {
        _leaveMeetForStudent(context, meetId, call);
        if (!isClosed) (StudentLeavedMeetState());
      }
    } catch (e) {
      print("Error end call: $e");
    }
  }

  // 5- end meet via set isActive to false
  Future<void> _endMeetFromTeacher(BuildContext context, String meetId, Call call) async {
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
      if (!isClosed) emit(MeetingEndedState(meetId: meetId, duration: const Duration(minutes: 60)));
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
      if (!isClosed) emit(MeetingErrorState("Failed to end meet: $e"));
    }
  }

  // 6- reject the meet from teacher in ready to start screen
  Future<void> rejectMeetFromTeacher(BuildContext context, String meetId, Call call) async {
    try {
      await call.leave();
      await call.end();

      await FirebaseServices().firestore.collection("meets").doc(meetId).update({
        'creatorID': '',
        'isActiveMeet': false,
        'receiverID': '',
        'receiverName': '',
      }).then(
        (value) async {
          print("?>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>The value is set false");
          showSuccessSnackBar("Change values success", 3, context);
          await Navigator.maybePop(context);
          if (!isClosed) emit(MeetingEndedState(meetId: meetId, duration: const Duration(minutes: 0)));
        },
      );
      print("?>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>End call and change the active meets to false success");
    } catch (e) {
      if (!isClosed) emit(MeetingErrorState("Failed to end meet: $e"));
    }
  }

  /// Student settings
  // 1- fetch active meets
  Future<void> fetchActiveMeets() async {
    if (!isClosed) emit(ActiveMeetsLoadingState());
    try {
      final querySnapshot = await FirebaseFirestore.instance.collection("meets").get();

      final activeMeets = querySnapshot.docs.map((doc) {
        return MeetingModel.fromMap(doc.data());
      }).toList();
      if (!isClosed) emit(ActiveMeetsFetchedState(activeMeets: activeMeets));
    } catch (e) {
      if (!isClosed) emit(MeetingErrorState("Failed to fetch active meets: ${e.toString()}"));
    }
  }

  // 2- leave meet in student side
  Future<void> _leaveMeetForStudent(context, String meetId, Call call) async {
    try {
      // final docSnapshot = await FirebaseServices().firestore.collection("meets").doc(meetId).get();

      // if (docSnapshot.exists) {
      //   final data = docSnapshot.data();
        // final isActiveMeet = data?['isActiveMeet'] ?? true;

        // print(">>>>>>>>????????>>>>>>>>>>??????????>>>>>>>>>>>>>>?????????????>>>>>>>???????>>>>>$isActiveMeet");
        // if (isActiveMeet == false && call.state.value.status.isActive) {
        //   print("Teacher has already ended the meet. Ending the call for the student.");
        //   await call.leave();
        // } else {
          print("Teacher has not ended the meet. Student will leave the call.");
          await call.leave();
          await FirebaseServices().firestore.collection("meets").doc(meetId).update({
            'receiverID': '',
            'receiverName': '',
          });
        // }
        Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const Layout(type: 'Student')),
          (route) => false,
        );
      // }
    } catch (e) {
      if (!isClosed) emit(MeetingErrorState("Failed to leave meet: $e"));
    }
  }
}
