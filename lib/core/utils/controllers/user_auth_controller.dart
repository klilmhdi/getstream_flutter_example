import 'package:flutter/cupertino.dart';
import 'package:getstream_flutter_example/core/di/injector.dart';
import 'package:getstream_flutter_example/features/data/repo/user_chat_repository.dart';
import 'package:stream_chat_flutter/stream_chat_flutter.dart' hide User;
import 'package:stream_video_flutter/stream_video_flutter.dart';

import '../../../features/data/models/user_credentials_model.dart';
import '../../../features/data/repo/app_preferences.dart';
import '../../../features/data/repo/user_auth_repository.dart';
import '../../../features/data/services/token_service.dart';

class UserAuthController extends ChangeNotifier {
  UserAuthController({
    required AppPreferences prefs,
    required TokenService tokenService,
  })  : _prefs = prefs,
        _tokenService = tokenService;

  final AppPreferences _prefs;
  final TokenService _tokenService;

  UserAuthRepository? _authRepo;

  UserInfo? _currentUser;

  // Returns the current user
  UserInfo? get currentUser => _currentUser;

  Future<UserCredentialsModel> login(User user, EnvEnum environment) async {
    final tokenResponse = await _tokenService.loadToken(
      userId: user.id,
      environment: environment,
    );

    await _prefs.setApiKey(tokenResponse.apiKey);
    await _prefs.setEnvEnum(environment);

    // Initialize auth repository
    _authRepo ??= locator.get<UserAuthRepository>(param1: user, param2: tokenResponse);

    // Login and get user credentials
    final credentials = await _authRepo!.login();

    // Sync the current user info with the returned credentials
    _currentUser = credentials.userInfo;

    // If not anonymous, store the credentials
    if (_authRepo!.currentUserType != UserType.anonymous) {
      await _prefs.setUserCredentials(credentials);
    }

    notifyListeners();
    return credentials;
  }

  Future<void> logout() async {
    _currentUser = null;
    if (_authRepo != null) {
      await _authRepo!.logout();
      _authRepo = null;
      locator.unregister<StreamVideo>();
      locator.unregister<StreamChatClient>();
      locator.unregister<UserChatRepository>();
    }
    await _prefs.clearUserCredentials();
    notifyListeners();
  }
}