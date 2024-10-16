import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:getstream_flutter_example/features/data/models/user_model.dart';
import 'package:getstream_flutter_example/features/presentation/manage/auth/register/register_cubit.dart';
import 'package:getstream_flutter_example/features/presentation/manage/fetch_users/fetch_users_cubit.dart';
import 'package:getstream_flutter_example/features/data/services/firebase_services.dart';
import 'package:getstream_flutter_example/features/presentation/view/meet/meet_screen.dart';
import 'package:getstream_flutter_example/features/presentation/view/meet/ready_to_start_screen.dart';
import 'package:stream_video_flutter/stream_video_flutter.dart' hide Filter;
import 'package:stream_chat_flutter/stream_chat_flutter.dart' show Channel, Filter, StreamChatClient;
import '../../manage/auth/register/register_state.dart';
import '../../manage/call/call_cubit.dart';

class Layout extends StatefulWidget {
  final String type;

  const Layout({super.key, required this.type});

  @override
  State<Layout> createState() => _LayoutState();
}

class _LayoutState extends State<Layout> {
  late FetchUsersCubit _fetchUsersCubit;

  @override
  void initState() {
    super.initState();
    // Initialize the cubit with Firebase services
    _fetchUsersCubit = FetchUsersCubit(firestore: FirebaseServices().firestore, auth: FirebaseServices().auth);

    // Fetch users based on role
    _fetchUsersCubit.fetchUsersBasedOnRole();
  }

  @override
  void dispose() {
    _fetchUsersCubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<FetchUsersCubit>(
      create: (context) => _fetchUsersCubit,
      child: BlocBuilder<FetchUsersCubit, FetchUsersState>(
        builder: (context, state) {
          if (state is UserLoading) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          } else if (state is UserError) {
            return Scaffold(
              body: Center(
                child: Text('Error loading users: ${state.error}'),
              ),
            );
          } else if (state is UserLoaded) {
            return Scaffold(
                body: widget.type == 'Teacher'
                    ? const TeacherScreen()
                    : widget.type == 'Student'
                    ? const StudentScreen()
                    : Center(child: Text('Unknown type: ${widget.type}')));
          } else {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }
        },
      ),
    );
  }
}

