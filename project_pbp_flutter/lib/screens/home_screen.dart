import 'package:flutter/material.dart';
import 'package:project_pbp_flutter/models/user.dart';
import 'package:project_pbp_flutter/models/hutang.dart';
import 'package:project_pbp_flutter/screens/user_detail_screen.dart';
import 'package:project_pbp_flutter/screens/add_hutang_screen.dart';
import 'package:project_pbp_flutter/services/api_service.dart';
import 'package:project_pbp_flutter/services/auth_service.dart';
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
      if (!AuthService.isAuthenticated) {
        setState(() {
          users = [];
          hutangs = [];
          summary = {
            'totalHutang': 0,
            'jumlahPenghutang': 0,
            'jumlahHutang': 0,
            'hutangLunas': 0,
            'hutangJatuhTempo': 0,
          };
          isLoading = false;
          errorMessage = '';
        });
        return;
      }
      setState(() {
        isLoading = true;
        errorMessage = '';
      });

      // Load users with hutang summary
      final loadedUsers = await ApiService.getUsers();
      final loadedHutangs = await ApiService.getHutangs();
      final loadedSummary = await ApiService.getSummary();

      setState(() {
        users = loadedUsers.where((u) => AuthService.currentUserId == null ? true : u.id != AuthService.currentUserId).toList();
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
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  Future<void> refreshData() async {
    await loadData();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hutangmu'),
        backgroundColor: cs.primary,
        elevation: 4,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'logout') {
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
                  final resp = await AuthService.logout();
                  widget.onLogout?.call();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(resp['message'] ?? 'Logout berhasil'),
                      backgroundColor: Theme.of(context).colorScheme.tertiary,
                    ),
                  );
                }
              }
            },
            itemBuilder: (BuildContext context) => [
              PopupMenuItem<String>(
                value: 'logout',
                child: ListTile(
                  leading: Icon(Icons.logout, color: cs.error),
                  title: Text('Logout', style: TextStyle(color: cs.error)),
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
                        style: TextStyle(color: Theme.of(context).colorScheme.secondary),
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
                    color: Theme.of(context).scaffoldBackgroundColor,
                    child: Column(
                      children: [
                        // Summary Card
                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.all(16),
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: cs.secondaryContainer,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Ringkasan Hutang',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.onSecondaryContainer,
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
                                          color: Theme.of(context).colorScheme.onSecondaryContainer,
                                          fontSize: 14,
                                        ),
                                      ),
                                      Text(
                                        currencyFormat.format(summary['totalHutang'] ?? 0),
                                        style: TextStyle(
                                          color: Theme.of(context).colorScheme.onSecondaryContainer,
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
                                          color: Theme.of(context).colorScheme.onSecondaryContainer,
                                          fontSize: 14,
                                        ),
                                      ),
                                      Text(
                                        currencyFormat.format(summary['totalHutang'] ?? 0),
                                        style: TextStyle(
                                          color: Theme.of(context).colorScheme.onSecondaryContainer,
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
                              Text(
                                'Daftar Penghutang',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox.shrink(),
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
                                            color: cs.primary.withValues(alpha: 0.15),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Center(
                                            child: Text(
                                              user.name.substring(0, 1).toUpperCase(),
                                              style: TextStyle(
                                                color: Colors.white,
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
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: Theme.of(context).colorScheme.onSurface,
                                              ),
                                              ),
                                              if (user.phone != null) ...[
                                                const SizedBox(height: 4),
                                                Text(
                                                  user.phone!,
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
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
                                                color: totalHutang > 0 ? Colors.red : cs.secondary,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              totalHutang > 0 ? 'Belum Lunas' : 'Lunas',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: totalHutang > 0 ? Colors.red : cs.tertiary,
                                              ),
                                            ),
                                          ],
                                        ),
                                        
                                        const SizedBox(width: 8),
                                        Icon(
                                          Icons.chevron_right,
                                          color: Theme.of(context).colorScheme.outline,
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
        backgroundColor: cs.secondary,
        child: const Icon(Icons.add, color: Colors.white, size: 28),
        tooltip: 'Tambah Hutang Baru',
      ),
    );
  }
}
