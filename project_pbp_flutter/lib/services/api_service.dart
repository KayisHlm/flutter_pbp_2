import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:project_pbp_flutter/models/user.dart';
import 'package:project_pbp_flutter/models/hutang.dart';
import 'package:project_pbp_flutter/services/auth_service.dart';

class ApiService {
  static const String baseUrl = 'http://localhost:3000/api';
  static bool offline = false;
  static final List<User> _users = [];
  static final List<Hutang> _hutangs = [];

  static String _genId() {
    final r = Random();
    return '${DateTime.now().millisecondsSinceEpoch}${r.nextInt(999999)}';
  }

  static User _ensureUserByEmail(String email, {String? name}) {
    final idx = _users.indexWhere(
      (u) => (u.email ?? '').toLowerCase() == email.toLowerCase(),
    );
    if (idx != -1) return _users[idx];
    final user = User(
      id: _genId(),
      name: name ?? email.split('@').first,
      email: email,
      phone: null,
      address: null,
      photoUrl: null,
      createdAt: DateTime.now().toIso8601String(),
      updatedAt: DateTime.now().toIso8601String(),
    );
    _users.add(user);
    return user;
  }

  // Users API
  static Future<List<User>> getUsers() async {
    if (offline) {
      final result = _users.map((u) {
        final userHutangs = _hutangs
            .where((h) => h.debtor.id == u.id && h.status != 'paid')
            .toList();
        final totalOutstanding = userHutangs.fold<double>(
          0.0,
          (sum, h) => sum + h.remainingAmount,
        );
        return User(
          id: u.id,
          name: u.name,
          email: u.email,
          phone: u.phone,
          address: u.address,
          photoUrl: u.photoUrl,
          totalHutang: totalOutstanding,
          jumlahHutang: userHutangs.length,
          createdAt: u.createdAt,
          updatedAt: u.updatedAt,
        );
      }).toList();
      return result;
    }
    final resp = await http.get(
      Uri.parse('$baseUrl/users'),
      headers: AuthService.headers,
    );
    final data = jsonDecode(resp.body);
    if (resp.statusCode == 200 && data['success'] == true) {
      final List<dynamic> list = data['data'];
      return list.map((e) => User.fromJson(e)).toList();
    }
    throw Exception(data['message'] ?? 'Gagal memuat users');
  }

  static Future<User> getUser(String id) async {
    if (offline) {
      final u = _users.firstWhere((x) => x.id == id);
      final userHutangs = _hutangs
          .where((h) => h.debtor.id == u.id && h.status != 'paid')
          .toList();
      final totalOutstanding = userHutangs.fold<double>(
        0.0,
        (sum, h) => sum + h.remainingAmount,
      );
      return User(
        id: u.id,
        name: u.name,
        email: u.email,
        phone: u.phone,
        address: u.address,
        photoUrl: u.photoUrl,
        totalHutang: totalOutstanding,
        jumlahHutang: userHutangs.length,
        createdAt: u.createdAt,
        updatedAt: u.updatedAt,
      );
    }
    final resp = await http.get(
      Uri.parse('$baseUrl/users/$id'),
      headers: AuthService.headers,
    );
    final data = jsonDecode(resp.body);
    if (resp.statusCode == 200 && data['success'] == true) {
      return User.fromJson(data['data']);
    }
    throw Exception(data['message'] ?? 'Gagal memuat user');
  }

  static Future<User> createUser({
    required String name,
    String? phone,
    String? address,
    String? photoUrl,
  }) async {
    if (offline) {
      final user = User(
        id: _genId(),
        name: name,
        email: null,
        phone: phone,
        address: address,
        photoUrl: photoUrl,
        createdAt: DateTime.now().toIso8601String(),
        updatedAt: DateTime.now().toIso8601String(),
      );
      _users.add(user);
      return user;
    }
    throw Exception(
      'Membuat user penghutang dinonaktifkan. Daftarkan melalui AuthService.register',
    );
  }

