import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:giyas_ai/core/models/user.dart';

class AuthService {
  static const String _baseUrl = 'http://localhost:3000/api';

  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'user_data';

  // Get stored token
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  // Get stored user
  static Future<User?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString(_userKey);
    if (userData != null) {
      return User.fromJson(jsonDecode(userData));
    }
    return null;
  }

  // Get authentication headers
  static Future<Map<String, String>> getAuthHeaders() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // Store authentication data
  static Future<void> storeAuthData(String token, User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_userKey, jsonEncode(user.toJson()));
  }

  // Clear authentication data
  static Future<void> clearAuthData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
  }

  // Check if user is authenticated
  static Future<bool> isAuthenticated() async {
    final token = await getToken();
    return token != null;
  }

  // User registration
  static Future<AuthResult> register({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final user = User.fromJson(data['user']);
        final token = data['token'] as String;

        await storeAuthData(token, user);

        return AuthResult.success(user: user, token: token);
      } else {
        final error = jsonDecode(response.body);
        return AuthResult.failure(
            message: error['error'] ?? 'Registration failed');
      }
    } catch (e) {
      return AuthResult.failure(message: 'Network error: $e');
    }
  }

  // User login
  static Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final user = User.fromJson(data['user']);
        final token = data['token'] as String;

        await storeAuthData(token, user);

        return AuthResult.success(user: user, token: token);
      } else {
        final error = jsonDecode(response.body);
        return AuthResult.failure(message: error['error'] ?? 'Login failed');
      }
    } catch (e) {
      return AuthResult.failure(message: 'Network error: $e');
    }
  }

  // Get user profile
  static Future<AuthResult> getProfile() async {
    try {
      final token = await getToken();
      if (token == null) {
        return AuthResult.failure(message: 'No authentication token');
      }

      final response = await http.get(
        Uri.parse('$_baseUrl/auth/profile'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final user = User.fromJson(data['user']);

        // Update stored user data
        await storeAuthData(token, user);

        return AuthResult.success(user: user);
      } else {
        final error = jsonDecode(response.body);
        return AuthResult.failure(
            message: error['error'] ?? 'Failed to get profile');
      }
    } catch (e) {
      return AuthResult.failure(message: 'Network error: $e');
    }
  }

  // Update user profile
  static Future<AuthResult> updateProfile({
    String? name,
    UserPreferences? preferences,
  }) async {
    try {
      final token = await getToken();
      if (token == null) {
        return AuthResult.failure(message: 'No authentication token');
      }

      final updateData = <String, dynamic>{};
      if (name != null) updateData['name'] = name;
      if (preferences != null) updateData['preferences'] = preferences.toJson();

      final response = await http.put(
        Uri.parse('$_baseUrl/auth/profile'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(updateData),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final user = User.fromJson(data['user']);

        // Update stored user data
        await storeAuthData(token, user);

        return AuthResult.success(user: user);
      } else {
        final error = jsonDecode(response.body);
        return AuthResult.failure(
            message: error['error'] ?? 'Failed to update profile');
      }
    } catch (e) {
      return AuthResult.failure(message: 'Network error: $e');
    }
  }

  // Change password
  static Future<AuthResult> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final token = await getToken();
      if (token == null) {
        return AuthResult.failure(message: 'No authentication token');
      }

      final response = await http.put(
        Uri.parse('$_baseUrl/auth/change-password'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'currentPassword': currentPassword,
          'newPassword': newPassword,
        }),
      );

      if (response.statusCode == 200) {
        return AuthResult.success(message: 'Password changed successfully');
      } else {
        final error = jsonDecode(response.body);
        return AuthResult.failure(
            message: error['error'] ?? 'Failed to change password');
      }
    } catch (e) {
      return AuthResult.failure(message: 'Network error: $e');
    }
  }

  // Refresh token
  static Future<AuthResult> refreshToken() async {
    try {
      final token = await getToken();
      if (token == null) {
        return AuthResult.failure(message: 'No authentication token');
      }

      final response = await http.post(
        Uri.parse('$_baseUrl/auth/refresh-token'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final user = User.fromJson(data['user']);
        final newToken = data['token'] as String;

        await storeAuthData(newToken, user);

        return AuthResult.success(user: user, token: newToken);
      } else {
        final error = jsonDecode(response.body);
        return AuthResult.failure(
            message: error['error'] ?? 'Failed to refresh token');
      }
    } catch (e) {
      return AuthResult.failure(message: 'Network error: $e');
    }
  }

  // Logout
  static Future<void> logout() async {
    await clearAuthData();
  }
}

class AuthResult {
  final bool isSuccess;
  final User? user;
  final String? token;
  final String? message;

  const AuthResult._({
    required this.isSuccess,
    this.user,
    this.token,
    this.message,
  });

  factory AuthResult.success({User? user, String? token, String? message}) {
    return AuthResult._(
      isSuccess: true,
      user: user,
      token: token,
      message: message,
    );
  }

  factory AuthResult.failure({String? message}) {
    return AuthResult._(
      isSuccess: false,
      message: message,
    );
  }
}
