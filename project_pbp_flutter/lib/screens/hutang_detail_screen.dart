import 'package:flutter/material.dart';
import 'package:project_pbp_flutter/models/hutang.dart';
import 'package:project_pbp_flutter/services/api_service.dart';

import 'package:intl/intl.dart';

class HutangDetailScreen extends StatefulWidget {
  final Hutang hutang;

  const HutangDetailScreen({super.key, required this.hutang});

  @override
  State<HutangDetailScreen> createState() => _HutangDetailScreenState();
}

class _HutangDetailScreenState extends State<HutangDetailScreen> {
  late Hutang currentHutang;
  final NumberFormat currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  final DateFormat dateFormat = DateFormat('dd MMMM yyyy', 'id_ID');

  @override
  void initState() {
    super.initState();
    currentHutang = widget.hutang;
  }

  Color _getStatusColor(BuildContext context, String status) {
    final cs = Theme.of(context).colorScheme;
    switch (status) {
      case 'paid':
        return cs.tertiary;
      case 'overdue':
        return Colors.red;
      case 'pending':
      default:
        return Colors.red;
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
                    SnackBar(
                      content: const Text('Jumlah pembayaran wajib diisi'),
                      backgroundColor: Theme.of(context).colorScheme.error,
                    ),
                  );
                  return;
                }

