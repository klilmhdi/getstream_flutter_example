import 'dart:convert';
import 'package:getstream_flutter_example/features/data/models/user_credentials_model.dart';
import 'package:getstream_flutter_example/features/data/services/token_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppPreferences {
  const AppPreferences({
    required SharedPreferences prefs,
  }) : _prefs = prefs;

  final SharedPreferences _prefs;

  static const String _kUserCredentialsPref = 'user_credentials';
  static const String _kApiKeyPref = 'z3k88gbquy4a';
  static const String _kEnvironemntPref = 'environment';

  EnvEnum get environment => EnvEnum.fromSubdomain(_prefs.getString(_kEnvironemntPref) ?? EnvEnum.pronto.name);

  UserCredentialsModel? get userCredentials {
    final jsonString = _prefs.getString(_kUserCredentialsPref);
    if (jsonString == null) {
      print("No user credentials found in SharedPreferences.");
      return null;
    }

    try {
      final json = jsonDecode(jsonString) as Map<String, Object?>;
      return UserCredentialsModel.fromJson(json);
    } catch (e) {
      print("Error decoding user credentials: $e");
      return null;
    }
  }

  Future<void> setUserCredentials(UserCredentialsModel credentials) async {
    final jsonString = jsonEncode(credentials.toJson());
    await _prefs.setString(_kUserCredentialsPref, jsonString);
    print("User credentials saved in SharedPreferences.");
  }

  Future<bool> setApiKey(String apiKey) => _prefs.setString(_kApiKeyPref, apiKey);

  Future<bool> setEnvEnum(EnvEnum env) => _prefs.setString(_kEnvironemntPref, env.name);

  Future<bool> clearUserCredentials() async =>
      await _prefs.remove(_kUserCredentialsPref) && await _prefs.remove(_kApiKeyPref);

  Future<void> saveCredentials(UserCredentialsModel credentials) async {
    final prefs = await SharedPreferences.getInstance();
    final appPrefs = AppPreferences(prefs: prefs);

    await appPrefs.setUserCredentials(credentials);
    await appPrefs.setApiKey(_kApiKeyPref);
  }
}
