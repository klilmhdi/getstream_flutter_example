import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:getstream_flutter_example/features/presentation/manage/call/call_cubit.dart';
import 'package:getstream_flutter_example/features/presentation/view/meet/ready_to_start_screen.dart';
import '../../../data/services/firebase_services.dart';
import '../meet/meet_screen.dart';

class StudentScreen extends StatefulWidget {
  const StudentScreen({super.key});

  @override
  State<StudentScreen> createState() => _StudentScreenState();
}

class _StudentScreenState extends State<StudentScreen> {
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey = GlobalKey<RefreshIndicatorState>();

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => CallingsCubit()..fetchActiveCalls(),
      child: Scaffold(
        floatingActionButton: FloatingActionButton.small(
          onPressed: () =>
              _refreshIndicatorKey.currentState?.show().then((_) => context.read<CallingsCubit>().fetchActiveCalls()),
          child: const Icon(Icons.refresh),
        ),
        body: RefreshIndicator(
          key: _refreshIndicatorKey,
          onRefresh: () async {
            await Future.delayed(const Duration(milliseconds: 300))
                .then((_) => context.read<CallingsCubit>().fetchActiveCalls());
          },
          child: BlocBuilder<CallingsCubit, CallingsState>(
            builder: (context, state) {
              if (state is ActiveCallsLoadingState) {
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
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: callData["isActive"] == true ? CupertinoColors.activeGreen : Colors.deepPurple,
                        child: Text(
                          callData["callId"][0].toUpperCase(),
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      title: Text("CallID: ${callData["callId"]}"),
                      trailing: callData["isActive"] == true
                          ? IconButton(
                              icon: const Icon(Icons.meeting_room),
                              onPressed: () {
                                _showJoinCancelDialog(context, callData["callId"]);
                              },
                              color: Colors.blue,
                            )
                          : const SizedBox.shrink(),
                    );
                  },
                );
              } else if (state is CallErrorState) {
                return const Center(child: Text("No calls created yet"));
              } else {
                return const Center(child: Text("No data available."));
              }
            },
          ),
        ),
      ),
    );
  }

  void _showJoinCancelDialog(BuildContext context, String callId) {
    final studentId = FirebaseServices().auth.currentUser?.uid ?? "empty_student";

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
              onPressed: () => context.read<CallingsCubit>().readyToStartMeet(context, callId, studentId),
              child: const Text("Join"),
            )
          ],
        );
      },
    );
  }
}