// class TeacherScreen extends StatelessWidget {
//   const TeacherScreen({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return BlocProvider(
//       create: (context) => CallingsCubit(),
//       child: BlocListener<CallingsCubit, CallingsState>(
//         listener: (context, state) {},
//         child: BlocBuilder<FetchUsersCubit, FetchUsersState>(
//           builder: (context, state) => Scaffold(
//             appBar: AppBar(
//                 leading: IconButton(
//                     onPressed: () async => await FirebaseServices().logout().then((value) => Navigator.pop(context)),
//                     icon: const Icon(Icons.logout, color: Colors.redAccent))),
//             body: Center(
//                 child: state is UserLoading
//                     ? const Center(child: CircularProgressIndicator())
//                     : (state as UserLoaded).users.isEmpty
//                         ? const Center(child: Text("No students found."))
//                         : ListView.builder(
//                             itemCount: state.users.length,
//                             itemBuilder: (context, index) {
//                               UserModel student = state.users[index];
//                               return ListTile(
//                                 leading: CircleAvatar(
//                                   backgroundColor: Colors.deepPurple,
//                                   child: Text(
//                                     student.name.isNotEmpty ? student.name[0] : '?',
//                                     style: const TextStyle(color: Colors.white),
//                                   ),
//                                 ),
//                                 title: Text(student.name),
//                                 subtitle: Text(student.email),
//                                 trailing: IconButton(
//                                   onPressed: () {
//                                     // Implement call functionality
//                                   },
//                                   icon: const Icon(Icons.call),
//                                   color: Colors.green,
//                                 ),
//                               );
//                             },
//                           )),
//             floatingActionButton: FloatingActionButton(
//               child: const Icon(Icons.add),
//               onPressed: () async {
//                 // Fetch the teacherId (make sure it's valid)
//                 final teacherId = context.read<RegisterCubit>().state is RegisterSuccessState
//                     ? (context.read<RegisterCubit>().state as RegisterSuccessState).user.uid
//                     : null;
//
//                 if (teacherId != null) {
//                   // Initiate the call
//                   await context.read<CallingsCubit>().initiateCall(teacherId, context);
//                 }
//               },
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }
class TeacherScreen extends StatelessWidget {
  const TeacherScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<CallingsCubit>(create: (context) => CallingsCubit()),
        BlocProvider<FetchUsersCubit>(
            create: (context) =>
            FetchUsersCubit(firestore: FirebaseFirestore.instance, auth: FirebaseAuth.instance)
              ..fetchUsersBasedOnRole())
      ],
      child: BlocListener<CallingsCubit, CallingsState>(
        listener: (context, state) {},
        child: BlocBuilder<FetchUsersCubit, FetchUsersState>(
          builder: (context, state) {
            return Scaffold(
              appBar: AppBar(
                  leading: IconButton(
                      onPressed: () async => await FirebaseServices().logout().then((_) => Navigator.pop(context)),
                      icon: const Icon(Icons.logout, color: Colors.redAccent)),
                  title: const Text('Teacher Screen')),
              body: _buildBody(state),
              floatingActionButton: FloatingActionButton(
                child: const Icon(Icons.add),
                onPressed: () async {
                  final teacherId = context
                      .read<RegisterCubit>()
                      .state is RegisterSuccessState
                      ? (context
                      .read<RegisterCubit>()
                      .state as RegisterSuccessState).user.uid
                      : null;

                  if (teacherId != null) {
                    await context.read<CallingsCubit>().initiateCall(teacherId, context);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Teacher ID is invalid.')));
                  }
                },
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildBody(FetchUsersState state) {
    if (state is UserLoading) {
      return const Center(child: CircularProgressIndicator());
    } else if (state is UserLoaded) {
      if (state.users.isEmpty) {
        return const Center(child: Text("No students found."));
      }
      return ListView.builder(
        itemCount: state.users.length,
        itemBuilder: (context, index) {
          UserModel student = state.users[index];
          return ListTile(
            leading: CircleAvatar(
                backgroundColor: Colors.deepPurple,
                child:
                Text(student.name.isNotEmpty ? student.name[0] : '?', style: const TextStyle(color: Colors.white))),
            title: Text(student.name),
            subtitle: Text(student.email),
            trailing: IconButton(
              onPressed: () {},
              icon: const Icon(Icons.call),
              color: Colors.green,
            ),
          );
        },
      );
    } else if (state is UserError) {
      return Center(child: Text("Error: ${state.error}"));
    } else {
      return const Center(child: Text("No data available."));
    }
  }
}

class StudentScreen extends StatelessWidget {
  const StudentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          leading: IconButton(
              onPressed: () async => await FirebaseServices().logout().then((value) => Navigator.pop(context)),
              icon: const Icon(Icons.logout, color: Colors.redAccent))),
      body: BlocBuilder<FetchUsersCubit, FetchUsersState>(
        builder: (context, state) {
          if (state is UserLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is UserLoaded) {
            final users = state.users;
            if (users.isEmpty) {
              return const Center(child: Text("No teachers found."));
            }
            return ListView.builder(
              itemCount: users.length,
              itemBuilder: (context, index) {
                UserModel teacher = users[index];
                return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.deepPurple,
                      child: Text(
                        teacher.name.isNotEmpty ? teacher.name[0].toUpperCase() : '?',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    title: Text(teacher.name),
                    subtitle: Text(teacher.email),
                    // trailing: Text(teacher.role),
                    trailing: IconButton(
                      onPressed: () => _showJoinCallDialog(context, teacher.uid),
                      icon: const Icon(Icons.meeting_room),
                      color: Colors.blue,
                    ));
              },
            );
          } else if (state is UserError) {
            return Center(child: Text("Error: ${state.error}"));
          } else {
            return const Center(child: Text("No data available."));
          }
        },
      ),
    );
  }

  /// Shows a dialog to confirm joining a call.
  void _showJoinCallDialog(BuildContext context, String teacherId) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Join Call'),
          content: const Text('Do you want to join this call?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                // _joinCall(context, teacherId);
              },
              child: const Text('Join'),
            ),
          ],
        );
      },
    );
  }

