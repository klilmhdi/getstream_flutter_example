import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:getstream_flutter_example/core/utils/consts/functions.dart';
import 'package:getstream_flutter_example/features/data/repo/app_preferences.dart';
import 'package:getstream_flutter_example/firebase_options.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stream_video_flutter/stream_video_flutter.dart';

// show Priority, StreamVideo, StreamVideoOptions, User, UserInfo, UserToken;
import 'package:getstream_flutter_example/features/data/services/firebase_services.dart';
import 'package:getstream_flutter_example/features/presentation/manage/auth/register/register_cubit.dart';
import 'package:getstream_flutter_example/features/presentation/manage/fetch_users/fetch_users_cubit.dart';
import 'package:getstream_flutter_example/features/presentation/view/auth/signin.dart';
import 'package:stream_video_push_notification/stream_video_push_notification.dart';

import 'features/data/models/user_credentials_model.dart';
import 'features/presentation/manage/call/call_cubit.dart';

// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//
//   await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
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
//   String userId = credentials?.userInfo.id ?? await fetchUserIdFromFirebase() ?? "user_1";
//   const secretKey = "cx9tktcjg34ew2uskpv9d4ewfxh2b5ya3xuzn79gkvtrc8rkugmt9yua2h55cz2k";
//   final String jwtToken = generateJwt(userId: userId, secretKey: secretKey);
//
//   print("?????????????????????????????????????????????????????????ID: $userId");
//   print("?????????????????????????????????????????????????????????credentials: ${credentials?.token.userId ?? "KHKH123123"}");
//   print("?????????????????????????????????????????????????????????api key: $apiKey");
//
//   if (apiKey == null || credentials == null || credentials.token.rawValue.isEmpty) {
//     print("API key or user credentials are missing or invalid. Falling back to defaults...");
//
//     const defaultApiKey = '8fqmp9ngwbm8';
//     final defaultCredentials = UserCredentialsModel(
//         token: UserToken.jwt(jwtToken),
//         userInfo: const UserInfo(
//             id: 'default-user-1', name: 'Default User', role: 'user', image: '', teams: [], extraData: {}));
//
//     StreamVideo(
//       defaultApiKey,
//       user: User(info: defaultCredentials.userInfo),
//       userToken: defaultCredentials.token.userId,
//       options: const StreamVideoOptions(
//           logPriority: Priority.verbose, muteAudioWhenInBackground: true, muteVideoWhenInBackground: true),
//       // pushNotificationManagerProvider: null
//         pushNotificationManagerProvider: StreamVideoPushNotificationManager.create(
//           iosPushProvider: const StreamVideoPushProvider.apn(
//             name: 'flutter-apn',
//             // Ensure that the APN certificate is correctly uploaded in Stream's dashboard
//           ),
//           androidPushProvider: const StreamVideoPushProvider.firebase(
//             name: 'flutter-firebase',
//             // Ensure that the Firebase credentials are correctly configured in your project
//           ),
//           pushParams: const StreamVideoPushParams(
//             appName: "Example",
//             ios: IOSParams(iconName: 'IconMask'), // Ensure this icon exists in your app
//           ),
//           registerApnDeviceToken: true,
//         )
//     ).connect();
//     // StreamVideoPushNotificationManager.create(
//     //     iosPushProvider: const StreamVideoPushProvider.apn(name: 'flutter-apn'),
//     //     androidPushProvider: const StreamVideoPushProvider.firebase(name: 'flutter-firebase'),
//     //     pushParams: const StreamVideoPushParams(appName: "Example", ios: IOSParams(iconName: 'IconMask')),
//     //     registerApnDeviceToken: true)
//   } else {
//     StreamVideo(
//       apiKey,
//       user: User(info: credentials.userInfo),
//       userToken: credentials.token.userId,
//       options: const StreamVideoOptions(
//           logPriority: Priority.verbose, muteAudioWhenInBackground: true, muteVideoWhenInBackground: true),
//       // pushNotificationManagerProvider: null
//         pushNotificationManagerProvider: StreamVideoPushNotificationManager.create(
//           iosPushProvider: const StreamVideoPushProvider.apn(
//             name: 'flutter-apn',
//             // Ensure that the APN certificate is correctly uploaded in Stream's dashboard
//           ),
//           androidPushProvider: const StreamVideoPushProvider.firebase(
//             name: 'flutter-firebase',
//             // Ensure that the Firebase credentials are correctly configured in your project
//           ),
//           pushParams: const StreamVideoPushParams(
//             appName: "Example",
//             ios: IOSParams(iconName: 'IconMask'), // Ensure this icon exists in your app
//           ),
//           registerApnDeviceToken: true,
//         )
//     ).connect();
//     //       StreamVideoPushNotificationManager.create(
//     //       iosPushProvider: const StreamVideoPushProvider.apn(name: 'flutter-apn'),
//     // androidPushProvider: const StreamVideoPushProvider.firebase(name: 'flutter-firebase'),
//     // pushParams: const StreamVideoPushParams(appName: "Example", ios: IOSParams(iconName: 'IconMask')),
//     // registerApnDeviceToken: true)
//   }
//
//   runApp(const MyApp());
// }
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  FlutterError.onError = (FlutterErrorDetails errorDetails) {
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

  final prefs = await SharedPreferences.getInstance();
  final appPrefs = AppPreferences(prefs: prefs);
  const apiKey = "8fqmp9ngwbm8";
  final credentials = appPrefs.userCredentials;
  const secretKey = "cx9tktcjg34ew2uskpv9d4ewfxh2b5ya3xuzn79gkvtrc8rkugmt9yua2h55cz2k";

  String userId = credentials?.userInfo.id ?? await fetchUserIdFromFirebase() ?? "default-user-id";
  final String jwtToken = generateJwt(userId: userId, secretKey: secretKey);

  print("?????????????????????????User ID: $userId");
  print("?????????????????????????Credentials Token: ${credentials?.token.rawValue ?? "No Credentials"}");
  print("?????????????????????????API Key: $apiKey");

  if (apiKey == null || credentials == null || credentials.token.rawValue.isEmpty) {
    print("API key or user credentials are missing or invalid. Falling back to defaults...");

    const defaultApiKey = '8fqmp9ngwbm8';
    final defaultCredentials = UserCredentialsModel(
      token: UserToken.jwt(jwtToken),
      userInfo: const UserInfo(
        id: 'default-user-id',
        name: 'Default User',
        role: 'user',
        image: '',
        teams: [],
        extraData: {},
      ),
    );

    // Initialize StreamVideo without push notifications
    StreamVideo(
      defaultApiKey,
      user: User(info: defaultCredentials.userInfo),
      userToken: defaultCredentials.token.rawValue,
      options: const StreamVideoOptions(
        logPriority: Priority.verbose,
        muteAudioWhenInBackground: true,
        muteVideoWhenInBackground: true,
      ),
      pushNotificationManagerProvider: null,  // Temporarily disable push notifications
    ).connect();
  } else {
    // Initialize StreamVideo with credentials and disable push notifications
    StreamVideo(
      apiKey,
      user: User(info: credentials.userInfo),
      userToken: credentials.token.rawValue,
      options: const StreamVideoOptions(
        logPriority: Priority.verbose,
        muteAudioWhenInBackground: true,
        muteVideoWhenInBackground: true,
      ),
      pushNotificationManagerProvider: null,  // Temporarily disable push notifications
    ).connect();
  }

  runApp(const MyApp());
}

// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//
//   await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
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
//   print("?????????????????????????????????????????????????User ID: $userId");
//   print("?????????????????????????????????????????????????Credentials Token: ${credentials?.token.rawValue ?? "No Credentials"}");
//   print("?????????????????????????????????????????????????API Key: $apiKey");
//
//   if (apiKey == null || credentials == null || credentials.token.rawValue.isEmpty) {
//     print("API key or user credentials are missing or invalid. Falling back to defaults...");
//
//     const defaultApiKey = '8fqmp9ngwbm8';
//     final defaultCredentials = UserCredentialsModel(
//       token: UserToken.jwt(jwtToken),
//       userInfo: const UserInfo(
//         id: 'default-user-id',
//         name: 'Default User',
//         role: 'user',
//         image: '',
//         teams: [],
//         extraData: {},
//       ),
//     );
//
//     StreamVideo(
//       defaultApiKey,
//       user: User(info: defaultCredentials.userInfo),
//       userToken: defaultCredentials.token.rawValue,
//       options: const StreamVideoOptions(
//         logPriority: Priority.verbose,
//         muteAudioWhenInBackground: true,
//         muteVideoWhenInBackground: true,
//       ),
//       pushNotificationManagerProvider: StreamVideoPushNotificationManager.create(
//         iosPushProvider: const StreamVideoPushProvider.apn(name: 'flutter-apn'),
//         androidPushProvider: const StreamVideoPushProvider.firebase(name: 'flutter-firebase'),
//         pushParams: const StreamVideoPushParams(
//           appName: "Example",
//           ios: IOSParams(iconName: 'IconMask'),
//         ),
//         registerApnDeviceToken: true,
//       ),
//     ).connect();
//   } else {
//     StreamVideo(
//       apiKey,
//       user: User(info: credentials.userInfo),
//       userToken: credentials.token.rawValue,
//       options: const StreamVideoOptions(
//         logPriority: Priority.verbose,
//         muteAudioWhenInBackground: true,
//         muteVideoWhenInBackground: true,
//       ),
//       pushNotificationManagerProvider: StreamVideoPushNotificationManager.create(
//         iosPushProvider: const StreamVideoPushProvider.apn(name: 'flutter-apn'),
//         androidPushProvider: const StreamVideoPushProvider.firebase(name: 'flutter-firebase'),
//         pushParams: const StreamVideoPushParams(
//           appName: "Example",
//           ios: IOSParams(iconName: 'IconMask'),
//         ),
//         registerApnDeviceToken: true,
//       ),
//     ).connect();
//   }
//
//   runApp(const MyApp());
// }

