import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:getstream_flutter_example/core/di/injector.dart';
import 'package:getstream_flutter_example/core/utils/widgets.dart';
import 'package:getstream_flutter_example/features/data/models/live_stream_model.dart';
import 'package:getstream_flutter_example/features/data/services/firebase_services.dart';
import 'package:getstream_flutter_example/features/presentation/view/getstream_service/livestream/live_steam_screen.dart';
import 'package:getstream_flutter_example/features/presentation/view/getstream_service/livestream/watch_live_stream_screen.dart';
import 'package:stream_video_flutter/stream_video_flutter.dart';

import '../../../../core/utils/consts/functions.dart';
import '../../../../core/utils/controllers/user_auth_controller.dart';
import '../../view/home/layout.dart';

part 'live_stream_state.dart';

class LiveStreamCubit extends Cubit<LiveStreamState> {
  LiveStreamCubit() : super(LiveStreamInitial());

  static LiveStreamCubit get(context) => BlocProvider.of(context, listen: false);

  final liveStreamType = StreamCallType.liveStream();
  final streamVideo = locator.get<StreamVideo>();
  Call? initLiveStream;

  // RtcLocalAudioTrack? _microphoneTrack;
  // RtcLocalCameraTrack? _cameraTrack;

  /// Basic function to (create / make) a livestream in general
  Call _makeLiveStream(String liveId) =>
      initLiveStream = locator.get<StreamVideo>().makeCall(callType: liveStreamType, id: liveId);

