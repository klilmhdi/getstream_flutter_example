import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:getstream_flutter_example/core/app/app_consumers.dart';
import 'package:getstream_flutter_example/core/di/injector.dart';
import 'package:getstream_flutter_example/core/utils/controllers/user_auth_controller.dart';
import 'package:getstream_flutter_example/features/data/services/firebase_services.dart';
import 'package:getstream_flutter_example/features/presentation/manage/fetch_users/fetch_users_cubit.dart';
import 'package:getstream_flutter_example/features/presentation/view/auth/signin.dart';
import 'package:getstream_flutter_example/features/presentation/view/home/student_screen.dart';
import 'package:getstream_flutter_example/features/presentation/view/home/teacher_screen.dart';
import 'package:stream_video_flutter/stream_video_flutter.dart';
import 'package:stream_video_flutter/stream_video_flutter_background.dart';

class Layout extends StatefulWidget {
  final String type;

  const Layout({super.key, required this.type});

  @override
  State<Layout> createState() => _LayoutState();
}

class _LayoutState extends State<Layout> with SingleTickerProviderStateMixin {
  late FetchUsersCubit _fetchUsersCubit;
  late TabController _tabController;

  @override
  void initState() {
    _tabController = TabController(length: 3, vsync: this);
    super.initState();
    _fetchUsersCubit = FetchUsersCubit();
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
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    return BlocProvider<FetchUsersCubit>(
      create: (context) => _fetchUsersCubit,
      child: BlocBuilder<FetchUsersCubit, FetchUsersState>(builder: (context, state) {
        if (state is UserLoading) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        } else if (state is UserError) {
          return Scaffold(body: Center(child: Text('Error loading users: ${state.error}')));
        }
        return Scaffold(
          body: widget.type == 'Teacher'
              ? const TeacherScreen()
              : widget.type == 'Student'
                  ? const StudentScreen()
                  : Center(child: Text('Unknown type: ${widget.type}')),
        );
      }),
    );
  }
}
