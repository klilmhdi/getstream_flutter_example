import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_database/firebase_database.dart';
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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MainApp());
}

Future<void> initializeServices(BuildContext context) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  FirebaseDatabase database = FirebaseDatabase.instance;

  // Optional: Enable persistence on web (if needed)
  database.databaseURL ??= 'https://getstream-flutter-example-default-rtdb.firebaseio.com';

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

Future<void> _handleSavedLogin() async {
  final prefs = locator.get<AppPreferences>();
  final credentials = prefs.userCredentials;
  if (credentials == null) return;

  final authController = locator.get<UserAuthController>();
  await authController.login(User(info: credentials.userInfo), prefs.environment);
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
// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//
//   await _initApp();
//   runApp(const MyApp());
// }
//
// class MyApp extends StatelessWidget {
//   const MyApp({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return MultiBlocProvider(
//         providers: [
//           BlocProvider<RegisterCubit>(create: (context) => RegisterCubit()),
//           BlocProvider<FetchUsersCubit>(
//               create: (context) =>
//                   FetchUsersCubit(firestore: FirebaseServices().firestore, auth: FirebaseServices().auth)),
//           BlocProvider<CallingsCubit>(create: (context) => CallingsCubit())
//         ],
//         child: MaterialApp(
//             title: 'Flutter Demo',
//             theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple), useMaterial3: true),
//             home: const RegisterScreen()));
//   }
// }
//
// Future<void> _initApp() async {
//   await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
//
//   await AppInjector.init();
//
//   FlutterError.onError = (FlutterErrorDetails errorDetails) {
//     if (kDebugMode) {
//       FlutterError.dumpErrorToConsole(errorDetails);
//     } else {
//       FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
//     }
//   };
//
//   PlatformDispatcher.instance.onError = (error, stack) {
//     FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
//     return true;
//   };
//
//   final prefs = await SharedPreferences.getInstance();
//   final appPrefs = AppPreferences(prefs: prefs);
//   const apiKey = "8fqmp9ngwbm8";
//   final credentials = appPrefs.userCredentials;
//   const secretKey = "cx9tktcjg34ew2uskpv9d4ewfxh2b5ya3xuzn79gkvtrc8rkugmt9yua2h55cz2k";
//
//   String userId = credentials?.userInfo.id ?? await fetchUserIdFromFirebase() ?? "default-user-id";
//   final String jwtToken = generateJwt(userId: userId, secretKey: secretKey);
//
//   print("?????????????????????????User ID: $userId");
//   print("?????????????????????????Credentials Token: ${credentials!.token.rawValue.isEmpty ? "empty" : credentials?.token.rawValue}");
//   print("?????????????????????????API Key: $apiKey");
//
//   if (credentials.token.rawValue.isEmpty) {
//     print("API key or user credentials are missing or invalid. Falling back to defaults...");
//
//     const defaultApiKey = '8fqmp9ngwbm8';
//     final defaultCredentials = UserCredentialsModel(token: UserToken.jwt(jwtToken), userInfo: UserInfo.empty());
//
//     StreamVideo(defaultApiKey,
//             user: User(info: defaultCredentials.userInfo),
//             userToken: defaultCredentials.token.rawValue,
//             options: const StreamVideoOptions(
//                 logPriority: Priority.verbose, muteAudioWhenInBackground: true, muteVideoWhenInBackground: true),
//             pushNotificationManagerProvider: null)
//         .connect();
//   } else {
//     StreamVideo(apiKey,
//             user: User(info: credentials.userInfo),
//             userToken: credentials.token.rawValue,
//             options: const StreamVideoOptions(
//                 logPriority: Priority.verbose, muteAudioWhenInBackground: true, muteVideoWhenInBackground: true),
//             pushNotificationManagerProvider: null)
//         .connect();
//   }
// }
