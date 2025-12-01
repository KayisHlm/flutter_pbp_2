import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:project_pbp_flutter/services/api_service.dart';

class AuthService {
  static const String baseUrl = 'http://10.171.254.139:3000/api';
  static bool offline = true;
  
  static String? _currentUserId;
  static Map<String, dynamic>? _currentUser;

  static String? get currentUserId => _currentUserId;
  static Map<String, dynamic>? get currentUser => _currentUser;
  static bool get isAuthenticated => _currentUserId != null;

  static Map<String, String> get headers {
    return {
      'Content-Type': 'application/json',
      if (_currentUserId != null) 'X-User-Id': _currentUserId!,
    };
  }

  static Future<Map<String, dynamic>> register({
    required String username,
    required String email,
    required String password,
    String? name,
  }) async {
    if (offline) {
      final user = ApiService.ensureOfflineUser(username: username, email: email, name: name ?? username);
      _currentUserId = user.id;
      _currentUser = user.toJson();
      return {
        'success': true,
        'data': _currentUser,
        'message': 'Registration successful'
      };
    }
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'email': email,
          'password': password,
          'name': name ?? username,
        }),
      );

      final data = jsonDecode(response.body);
      
      if (response.statusCode == 201) {
        return {
          'success': true,
          'data': data['data'],
          'message': data['message'] ?? 'Registration successful'
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Registration failed'
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}'
      };
    }
  }

  static Future<Map<String, dynamic>> login({
    required String username,
    required String password,
  }) async {
    if (offline) {
      final user = ApiService.ensureOfflineUser(username: username, name: username);
      _currentUserId = user.id;
      _currentUser = user.toJson();
      return {
        'success': true,
        'data': {'user': _currentUser, 'userId': _currentUserId},
        'message': 'Login successful'
      };
    }
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'password': password,
        }),
      );

      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        _currentUserId = data['data']['userId'];
        _currentUser = data['data']['user'];
        
        return {
          'success': true,
          'data': data['data'],
          'message': data['message'] ?? 'Login successful'
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Login failed'
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}'
      };
    }
  }

  static Future<Map<String, dynamic>> logout() async {
    try {
      if (_currentUserId == null) {
        return {
          'success': false,
          'message': 'No user logged in'
        };
      }
      
      _currentUserId = null;
      _currentUser = null;
      return {
        'success': true,
        'message': 'Logout successful'
      };
    } catch (e) {
      _currentUserId = null;
      _currentUser = null;
      
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}'
      };
    }
  }

  static Future<Map<String, dynamic>> getCurrentUser() async {
    try {
      if (_currentUserId == null) {
        return {
          'success': false,
          'message': 'No user logged in'
        };
      }
      return {
        'success': true,
        'data': _currentUser,
        'message': 'User profile retrieved'
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}'
      };
    }
  }

  static void clearSession() {
    _currentUserId = null;
    _currentUser = null;
  }

  static Future<Map<String, dynamic>> loginOffline({
    required String username,
    required String password,
  }) async {
    final user = ApiService.ensureOfflineUser(username: username, name: username);
    _currentUserId = user.id;
    _currentUser = user.toJson();
    return {
      'success': true,
      'data': {'user': _currentUser, 'userId': _currentUserId},
      'message': 'Login berhasil'
    };
  }
}
