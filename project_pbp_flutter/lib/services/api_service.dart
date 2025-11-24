import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:project_pbp_flutter/models/user.dart';
import 'package:project_pbp_flutter/models/hutang.dart';
import 'package:project_pbp_flutter/services/auth_service.dart';

class ApiService {
  static const String baseUrl = 'http://localhost:3000/api';
  
  // Users API
  static Future<List<User>> getUsers() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/users'),
        headers: AuthService.headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return (data['data'] as List).map((userJson) => User.fromJson(userJson)).toList();
        } else {
          throw Exception(data['message'] ?? 'Failed to load users');
        }
      } else {
        throw Exception('Failed to load users: ${response.statusCode}');
      }
    } catch (e) {
      print('Error getting users: $e');
      rethrow;
    }
  }

  static Future<User> getUser(String id) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/users/$id'),
        headers: AuthService.headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return User.fromJson(data['data']);
        } else {
          throw Exception(data['message'] ?? 'Failed to load user');
        }
      } else {
        throw Exception('Failed to load user: ${response.statusCode}');
      }
    } catch (e) {
      print('Error getting user: $e');
      rethrow;
    }
  }

  static Future<User> createUser({
    required String name,
    String? phone,
    String? address,
    String? photoUrl,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/users'),
        headers: AuthService.headers,
        body: json.encode({
          'name': name,
          'phone': phone,
          'address': address,
          'photoUrl': photoUrl,
        }),
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return User.fromJson(data['data']);
        } else {
          throw Exception(data['message'] ?? 'Failed to create user');
        }
      } else {
        throw Exception('Failed to create user: ${response.statusCode}');
      }
    } catch (e) {
      print('Error creating user: $e');
      rethrow;
    }
  }

  // Hutangs API
  static Future<List<Hutang>> getHutangs() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/hutangs'),
        headers: AuthService.headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return (data['data'] as List).map((hutangJson) => Hutang.fromJson(hutangJson)).toList();
        } else {
          throw Exception(data['message'] ?? 'Failed to load hutangs');
        }
      } else {
        throw Exception('Failed to load hutangs: ${response.statusCode}');
      }
    } catch (e) {
      print('Error getting hutangs: $e');
      rethrow;
    }
  }

  static Future<Hutang> getHutang(String id) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/hutangs/$id'),
        headers: AuthService.headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return Hutang.fromJson(data['data']);
        } else {
          throw Exception(data['message'] ?? 'Failed to load hutang');
        }
      } else {
        throw Exception('Failed to load hutang: ${response.statusCode}');
      }
    } catch (e) {
      print('Error getting hutang: $e');
      rethrow;
    }
  }

  static Future<Hutang> createHutang({
    required String description,
    required double amount,
    required DateTime dueDate,
    required String debtorId,
    String? notes,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/hutangs'),
        headers: AuthService.headers,
        body: json.encode({
          'description': description,
          'amount': amount,
          'dueDate': dueDate.toIso8601String(),
          'debtorId': debtorId,
          'notes': notes,
        }),
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return Hutang.fromJson(data['data']);
        } else {
          throw Exception(data['message'] ?? 'Failed to create hutang');
        }
      } else {
        throw Exception('Failed to create hutang: ${response.statusCode}');
      }
    } catch (e) {
      print('Error creating hutang: $e');
      rethrow;
    }
  }

  static Future<Hutang> addPayment({
    required String hutangId,
    required double amount,
    String? notes,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/hutangs/$hutangId/payments'),
        headers: AuthService.headers,
        body: json.encode({
          'amount': amount,
          'notes': notes,
        }),
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return Hutang.fromJson(data['data']);
        } else {
          throw Exception(data['message'] ?? 'Failed to add payment');
        }
      } else {
        throw Exception('Failed to add payment: ${response.statusCode}');
      }
    } catch (e) {
      print('Error adding payment: $e');
      rethrow;
    }
  }

  // Summary API
  static Future<Map<String, dynamic>> getSummary() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/summary'),
        headers: AuthService.headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return data['data'] as Map<String, dynamic>;
        } else {
          throw Exception(data['message'] ?? 'Failed to load summary');
        }
      } else {
        throw Exception('Failed to load summary: ${response.statusCode}');
      }
    } catch (e) {
      print('Error getting summary: $e');
      rethrow;
    }
  }

  // Helper method untuk check connection
  static Future<bool> checkConnection() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/health'),
        headers: {'Content-Type': 'application/json'},
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Connection check failed: $e');
      return false;
    }
  }
}