  // Initial live stream from teacher
  Future<void> initiateLiveStream(BuildContext context, String teacherId, String teacherName) async {
    if (!isClosed)  emit(LoadingInitLiveStreamState());
    if (teacherId.isEmpty) {
      debugPrint('*************** Teacher or student ID is missing.');
      if (!isClosed) emit(const LiveStreamErrorMessageState('Invalid member IDs.'));
      return;
    }
    try {
      final liveStreamId = generateCallId(5);
      final liveStream = _makeLiveStream(liveStreamId);

      liveStream.connectOptions = CallConnectOptions(
        camera: TrackOption.enabled(),
        microphone: TrackOption.enabled(),
      );
      checkAndRequestPermissions(context).then((value) async {
        await liveStream.getOrCreate(video: true).then((value) async {
          debugPrint("LiveStream state after creation: ${liveStream.state.value.status}");
          debugPrint("?>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>LiveStreamId: ${liveStream.id}");
          debugPrint("LiveStream session ID: ${liveStream.state.value.sessionId}");
          if (value.isSuccess) {
            debugPrint(">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>LiveStream successfully connected!");
            await liveStream.join();
            await liveStream.goLive();
            final living = LiveStreamModel(
              id: liveStreamId,
              title: 'New Live Stream: ${generateCallId(2)}',
              creatorId: teacherId,
              creatorName: teacherName,
              startTime: DateTime.now(),
            );
            FirebaseServices().uploadLiveStreamDataToFirebase(living);
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Navigator.push(
                  context, MaterialPageRoute(builder: (context) => LiveStreamScreen(livestreamCall: liveStream)));
            });

            if (!isClosed) emit(SuccessInitLiveStreamState(liveStream));
          } else if (liveStream.state.value.status.isIdle) {
            debugPrint(">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>Call Status: ${liveStream.state.value.status}");
            if (!isClosed)  emit(const FailedInitLiveStreamState("Call is IDLE"));
          } else if (value.isFailure) {
            debugPrint(">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>LiveStream failed: ${liveStream.state.value.status}");
            if (!isClosed) emit(const FailedInitLiveStreamState("LiveStream is failed"));
          }
        }).catchError((onError, stackTrace) {
          debugPrint('*>>>>>>>>>>>>>>>>>>>>>>>>>>>>on catch error Error joining or creating LiveStream: $onError');
          debugPrint('*>>>>>>>>>>>>>>>>>>>>>>>>>>>>on catch error Error joining or creating LiveStream: $stackTrace');
          if (!isClosed) emit(const LiveStreamErrorMessageState("Catch Error"));
        }).onError((e, stk) {
          debugPrint('>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>on error Error joining or creating LiveStream: $e');
          debugPrint(">>>>>>>>>>>>>>>>>>>on error Error joining or creating LiveStream: ${stk.toString()}");
          if (!isClosed) emit(const LiveStreamErrorMessageState("On Error"));
        });
      });
    } catch (e, s) {
      debugPrint(">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>on catch LiveStream initiation error: ${e.toString()}");
      debugPrint(">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>on catch Stack trace: ${s.toString()}");
      if (!isClosed) emit(LiveStreamErrorMessageState("Failed to initiate LiveStream: ${s.toString()}"));
    }
  }

  // Join to live stream
  Future<void> joinLiveStream(BuildContext context, String liveStreamId, {CallConnectOptions? connectOptions}) async {
    if (!isClosed) emit(LoadingJoinLiveStreamState());

    try {
      final liveStream = _makeLiveStream(liveStreamId);
      await checkAndRequestPermissions(context).then((value) async {
        await liveStream.join(connectOptions: connectOptions).then((_) {
          if (context.mounted) {
            Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => WatchLivestreamScreen(livestreamCall: liveStream)),
                (route) => false);
            if (!isClosed)  emit(SuccessJoinLiveStreamState(liveStream: liveStream, connectOptions: connectOptions!));
          }
        }).catchError((e, StackTrace s) {
          debugPrint("Failed to join call: ${e.toString()}");
          debugPrint("Stack trace: ${s.toString()}");
          if (!isClosed) emit(FailedJoinLiveStreamState(e.toString()));
        });
      });
    } catch (e, s) {
      debugPrint("************************* Failed to join call: ${e.toString()}");
      debugPrint("Stack trace: ${s.toString()}");
      if (!isClosed) emit(LiveStreamErrorMessageState(e.toString()));
    }
  }

  // fetch all live streams from firebase
  Future<void> fetchActiveLiveStreams() async {
    if (!isClosed) emit(LoadingFetchingLiveStreamState());
    try {
      final querySnapshot = await FirebaseFirestore.instance.collection("livestreams").get();

      final activeLiveStreams = querySnapshot.docs.map((doc) {
        return LiveStreamModel.fromMap(doc.data());
      }).toList();

      if (!isClosed) emit(SuccessFetchingLiveStreamState(activeLiveStreams: activeLiveStreams));
    } catch (e, s) {
      debugPrint("************************* Failed to fetch live stream: ${e.toString()}");
      debugPrint("Stack trace: ${s.toString()}");
      if (!isClosed) emit(LiveStreamErrorMessageState("****** Failed to fetch active live stream: ${e.toString()}"));
    }
  }

  // End the live stream
  Future<void> endLiveStream(
    Call livestreamCall,
    BuildContext context,
  ) async {
    final userAuthController = locator.get<UserAuthController>();
    if (!isClosed) emit(LoadingEndLiveStreamState());
    try {
      if (livestreamCall.state.value.status.isDisconnected) {
        if (!isClosed) emit(const LiveStreamErrorMessageState("Call already ended."));
        return;
      }
      livestreamCall.stopLive().then((value) async {
        await livestreamCall.end();
        // await streamVideo.dispose();
        await FirebaseServices().firestore.collection("livestreams").doc(livestreamCall.id).update({
          'isLive': false,
          'subscriptionsId': [],
          'subscriptionsName': [],
        });
        if (!isClosed) emit(SuccessEndLiveStreamState());
        showSuccessSnackBar("Live stream finished successfully!", 4, context);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                  builder: (context) =>
                      Layout(type: userAuthController.currentUser?.role == 'admin' ? "Teacher" : 'Student')),
              (route) => false);
        });
      }).catchError((e, s) {
        debugPrint("Failed to end live stream: ${e.toString()}");
        debugPrint("Stack trace: ${s.toString()}");
        if (!isClosed) emit(FailedEndLiveStreamState("Failed to end live stream: ${e.toString()}"));
      });
    } catch (e, s) {
      debugPrint("************************* Failed to end live stream: ${e.toString()}");
      debugPrint("Stack trace: ${s.toString()}");
      if (!isClosed)
        (LiveStreamErrorMessageState("************************* Failed to end live stream: ${e.toString()}"));
    }
  }

  // Leave live stream
  Future<void> leaveLiveStream(Call livestreamCall, BuildContext context) async {
    if (!isClosed) emit(LoadingLeaveLiveStreamState());
    try {
      if (livestreamCall.state.value.status.isDisconnected) {
        if (!isClosed) emit(const LiveStreamErrorMessageState("Call already ended."));
        return;
      }
      livestreamCall.leave().then((value) async {
        // livestreamCall.end();
        // await FirebaseServices().firestore.collection("livestreams").doc(livestreamCall.id).update({});
        showSuccessSnackBar("Live stream leaved successfully!", 4, context);
        if (!isClosed) emit(SuccessLeaveLiveStreamState());
        Navigator.pushAndRemoveUntil(
            context, MaterialPageRoute(builder: (context) => const Layout(type: 'Student')), (route) => false);
      }).catchError((e, s) {
        debugPrint("Failed to leave live stream: ${e.toString()}");
        debugPrint("Stack trace: ${s.toString()}");
        if (!isClosed) emit(FailedLeaveLiveStreamState("Failed to leave live stream: ${e.toString()}"));
      });
    } catch (e, s) {
      debugPrint("************************* Failed to leave live stream: ${e.toString()}");
      debugPrint("Stack trace: ${s.toString()}");
      if (!isClosed)
        emit(LiveStreamErrorMessageState("************************* Failed to leave live stream: ${e.toString()}"));
    }
  }
}
