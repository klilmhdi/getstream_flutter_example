import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:firebase_auth/firebase_auth.dart' hide UserInfo, User;
import 'package:firebase_database/firebase_database.dart';
import 'package:getstream_flutter_example/core/di/injector.dart';
import 'package:getstream_flutter_example/core/utils/consts/functions.dart';
import 'package:getstream_flutter_example/core/utils/consts/user_auth_controller.dart';
import 'package:getstream_flutter_example/features/data/repo/app_preferences.dart';
import 'package:getstream_flutter_example/features/data/services/firebase_services.dart';
import 'package:getstream_flutter_example/features/data/services/token_service.dart';
import 'package:getstream_flutter_example/features/presentation/manage/auth/register/register_state.dart';
import 'package:stream_video_flutter/stream_video_flutter.dart';

import '../../../../data/models/user_credentials_model.dart';

class RegisterCubit extends Cubit<RegisterState> {
  RegisterCubit() : super(RegisterInitState());

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _database = FirebaseDatabase.instance.ref('users');

  Future<void> registerUser(String name, String email, String password, String type) async {
    emit(RegisterLoadingState());

    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      final user = userCredential.user;

      if (user == null) {
        emit(RegisterFailedState("User creation failed. Please try again."));
        return;
      }

      String uid = user.uid;
      String platform = defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS
          ? "Mobile"
          : "Web";

      final rules = type.toLowerCase() == "teacher" ? "admin" : "user";
          final images = type.toLowerCase() == "teacher"
          ? "https://d26oc3sg82pgk3.cloudfront.net/files/media/edit/image/56073/article_full%401x.jpg"
          : "https://static.wikia.nocookie.net/dragonball/images/b/ba/Goku_anime_profile.png/revision/latest?cb=20240723150655";

      final authController = locator.get<UserAuthController>();
      final appPreferences = locator<AppPreferences>();

      String? token = platform == "Web" ? user.uid : await FirebaseMessaging.instance.getToken();

      await FirebaseServices().uploadUserDataToFirebase(uid, name: name, email: email, role: type).then(
            (_) async {
          await _database.child(uid).set({'name': name, 'email': email, 'platform': platform, 'token': token, 'role': type});

          final user = UserInfo(id: uid, name: name, role: rules, image: images);
          print("User registered successfully: $user");

          // Login user and save credentials
          await authController.login(User(info: user), appPreferences.environment);
          print("User logged in successfully and credentials saved.");

          // Save user credentials in SharedPreferences
          await appPreferences.setUserCredentials(UserCredentialsModel(
            token: UserToken.jwt(generateJwt(userId: uid, secretKey: '7azrmrktn5q59se4nvdetrzepn3gg5v7evuxhkj5x7ydg29hfdcbp9ph483vyhwm')),
            userInfo: user,
          ));

          emit(RegisterSuccessState(user: User(info: user)));
        },
      );
    } catch (e) {
      emit(RegisterFailedState("Registration failed. Please try again."));
    }
  }
}
