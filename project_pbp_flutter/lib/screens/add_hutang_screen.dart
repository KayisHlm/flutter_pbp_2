import 'package:flutter/material.dart';
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
  final TextEditingController _emailController = TextEditingController();
  List<Map<String, String>> _userOptions = [];

  DateTime _selectedDueDate = DateTime.now().add(const Duration(days: 30));

  final NumberFormat currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  final DateFormat dateFormat = DateFormat('dd MMMM yyyy', 'id_ID');

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _fetchUsers() async {
    try {
      final users = await ApiService.getUsers();
      if (!mounted) return;
      setState(() {
        _userOptions = users
            .map((u) => {'email': (u.email ?? '').trim(), 'name': u.name})
            .where((m) => m['email']!.isNotEmpty)
            .toList();
      });
    } catch (_) {}
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

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final email = _emailController.text.trim();
      final description = _descriptionController.text.trim();
      final amount = double.parse(
        _amountController.text.replaceAll(RegExp(r'[^0-9]'), ''),
      );
      final notes = _notesController.text.trim();

      await ApiService.createHutang(
        description: description,
        amount: amount,
        dueDate: _selectedDueDate,
        debtorEmail: email,
        notes: notes,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Hutang berhasil ditambahkan'),
          backgroundColor: Theme.of(context).colorScheme.tertiary,
        ),
      );

      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = 'Gagal menambahkan hutang: ${e.toString()}';
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_errorMessage!),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tambah Hutang Baru')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Autocomplete<String>(
                optionsBuilder: (TextEditingValue t) {
                  final q = t.text.trim().toLowerCase();
                  if (q.isEmpty) return const Iterable<String>.empty();
                  return _userOptions.map((m) => m['email']!).where((e) => e.toLowerCase().contains(q));
                },
                fieldViewBuilder: (context, ctrl, focusNode, onSubmit) {
                  ctrl.addListener(() {
                    _emailController.text = ctrl.text;
                  });
                  return TextFormField(
                    controller: ctrl,
                    focusNode: focusNode,
                    decoration: const InputDecoration(
                      labelText: 'Email Penghutang',
                      hintText: 'Ketik untuk mencari pengguna',
                      prefixIcon: Icon(Icons.email),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    onFieldSubmitted: (_) => onSubmit(),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) return 'Email wajib diisi';
                      if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value.trim())) return 'Format email tidak valid';
                      return null;
                    },
                  );
                },
                optionsViewBuilder: (context, onSelected, options) {
                  final items = options.toList();
                  return Align(
                    alignment: Alignment.topLeft,
                    child: Material(
                      elevation: 4,
                      borderRadius: BorderRadius.circular(8),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 240),
                        child: ListView.builder(
                          padding: EdgeInsets.zero,
                          itemCount: items.length,
                          itemBuilder: (context, index) {
                            final email = items[index];
                            final map = _userOptions.firstWhere(
                              (m) => m['email'] == email,
                              orElse: () => const {'name': ''},
                            );
                            final name = map['name']!;
                            return ListTile(
                              title: Text(name),
                              subtitle: Text(email),
                              onTap: () => onSelected(email),
                            );
                          },
                        ),
                      ),
                    ),
                  );
                },
                onSelected: (email) => _emailController.text = email,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Deskripsi Hutang',
                  hintText: 'Contoh: Hutang beli laptop',
                  prefixIcon: Icon(Icons.description),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Deskripsi wajib diisi';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(
                  labelText: 'Jumlah Hutang',
                  hintText: 'Contoh: 1000000',
                  prefixIcon: Icon(Icons.attach_money),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Jumlah hutang wajib diisi';
                  }
                  if (double.tryParse(
                        value.replaceAll(RegExp(r'[^0-9]'), ''),
                      ) ==
                      null) {
                    return 'Jumlah hutang harus berupa angka';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: _selectDueDate,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Tanggal Jatuh Tempo',
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
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Catatan (Opsional)',
                  hintText: 'Tambahan informasi',
                  prefixIcon: Icon(Icons.note),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _submitForm,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Simpan Hutang',
                        style: TextStyle(fontSize: 16),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
