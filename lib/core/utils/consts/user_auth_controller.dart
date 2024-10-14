import 'package:flutter/cupertino.dart';
import 'package:getstream_flutter_example/core/di/injector.dart';
import 'package:getstream_flutter_example/features/data/models/user_credentials_model.dart';
import 'package:getstream_flutter_example/features/data/repo/app_preferences.dart';
import 'package:getstream_flutter_example/features/data/repo/user_auth_repository.dart';
import 'package:getstream_flutter_example/features/data/repo/user_chat_repository.dart';
import 'package:getstream_flutter_example/features/data/services/token_service.dart';
import 'package:stream_chat_flutter/stream_chat_flutter.dart' hide User;
import 'package:stream_video_flutter/stream_video_flutter.dart';

class UserAuthController extends ChangeNotifier {
  UserAuthController({
    required AppPreferences prefs,
    required TokenService tokenService,
  })  : _prefs = prefs,
        _tokenService = tokenService;

  final AppPreferences _prefs;
  final TokenService _tokenService;

  UserAuthRepository? _authRepo;

  /// Returns the current user if they are logged in, or null if they are not.
  UserInfo? get currentUser => _currentUser;
  UserInfo? _currentUser;

  /// Logs in the given [user] and returns the user credentials.
  Future<UserCredentialsModel> login(User user, EnvEnum environment) async {
    final tokenResponse = await _tokenService.loadToken(
      userId: user.id,
      environment: environment,
    );
    await _prefs.setApiKey(tokenResponse.apiKey);
    await _prefs.setEnvEnum(environment);

    _authRepo ??=
        locator.get<UserAuthRepository>(param1: user, param2: tokenResponse);
    final credentials = await _authRepo!.login();
    _currentUser = credentials.userInfo;

    // Store the user credentials if the user is not anonymous.
    if (_authRepo!.currentUserType != UserType.anonymous) {
      await _prefs.setUserCredentials(credentials);
    }

    notifyListeners();
    return credentials;
  }

  /// Logs out the current user.
  Future<void> logout() async {
    _currentUser = null;

    if (_authRepo != null) {
      await _authRepo!.logout();
      _authRepo = null;

      // Unregister the video client.
      locator.unregister<StreamVideo>(
        disposingFunction: (_) => StreamVideo.reset(),
      );

      locator.unregister<StreamChatClient>();
      locator.unregister<UserChatRepository>();
    }

    await _prefs.clearUserCredentials();
    notifyListeners();
  }
}
