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
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    final body = jsonDecode(response.body);
    throw Exception(body['error'] ?? 'Registration failed');
  }

  static Future<Map<String, dynamic>> signIn(
      String email, String password) async {
    final response = await ApiService.post('auth/signin', {
      'email': email,
      'password': password,
    });

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      await _saveSession(data);
      return data;
    }

    final body = jsonDecode(response.body);
    throw Exception(body['error'] ?? 'Sign in failed');
  }

  static Future<Map<String, dynamic>> requestOtp(String email) async {
    final response = await ApiService.post('auth/request-otp', {
      'email': email,
    });
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    final body = jsonDecode(response.body);
    throw Exception(body['error'] ?? 'Failed to send OTP');
  }

  static Future<Map<String, dynamic>> verifyOtp(
      String email, String code) async {
    final response = await ApiService.post('auth/verify-otp', {
      'email': email,
      'code': code,
    });

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      await _saveSession(data);
      return data;
    }

    final body = jsonDecode(response.body);
    throw Exception(body['error'] ?? 'OTP verification failed');
  }

  static Future<void> _saveSession(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', data['token']);
    await prefs.setString('refresh_token', data['refreshToken']);
    await prefs.setString('user_id', data['userId']);
    await prefs.setString('user_email', data['email']);
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
