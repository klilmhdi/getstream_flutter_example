import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:getstream_flutter_example/core/app/app_consumers.dart';
import 'package:getstream_flutter_example/core/di/injector.dart';
import 'package:getstream_flutter_example/core/utils/controllers/user_auth_controller.dart';
import 'package:getstream_flutter_example/features/data/services/firebase_services.dart';
import 'package:getstream_flutter_example/features/presentation/manage/audio_room/audio_room_cubit.dart';
import 'package:getstream_flutter_example/features/presentation/manage/auth/register/register_cubit.dart';
import 'package:getstream_flutter_example/features/presentation/manage/auth/register/register_state.dart';
import 'package:getstream_flutter_example/features/presentation/manage/call/call_cubit.dart';
import 'package:getstream_flutter_example/features/presentation/manage/fetch_users/fetch_users_cubit.dart';
import 'package:getstream_flutter_example/features/presentation/manage/live_stream/live_stream_cubit.dart';
import 'package:getstream_flutter_example/features/presentation/manage/meet/meet_cubit.dart';
import 'package:getstream_flutter_example/features/presentation/view/getstream_service/calling/call_screen.dart';
import 'package:stream_video_flutter/stream_video_flutter.dart';
import 'package:stream_video_flutter/stream_video_flutter_background.dart';

import '../auth/signin.dart';

class TeacherScreen extends StatefulWidget {
  const TeacherScreen({super.key});

  @override
  State<TeacherScreen> createState() => _TeacherScreenState();
}

class _TeacherScreenState extends State<TeacherScreen> {
  late final _userAuthController;

