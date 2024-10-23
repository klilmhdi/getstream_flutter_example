import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:getstream_flutter_example/core/di/injector.dart';
import 'package:getstream_flutter_example/core/utils/consts/user_auth_controller.dart';
import 'package:getstream_flutter_example/features/data/models/user_model.dart';
import 'package:getstream_flutter_example/features/presentation/manage/auth/register/register_cubit.dart';
import 'package:getstream_flutter_example/features/presentation/manage/fetch_users/fetch_users_cubit.dart';
import 'package:getstream_flutter_example/features/data/services/firebase_services.dart';
import 'package:getstream_flutter_example/features/presentation/view/auth/signin.dart';
import 'package:getstream_flutter_example/features/presentation/view/home/student_screen.dart';
import 'package:getstream_flutter_example/features/presentation/view/home/teacher_screen.dart';
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
  late final _userAuthController;

  @override
  void initState() {
    super.initState();
    // Initialize the cubit with Firebase services
    _fetchUsersCubit = FetchUsersCubit(firestore: FirebaseServices().firestore, auth: FirebaseServices().auth);
    _userAuthController = locator.get<UserAuthController>();
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
    final currentUser = _userAuthController.currentUser;
    print(">>>>>>>>>>>>>Current User: $currentUser");
    return BlocProvider<FetchUsersCubit>(
      create: (context) => _fetchUsersCubit,
      child: BlocBuilder<FetchUsersCubit, FetchUsersState>(
        builder: (context, state) {
          if (state is UserLoading) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          } else if (state is UserError) {
            return Scaffold(body: Center(child: Text('Error loading users: ${state.error}')));
          } else if (state is UserLoaded) {
            return Scaffold(
                appBar: AppBar(
                  elevation: 0,
                  backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                  leading: Padding(
                      padding: const EdgeInsets.all(8),
                      child: CircleAvatar(backgroundImage: NetworkImage(currentUser?.image ?? ""))),
                  titleSpacing: 4,
                  centerTitle: false,
                  title: Text(
                    currentUser?.name ?? "Empty Name",
                    style: const TextStyle(fontSize: 25, color: CupertinoColors.black),
                  ),
                  actions: [
                    IconButton(
                        onPressed: () async => await FirebaseServices().logout().then((value) {
                              locator.get<UserAuthController>().logout().then((value) => Navigator.push(
                                  context, MaterialPageRoute(builder: (context) => const RegisterScreen())));
                            }),
                        icon: const Icon(Icons.logout, color: Colors.redAccent))
                  ],
                ),
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