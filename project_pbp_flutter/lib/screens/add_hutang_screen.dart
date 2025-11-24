import 'package:flutter/material.dart';
import 'package:project_pbp_flutter/models/user.dart';
import 'package:project_pbp_flutter/services/api_service.dart';

import 'package:intl/intl.dart';

class AddHutangScreen extends StatefulWidget {
  const AddHutangScreen({super.key});

  @override
  State<AddHutangScreen> createState() => _AddHutangScreenState();
}

class _AddHutangScreenState extends State<AddHutangScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  
  DateTime _selectedDueDate = DateTime.now().add(const Duration(days: 30));
  User? _selectedUser;
  
  final NumberFormat currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  final DateFormat dateFormat = DateFormat('dd MMMM yyyy', 'id_ID');

  List<User> _users = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final users = await ApiService.getUsers();
      setState(() {
        _users = users;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Gagal memuat data pengguna: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _selectDueDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDueDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('id', 'ID'),
    );
    
    if (picked != null && picked != _selectedDueDate) {
      setState(() {
        _selectedDueDate = picked;
      });
    }
  }

  void _showUserSelectionDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Pilih Penghutang'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _users.length,
              itemBuilder: (context, index) {
                final user = _users[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.blue[100],
                    child: Text(
                      user.name.substring(0, 1).toUpperCase(),
                      style: TextStyle(
                        color: Colors.blue[800],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(user.name),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (user.phone != null) Text(user.phone!),
                      if (user.address != null) Text(user.address!),
                    ],
                  ),
                  onTap: () {
                    setState(() {
                      _selectedUser = user;
                    });
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pilih penghutang terlebih dahulu'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      try {
        final amount = double.parse(_amountController.text);
        
        await ApiService.createHutang(
          description: _descriptionController.text,
          amount: amount,
          dueDate: _selectedDueDate,
          debtorId: _selectedUser!.id,
          notes: _notesController.text.isNotEmpty ? _notesController.text : null,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Hutang berhasil ditambahkan'),
            backgroundColor: Colors.green,
          ),
        );
        
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menambahkan hutang: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Tambah Hutang Baru'),
          backgroundColor: Colors.blue[800],
          elevation: 4,
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Tambah Hutang Baru'),
          backgroundColor: Colors.blue[800],
          elevation: 4,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadUsers,
                child: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tambah Hutang Baru'),
        backgroundColor: Colors.blue[800],
        elevation: 4,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Select User Card
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: InkWell(
                  onTap: _showUserSelectionDialog,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    child: Row(
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
                              _selectedUser?.name.substring(0, 1).toUpperCase() ?? '?',
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
                                _selectedUser?.name ?? 'Pilih Penghutang',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              if (_selectedUser != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  _selectedUser!.phone ?? 'Tidak ada nomor telepon',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_drop_down, color: Colors.grey),
                      ],
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 16),

              // Description Field
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Deskripsi Hutang *',
                  hintText: 'Contoh: Hutang belanja bulanan',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Deskripsi wajib diisi';
                  }
                  return null;
                },
                maxLines: 2,
              ),

              const SizedBox(height: 16),

              // Amount Field
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Jumlah Hutang *',
                  hintText: 'Contoh: 2500000',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.attach_money),
                  prefixText: 'Rp ',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Jumlah wajib diisi';
                  }
                  if (double.tryParse(value) == null || double.parse(value) <= 0) {
                    return 'Jumlah harus valid dan lebih dari 0';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Due Date Field
              InkWell(
                onTap: _selectDueDate,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Tanggal Jatuh Tempo *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(dateFormat.format(_selectedDueDate)),
                      const Icon(Icons.arrow_drop_down),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Notes Field
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Catatan (Opsional)',
                  hintText: 'Tambahkan catatan tambahan di sini',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.note_add),
                ),
                maxLines: 3,
              ),

              const SizedBox(height: 24),

              // Submit Button
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[800],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 4,
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.save, color: Colors.white),
                      SizedBox(width: 8),
                      Text(
                        'Simpan Hutang',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Cancel Button
              SizedBox(
                height: 50,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.grey[400]!),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Batal',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}