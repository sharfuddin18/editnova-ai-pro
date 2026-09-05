import 'package:shared_preferences/shared_preferences.dart';

class AuthSession {
  const AuthSession._();

  static const _tokenKey = 'authToken';
  static const _usernameKey = 'authUsername';

  static Future<void> save(String token, String username) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_usernameKey, username);
  }

  static Future<String?> token() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  static Future<String?> username() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_usernameKey);
  }

  static Future<Map<String, String>> headers() async {
    final value = await token();
    return {
      'Content-Type': 'application/json',
      if (value != null && value.isNotEmpty) 'Authorization': 'Bearer $value',
    };
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_usernameKey);
  }
}
