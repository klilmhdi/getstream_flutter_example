import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:getstream_flutter_example/core/app/app_consumers.dart';
import 'package:getstream_flutter_example/core/di/injector.dart';
import 'package:getstream_flutter_example/core/utils/controllers/user_auth_controller.dart';
import 'package:getstream_flutter_example/core/utils/widgets.dart';
import 'package:getstream_flutter_example/features/data/services/firebase_services.dart';
import 'package:getstream_flutter_example/features/presentation/manage/auth/register/register_cubit.dart';
import 'package:getstream_flutter_example/features/presentation/manage/auth/register/register_state.dart';
import 'package:getstream_flutter_example/features/presentation/manage/call/call_cubit.dart';
import 'package:getstream_flutter_example/features/presentation/manage/fetch_users/fetch_users_cubit.dart';
import 'package:getstream_flutter_example/features/presentation/manage/meet/meet_cubit.dart';
import 'package:getstream_flutter_example/features/presentation/view/meet/incoming_call.dart';
import 'package:getstream_flutter_example/features/presentation/view/meet/outgoing_call.dart';
import 'package:stream_video_flutter/stream_video_flutter.dart';
import 'package:stream_video_flutter/stream_video_flutter_background.dart';

import '../meet/ready_to_start_screen.dart';

class TeacherScreen extends StatefulWidget {
  const TeacherScreen({super.key});

  @override
  State<TeacherScreen> createState() => _TeacherScreenState();
}

class _TeacherScreenState extends State<TeacherScreen> {
  @override
  void initState() {
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

  // _makeCall(BuildContext context, {required String studentName, required String studentId}) async {
  //   final teacherId = locator.get<UserAuthController>().currentUser?.id ?? '';
  //   final teacherName = locator.get<UserAuthController>().currentUser?.name ?? 'Teacher';
  //   final cubit = context.read<CallingsCubit>();
  //
  //   try {
  //     await cubit
  //         .initiateCall(context, teacherId, teacherName, studentId: studentId, studentName: studentName)
  //         .then((value) async {
  //       // Check the state's emitted after initiating the call
  //       if (cubit.state is CallCreatedState) {
  //         await cubit.createCall(context, teacherId, studentId, teacherName).then((value) {});
  //       } else {
  //         debugPrint('Call initiation failed with state: ${cubit.state}');
  //       }
  //     });
  //   } catch (e, stacktrace) {
  //     debugPrint('Error during _makeCall: $e');
  //     debugPrint('Stacktrace: $stacktrace');
  //   }
  // }

  @override
  void dispose() {
    AppConsumers().compositeSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final teacherId = context.read<RegisterCubit>().state is RegisterSuccessState
        ? (context.read<RegisterCubit>().state as RegisterSuccessState).user.id
        : FirebaseServices().auth.currentUser?.uid ?? "";

    final teacherName = locator<UserAuthController>().currentUser?.name.toString();

    print("?>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> Teacher name: $teacherName");
    print("?>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> Teacher ID: ${locator<UserAuthController>().currentUser?.id}");
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => CallingsCubit()..initiateCall(context, teacherId, teacherName)),
        BlocProvider(create: (context) => MeetingsCubit()..initiateMeet(context, teacherId, teacherName!)),
        BlocProvider(
            create: (context) => FetchUsersCubit()..fetchStudents()),
      ],
      child: BlocBuilder<CallingsCubit, CallingsState>(
        builder: (context, state) {
          if (state is SuccessSendCallToStudentState) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CustomOutgoingCallScreen(
                    call: state.call,
                    callState: state.callState,
                  ),
                ),
              );
            });
          } else if (state is FailedSendCallToStudentState) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Failed to send call: ${state.error}')),
              );
            });
          }
          return Scaffold(
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
                            final studentId = student['userId'];
                            final studentName = student['name'];

                            try {
                              // Initiate the call creation
                              await cubit
                                  .initiateCall(
                                context,
                                teacherId,
                                teacherName,
                                studentId: studentId,
                                studentName: studentName,
                              )
                                  .then((value) {
                                // Check the state for CallCreatedState
                                if (cubit.state is CallCreatedState) {
                                  final state = cubit.state as CallCreatedState;

                                  // Send call notification to the student
                                  cubit.sendCallToStudent(
                                    context,
                                    studentId,
                                    teacherName,
                                    state.call,
                                    state.callState,
                                  );
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
            floatingActionButton: BlocBuilder<MeetingsCubit, MeetingState>(
              builder: (context, state) {
                return FloatingActionButton(
                  child: const Icon(Icons.add),
                  onPressed: () async {
                    print(">>>>>>>>>>>>>>>>>>>>ID: ${teacherId.toString()}");
                    print(">>>>>>>>>>>>>>>>>>>>ID: ${FirebaseServices().auth.currentUser?.uid ?? "Emprty"}");
                    if (state is MeetingCreatedState) {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => ReadyToStartScreen(
                                  onJoinCallPressed: (_) =>
                                      context.read<MeetingsCubit>().joinMeet(context, state.meet.id),
                                  call: state.meet)));
                    } else if (state is MeetingErrorState) {
                      print("Failed Create call, ${state.message}");
                    }
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}
