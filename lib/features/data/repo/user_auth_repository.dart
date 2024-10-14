import 'package:getstream_flutter_example/features/data/models/user_credentials_model.dart';
import 'package:stream_video_flutter/stream_video_flutter.dart';

import '../services/token_service.dart';

class UserAuthRepository {
  const UserAuthRepository({required this.videoClient, required this.tokenService});

  final TokenService tokenService;
  final StreamVideo videoClient;

  Future<UserCredentialsModel> login() async {
    final response = await videoClient.connect();
    final userToken = response.getDataOrNull();
    if (userToken == null) {
      print(">>>>>>>>>>>>>>>>>>>>>>user token is null!!!");
      throw Exception('Failed to connect user');
    }

    return UserCredentialsModel(token: userToken, userInfo: currentUser);
  }

  UserInfo get currentUser => videoClient.currentUser;

  UserType get currentUserType => videoClient.currentUserType;

  Future<void> logout() => videoClient.disconnect();
}

extension on UserResponseData {
  // ignore: unused_element
  UserInfo toUserInfo() {
    return UserInfo(id: id, role: role, name: name ?? '', image: image, teams: teams);
  }
}
