import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:getstream_flutter_example/core/app/app_consumers.dart';
import 'package:getstream_flutter_example/core/di/injector.dart';
import 'package:getstream_flutter_example/core/utils/controllers/user_auth_controller.dart';
import 'package:getstream_flutter_example/features/presentation/manage/fetch_users/fetch_users_cubit.dart';
import 'package:getstream_flutter_example/features/data/services/firebase_services.dart';
import 'package:getstream_flutter_example/features/presentation/view/auth/signin.dart';
import 'package:getstream_flutter_example/features/presentation/view/home/student_screen.dart';
import 'package:getstream_flutter_example/features/presentation/view/home/teacher_screen.dart';
import 'package:stream_chat_flutter/stream_chat_flutter.dart';
import 'package:stream_video_flutter/stream_video_flutter.dart';
import 'package:stream_video_flutter/stream_video_flutter_background.dart';

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
    _fetchUsersCubit = FetchUsersCubit();
    _userAuthController = locator.get<UserAuthController>();
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

  }

  @override
  void dispose() {
    _fetchUsersCubit.close();
    AppConsumers().compositeSubscription.cancel();
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
                        : Center(child: Text('Unknown type: ${widget.type}')),
            );
          }
      ),
    );
  }
}
