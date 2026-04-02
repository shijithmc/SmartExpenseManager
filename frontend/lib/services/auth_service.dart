import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

class AuthService {
  static Future<Map<String, dynamic>> signUp(
      String email, String password, String name) async {
    final response = await ApiService.post('auth/signup', {
      'email': email,
      'password': password,
      'name': name,
    });
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> confirmSignUp(
      String email, String code) async {
    final response = await ApiService.post('auth/confirm', {
      'email': email,
      'confirmationCode': code,
    });
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> signIn(
      String email, String password) async {
    final response = await ApiService.post('auth/signin', {
      'email': email,
      'password': password,
    });

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', data['token']);
      await prefs.setString('refresh_token', data['refreshToken']);
      await prefs.setString('user_id', data['userId']);
      await prefs.setString('user_email', data['email']);
      return data;
    }

    throw Exception('Sign in failed: ${response.body}');
  }

  static Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('refresh_token');
    await prefs.remove('user_id');
    await prefs.remove('user_email');
  }

  static Future<bool> isSignedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey('auth_token');
  }

  static Future<String?> getUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_email');
  }
}