                final amount = double.tryParse(amountText);
                if (amount == null || amount <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Jumlah pembayaran tidak valid'),
                      backgroundColor: Theme.of(context).colorScheme.error,
                    ),
                  );
                  return;
                }

                if (amount > widget.hutang.remainingAmount) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Jumlah pembayaran tidak boleh melebihi sisa hutang Rp ${currencyFormat.format(widget.hutang.remainingAmount)}',
                      ),
                      backgroundColor: Theme.of(context).colorScheme.error,
                    ),
                  );
                  return;
                }

                try {
                  final messenger = ScaffoldMessenger.of(context);
                  final cs2 = Theme.of(context).colorScheme;
                  await ApiService.addPayment(
                    hutangId: widget.hutang.id,
                    amount: amount,
                    notes: notesController.text.trim().isNotEmpty
                        ? notesController.text.trim()
                        : null,
                  );

                  if (!context.mounted) return;
                  Navigator.pop(context);

                  // Refresh the hutang data
                  try {
                    final updatedHutang = await ApiService.getHutang(
                      widget.hutang.id,
                    );

                    // Navigate back and pass the updated data
                    if (!context.mounted) return;
                    Navigator.pop(context, updatedHutang);

                    messenger.showSnackBar(
                      SnackBar(
                        content: const Text('Pembayaran berhasil ditambahkan'),
                        backgroundColor: cs2.secondary,
                      ),
                    );
                  } catch (e) {
                    // Even if refresh fails, close the dialog and show success
                    if (!context.mounted) return;
                    Navigator.pop(context);

                    messenger.showSnackBar(
                      SnackBar(
                        content: Text(
                          'Pembayaran berhasil, namun gagal memperbarui tampilan: ${e.toString()}',
                        ),
                        backgroundColor: cs2.secondary,
                      ),
                    );
                  }
                } catch (e) {
                  if (!context.mounted) return;
                  Navigator.pop(context);
                  final messenger = ScaffoldMessenger.of(context);
                  final cs2 = Theme.of(context).colorScheme;
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(
                        'Gagal menambahkan pembayaran: ${e.toString()}',
                      ),
                      backgroundColor: cs2.error,
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

  Future<void> _markAsPaid() async {
    final messenger = ScaffoldMessenger.of(context);
    final cs2 = Theme.of(context).colorScheme;
    final nav = Navigator.of(context);
    final remaining = currentHutang.remainingAmount;
    if (remaining <= 0) {
      messenger.showSnackBar(
        SnackBar(
          content: const Text('Hutang sudah lunas'),
          backgroundColor: cs2.secondary,
        ),
      );
      return;
    }

    try {
      final added = await ApiService.addPayment(
        hutangId: currentHutang.id,
        amount: remaining,
        notes: 'Pelunasan cepat',
      );
      if (mounted) {
        setState(() {
          currentHutang = added;
        });
      }

      if (currentHutang.status != 'paid') {
        try {
          final refreshed = await ApiService.getHutang(currentHutang.id);
          if (mounted) {
            setState(() {
              currentHutang = refreshed;
            });
          }
        } catch (_) {}
      }

      if (currentHutang.status != 'paid') {
        final newPayments =
            List<HutangPayment>.from(currentHutang.payments ?? const [])..add(
              HutangPayment(
                id: 'temp',
                amount: remaining,
                paymentDate: DateTime.now(),
                notes: 'Pelunasan cepat',
              ),
            );
        if (mounted) {
          setState(() {
            currentHutang = Hutang(
              id: currentHutang.id,
              description: currentHutang.description,
              amount: currentHutang.amount,
              dueDate: currentHutang.dueDate,
              createdDate: currentHutang.createdDate,
              status: 'paid',
              debtor: currentHutang.debtor,
              notes: currentHutang.notes,
              payments: newPayments,
            );
          });
        }
      }

      if (!context.mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: const Text('Status diperbarui menjadi LUNAS'),
          backgroundColor: cs2.secondary,
        ),
      );
      nav.pop(currentHutang);
    } catch (e) {
      if (!context.mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text('Gagal memperbarui status: ${e.toString()}'),
          backgroundColor: cs2.error,
        ),
      );
    }
  }

  Future<void> _deleteHutang() async {
    final messenger = ScaffoldMessenger.of(context);
    final cs2 = Theme.of(context).colorScheme;
    final nav = Navigator.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Hutang'),
        content: const Text('Apakah Anda yakin ingin menghapus hutang ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      final ok = await ApiService.deleteHutang(currentHutang.id);
      if (!context.mounted) return;
      if (ok) {
        messenger.showSnackBar(
          SnackBar(
            content: const Text('Hutang berhasil dihapus'),
            backgroundColor: cs2.tertiary,
          ),
        );
        if (!context.mounted) return;
        nav.pop(true);
      } else {
        messenger.showSnackBar(
          SnackBar(
            content: const Text('Gagal menghapus hutang'),
            backgroundColor: cs2.error,
          ),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text('Gagal menghapus hutang: ${e.toString()}'),
          backgroundColor: cs2.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final hutang = currentHutang;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Hutang'),
        backgroundColor: cs.primary,
        elevation: 4,
        actions: [
          if (hutang.status != 'paid')
            IconButton(
              icon: const Icon(Icons.attach_money),
              onPressed: _showAddPaymentDialog,
              tooltip: 'Tambah Pembayaran',
            ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: _deleteHutang,
            tooltip: 'Hapus Hutang',
          ),
        ],
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
                color: Theme.of(context).colorScheme.surface,
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
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
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
                          color: _getStatusColor(
                            context,
                            hutang.status,
                          ).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _getStatusColor(context, hutang.status),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          _getStatusText(hutang.status),
                          style: TextStyle(
                            color: _getStatusColor(context, hutang.status),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Total Hutang',
                              style: TextStyle(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              currencyFormat.format(hutang.amount),
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
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
                color: Theme.of(context).colorScheme.surface,
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
                  Text(
                    'Informasi Penghutang',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: cs.secondaryContainer,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            hutang.debtor.name.substring(0, 1).toUpperCase(),
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSecondaryContainer,
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
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                            if (hutang.debtor.phone != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                hutang.debtor.phone!,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                            if (hutang.debtor.address != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                hutang.debtor.address!,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
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
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: hutang.isOverdue
                      ? Colors.red
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    hutang.isOverdue ? Icons.warning : Icons.schedule,
                    color: hutang.isOverdue
                        ? Colors.red
                        : Theme.of(context).colorScheme.onSurfaceVariant,
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
                            color: hutang.isOverdue
                                ? Colors.red
                                : Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          dateFormat.format(hutang.dueDate),
                          style: TextStyle(
                            fontSize: 16,
                            color: hutang.isOverdue
                                ? Colors.red
                                : Theme.of(context).colorScheme.onSurface,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (hutang.isOverdue) ...[
                          const SizedBox(height: 4),
                          Text(
                            '${DateTime.now().difference(hutang.dueDate).inDays} hari yang lalu',
                            style: TextStyle(fontSize: 12, color: Colors.red),
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
                  color: Theme.of(context).colorScheme.surface,
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
                    Text(
                      'Catatan',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      hutang.notes!,
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.onSurface,
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
                  color: Theme.of(context).colorScheme.surface,
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
                    Text(
                      'Riwayat Pembayaran',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
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
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: cs.tertiary,
                                  ),
                                ),
                                if (payment.notes != null) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    payment.notes!,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            Text(
                              dateFormat.format(payment.paymentDate),
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
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
              onPressed: _markAsPaid,
              backgroundColor: cs.secondary,
              icon: const Icon(Icons.check_circle, color: Colors.white),
              label: const Text(
                'Sudah Lunas',
                style: TextStyle(color: Colors.white),
              ),
            )
          : null,
    );
  }
}