// class StudentScreen extends StatefulWidget {
//   const StudentScreen({super.key});
//
//   @override
//   State<StudentScreen> createState() => _StudentScreenState();
// }
//
// class _StudentScreenState extends State<StudentScreen> {
//   @override
//   void initState() {
//     super.initState();
//   }
//
//   final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey = GlobalKey<RefreshIndicatorState>();
//
//   @override
//   Widget build(BuildContext context) {
//     return BlocProvider(
//       create: (context) =>
//       CallingsCubit()
//         ..fetchActiveCalls(),
//       child: Scaffold(
//         floatingActionButton: FloatingActionButton.small(
//           onPressed: () =>
//               _refreshIndicatorKey.currentState?.show().then((_) => context.read<CallingsCubit>()..fetchActiveCalls()),
//           child: const Icon(Icons.refresh),
//         ),
//         body: RefreshIndicator(
//           key: _refreshIndicatorKey,
//           onRefresh: () async {
//             await Future.delayed(const Duration(milliseconds: 300)).then((_) =>
//                 _refreshIndicatorKey.currentState?.show().then((_) =>
//                     context.read<CallingsCubit>().fetchActiveCalls()));
//           },
//           child: BlocConsumer<CallingsCubit, CallingsState>(
//             listener: (context, state) {
//
//             },
//             builder: (context, state) {
//               if (state is ActiveCallsLoadingState) {
//                 return const Center(child: CircularProgressIndicator());
//               } else if (state is ActiveCallsFetchedState) {
//                 final activeCalls = state.activeCalls;
//                 if (activeCalls.isEmpty) {
//                   return const Center(child: Text("No active calls found."));
//                 }
//
//                 return ListView.builder(
//                   itemCount: activeCalls.length,
//                   itemBuilder: (context, index) {
//                     final callData = activeCalls[index];
//                     return ListTile(
//                       leading: CircleAvatar(
//                         backgroundColor: Colors.deepPurple,
//                         child: Text(
//                           callData["teacherId"][0].toUpperCase(),
//                           style: const TextStyle(color: Colors.white),
//                         ),
//                       ),
//                       // title: Text("${callData["teacherName"]} (${callData["rule"].toString()})"),
//                       title: Text("CallID: ${callData["callId"]}"),
//                       trailing: IconButton(
//                         icon: const Icon(Icons.meeting_room),
//                         onPressed: () {
//                           _showJoinCancelDialog(context, callData["callId"]);
//                         },
//                         color: Colors.blue,
//                       ),
//                     );
//                   },
//                 );
//               } else if (state is CallErrorState) {
//                 return const Center(child: Text("No calls created yet"));
//               } else {
//                 return const Center(child: Text("No data available."));
//               }
//             },
//           ),
//         ),
//       ),
//     );
//   }
//
//   // void showJoinCancelDialog(BuildContext context, String callId) {
//   //   showDialog(
//   //     context: context,
//   //     builder: (BuildContext context) {
//   //       return AlertDialog(
//   //         title: Text("Join for: ${callId.toString()} Meeting"),
//   //         content: const Text("Are you sure to join in this meeting?"),
//   //         actions: [
//   //           TextButton(
//   //             onPressed: () {
//   //               Navigator.of(context).pop();
//   //             },
//   //             child: const Text("Cancel"),
//   //           ),
//   //           BlocBuilder<CallingsCubit, CallingsState>(
//   //             builder: (context, state) {
//   //               return ElevatedButton(
//   //                 onPressed: () {
//   //                   if (state is CallJoinedState) {
//   //                     // context.read<CallingsCubit>().joinMeet(context, callId);
//   //                     // Navigator.of(context).pop();
//   //                     Navigator.push(
//   //                       context,
//   //                       MaterialPageRoute(
//   //                         builder: (context) => ReadyToStartScreen(
//   //                           onJoinCallPressed: (_) => context.read<CallingsCubit>().joinMeet(context, state.call.id),
//   //                           call: state.call,
//   //                         ),
//   //                       ),
//   //                     );
//   //                   } else {
//   //                     ScaffoldMessenger.of(context).showSnackBar(
//   //                       const SnackBar(
//   //                         content: Text("The call does not active yet!"),
//   //                         backgroundColor: CupertinoColors.destructiveRed,
//   //                       ),
//   //                     );
//   //                     Navigator.of(context).pop();
//   //                   }
//   //                 },
//   //                 child: const Text("Join"),
//   //               );
//   //             },
//   //           ),
//   //         ],
//   //       );
//   //     },
//   //   );
//   // }
//   void _showJoinCancelDialog(BuildContext context, String callId) {
//     showDialog(
//       context: context,
//       builder: (BuildContext context) {
//         return AlertDialog(
//           title: Text("Join Meeting: $callId"),
//           content: const Text("Are you sure you want to join this meeting?"),
//           actions: [
//             TextButton(
//               onPressed: () {
//                 Navigator.of(context).pop();
//               },
//               child: const Text("Cancel"),
//             ),
//             ElevatedButton(
//               onPressed: () {
//                 // context.read<CallingsCubit>().joinMeet(context, callId);
//                 // Navigator.of(context).pop();
//
//                 // Navigate to ReadyToStartScreen after joining the call
//                 Navigator.push(
//                   context,
//                   MaterialPageRoute(
//                     builder: (context) =>
//                         BlocBuilder<CallingsCubit, CallingsState>(
//                           builder: (context, state) {
//                             if (state is CallJoinedState && state.call.id == callId) {
//                               return ReadyToStartScreen(
//                                 onJoinCallPressed: (_) =>
//                                     context.read<CallingsCubit>().joinMeet(context, state.call.id),
//                                 call: state.call,
//                               );
//                             } else {
//                               return const Scaffold(
//                                 body: Center(
//                                   child: Text("Joining failed or call inactive."),
//                                 ),
//                               );
//                             }
//                           },
//                         ),
//                   ),
//                 );
//               },
//               child: const Text("Join"),
//             ),
//           ],
//         );
//       },
//     );
//   }
// }
