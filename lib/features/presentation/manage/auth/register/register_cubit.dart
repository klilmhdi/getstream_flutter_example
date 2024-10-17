import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth/firebase_auth.dart' hide UserInfo, User;
import 'package:firebase_database/firebase_database.dart';
import 'package:getstream_flutter_example/core/di/injector.dart';
import 'package:getstream_flutter_example/core/utils/consts/user_auth_controller.dart';
import 'package:getstream_flutter_example/features/data/repo/app_preferences.dart';
import 'package:getstream_flutter_example/features/data/services/firebase_services.dart';
import 'package:getstream_flutter_example/features/presentation/manage/auth/register/register_state.dart';
import 'package:stream_video_flutter/stream_video_flutter.dart';

class RegisterCubit extends Cubit<RegisterState> {
  RegisterCubit() : super(RegisterInitState());

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _database = FirebaseDatabase.instance.ref('users');

  // Future<void> registerUser(String name, String email, String password, String type) async {
  //   emit(RegisterLoadingState());
  //
  //   try {
  //     // Create User in Firebase Auth
  //     UserCredential userCredential = await _auth.createUserWithEmailAndPassword(email: email, password: password);
  //
  //     final user = userCredential.user;
  //     final appPreferences = locator<AppPreferences>();
  //
  //     if (user == null) {
  //       emit(RegisterFailedState("User creation failed. Please try again."));
  //       return;
  //     }
  //
  //     String uid = user.uid; // Correctly obtain the authenticated user's UID
  //
  //     // Fetch Platform
  //     String platform = defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS
  //         ? "Mobile"
  //         : "Web";
  //
  //     // Handle Web Token
  //     String? token;
  //     if (platform == "Web") {
  //       token = user.uid; // Use UID as token for simplicity on Web
  //     } else {
  //       token = await FirebaseMessaging.instance.getToken(); // Get FCM token for Mobile
  //     }
  //
  //     // Save User Data to FirebaseFirestore Database with correct UID
  //     await FirebaseServices().uploadUserDataToFirebase(uid, name: name, email: email, role: type).then((_) async {
  //       // Save User Data to Firebase Realtime Database
  //       await _database
  //           .child(uid)
  //           .set({'name': name, 'email': email, 'platform': platform, 'token': token, 'role': type}).then(
  //         (_) async {
  //           final user = UserInfo(id: uid, name: name, role: type.toLowerCase() == "teacher" ? "admin" : "user", image: "");
  //           final authController = locator.get<UserAuthController>();
  //           await authController.login(User(info: user), appPreferences.environment);
  //           print(">?>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>User: $user");
  //         },
  //       );
  //     });
  //
  //     // Emit Success
  //     emit(RegisterSuccessState(user: user));
  //   } on FirebaseAuthException catch (e) {
  //     // Handle Firebase Auth specific errors
  //     String errorMessage;
  //     switch (e.code) {
  //       case 'email-already-in-use':
  //         errorMessage = "This email is already in use.";
  //         break;
  //       case 'invalid-email':
  //         errorMessage = "The email address is not valid.";
  //         break;
  //       case 'weak-password':
  //         errorMessage = "The password is too weak.";
  //         break;
  //       default:
  //         errorMessage = e.message ?? "Registration failed. Please try again.";
  //     }
  //     emit(RegisterFailedState(errorMessage));
  //   } catch (e, s) {
  //     print("StackTrace: ${s.toString()}");
  //     print("Error: ${e.toString()}");
  //     taggedLogger(tag: "StackTrace: ${s.toString()}");
  //     taggedLogger(tag: "Error: ${e.toString()}");
  //     String errorMessage = "Registration failed. Please try again.";
  //     emit(RegisterFailedState(errorMessage));
  //   }
  // }
  Future<void> registerUser(String name, String email, String password, String type) async {
    emit(RegisterLoadingState());

    try {
      // Create User in Firebase Auth
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(email: email, password: password);

      final user = userCredential.user;
      final appPreferences = locator<AppPreferences>();

      if (user == null) {
        emit(RegisterFailedState("User creation failed. Please try again."));
        return;
      }

      String uid = user.uid; // Correctly obtain the authenticated user's UID

      // Fetch Platform
      String platform = defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS
          ? "Mobile"
          : "Web";

      // Handle Web Token
      String? token;
      if (platform == "Web") {
        token = user.uid; // Use UID as token for simplicity on Web
      } else {
        token = await FirebaseMessaging.instance.getToken(); // Get FCM token for Mobile
      }

      // Save User Data to FirebaseFirestore Database with correct UID
      await FirebaseServices().uploadUserDataToFirebase(uid, name: name, email: email, role: type).then((_) async {
        // Save User Data to Firebase Realtime Database
        await _database
            .child(uid)
            .set({'name': name, 'email': email, 'platform': platform, 'token': token, 'role': type}).then(
              (_) async {
            final userInfo = UserInfo(
              id: uid,
              name: name,
              role: type.toLowerCase() == "teacher" ? "admin" : "user",
              image: "",
            );
            final user = User(info: userInfo);
            final authController = locator.get<UserAuthController>();

            // Properly log in the user with the correct environment
            await authController.login(user, appPreferences.environment);

            print(">?>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>User: $userInfo");
          },
        );
      });

      // Emit Success
      emit(RegisterSuccessState(user: user));
    } on FirebaseAuthException catch (e) {
      // Handle Firebase Auth specific errors
      String errorMessage;
      switch (e.code) {
        case 'email-already-in-use':
          errorMessage = "This email is already in use.";
          break;
        case 'invalid-email':
          errorMessage = "The email address is not valid.";
          break;
        case 'weak-password':
          errorMessage = "The password is too weak.";
          break;
        default:
          errorMessage = e.message ?? "Registration failed. Please try again.";
      }
      emit(RegisterFailedState(errorMessage));
    } catch (e, s) {
      print("StackTrace: ${s.toString()}");
      print("Error: ${e.toString()}");
      String errorMessage = "Registration failed. Please try again.";
      emit(RegisterFailedState(errorMessage));
    }
  }

}