class MyApp extends StatelessWidget {
  const MyApp({super.key});

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
            title: 'Flutter Demo',
            theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple), useMaterial3: true),
            home: const RegisterScreen()));
  }
}

// import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
// import 'package:firebase_core/firebase_core.dart';
// import 'package:firebase_crashlytics/firebase_crashlytics.dart';
// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:getstream_flutter_example/features/data/repo/app_preferences.dart';
// import 'package:getstream_flutter_example/features/data/services/token_service.dart';
// import 'package:getstream_flutter_example/features/presentation/view/home/layout.dart';
// import 'package:getstream_flutter_example/firebase_options.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:stream_chat_flutter/stream_chat_flutter.dart' hide User;
// import 'package:stream_video_flutter/stream_video_flutter.dart'
//     show Priority, StreamVideo, StreamVideoOptions, User, UserInfo, UserToken;
// import 'package:getstream_flutter_example/core/di/injector.dart';
// import 'package:getstream_flutter_example/features/data/services/firebase_services.dart';
// import 'package:getstream_flutter_example/features/presentation/manage/auth/register/register_cubit.dart';
// import 'package:getstream_flutter_example/features/presentation/manage/fetch_users/fetch_users_cubit.dart';
// import 'package:getstream_flutter_example/features/presentation/view/auth/signin.dart';
// import 'package:stream_video_push_notification/stream_video_push_notification.dart';
//
// import 'features/data/models/user_credentials_model.dart';
// import 'features/presentation/manage/call/call_cubit.dart';
//
// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//
//   // Initialize Firebase
//   await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
//
//   // Configure Crashlytics
//   FlutterError.onError = (FlutterErrorDetails errorDetails) {
//     if (kDebugMode) {
//       FlutterError.dumpErrorToConsole(errorDetails);
//     } else {
//       FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
//     }
//   };
//
//   // Handle asynchronous errors not caught by Flutter framework
//   PlatformDispatcher.instance.onError = (error, stack) {
//     FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
//     return true;
//   };
//
//   // Initialize SharedPreferences
//   final prefs = await SharedPreferences.getInstance();
//   final appPrefs = AppPreferences(prefs: prefs);
//
//   // Fetch API Key and User Credentials
//   final apiKey = appPrefs.apiKey;
//   final credentials = appPrefs.userCredentials;
//   const secretKey = "cx9tktcjg34ew2uskpv9d4ewfxh2b5ya3xuzn79gkvtrc8rkugmt9yua2h55cz2k";
//   final String jwtToken = _generateJwt(userId: credentials?.userInfo.id ?? "user_1", secretKey: secretKey);
//   print("?????????????????????????????????????????????????????????ID: ${credentials?.userInfo.id ?? "user_1"}");
//
//   if (apiKey == null || credentials == null || credentials.token.rawValue.isEmpty) {
//     // Log missing credentials and fallback to default behavior
//     print("API key or user credentials are missing or invalid. Falling back to defaults...");
//
//     // Example: Set default API key and dummy credentials
//     const defaultApiKey = '8fqmp9ngwbm8';
//     final defaultCredentials = UserCredentialsModel(
//       token: UserToken.jwt(jwtToken), // Replace with a valid JWT or mock token
//       userInfo:
//           const UserInfo(id: 'default-user', name: 'Default User', role: 'user', image: '', teams: [], extraData: {}));
//
//     // Initialize Stream Video with default or dummy values
//     StreamVideo(defaultApiKey,
//         user: User(info: defaultCredentials.userInfo),
//         userToken: defaultCredentials.token.rawValue,
//         options: const StreamVideoOptions(
//             logPriority: Priority.verbose, muteAudioWhenInBackground: true, muteVideoWhenInBackground: true),
//         pushNotificationManagerProvider: StreamVideoPushNotificationManager.create(
//             iosPushProvider: const StreamVideoPushProvider.apn(name: 'flutter-apn'),
//             androidPushProvider: const StreamVideoPushProvider.firebase(name: 'flutter-firebase'),
//             pushParams: const StreamVideoPushParams(appName: "Example", ios: IOSParams(iconName: 'IconMask')),
//             registerApnDeviceToken: true));
//   } else {
//     // Initialize Stream Video with actual credentials
//     StreamVideo(apiKey,
//         user: User(info: credentials.userInfo),
//         userToken: credentials.token.rawValue,
//         options: const StreamVideoOptions(
//             logPriority: Priority.verbose, muteAudioWhenInBackground: true, muteVideoWhenInBackground: true),
//         pushNotificationManagerProvider: StreamVideoPushNotificationManager.create(
//             iosPushProvider: const StreamVideoPushProvider.apn(name: 'flutter-apn'),
//             androidPushProvider: const StreamVideoPushProvider.firebase(name: 'flutter-firebase'),
//             pushParams: const StreamVideoPushParams(appName: "Example", ios: IOSParams(iconName: 'IconMask')),
//             registerApnDeviceToken: true));
//   }
//
//   runApp(const MyApp());
// }
//
// class MyApp extends StatelessWidget {
//   const MyApp({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return MultiBlocProvider(
//       providers: [
//         BlocProvider<RegisterCubit>(create: (context) => RegisterCubit()),
//         BlocProvider<FetchUsersCubit>(
//             create: (context) =>
//                 FetchUsersCubit(firestore: FirebaseServices().firestore, auth: FirebaseServices().auth)),
//         BlocProvider<CallingsCubit>(create: (context) => CallingsCubit())
//       ],
//       child: MaterialApp(
//         title: 'Flutter Demo',
//         theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple), useMaterial3: true),
//         // Show the RegisterScreen as the main screen
//         home: const RegisterScreen(),
//       ),
//     );
//   }
// }
//
// /// Function to generate JWT
// String _generateJwt({
//   required String userId,
//   required String secretKey,
//   int expiryMinutes = 60,
// }) {
//   // Create a JWT payload with user information and expiration time
//   final jwt = JWT(
//     {
//       'id': userId,
//       'exp': DateTime.now().add(Duration(minutes: expiryMinutes)).millisecondsSinceEpoch ~/ 1000,
//     },
//   );
//
//   // Sign the JWT with a secret key using HS256 algorithm
//   return jwt.sign(SecretKey(secretKey), algorithm: JWTAlgorithm.HS256);
// }
// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//
//   // Initialize Firebase
//   await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
//
//   // Configure Crashlytics
//   FlutterError.onError = (FlutterErrorDetails errorDetails) {
//     if (kDebugMode) {
//       FlutterError.dumpErrorToConsole(errorDetails);
//     } else {
//       FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
//     }
//   };
//
//   // Handle asynchronous errors not caught by Flutter framework
//   PlatformDispatcher.instance.onError = (error, stack) {
//     FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
//     return true;
//   };
//
//   // Initialize SharedPreferences
//   final prefs = await SharedPreferences.getInstance();
//   final appPrefs = AppPreferences(prefs: prefs);
//
//   // Fetch API Key and User Credentials
//   final apiKey = appPrefs.apiKey;
//   final credentials = appPrefs.userCredentials;
//
//   // Check if apiKey or credentials are missing
//   if (apiKey == null || credentials == null) {
//     print("Missing API key or user credentials");
//     // You can choose to navigate to a login or setup screen here if credentials are missing
//     runApp(const MyApp());
//     return;
//   }
//
//   // Initialize Stream Video
//   StreamVideo(
//     apiKey,
//     user: User(info: credentials.userInfo),
//     userToken: credentials.token.rawValue,
//     options: const StreamVideoOptions(
//       logPriority: Priority.verbose,
//       muteAudioWhenInBackground: true,
//       muteVideoWhenInBackground: true,
//     ),
//     pushNotificationManagerProvider: StreamVideoPushNotificationManager.create(
//       iosPushProvider: const StreamVideoPushProvider.apn(
//         name: 'flutter-apn',
//       ),
//       androidPushProvider: const StreamVideoPushProvider.firebase(
//         name: 'flutter-firebase',
//       ),
//       pushParams: const StreamVideoPushParams(
//         appName: "Example",
//         ios: IOSParams(iconName: 'IconMask'),
//       ),
//       registerApnDeviceToken: true,
//     ),
//   );
//
//   // Run the app after initialization
//   runApp(const MyApp());
// }
//
// class MyApp extends StatelessWidget {
//
//   const MyApp({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return MultiBlocProvider(
//       providers: [
//         BlocProvider<RegisterCubit>(create: (context) => RegisterCubit()),
//         BlocProvider<FetchUsersCubit>(
//             create: (context) =>
//                 FetchUsersCubit(firestore: FirebaseServices().firestore, auth: FirebaseServices().auth)),
//         BlocProvider<CallingsCubit>(create: (context) => CallingsCubit())
//       ],
//       child: MaterialApp(
//         title: 'Flutter Demo',
//         theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple), useMaterial3: true),
//         // Show login screen if no credentials found, else show the Register screen
//         home: const RegisterScreen(),
//       ),
//     );
//   }
// }

// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//
//   // Initialize Firebase
//   await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
//
//   // Configure Crashlytics
//   FlutterError.onError = (FlutterErrorDetails errorDetails) {
//     if (kDebugMode) {
//       FlutterError.dumpErrorToConsole(errorDetails);
//     } else {
//       FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
//     }
//   };
//
//   // Handle asynchronous errors not caught by Flutter framework
//   PlatformDispatcher.instance.onError = (error, stack) {
//     FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
//     return true;
//   };
//
//   // Initialize dependencies
//   await AppInjector.init();
//
//   // Set up Stream Video
//   // final prefs = locator.get<AppPreferences>();
//   // final credentials = prefs.userCredentials;
//
//   // if (credentials != null) {
//   //   final tokenResponse = await locator.get<TokenService>().loadToken(
//   //     userId: credentials.userInfo.id,
//   //     environment: prefs.environment,
//   //   );
//   //
//   //   AppInjector.registerStreamVideo(
//   //     tokenResponse,
//   //     User(info: credentials.userInfo),
//   //     prefs.environment,
//   //   );
//   // }
//
//   // await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
//   //
//   // await FirebaseServices.initFcmToken();
//   //
//   // // Activate App Check
//   // await FirebaseAppCheck.instance
//   //     .activate(androidProvider: AndroidProvider.playIntegrity, appleProvider: AppleProvider.deviceCheck);
//   //
//   // final prefs = locator.get<AppPreferences>();
//   // final credentials = prefs.userCredentials;
//   // if (credentials == null) return;
//   // final tokenResponse =
//   //     await locator.get<TokenService>().loadToken(userId: credentials.userInfo.id, environment: prefs.environment);
//   // // Initialise injector
//   // await AppInjector.init();
//   // final streamVideo =
//   //     AppInjector.registerStreamVideo(tokenResponse, User(info: credentials.userInfo), prefs.environment);
//   // streamVideo.observeCallDeclinedCallKitEvent();
//   final prefs = await SharedPreferences.getInstance();
//   final AppPreferences appPrefs = AppPreferences(prefs: prefs);
//
//   final apiKey = appPrefs.apiKey;
//   final credentials = appPrefs.userCredentials;
//   if (apiKey == null || credentials == null) {
//     return;
//   }
//   StreamVideo(
//     apiKey,
//     user: User(info: credentials.userInfo),
//     userToken: credentials.token.rawValue,
//     options: const StreamVideoOptions(
//       logPriority: Priority.verbose,
//       muteAudioWhenInBackground: true,
//       muteVideoWhenInBackground: true,
//     ),
//     pushNotificationManagerProvider: StreamVideoPushNotificationManager.create(
//       iosPushProvider: const StreamVideoPushProvider.apn(
//         name: 'flutter-apn',
//       ),
//       androidPushProvider: const StreamVideoPushProvider.firebase(
//         name: 'flutter-firebase',
//       ),
//       pushParams: const StreamVideoPushParams(
//         appName: "Ecample",
//         ios: IOSParams(iconName: 'IconMask'),
//       ),
//       registerApnDeviceToken: true,
//     ),
//   );
//
//   runApp(MyApp());
// }
//
// class MyApp extends StatelessWidget {
//   final client = StreamChatClient('8fqmp9ngwbm8', logLevel: Level.INFO);
//
//   @override
//   Widget build(BuildContext context) {
//     return MultiBlocProvider(
//       providers: [
//         BlocProvider<RegisterCubit>(create: (context) => RegisterCubit()),
//         BlocProvider<FetchUsersCubit>(
//             create: (context) =>
//                 FetchUsersCubit(firestore: FirebaseServices().firestore, auth: FirebaseServices().auth)),
//         BlocProvider<CallingsCubit>(create: (context) => CallingsCubit())
//       ],
//       child: MaterialApp(
//         title: 'Flutter Demo',
//         theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple), useMaterial3: true),
//         // home: const StreamDogFoodingApp(),
//         home: RegisterScreen(client),
//       ),
//     );
//   }
// }