  @override
  void initState() {
    _userAuthController = locator.get<UserAuthController>();
    StreamBackgroundService.init(
      StreamVideo.instance,
      onButtonClick: (call, type, serviceType) async {
        switch (serviceType) {
          case ServiceType.call:
            call.reject();
            call.end();
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
    // CallingsCubit().close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final teacherId = context.read<RegisterCubit>().state is RegisterSuccessState
        ? (context.read<RegisterCubit>().state as RegisterSuccessState).user.id
        : FirebaseServices().auth.currentUser?.uid ?? "";

    final teacherName = locator<UserAuthController>().currentUser?.name.toString();
    final currentUser = _userAuthController.currentUser;
    print(">>>>>>>>>>>>>Current User: $currentUser");
    print("?>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> Teacher name: $teacherName");
    print("?>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> Teacher ID: ${locator<UserAuthController>().currentUser?.id}");
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => CallingsCubit()),
        BlocProvider(create: (context) => LiveStreamCubit()),
        BlocProvider(create: (context) => MeetingsCubit()),
        BlocProvider(create: (context) => AudioRoomCubit()),
        BlocProvider(create: (context) => FetchUsersCubit()..fetchStudents()),
      ],
      child: BlocBuilder<CallingsCubit, CallingsState>(
        builder: (context, state) {
          if (state is FailedSendCallToStudentState) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Failed to send call: ${state.error}')),
              );
            });
          }
          return Scaffold(
            appBar: AppBar(
              elevation: 0,
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              leading: Padding(
                padding: const EdgeInsets.all(4.0),
                child: ClipOval(
                  child: FadeInImage(
                    image: NetworkImage(currentUser?.image ?? "images"),
                    placeholder: const AssetImage('assets/ic_launcher_foreground.png'),
                    imageErrorBuilder: (context, error, stackTrace) {
                      return const Icon(Icons.supervised_user_circle_sharp);
                    },
                    fit: BoxFit.cover,
                    width: 80,
                    height: 80,
                  ),
                ),
              ),
              titleSpacing: 4,
              centerTitle: false,
              title: Text(
                currentUser?.name ?? "Empty Name",
                style: const TextStyle(fontSize: 25, color: CupertinoColors.black),
              ),
              actions: [
                BlocBuilder<LiveStreamCubit, LiveStreamState>(
                  builder: (context, state) => IconButton(
                    icon: const Icon(Icons.live_tv),
                    onPressed: () async =>
                        context.read<LiveStreamCubit>().initiateLiveStream(context, teacherId, teacherName!),
                  ),
                ),
                BlocBuilder<MeetingsCubit, MeetingState>(
                  builder: (context, state) => IconButton(
                    icon: const Icon(Icons.video_call),
                    onPressed: () async => context.read<MeetingsCubit>().initiateMeet(context, teacherId, teacherName!),
                  ),
                ),
                BlocBuilder<AudioRoomCubit, AudioRoomState>(
                  builder: (context, state) => IconButton(
                    icon: const Icon(Icons.multitrack_audio),
                    onPressed: () async {},
                  ),
                ),
              ],
            ),
            body: BlocBuilder<FetchUsersCubit, FetchUsersState>(
              builder: (context, state) {
                if (state is LoadingStudentFetchState) {
                  return const Center(child: CircularProgressIndicator());
                } else if (state is SuccessStudentFetchState) {
                  final students = state.students;
                  if (students.isEmpty) {
                    return const Center(child: Text('There is not any students register yet!!'));
                  }
                  return ListView.builder(
                    itemCount: students.length,
                    itemBuilder: (context, index) {
                      final student = students[index];
                      return ListTile(
                        // leading: Icon(Icons.person,
                        //     color: student['isActiveUser'] == true ? CupertinoColors.activeGreen : Colors.redAccent),
                        leading: CircleAvatar(
                          backgroundColor: student['isActiveUser'] ? CupertinoColors.activeGreen : Colors.red,
                          child: Text(
                            student['userId'].toString().isNotEmpty ? student['userId'][0].toUpperCase() : '?',
                            // Use '?' as a fallback
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),

                        title: Text("${student['name']}"),
                        subtitle: Text(student['email'] ?? 'No Email'),
                        trailing: IconButton(
                          icon: const Icon(Icons.call),
                          onPressed: () async {
                            final cubit = context.read<CallingsCubit>();

                            final teacherId = locator.get<UserAuthController>().currentUser?.id ?? '';
                            final teacherName = locator.get<UserAuthController>().currentUser?.name ?? 'Teacher';
                            final teacherImage = locator.get<UserAuthController>().currentUser?.image ?? '';
                            final studentId = student['userId'];
                            final studentName = student['name'];

                            try {
                              await cubit
                                  .initiateCall(context, teacherId, teacherName, teacherImage,
                                      studentId: studentId, studentName: studentName)
                                  .then((value) {
                                if (cubit.state is CallCreatedState) {
                                  debugPrint("Call initiation Success");

                                  final state = cubit.state as CallCreatedState;
                                  cubit.sendCallToStudent(context, studentId, studentName, teacherName, teacherId,
                                      teacherImage, state.call, state.callState);
                                  final result = Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => CallScreen(call: state.call),
                                    ),
                                  );

                                  // Refresh the screen when the call ends
                                  if (result == true) {
                                    context.read<FetchUsersCubit>().fetchStudents();
                                  }
                                } else {
                                  debugPrint("Call initiation failed with state: ${cubit.state}");
                                }
                              });
                            } catch (e, stacktrace) {
                              debugPrint("Error during call initiation: $e");
                              debugPrint("Stacktrace: $stacktrace");
                            }
                          },
                        ),
                      );
                    },
                  );
                } else if (state is FailedStudentFetchState) {
                  return Center(child: Text('Error: ${state.message}'));
                } else {
                  return const Center(child: Text('No Data avaliable!'));
                }
              },
            ),
            floatingActionButton: FloatingActionButton.small(
              onPressed: () async => await FirebaseServices().logout().then((value) => locator
                  .get<UserAuthController>()
                  .logout()
                  .then((value) =>
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const RegisterScreen())))),
              child: const Icon(Icons.logout, color: Colors.redAccent),
            ),
          );
        },
      ),
    );
  }
}
