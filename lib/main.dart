import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:getstream_flutter_example/core/app/app_consumers.dart';
import 'package:getstream_flutter_example/core/di/injector.dart';
import 'package:getstream_flutter_example/core/utils/controllers/user_auth_controller.dart';
import 'package:getstream_flutter_example/core/utils/widgets.dart';
import 'package:getstream_flutter_example/features/data/services/firebase_services.dart';
import 'package:getstream_flutter_example/features/presentation/manage/auth/register/register_cubit.dart';
import 'package:getstream_flutter_example/features/presentation/manage/call/call_cubit.dart';
import 'package:getstream_flutter_example/features/presentation/manage/fetch_users/fetch_users_cubit.dart';
import 'package:getstream_flutter_example/features/presentation/view/home/layout.dart';
import 'package:getstream_flutter_example/features/presentation/view/splash_screen.dart';
import 'package:stream_chat_flutter/stream_chat_flutter.dart' hide User;
import 'package:stream_video_flutter/stream_video_flutter.dart' hide ConnectionState;
import 'features/presentation/view/auth/signin.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MainApp());
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  Future<void>? _appLoader;
  // final Connectivity _connectivity = Connectivity();

  @override
  void initState() {
    super.initState();
    AppConsumers()
      // ..initializeServices(context)
      ..initPushNotificationManagerIfAvailable(context)
      ..consumeIncomingCall(context);
      // ..initPushNotificationManagerIfAvailable();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _appLoader ??= Future.wait([
      AppConsumers().initializeServices(context),
      Future.delayed(const Duration(seconds: 3)),
    ]);
  }

  @override
  void dispose() {
    super.dispose();
    AppInjector.reset();
    _appLoader = null;
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<RegisterCubit>(create: (context) => RegisterCubit()),
        BlocProvider<FetchUsersCubit>(
            create: (context) => FetchUsersCubit(firestore: FirebaseServices().firestore, auth: FirebaseServices().auth)
              ..fetchUsersBasedOnRole()..fetchStudents()),
        BlocProvider<CallingsCubit>(create: (context) => CallingsCubit())
      ],
      child: MaterialApp(
        builder: (context, child) =>
            StreamChat(client: StreamChatClient("z3k88gbquy4a", logLevel: Level.INFO), child: child),
        theme: ThemeData(
          extensions: <ThemeExtension<dynamic>>[
            StreamVideoTheme.dark().copyWith(
              callControlsTheme: StreamCallControlsThemeData(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(32),
                  topRight: Radius.circular(32),
                ),
                callReactions: callReactions,
                backgroundColor: CupertinoColors.white,
                elevation: 8,
                padding: const EdgeInsets.all(14),
                spacing: 4,
                optionIconColor: Colors.black,
                inactiveOptionIconColor: Colors.white,
              ),
            ),
          ],
        ),
        home: FutureBuilder(
          future: _appLoader,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              if (snapshot.hasError) {
                debugPrint(snapshot.error.toString());
                debugPrint(snapshot.stackTrace.toString());

                return const Directionality(
                  textDirection: TextDirection.ltr,
                  child: Center(child: Text('Error loading app')),
                );
              }
              // Navigate based on the saved user’s role
              final authController = locator.get<UserAuthController>();
              final currentUser = authController.currentUser;
              if (currentUser != null) {
                return Layout(type: currentUser.role == 'admin' ? "Teacher" : "Student");
              } else {
                return const RegisterScreen();
              }
            }

            return const SplashScreen();
          },
        ),
      ),
    );
  }
}
