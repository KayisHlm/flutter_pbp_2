import 'package:flutter/material.dart';
import 'package:project_pbp_flutter/models/user.dart';
import 'package:project_pbp_flutter/models/hutang.dart';
import 'package:project_pbp_flutter/screens/user_detail_screen.dart';
import 'package:project_pbp_flutter/screens/add_hutang_screen.dart';
import 'package:project_pbp_flutter/screens/add_user_screen.dart';
import 'package:project_pbp_flutter/services/api_service.dart';
import 'package:intl/intl.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback? onLogout;
  
  const HomeScreen({super.key, this.onLogout});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<User> users = [];
  List<Hutang> hutangs = [];
  Map<String, dynamic> summary = {};
  bool isLoading = true;
  String errorMessage = '';

  final NumberFormat currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = '';
      });

      // Load users with hutang summary
      final loadedUsers = await ApiService.getUsers();
      final loadedHutangs = await ApiService.getHutangs();
      final loadedSummary = await ApiService.getSummary();

      setState(() {
        users = loadedUsers;
        hutangs = loadedHutangs;
        summary = loadedSummary;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Gagal memuat data: ${e.toString()}';
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
    await loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hutangmu'),
        backgroundColor: Colors.grey[850],
        elevation: 4,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AddUserScreen(),
                ),
              );
              if (result == true) {
                loadData(); // Refresh data after adding user
              }
            },
            tooltip: 'Tambah User Baru',
          ),
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'settings') {
                // Navigate to settings
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Fitur Pengaturan akan segera tersedia')),
                );
              } else if (value == 'about') {
                showAboutDialog(
                  context: context,
                  applicationName: 'Hutangmu',
                  applicationVersion: '1.0.0',
                  applicationLegalese: '© 2024 Hutangmu\n\nAplikasi untuk mencatat dan mengelola hutang dengan mudah.',
                );
              } else if (value == 'logout') {
                // Handle logout
                final result = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Logout'),
                    content: const Text('Apakah Anda yakin ingin logout?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Batal'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Logout'),
                      ),
                    ],
                  ),
                );

                if (result == true) {
                  widget.onLogout?.call();
                }
              }
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem<String>(
                value: 'settings',
                child: ListTile(
                  leading: Icon(Icons.settings),
                  title: Text('Pengaturan'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem<String>(
                value: 'about',
                child: ListTile(
                  leading: Icon(Icons.info),
                  title: Text('Tentang'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem<String>(
                value: 'logout',
                child: ListTile(
                  leading: Icon(Icons.logout, color: Colors.red),
                  title: Text('Logout', style: TextStyle(color: Colors.red)),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
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
                        onPressed: loadData,
                        child: const Text('Coba Lagi'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: refreshData,
                  child: Container(
                    color: Colors.grey[50],
                    child: Column(
                      children: [
                        // Summary Card
                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.all(16),
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.grey[850],
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Ringkasan Hutang',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Total Hutang',
                                        style: TextStyle(
                                          color: Colors.green[400],
                                          fontSize: 14,
                                        ),
                                      ),
                                      Text(
                                        currencyFormat.format(summary['totalHutang'] ?? 0),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        'Total Piutang',
                                        style: TextStyle(
                                          color: Colors.red[400],
                                          fontSize: 14,
                                        ),
                                      ),
                                      Text(
                                        currencyFormat.format(summary['totalHutang'] ?? 0),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 20,
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

                        // User List Header
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Daftar Penghutang',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  // Navigate to all users screen
                                },
                                child: const Text('Lihat Semua'),
                              ),
                            ],
                          ),
                        ),

                        // User List
                        Expanded(
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: users.length,
                            itemBuilder: (context, index) {
                              final user = users[index];
                              final totalHutang = user.totalHutang ?? 0;
                              
                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: InkWell(
                                  onTap: () {
                                    // Navigate to user detail
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => UserDetailScreen(user: user),
                                      ),
                                    );
                                  },
                                  borderRadius: BorderRadius.circular(12),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Row(
                                      children: [
                                        // User Avatar
                                        Container(
                                          width: 50,
                                          height: 50,
                                          decoration: BoxDecoration(
                                            color: Colors.blue[100],
                                            shape: BoxShape.circle,
                                          ),
                                          child: Center(
                                            child: Text(
                                              user.name.substring(0, 1).toUpperCase(),
                                              style: TextStyle(
                                                color: Colors.blue[800],
                                                fontSize: 20,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        
                                        // User Info
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                user.name,
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.black87,
                                                ),
                                              ),
                                              if (user.phone != null) ...[
                                                const SizedBox(height: 4),
                                                Text(
                                                  user.phone!,
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    color: Colors.grey[600],
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                        
                                        // Total Hutang
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          children: [
                                            Text(
                                              currencyFormat.format(totalHutang),
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: totalHutang > 0 ? Colors.red[700] : Colors.green[700],
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              totalHutang > 0 ? 'Belum Lunas' : 'Lunas',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: totalHutang > 0 ? Colors.red[600] : Colors.green[600],
                                              ),
                                            ),
                                          ],
                                        ),
                                        
                                        const SizedBox(width: 8),
                                        const Icon(
                                          Icons.chevron_right,
                                          color: Colors.grey,
                                          size: 24,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navigate to add hutang screen
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddHutangScreen(),
            ),
          ).then((_) => loadData()); // Refresh data after adding hutang
        },
        backgroundColor: Colors.green[600],
        child: const Icon(Icons.add, color: Colors.white, size: 28),
        tooltip: 'Tambah Hutang Baru',
      ),
    );
  }
}