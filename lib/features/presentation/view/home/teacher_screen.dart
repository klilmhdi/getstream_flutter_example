import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:getstream_flutter_example/core/di/injector.dart';
import 'package:getstream_flutter_example/core/utils/controllers/user_auth_controller.dart';
import 'package:getstream_flutter_example/features/data/services/firebase_services.dart';
import 'package:getstream_flutter_example/features/presentation/manage/auth/register/register_cubit.dart';
import 'package:getstream_flutter_example/features/presentation/manage/auth/register/register_state.dart';
import 'package:getstream_flutter_example/features/presentation/manage/call/call_cubit.dart';
import 'package:getstream_flutter_example/features/presentation/manage/fetch_users/fetch_users_cubit.dart';
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
            call.leave();
          case ServiceType.screenSharing:
            StreamVideoFlutterBackground.stopService(ServiceType.screenSharing);
            call.setScreenShareEnabled(enabled: false);
        }
      },
    );

    super.initState();
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
        BlocProvider(
          create: (context) => CallingsCubit()..initiateMeet(context, teacherId, teacherName!),
        ),
        BlocProvider(
          create: (context) =>
              FetchUsersCubit(firestore: FirebaseServices().firestore, auth: FirebaseServices().auth)..fetchStudents(),
        ),
      ],
      child: BlocBuilder<CallingsCubit, CallingsState>(
        builder: (context, state) {
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
                        leading: Icon(Icons.person,
                            color: student['isActiveUser'] == true ? CupertinoColors.activeGreen : Colors.redAccent),
                        title: Text("${student['name']}"),
                        subtitle: Text(student['email'] ?? 'No Email'),
                        trailing: IconButton(
                          icon: const Icon(Icons.call),
                          onPressed: () {
                            // _makeCall(context, student['name']);
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
            floatingActionButton: FloatingActionButton(
              child: const Icon(Icons.add),
              onPressed: () async {
                print(">>>>>>>>>>>>>>>>>>>>ID: ${teacherId.toString()}");
                print(">>>>>>>>>>>>>>>>>>>>ID: ${FirebaseServices().auth.currentUser?.uid ?? "Emprty"}");
                if (state is MeetingCreatedState) {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => ReadyToStartScreen(
                              onJoinCallPressed: (_) => context.read<CallingsCubit>().joinMeet(context, state.meet.id),
                              call: state.meet)));
                } else if (state is MeetingErrorState) {
                  print("Failed Create call, ${state.message}");
                }
              },
            ),
          );
        },
      ),
    );
  }
}