  // Hutangs API
  static Future<List<Hutang>> getHutangs() async {
    if (offline) {
      return List<Hutang>.from(_hutangs);
    }
    final resp = await http.get(
      Uri.parse('$baseUrl/hutangs'),
      headers: AuthService.headers,
    );
    final data = jsonDecode(resp.body);
    if (resp.statusCode == 200 && data['success'] == true) {
      final List<dynamic> list = data['data'];
      return list.map((e) => Hutang.fromJson(e)).toList();
    }
    throw Exception(data['message'] ?? 'Gagal memuat hutang');
  }

  static Future<Hutang> getHutang(String id) async {
    if (offline) {
      return _hutangs.firstWhere((h) => h.id == id);
    }
    final resp = await http.get(
      Uri.parse('$baseUrl/hutangs/$id'),
      headers: AuthService.headers,
    );
    final data = jsonDecode(resp.body);
    if (resp.statusCode == 200 && data['success'] == true) {
      return Hutang.fromJson(data['data']);
    }
    throw Exception(data['message'] ?? 'Gagal memuat detail hutang');
  }

  static Future<Hutang> createHutang({
    required String description,
    required double amount,
    required DateTime dueDate,
    required String debtorEmail,
    String? notes,
  }) async {
    if (offline) {
      final debtor = _ensureUserByEmail(debtorEmail);
      final hutang = Hutang(
        id: _genId(),
        description: description,
        amount: amount,
        dueDate: dueDate,
        createdDate: DateTime.now(),
        status: 'pending',
        debtor: debtor,
        notes: notes,
        payments: [],
      );
      _hutangs.add(hutang);
      return hutang;
    }
    final resp = await http.post(
      Uri.parse('$baseUrl/hutangs'),
      headers: AuthService.headers,
      body: jsonEncode({
        'description': description,
        'amount': amount,
        'dueDate': dueDate.toIso8601String(),
        'debtorEmail': debtorEmail,
        'notes': notes,
      }),
    );
    final data = jsonDecode(resp.body);
    if ((resp.statusCode == 201 || resp.statusCode == 200) &&
        data['success'] == true) {
      return Hutang.fromJson(data['data']);
    }
    throw Exception(data['message'] ?? 'Gagal membuat hutang');
  }

  static Future<Hutang> addPayment({
    required String hutangId,
    required double amount,
    String? notes,
  }) async {
    if (offline) {
      final idx = _hutangs.indexWhere((h) => h.id == hutangId);
      if (idx == -1) throw Exception('Hutang not found');
      final h = _hutangs[idx];
      final payment = HutangPayment(
        id: _genId(),
        amount: amount,
        paymentDate: DateTime.now(),
        notes: notes,
      );
      final payments = List<HutangPayment>.from(h.payments ?? []);
      payments.add(payment);
      final newRemaining =
          h.amount - payments.fold<double>(0.0, (s, p) => s + p.amount);
      final newStatus = newRemaining <= 0
          ? 'paid'
          : (h.dueDate.isBefore(DateTime.now()) ? 'overdue' : 'pending');
      final updated = Hutang(
        id: h.id,
        description: h.description,
        amount: h.amount,
        dueDate: h.dueDate,
        createdDate: h.createdDate,
        status: newStatus,
        debtor: h.debtor,
        notes: h.notes,
        payments: payments,
      );
      _hutangs[idx] = updated;
      return updated;
    }
    final resp = await http.post(
      Uri.parse('$baseUrl/hutangs/$hutangId/payments'),
      headers: AuthService.headers,
      body: jsonEncode({'amount': amount, 'notes': notes}),
    );
    final data = jsonDecode(resp.body);
    if ((resp.statusCode == 201 || resp.statusCode == 200) &&
        data['success'] == true) {
      return Hutang.fromJson(data['data']);
    }
    throw Exception(data['message'] ?? 'Gagal menambahkan pembayaran');
  }

