import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:getstream_flutter_example/core/app/app_consumers.dart';
import 'package:getstream_flutter_example/core/di/injector.dart';
import 'package:getstream_flutter_example/core/utils/flutter_incoming_callkit.dart';
import 'package:getstream_flutter_example/features/presentation/manage/meet/meet_cubit.dart';
import 'package:getstream_flutter_example/features/presentation/view/meet/incoming_call.dart';
import 'package:stream_video_flutter/stream_video_flutter.dart';
import 'package:stream_video_flutter/stream_video_flutter_background.dart';

import '../../../../core/utils/controllers/user_auth_controller.dart';
import '../../../data/services/firebase_services.dart';
import '../../manage/call/call_cubit.dart';

// import 'package:getstream_flutter_example/features/presentation/view/meet/call_screen.dart';
// import 'package:flutter_callkit_incoming/entities/call_event.dart';
// import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
// import '../../../../core/utils/flutter_incoming_callkit.dart';
// import '../meet/incoming_call.dart';

class StudentScreen extends StatefulWidget {
  const StudentScreen({super.key});

  @override
  State<StudentScreen> createState() => _StudentScreenState();
}

class _StudentScreenState extends State<StudentScreen> {
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey = GlobalKey<RefreshIndicatorState>();
  final studentId = locator.get<UserAuthController>().currentUser?.id ?? FirebaseServices().auth.currentUser?.uid ?? "";
  final studentName = locator.get<UserAuthController>().currentUser?.name ?? "empty_student";

  @override
  void initState() {
    StreamBackgroundService.init(
      StreamVideo.instance,
      onButtonClick: (call, type, serviceType) async {
        switch (serviceType) {
          case ServiceType.call:
            call.reject();
            call.leave();
          case ServiceType.screenSharing:
            StreamVideoFlutterBackground.stopService(ServiceType.screenSharing);
            StreamVideoFlutterBackground.stopService(ServiceType.call);
            call.setScreenShareEnabled(enabled: false);
        }
      },
    );
    AppConsumers()
      ..observeCallKitEvents(context)
      ..initPushNotificationManagerIfAvailable(context)
      ..consumeIncomingCall(context);

    super.initState();
  }

  @override
  void dispose() {
    AppConsumers().compositeSubscription.cancel();
    context.read<CallingsCubit>().streamVideo.pushNotificationManager!.endAllCalls();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<CallingsCubit>(create: (context) => CallingsCubit()..listenForIncomingCalls(context, studentId)),
        BlocProvider<MeetingsCubit>(create: (context) => MeetingsCubit()..fetchActiveMeets()),
      ],
      child: BlocBuilder<CallingsCubit, CallingsState>(
        builder: (context, state) {
          if (state is IncomingCallState) {
            WidgetsBinding.instance.addPostFrameCallback((_) async {
              // return await CallKitServices().incomingCallFromTeacher(state.call.id, state.teacherName, state.teacherId);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CustomIncomingCallScreen(call: state.call),
                ),
              );
            });
          }
          return Scaffold(
            floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
            floatingActionButton: FloatingActionButton.small(
                onPressed: () => _refreshIndicatorKey.currentState
                    ?.show()
                    .then((_) => context.read<MeetingsCubit>()..fetchActiveMeets()),
                // onPressed: () => Navigator.push(
                //     context,
                //     MaterialPageRoute(
                //         builder: (context) => CustomIncomingCallScreen())),
                child: const Icon(Icons.refresh)),
            body: BlocBuilder<MeetingsCubit, MeetingState>(
              builder: (context, state) {
                if (state is ActiveMeetsLoadingState) {
                  return const Center(child: CircularProgressIndicator());
                } else if (state is ActiveMeetsFetchedState) {
                  final activeMeets = state.activeMeets;
                  if (activeMeets.isEmpty) {
                    return const Center(child: Text("No active calls found."));
                  }

                  return RefreshIndicator(
                    onRefresh: () async => context.read<MeetingsCubit>()..fetchActiveMeets(),
                    key: _refreshIndicatorKey,
                    child: ListView.builder(
                      itemCount: activeMeets.length,
                      itemBuilder: (context, index) {
                        if (index >= activeMeets.length) {
                          return const SizedBox.shrink();
                        }
                        final meet = activeMeets[index];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: meet.isActiveMeet ? CupertinoColors.activeGreen : Colors.red,
                            child: Text(
                              meet.meetID.isNotEmpty ? activeMeets[index].meetID[0].toUpperCase() : '?',
                              // Use '?' as a fallback
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          title: Text("Creator Name: ${meet.creatorName}"),
                          subtitle: Text("MeetID: ${meet.meetID.isNotEmpty ? meet.meetID : 'Unknown'}"),
                          // Fallback for empty meetID
                          trailing: meet.isActiveMeet
                              ? IconButton(
                                  icon: const Icon(Icons.meeting_room),
                                  onPressed: () {
                                    _showJoinCancelDialog(context, meet.meetID);
                                  },
                                  color: Colors.blue,
                                )
                              : const Icon(Icons.no_meeting_room, color: Colors.redAccent),
                        );
                      },
                    ),
                  );
                } else if (state is CallErrorState) {
                  return const Center(child: Text("No calls created yet"));
                } else {
                  return const Center(child: Text("No data available."));
                }
              },
            ),
          );
        },
      ),
    );
  }

  void _showJoinCancelDialog(BuildContext context, String callId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Join for: ${callId.toString()} Meeting"),
          content: const Text("Are you sure to join in this meeting?"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () => context.read<MeetingsCubit>().readyToStartMeet(context, callId, studentId, studentName),
              child: const Text("Join"),
            )
          ],
        );
      },
    );
  }
}
