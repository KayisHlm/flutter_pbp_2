import 'package:flutter/material.dart';
import 'package:project_pbp_flutter/models/hutang.dart';
import 'package:project_pbp_flutter/services/api_service.dart';

import 'package:intl/intl.dart';

class HutangDetailScreen extends StatefulWidget {
  final Hutang hutang;
  
  const HutangDetailScreen({
    super.key,
    required this.hutang,
  });

  @override
  State<HutangDetailScreen> createState() => _HutangDetailScreenState();
}

class _HutangDetailScreenState extends State<HutangDetailScreen> {
  final NumberFormat currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  final DateFormat dateFormat = DateFormat('dd MMMM yyyy', 'id_ID');

  Color _getStatusColor(String status) {
    switch (status) {
      case 'paid':
        return Colors.green;
      case 'overdue':
        return Colors.red;
      case 'pending':
      default:
        return Colors.orange;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'paid':
        return 'LUNAS';
      case 'overdue':
        return 'JATUH TEMPO';
      case 'pending':
      default:
        return 'BELUM LUNAS';
    }
  }

  Future<void> _showAddPaymentDialog() async {
    final TextEditingController amountController = TextEditingController();
    final TextEditingController notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Tambah Pembayaran'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Jumlah Pembayaran',
                  prefixText: 'Rp ',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: notesController,
                decoration: const InputDecoration(
                  labelText: 'Catatan (Opsional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                final amountText = amountController.text.trim();
                if (amountText.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Jumlah pembayaran wajib diisi'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                final amount = double.tryParse(amountText);
                if (amount == null || amount <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Jumlah pembayaran tidak valid'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                if (amount > widget.hutang.remainingAmount) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Jumlah pembayaran tidak boleh melebihi sisa hutang Rp ${currencyFormat.format(widget.hutang.remainingAmount)}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                try {
                  await ApiService.addPayment(
                    hutangId: widget.hutang.id,
                    amount: amount,
                    notes: notesController.text.trim().isNotEmpty ? notesController.text.trim() : null,
                  );

                  Navigator.pop(context);
                  
                  // Refresh the hutang data
                  try {
                    final updatedHutang = await ApiService.getHutang(widget.hutang.id);
                    
                    // Navigate back and pass the updated data
                    if (mounted) {
                      Navigator.pop(context, updatedHutang);
                    }
                    
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Pembayaran berhasil ditambahkan'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } catch (e) {
                    // Even if refresh fails, close the dialog and show success
                    if (mounted) {
                      Navigator.pop(context);
                    }
                    
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Pembayaran berhasil, namun gagal memperbarui tampilan: ${e.toString()}'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                  }
                } catch (e) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Gagal menambahkan pembayaran: ${e.toString()}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final hutang = widget.hutang;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Hutang'),
        backgroundColor: Colors.blue[800],
        elevation: 4,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Main Info Card
            Container(
              width: double.infinity,
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue[800]!, Colors.blue[600]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          hutang.description,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusColor(hutang.status).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _getStatusColor(hutang.status),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          _getStatusText(hutang.status),
                          style: TextStyle(
                            color: _getStatusColor(hutang.status),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Total Hutang',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            currencyFormat.format(hutang.amount),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text(
                            'Sisa Hutang',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            currencyFormat.format(hutang.remainingAmount),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Debtor Info
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Informasi Penghutang',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.blue[100],
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            hutang.debtor.name.substring(0, 1).toUpperCase(),
                            style: TextStyle(
                              color: Colors.blue[800],
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              hutang.debtor.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            if (hutang.debtor.phone != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                hutang.debtor.phone!,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                            if (hutang.debtor.address != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                hutang.debtor.address!,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Due Date Info
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: hutang.isOverdue ? Colors.red[50] : Colors.orange[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: hutang.isOverdue ? Colors.red[300]! : Colors.orange[300]!,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    hutang.isOverdue ? Icons.warning : Icons.schedule,
                    color: hutang.isOverdue ? Colors.red[600] : Colors.orange[600],
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          hutang.isOverdue ? 'Jatuh Tempo' : 'Jatuh Tempo',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: hutang.isOverdue ? Colors.red[600] : Colors.orange[600],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          dateFormat.format(hutang.dueDate),
                          style: TextStyle(
                            fontSize: 16,
                            color: hutang.isOverdue ? Colors.red[700] : Colors.orange[700],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (hutang.isOverdue) ...[
                          const SizedBox(height: 4),
                          Text(
                            '${DateTime.now().difference(hutang.dueDate).inDays} hari yang lalu',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.red[600],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Notes
            if (hutang.notes != null && hutang.notes!.isNotEmpty) ...[
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Catatan',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      hutang.notes!,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Payment History
            if (hutang.payments != null && hutang.payments!.isNotEmpty) ...[
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Riwayat Pembayaran',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: hutang.payments!.length,
                      separatorBuilder: (context, index) => const Divider(),
                      itemBuilder: (context, index) {
                        final payment = hutang.payments![index];
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  currencyFormat.format(payment.amount),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                                if (payment.notes != null) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    payment.notes!,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            Text(
                              dateFormat.format(payment.paymentDate),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 80), // Space for floating button
          ],
        ),
      ),
      floatingActionButton: hutang.status != 'paid'
          ? FloatingActionButton.extended(
              onPressed: _showAddPaymentDialog,
              backgroundColor: Colors.green[600],
              icon: const Icon(Icons.payment, color: Colors.white),
              label: const Text(
                'Tambah Pembayaran',
                style: TextStyle(color: Colors.white),
              ),
            )
          : null,
    );
  }
}