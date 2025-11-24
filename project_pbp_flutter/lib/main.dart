import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:project_pbp_flutter/screens/home_screen.dart';
import 'package:project_pbp_flutter/screens/hutang_detail_screen.dart';
import 'package:project_pbp_flutter/screens/user_detail_screen.dart';
import 'package:project_pbp_flutter/screens/add_hutang_screen.dart';
import 'package:project_pbp_flutter/screens/add_user_screen.dart';
import 'package:project_pbp_flutter/screens/login_screen.dart';
import 'package:project_pbp_flutter/screens/register_screen.dart';
import 'package:project_pbp_flutter/models/hutang.dart';
import 'package:project_pbp_flutter/models/user.dart';
import 'package:project_pbp_flutter/services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isAuthenticated = false;
  bool _isCheckingAuth = true;

  @override
  void initState() {
    super.initState();
    _checkAuthentication();
  }

  Future<void> _checkAuthentication() async {
    setState(() {
      _isCheckingAuth = true;
    });

    // Check if user is currently authenticated
    final isAuth = AuthService.isAuthenticated;
    
    setState(() {
      _isAuthenticated = isAuth;
      _isCheckingAuth = false;
    });
  }

  void _onLoginSuccess() {
    setState(() {
      _isAuthenticated = true;
    });
  }

  void _onLogout() {
    setState(() {
      _isAuthenticated = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hutangmu',
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('id', 'ID'),
        Locale('en', 'US'),
      ],
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.green,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          elevation: 4,
          centerTitle: false,
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.green,
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: Colors.grey[900],
        useMaterial3: true,
        appBarTheme: AppBarTheme(
          elevation: 4,
          centerTitle: false,
          backgroundColor: Colors.grey[850],
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          elevation: 8,
          backgroundColor: Colors.green[600],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 2,
          color: Colors.grey[850],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      themeMode: ThemeMode.dark, // Set to dark theme by default
      home: _isCheckingAuth
          ? const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            )
          : _isAuthenticated
              ? HomeScreen(onLogout: _onLogout)
              : LoginScreen(onLoginSuccess: _onLoginSuccess),
      debugShowCheckedModeBanner: false,
    );
  }
}