// /// Initiates joining a call.
// Future<void> _joinCall(BuildContext context, String teacherId) async {
//   final callCubit = context.read<CallingsCubit>();
//
//   // Fetch ongoing calls for the teacher
//   List<Channel> ongoingCalls = (await _fetchOngoingCalls(teacherId)).cast<Call>();
//
//   if (ongoingCalls.isEmpty) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(content: Text('No ongoing calls from this teacher.')),
//     );
//     return;
//   }
//
//   // For simplicity, join the first available call
//   Call call = ongoingCalls.first as Call;
//
//   callCubit.joinCall(call);
// }
//
// // Fetch ongoing calls based on teacherId
// Future<dynamic> _fetchOngoingCalls(String teacherId) async {
//   try {
//     var client = StreamChatClient("");
//     // Use the Filter class to filter by status 'ongoing' and teacherId
//     return await client.queryChannels(
//       filter: Filter.and([
//         Filter.equal('status', 'ongoing'),
//         Filter.equal('teacherId', teacherId),
//       ]),
//     );
//   } catch (e) {
//     print('Error fetching ongoing calls: $e');
//     return [];
//   }
// }

// /// Displays a modal with available calls to join.
// Future<void> _showAvailableCalls(BuildContext context) async {
//   // Fetch available calls (implement based on your backend or Stream Video)
//   List<Call> availableCalls = await _fetchAvailableCalls();
//
//   if (availableCalls.isEmpty) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(content: Text('No available calls to join.')),
//     );
//     return;
//   }
//
//   showModalBottomSheet(
//     context: context,
//     builder: (context) {
//       return ListView.builder(
//         itemCount: availableCalls.length,
//         itemBuilder: (context, index) {
//           Call call = availableCalls[index];
//           return ListTile(
//             title: Text('Call ID: ${call.id}'),
//             // subtitle: Text('Teacher: ${call.state}'),
//             onTap: () {
//               Navigator.pop(context);
//               context.read<CallingsCubit>().joinCall(call);
//             },
//           );
//         },
//       );
//     },
//   );
// }
//
// // Fetch ongoing calls
// Future<List<Channel>> _fetchOngoingCalls() async {
//   final StreamChatClient client;
//
//   try {
//     // Use the Filter class to define your filter
//     final response = await client.queryChannels(
//       filter: Filter.equal('status', 'ongoing'),
//     );
//
//     return response;
//   } catch (e) {
//     print('Error fetching ongoing calls: $e');
//     return [];
//   }
// }
//
// // Fetch available calls
// Future<List<Channel>> _fetchAvailableCalls() async {
//   try {
//     // Query available calls (assuming 'available' is a tag or field in your channel)
//     final response = await client.queryChannels(
//       filter: {
//         'status': {'\$eq': 'available'}
//       },
//     );
//
//     return response;
//   } catch (e) {
//     print('Error fetching available calls: $e');
//     return [];
//   }
// }

// /// Fetches ongoing calls for a specific teacher.
// Future<List<Call>> _fetchOngoingCalls(String teacherId) async {
//   // Implement your logic to fetch ongoing calls from the teacher
//   // This is a placeholder using StreamVideo's call list
//   // Replace with your actual implementation
//   return StreamVideo.instance.activeCall.call().where((call) => call.creatorId == teacherId && call.isActive).toList();
// }
//
// /// Fetches all available calls to join.
// Future<List<Call>> _fetchAvailableCalls() async {
//   // Implement your logic to fetch available calls to join
//   // This is a placeholder using StreamVideo's call list
//   // Replace with your actual implementation
//   return StreamVideo.instance.activeCall.call().where((call) => call.isActive).toList();
// }
}