  // Summary API
  static Future<Map<String, dynamic>> getSummary() async {
    if (offline) {
      final activeHutangs = _hutangs.where((h) => h.status != 'paid').toList();
      final totalHutang = activeHutangs.fold<double>(
        0.0,
        (sum, h) => sum + h.remainingAmount,
      );
      final jumlahPenghutang = _users.length;
      final jumlahHutang = activeHutangs.length;
      final hutangLunas = _hutangs.where((h) => h.status == 'paid').length;
      final hutangJatuhTempo = _hutangs
          .where(
            (h) =>
                h.status == 'overdue' ||
                (h.status == 'pending' && h.dueDate.isBefore(DateTime.now())),
          )
          .length;
      return {
        'totalHutang': totalHutang,
        'jumlahPenghutang': jumlahPenghutang,
        'jumlahHutang': jumlahHutang,
        'hutangLunas': hutangLunas,
        'hutangJatuhTempo': hutangJatuhTempo,
      };
    }
    final resp = await http.get(
      Uri.parse('$baseUrl/summary'),
      headers: AuthService.headers,
    );
    final data = jsonDecode(resp.body);
    if (resp.statusCode == 200 && data['success'] == true) {
      return Map<String, dynamic>.from(data['data']);
    }
    throw Exception(data['message'] ?? 'Gagal memuat ringkasan');
  }

  // Helper method untuk check connection
  static Future<bool> checkConnection() async {
    if (offline) return true;
    try {
      final resp = await http.get(Uri.parse('$baseUrl/health'));
      return resp.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  static User ensureOfflineUser({
    required String username,
    String? email,
    String? name,
  }) {
    final em = (email ?? '$username@example.local');
    return _ensureUserByEmail(em, name: name ?? username);
  }

  static Future<Hutang> updateHutang({
    required String id,
    String? description,
    double? amount,
    DateTime? dueDate,
    String? notes,
    String? status,
  }) async {
    if (offline) {
      final idx = _hutangs.indexWhere((h) => h.id == id);
      if (idx == -1) throw Exception('Hutang not found');
      final h = _hutangs[idx];
      final updated = Hutang(
        id: h.id,
        description: description ?? h.description,
        amount: amount ?? h.amount,
        dueDate: dueDate ?? h.dueDate,
        createdDate: h.createdDate,
        status: status ?? h.status,
        debtor: h.debtor,
        notes: notes ?? h.notes,
        payments: h.payments,
      );
      _hutangs[idx] = updated;
      return updated;
    }
    final resp = await http.put(
      Uri.parse('$baseUrl/hutangs/$id'),
      headers: AuthService.headers,
      body: jsonEncode({
        if (description != null) 'description': description,
        if (amount != null) 'amount': amount,
        if (dueDate != null) 'dueDate': dueDate.toIso8601String(),
        if (notes != null) 'notes': notes,
        if (status != null) 'status': status,
      }),
    );
    final data = jsonDecode(resp.body);
    if (resp.statusCode == 200 && data['success'] == true) {
      return Hutang.fromJson(data['data']);
    }
    throw Exception(data['message'] ?? 'Gagal memperbarui hutang');
  }

  static Future<bool> deleteHutang(String id) async {
    if (offline) {
      final idx = _hutangs.indexWhere((h) => h.id == id);
      if (idx == -1) return false;
      _hutangs.removeAt(idx);
      return true;
    }
    final resp = await http.delete(
      Uri.parse('$baseUrl/hutangs/$id'),
      headers: AuthService.headers,
    );
    if (resp.statusCode == 200) return true;
    try {
      final data = jsonDecode(resp.body);
      throw Exception(data['message'] ?? 'Gagal menghapus hutang');
    } catch (_) {
      throw Exception('Gagal menghapus hutang');
    }
  }
}
