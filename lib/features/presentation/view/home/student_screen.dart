import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:getstream_flutter_example/features/data/services/firebase_services.dart';
import 'package:getstream_flutter_example/features/presentation/manage/fetch_users/fetch_users_cubit.dart';

import '../../../data/models/user_model.dart';

class StudentScreen extends StatefulWidget {
  const StudentScreen({super.key});

  @override
  State<StudentScreen> createState() => _StudentScreenState();
}

class _StudentScreenState extends State<StudentScreen> {
  // @override
  // void initState() {
  //   super.initState();
  //   context.read<FetchUsersCubit>().fetchUsersBasedOnRole();
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocProvider(
        create: (context) => FetchUsersCubit(firestore: FirebaseServices().firestore, auth: FirebaseServices().auth)
          ..fetchUsersBasedOnRole(),
        child: BlocBuilder<FetchUsersCubit, FetchUsersState>(
          builder: (context, state) {
            if (state is UserLoading) {
              print("State: UserLoading");
              return const Center(child: CircularProgressIndicator());
            } else if (state is UserLoaded) {
              print("State: UserLoaded, Users: ${state.users}");
              final users = state.users;
              if (users.isEmpty) {
                print("No users found in the UserLoaded state.");
                return const Center(child: Text("No teachers found."));
              }
              return ListView.builder(
                itemCount: users.length,
                itemBuilder: (context, index) {
                  UserModel teacher = users[index];
                  print("Rendering user: ${teacher.name}");
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
                      trailing: IconButton(
                        onPressed: () => _showJoinCallDialog(context, teacher.uid),
                        icon: const Icon(Icons.meeting_room),
                        color: Colors.blue,
                      ));
                },
              );
            } else if (state is UserError) {
              print("State: UserError, Error: ${state.error}");
              return Center(child: Text("Error: ${state.error}"));
            } else {
              print("State: No data available.");
              return const Center(child: Text("No data available."));
            }
          },
        ),
      ),
    );
  }

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
              onPressed: () {},
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