import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:getstream_flutter_example/features/data/services/firebase_services.dart';
import 'package:getstream_flutter_example/features/presentation/manage/auth/register/register_cubit.dart';
import 'package:getstream_flutter_example/features/presentation/manage/auth/register/register_state.dart';
import 'package:getstream_flutter_example/features/presentation/manage/call/call_cubit.dart';
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

    return BlocProvider(
      create: (context) => CallingsCubit()..initiateCall(context, teacherId),
      child: BlocBuilder<CallingsCubit, CallingsState>(
        builder: (context, state) => Scaffold(
          body: const Center(
              child: Text("Let's to create a call", style: TextStyle(color: CupertinoColors.black, fontSize: 40))),
          floatingActionButton: FloatingActionButton(
            child: const Icon(Icons.add),
            onPressed: () async {
              print(">>>>>>>>>>>>>>>>>>>>ID: ${teacherId.toString()}");
              print(">>>>>>>>>>>>>>>>>>>>ID: ${FirebaseServices().auth.currentUser?.uid ?? "Emprty"}");
                if (state is CallCreatedState) {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => ReadyToStartScreen(
                              onJoinCallPressed: (_) => context.read<CallingsCubit>().joinMeet(context, state.call.id),
                              call: state.call)));
                } else if (state is CallErrorState) {
                  print("Failed Create call, ${state.message}");
                }
            },
          ),
        ),
      ),
    );
  }
}
