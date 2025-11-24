import 'package:project_pbp_flutter/models/user.dart';

class Hutang {
  final String id;
  final String description;
  final double amount;
  final DateTime dueDate;
  final DateTime createdDate;
  final String status; // 'pending', 'paid', 'overdue'
  final User debtor;
  final String? notes;
  final List<HutangPayment>? payments;

  Hutang({
    required this.id,
    required this.description,
    required this.amount,
    required this.dueDate,
    required this.createdDate,
    required this.status,
    required this.debtor,
    this.notes,
    this.payments,
  });

  double get remainingAmount {
    if (payments == null || payments!.isEmpty) {
      return amount;
    }
    double totalPaid = payments!.fold(0, (sum, payment) => sum + payment.amount);
    return amount - totalPaid;
  }

  bool get isOverdue {
    return status != 'paid' && dueDate.isBefore(DateTime.now());
  }

  factory Hutang.fromJson(Map<String, dynamic> json) {
    return Hutang(
      id: json['id'],
      description: json['description'],
      amount: json['amount'].toDouble(),
      dueDate: DateTime.parse(json['dueDate']),
      createdDate: DateTime.parse(json['createdDate']),
      status: json['status'],
      debtor: User.fromJson(json['debtor']),
      notes: json['notes'],
      payments: json['payments'] != null
          ? List<HutangPayment>.from(
              json['payments'].map((x) => HutangPayment.fromJson(x)))
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'description': description,
      'amount': amount,
      'dueDate': dueDate.toIso8601String(),
      'createdDate': createdDate.toIso8601String(),
      'status': status,
      'debtor': debtor.toJson(),
      'notes': notes,
      'payments': payments != null
          ? List<dynamic>.from(payments!.map((x) => x.toJson()))
          : null,
    };
  }
}

class HutangPayment {
  final String id;
  final double amount;
  final DateTime paymentDate;
  final String? notes;

  HutangPayment({
    required this.id,
    required this.amount,
    required this.paymentDate,
    this.notes,
  });

  factory HutangPayment.fromJson(Map<String, dynamic> json) {
    return HutangPayment(
      id: json['id'],
      amount: json['amount'].toDouble(),
      paymentDate: DateTime.parse(json['paymentDate']),
      notes: json['notes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'amount': amount,
      'paymentDate': paymentDate.toIso8601String(),
      'notes': notes,
    };
  }
}