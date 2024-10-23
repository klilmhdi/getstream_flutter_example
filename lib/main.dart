import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:getstream_flutter_example/core/di/injector.dart';
import 'package:getstream_flutter_example/core/utils/consts/user_auth_controller.dart';
import 'package:getstream_flutter_example/features/data/repo/app_preferences.dart';
import 'package:getstream_flutter_example/features/data/services/firebase_services.dart';
import 'package:getstream_flutter_example/features/presentation/manage/auth/register/register_cubit.dart';
import 'package:getstream_flutter_example/features/presentation/manage/call/call_cubit.dart';
import 'package:getstream_flutter_example/features/presentation/manage/fetch_users/fetch_users_cubit.dart';
import 'package:getstream_flutter_example/features/presentation/view/splash_screen.dart';
import 'package:getstream_flutter_example/firebase_options.dart';
import 'package:stream_video_flutter/stream_video_flutter.dart' hide ConnectionState;
import 'features/presentation/view/auth/signin.dart';

// initialize app services
Future<void> initializeServices(BuildContext context) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  FirebaseDatabase database = FirebaseDatabase.instance;

  // Optional: Enable persistence on web (if needed)
  database.databaseURL ??= 'https://getstream-flutter-example-default-rtdb.firebaseio.com';

  FirebaseMessaging messaging = FirebaseMessaging.instance;

// Request permission for push notifications
  NotificationSettings settings = await messaging.requestPermission(alert: true, badge: true, sound: true);

  print('?>>>>>>>>>>>>>>>>>>>>>>>>>>>>>User granted permission: ${settings.authorizationStatus}');

  FlutterError.onError = (errorDetails) {
    if (kDebugMode) {
      FlutterError.dumpErrorToConsole(errorDetails);
    } else {
      FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
    }
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

  await AppInjector.init();

  await _handleSavedLogin();
}

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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _appLoader ??= Future.wait([
      initializeServices(context),
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
            create: (context) =>
                FetchUsersCubit(firestore: FirebaseServices().firestore, auth: FirebaseServices().auth)),
        BlocProvider<CallingsCubit>(create: (context) => CallingsCubit())
      ],
      child: MaterialApp(
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

              return const RegisterScreen();
            }

            return const SplashScreen();
          },
        ),
      ),
    );
  }
}

// save login
Future<void> _handleSavedLogin() async {
  final prefs = locator.get<AppPreferences>();
  final credentials = prefs.userCredentials;

  if (credentials == null || credentials.userInfo.id.isEmpty) {
    print("No saved user credentials found.");
    return;
  }

  final authController = locator.get<UserAuthController>();
  await authController.login(User(info: credentials.userInfo), prefs.environment);
  print("User auto-logged in with credentials from SharedPreferences.");
}
