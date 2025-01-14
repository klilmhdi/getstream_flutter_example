import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:getstream_flutter_example/core/di/injector.dart';
import 'package:getstream_flutter_example/core/utils/consts/assets.dart';
import 'package:getstream_flutter_example/features/data/services/firebase_services.dart';
import 'package:getstream_flutter_example/features/presentation/manage/call/call_cubit.dart';
import 'package:getstream_flutter_example/features/presentation/manage/live_stream/live_stream_cubit.dart';
import 'package:getstream_flutter_example/features/presentation/manage/meet/meet_cubit.dart';
import 'package:stream_video_flutter/stream_video_flutter.dart';
import 'package:stream_video_flutter/stream_video_flutter_background.dart';

import '../../../../core/app/app_consumers.dart';
import '../../../../core/utils/controllers/user_auth_controller.dart';
import '../auth/signin.dart';

class StudentScreen extends StatefulWidget {
  const StudentScreen({super.key});

  @override
  State<StudentScreen> createState() => _StudentScreenState();
}

class _StudentScreenState extends State<StudentScreen>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  // final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey = GlobalKey<RefreshIndicatorState>();
  final GlobalKey<RefreshIndicatorState> _meetingsRefreshKey = GlobalKey<RefreshIndicatorState>();
  final GlobalKey<RefreshIndicatorState> _liveStreamsRefreshKey = GlobalKey<RefreshIndicatorState>();

  final studentId = locator.get<UserAuthController>().currentUser?.id ?? FirebaseServices().auth.currentUser?.uid ?? "";
  final studentName = locator.get<UserAuthController>().currentUser?.name ?? "empty_student";
  String callerId = '';
  String callerName = '';
  late TabController _tabController;
  late final _userAuthController;

  @override
  bool get wantKeepAlive => true; // Preserve the state of the tabs

  @override
  void initState() {
    super.initState();
    _fetchCallerDetails();

    _userAuthController = locator.get<UserAuthController>();
    // Initialize TabController with 3 tabs
    _tabController = TabController(length: 3, vsync: this);

    if (context.read<CallingsCubit>().call != null) {
      _fetchCallerDetails();
    }

    // Initialize background service
    StreamBackgroundService.init(
      StreamVideo.instance,
      onButtonClick: (call, type, serviceType) async {
        if (serviceType == ServiceType.call) {
          call.reject();
          call.leave();
        } else if (serviceType == ServiceType.screenSharing) {
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

    // Fetch active meetings after the widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<MeetingsCubit>().fetchActiveMeets();
        context.read<LiveStreamCubit>().fetchActiveLiveStreams();
      }
    });

    context.read<CallingsCubit>().listenForIncomingCalls(
      context,
      studentId,
      teacherId: callerId,
      teacherName: callerName,
      teacherImage: AppConsts.teacherNetworkImage);
  }

  @override
  void dispose() {
    _tabController.dispose();
    context.read<MeetingsCubit>().close();
    context.read<LiveStreamCubit>().close();
    context.read<CallingsCubit>().close();

    super.dispose();
  }

  @override
  void deactivate() {
    context.read<MeetingsCubit>().close();
    context.read<LiveStreamCubit>().close();
    context.read<CallingsCubit>().close();
    super.deactivate();
  }

  void _fetchCallerDetails() async {
    final call = context.read<CallingsCubit>().call;
    if (call != null) {
      final callerDetails = await FirebaseServices().firestore.collection('calls').doc(call.id).get();
      setState(() {
        callerId = callerDetails['callerId'] ?? 'Empty ID';
        callerName = callerDetails['callerName'] ?? 'Empty Name';
      });
    } else {
      setState(() {
        callerId = 'empty id';
        callerName = 'empty name';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final currentUser = _userAuthController.currentUser;
    return BlocProvider(
      create: (context) => CallingsCubit(),
      child: BlocConsumer<CallingsCubit, CallingsState>(
        listener: (context, state) {
          if (state is IncomingCallState) {
            _fetchCallerDetails();
          }
        },
        builder: (context, state) {
          return DefaultTabController(
            length: 3,
            child: Scaffold(
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
                bottom: TabBar(
                  controller: _tabController,
                  tabs: const [
                    Tab(text: "Meetings"),
                    Tab(text: "Live Streams"),
                    Tab(text: "Audio Rooms"),
                  ],
                ),
              ),
              body: TabBarView(
                controller: _tabController,
                children: [
                  _buildMeetingsTab(),
                  _buildLiveStreamsTab(),
                  _buildAudioRoomsTab(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMeetingsTab() {
    return BlocProvider<MeetingsCubit>(
      create: (context) => MeetingsCubit()..fetchActiveMeets(),
      child: BlocBuilder<MeetingsCubit, MeetingState>(
        buildWhen: (previous, current) => current is ActiveMeetsFetchedState || current is ActiveMeetsLoadingState,
        builder: (context, state) {
          if (state is ActiveMeetsLoadingState) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is ActiveMeetsFetchedState) {
            final activeMeets = state.activeMeets;
            if (activeMeets.isEmpty) {
              return const Center(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.videocam_off_outlined,
                      size: 60,
                    ),
                    SizedBox(
                      height: 10,
                    ),
                    Text(
                      "There isn't meets created yet!",
                      style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () async => context.read<MeetingsCubit>().fetchActiveMeets(),
              key: _meetingsRefreshKey, // Use a unique key here
              child: ListView.builder(
                itemCount: activeMeets.length,
                itemBuilder: (context, index) {
                  final meet = activeMeets[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: meet.isActiveMeet ? Colors.green : Colors.red,
                      child: Text(
                        meet.meetID.isNotEmpty ? meet.meetID[0].toUpperCase() : '?',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    title: Text("Creator Name: ${meet.creatorName}"),
                    subtitle: Text("MeetID: ${meet.meetID.isNotEmpty ? meet.meetID : 'Unknown'}"),
                    trailing: meet.isActiveMeet
                        ? IconButton(
                            icon: const Icon(Icons.meeting_room),
                            onPressed: () {
                              _showJoinOrCancelMeetDialog(context, meet.meetID);
                            },
                            color: Colors.blue,
                          )
                        : const Icon(Icons.no_meeting_room, color: Colors.redAccent),
                  );
                },
              ),
            );
          } else {
            return const Center(
              child: Text("Bad State"),
            );
          }
        },
      ),
    );
  }

  Widget _buildLiveStreamsTab() {
    return BlocProvider(
      create: (context) => LiveStreamCubit()..fetchActiveLiveStreams(),
      child: BlocBuilder<LiveStreamCubit, LiveStreamState>(
        buildWhen: (previous, current) =>
            current is SuccessFetchingLiveStreamState || current is LoadingFetchingLiveStreamState,
        builder: (context, state) {
          if (state is LoadingFetchingLiveStreamState) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is SuccessFetchingLiveStreamState) {
            final activeLives = state.activeLiveStreams;

            if (activeLives.isEmpty) {
              return const Center(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.tv_off_outlined,
                      size: 60,
                    ),
                    SizedBox(
                      height: 10,
                    ),
                    Text(
                      "There isn't live streams created yet!",
                      style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              );
            }
            return RefreshIndicator(
              onRefresh: () async => context.read<LiveStreamCubit>().fetchActiveLiveStreams(),
              key: _liveStreamsRefreshKey, // Use a unique key here
              child: ListView.builder(
                itemCount: activeLives.length,
                itemBuilder: (context, index) {
                  final live = activeLives[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: live.isLive ? Colors.green : Colors.red,
                      child: Text(
                        live.id.isNotEmpty ? live.id[0].toUpperCase() : '?',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    title: Text("Streamer Name: ${live.creatorName}"),
                    subtitle: Text("Live Stream ID: ${live.id.isNotEmpty ? live.id : 'Unknown'}"),
                    trailing: live.isLive
                        ? IconButton(
                            icon: const Icon(Icons.live_tv_rounded),
                            onPressed: () async =>
                                await context.read<LiveStreamCubit>().joinLiveStream(context, live.id),
                            color: Colors.blue,
                          )
                        : const Icon(Icons.no_meeting_room, color: Colors.redAccent),
                  );
                },
              ),
            );
          } else {
            return const Center(child: Text("Bad State."));
          }
        },
      ),
    );
  }

  Widget _buildAudioRoomsTab() {
    return const Center(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.portable_wifi_off_outlined,
            size: 60,
          ),
          SizedBox(
            height: 10,
          ),
          Text(
            "There isn't audio rooms created yet!",
            style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  void _showJoinOrCancelMeetDialog(BuildContext context, String callId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Join for: $callId Meeting"),
          content: const Text("Are you sure to join in this meeting?"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () => context.read<MeetingsCubit>().readyToStartMeet(context, callId, studentId, studentName),
              child: const Text("Join"),
            ),
          ],
        );
      },
    );
  }
}
