import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:getstream_flutter_example/features/presentation/manage/call/call_cubit.dart';
import '../meet/meet_screen.dart';

class StudentScreen extends StatefulWidget {
  const StudentScreen({super.key});

  @override
  State<StudentScreen> createState() => _StudentScreenState();
}

class _StudentScreenState extends State<StudentScreen> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => CallingsCubit()..fetchActiveCalls(),
      child: Scaffold(
        floatingActionButton: FloatingActionButton.small(
          onPressed: () => context.read<CallingsCubit>().fetchActiveCalls(),
          child: const Icon(Icons.refresh),
        ),
        body: BlocBuilder<CallingsCubit, CallingsState>(
          builder: (context, state) {
            if (state is CallLoadingState) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is ActiveCallsFetchedState) {
              final activeCalls = state.activeCalls;
              if (activeCalls.isEmpty) {
                return const Center(child: Text("No active calls found."));
              }

              return ListView.builder(
                itemCount: activeCalls.length,
                itemBuilder: (context, index) {
                  final callData = activeCalls[index];
                  print(callData["callId"]);
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.deepPurple,
                      child: Text(
                        callData["teacherId"][0].toUpperCase(),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    title: Text("${callData["teacherName"]} (${callData["rule"].toString()})"),
                    trailing: IconButton(
                      icon: const Icon(Icons.meeting_room),
                      onPressed: () {
                        context.read<CallingsCubit>().joinMeet(context, callData["callId"]);
                      },
                      color: Colors.blue,
                    ),
                  );
                },
              );
            } else if (state is CallErrorState) {
              debugPrint("Error: ${state.message}");
              return Center(child: Text("Error: ${state.message}"));
            } else {
              return const Center(child: Text("No data available."));
            }
          },
        ),
      ),
    );
  }
}