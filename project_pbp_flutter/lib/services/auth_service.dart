import 'dart:convert';
import 'package:http/http.dart' as http;

class AuthService {
  static const String baseUrl = 'http://localhost:3000/api';
  
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

      final response = await http.post(
        Uri.parse('$baseUrl/auth/logout'),
        headers: headers,
      );

      final data = jsonDecode(response.body);
      
      // Clear local data regardless of server response
      _currentUserId = null;
      _currentUser = null;
      
      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'] ?? 'Logout successful'
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Logout failed'
        };
      }
    } catch (e) {
      // Clear local data even if there's a network error
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

      final response = await http.get(
        Uri.parse('$baseUrl/auth/me'),
        headers: headers,
      );

      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        _currentUser = data['data'];
        return {
          'success': true,
          'data': data['data'],
          'message': data['message'] ?? 'User profile retrieved'
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to get user profile'
        };
      }
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
}