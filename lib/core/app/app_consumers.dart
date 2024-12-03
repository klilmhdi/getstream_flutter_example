import 'package:bloc/bloc.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:flutter_callkit_incoming/entities/call_kit_params.dart';
import 'package:stream_video_push_notification/stream_video_push_notification.dart';
import 'package:uuid/uuid.dart';

import '../../features/data/repo/app_preferences.dart';
import '../../features/data/services/token_service.dart';
import '../../features/presentation/view/meet/call_screen.dart';
import '../../firebase_options.dart';
import '../di/injector.dart';
import 'package:stream_video_flutter/stream_video_flutter.dart' hide ConnectionState;

import '../utils/bloc_observer.dart';
import '../utils/controllers/user_auth_controller.dart';

@pragma('vm:entry-point') // Required for Flutter on Android
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('Handling a background message: ${message.messageId}');

  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Handle the message
  await AppInjector.init();

  try {
    final prefs = locator.get<AppPreferences>();
    final credentials = prefs.userCredentials;
    if (credentials == null) return;

    final tokenResponse = await locator.get<TokenService>().loadToken(
          userId: credentials.userInfo.id,
          environment: prefs.environment,
        );

    final streamVideo = AppInjector.registerStreamVideo(
      tokenResponse,
      User(info: credentials.userInfo),
      prefs.environment,
    );

    streamVideo.observeCallDeclinedCallKitEvent();
    await AppConsumers().handleRemoteMessage(message);
  } catch (e, stk) {
    debugPrint('Error handling remote message: $e');
    debugPrint(stk.toString());
  }

  // Reset dependencies to clean up
  return AppInjector.reset();
}

class AppConsumers {
  final compositeSubscription = CompositeSubscription();

  // initialize app services when the app begin
  Future<void> initializeServices(BuildContext context) async {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    FirebaseDatabase database = FirebaseDatabase.instance;
    // showCallkitIncoming(const Uuid().v4());

    Bloc.observer = MyBlocObserver();
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

    await handleSavedLogin();
  }

  // save login
  Future<void> handleSavedLogin() async {
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

  // remote message
  Future<bool> handleRemoteMessage(RemoteMessage message) async {
    final streamVideo = locator.get<StreamVideo>();
    return streamVideo.handleVoipPushNotification(message.data);
  }

  // push notification
  void initPushNotificationManagerIfAvailable(BuildContext context) {
    if (!locator.isRegistered<StreamVideo>()) return;

    _observeFcmMessages();
    observeCallKitEvents(context);
  }

  // consume incoming call
  Future<void> consumeIncomingCall(context) async {
    if (!locator.isRegistered<StreamVideo>()) return;

    final streamVideo = locator.get<StreamVideo>();
    final calls = await streamVideo.pushNotificationManager?.activeCalls();

    if (calls == null || calls.isEmpty) return;

    final callResult = await streamVideo.consumeIncomingCall(
      uuid: calls.first.uuid!,
      cid: calls.first.callCid!,
    );

    callResult.fold(success: (result) async {
      final call = result.data;
      await call.accept();

      final extra = (
        call: result.data,
        connectOptions: null,
      );

      Navigator.push(context,
          MaterialPageRoute(builder: (context) => CallScreen(call: extra.call, connectOptions: extra.connectOptions)));
    }, failure: (error) {
      debugPrint('*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>Error consuming incoming call: $error');
    });
  }

  // observer callkit
  void observeCallKitEvents(context) {
    final streamVideo = locator.get<StreamVideo>();

    StreamVideo.instance.pushNotificationManager?.endAllCalls();

    compositeSubscription.add(
      streamVideo.observeCoreCallKitEvents(
        onCallAccepted: (callToJoin) {
          // Navigate to the call screen.
          final extra = (
            call: callToJoin,
            connectOptions: null,
          );

          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => CallScreen(call: extra.call, connectOptions: extra.connectOptions)));
        },
      ),
    );
  }

  /// private functions
  // observer FCM
  _observeFcmMessages() {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    compositeSubscription.add(
      FirebaseMessaging.onMessage.listen(handleRemoteMessage),
    );
  }

}
