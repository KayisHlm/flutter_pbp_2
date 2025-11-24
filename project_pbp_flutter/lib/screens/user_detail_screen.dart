import 'package:flutter/material.dart';
import 'package:project_pbp_flutter/models/user.dart';
import 'package:project_pbp_flutter/models/hutang.dart';
import 'package:project_pbp_flutter/screens/hutang_detail_screen.dart';
import 'package:project_pbp_flutter/services/api_service.dart';
import 'package:intl/intl.dart';

class UserDetailScreen extends StatefulWidget {
  final User user;
  
  const UserDetailScreen({
    super.key,
    required this.user,
  });

  @override
  State<UserDetailScreen> createState() => _UserDetailScreenState();
}

class _UserDetailScreenState extends State<UserDetailScreen> {
  List<Hutang> userHutangs = [];
  bool isLoading = true;
  String errorMessage = '';

  final NumberFormat currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  final DateFormat dateFormat = DateFormat('dd MMM yyyy', 'id_ID');

  @override
  void initState() {
    super.initState();
    loadUserHutangs();
  }

  Future<void> loadUserHutangs() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = '';
      });

      final allHutangs = await ApiService.getHutangs();
      final userHutangList = allHutangs
          .where((hutang) => hutang.debtor.id == widget.user.id)
          .toList();

      setState(() {
        userHutangs = userHutangList;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Gagal memuat data hutang: ${e.toString()}';
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> refreshData() async {
    await loadUserHutangs();
  }

  double getTotalHutang() {
    return userHutangs
        .where((hutang) => hutang.status != 'paid')
        .fold(0.0, (sum, hutang) => sum + hutang.remainingAmount);
  }

  int getJumlahHutang() {
    return userHutangs.where((hutang) => hutang.status != 'paid').length;
  }

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

  void _showAddHutangDialog() {
    final TextEditingController descriptionController = TextEditingController();
    final TextEditingController amountController = TextEditingController();
    final TextEditingController notesController = TextEditingController();
    DateTime selectedDate = DateTime.now().add(const Duration(days: 30));

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Tambah Hutang Baru'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Deskripsi Hutang',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: amountController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Jumlah Hutang',
                        prefixText: 'Rp ',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    InkWell(
                      onTap: () async {
                        final DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (picked != null) {
                          setState(() {
                            selectedDate = picked;
                          });
                        }
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Tanggal Jatuh Tempo',
                          border: OutlineInputBorder(),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(dateFormat.format(selectedDate)),
                            const Icon(Icons.calendar_today),
                          ],
                        ),
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
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    try {
                      await ApiService.createHutang(
                        description: descriptionController.text,
                        amount: double.parse(amountController.text),
                        dueDate: selectedDate,
                        debtorId: widget.user.id,
                        notes: notesController.text.isEmpty ? null : notesController.text,
                      );
                      
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Hutang berhasil ditambahkan'),
                          backgroundColor: Colors.green,
                        ),
                      );
                      await refreshData();
                    } catch (e) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error: ${e.toString()}'),
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
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Penghutang'),
        backgroundColor: Colors.blue[800],
        elevation: 4,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: refreshData,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage.isNotEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        errorMessage,
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: loadUserHutangs,
                        child: const Text('Coba Lagi'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: refreshData,
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        // User Info Card
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
                            children: [
                              Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    user.name.substring(0, 1).toUpperCase(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                user.name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (user.phone != null) ...[
                                const SizedBox(height: 8),
                                Text(
                                  user.phone!,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                              if (user.address != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  user.address!,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),

                        // Summary Cards
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            children: [
                              Expanded(
                                child: Container(
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
                                    children: [
                                      Text(
                                        currencyFormat.format(getTotalHutang()),
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: getTotalHutang() > 0 ? Colors.red[700] : Colors.green[700],
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Total Hutang',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Container(
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
                                    children: [
                                      Text(
                                        '${getJumlahHutang()}',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: getJumlahHutang() > 0 ? Colors.orange[700] : Colors.green[700],
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Jumlah Hutang',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Hutang List Header
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Daftar Hutang',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              TextButton(
                                onPressed: _showAddHutangDialog,
                                child: const Text('Tambah Hutang'),
                              ),
                            ],
                          ),
                        ),

                        // Hutang List
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: userHutangs.length,
                          itemBuilder: (context, index) {
                            final hutang = userHutangs[index];
                            
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: InkWell(
                                onTap: () async {
                                  final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => HutangDetailScreen(hutang: hutang),
                                    ),
                                  );
                                  
                                  // If payment was added, refresh the data
                                  if (result != null) {
                                    refreshData();
                                  }
                                },
                                borderRadius: BorderRadius.circular(12),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
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
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.black87,
                                              ),
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: _getStatusColor(hutang.status).withValues(alpha: 0.1),
                                              borderRadius: BorderRadius.circular(12),
                                              border: Border.all(
                                                color: _getStatusColor(hutang.status),
                                                width: 1,
                                              ),
                                            ),
                                            child: Text(
                                              _getStatusText(hutang.status),
                                              style: TextStyle(
                                                color: _getStatusColor(hutang.status),
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Total: ${currencyFormat.format(hutang.amount)}',
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.black87,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                'Sisa: ${currencyFormat.format(hutang.remainingAmount)}',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: hutang.remainingAmount > 0 ? Colors.red[600] : Colors.green[600],
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.end,
                                            children: [
                                              Text(
                                                'Jatuh Tempo',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                              Text(
                                                dateFormat.format(hutang.dueDate),
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: hutang.isOverdue ? Colors.red[600] : Colors.grey[700],
                                                  fontWeight: hutang.isOverdue ? FontWeight.bold : FontWeight.normal,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      if (hutang.notes != null && hutang.notes!.isNotEmpty) ...[
                                        const SizedBox(height: 8),
                                        Text(
                                          hutang.notes!,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                            fontStyle: FontStyle.italic,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),

                        const SizedBox(height: 80), // Space for floating button
                      ],
                    ),
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddHutangDialog,
        backgroundColor: Colors.blue[800],
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
    );
  }
}