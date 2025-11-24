import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:project_pbp_flutter/screens/home_screen.dart';
import 'package:project_pbp_flutter/screens/login_screen.dart';
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
        useMaterial3: true,
        colorScheme: ColorScheme.light().copyWith(
          primary: Colors.grey.shade900,
          onPrimary: Colors.white,
          secondary: Colors.green.shade600,
          onSecondary: Colors.white,
          tertiary: Colors.green.shade700,
          onTertiary: Colors.white,
          error: Colors.grey.shade800,
          onError: Colors.white,
          surface: Colors.grey.shade100,
          onSurface: Colors.black87,
          secondaryContainer: Colors.green.shade600,
          onSecondaryContainer: Colors.white,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green.shade600,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: Colors.green.shade600,
          ),
        ),
        appBarTheme: AppBarTheme(
          elevation: 4,
          centerTitle: false,
          backgroundColor: Colors.grey.shade900, // Hitam untuk AppBar
          foregroundColor: Colors.white, // Putih untuk teks AppBar
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          elevation: 8,
          backgroundColor: Colors.green.shade600, // Hijau emerald untuk FAB
          foregroundColor: Colors.white, // Putih untuk ikon FAB
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 2,
          color: Colors.white, // Putih untuk card di tema terang
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.grey.shade50, // Abu-abu sangat muda untuk input
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade400),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.green.shade600), // Hijau emerald untuk fokus
          ),
          hintStyle: TextStyle(color: Colors.grey.shade600), // Abu-abu untuk hint
          labelStyle: TextStyle(color: Colors.grey.shade800), // Abu-abu gelap untuk label
        ),
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.grey.shade900, // Hitam untuk SnackBar
          contentTextStyle: const TextStyle(color: Colors.white), // Putih untuk teks
        ),
        chipTheme: ChipThemeData(
          backgroundColor: Colors.green.shade100, // Hijau muda untuk chip
          selectedColor: Colors.green.shade200, // Hijau untuk chip terpilih
          labelStyle: TextStyle(color: Colors.grey.shade900), // Hitam untuk teks chip
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.dark().copyWith(
          primary: Colors.grey.shade900,
          onPrimary: Colors.white,
          secondary: Colors.green.shade600,
          onSecondary: Colors.white,
          tertiary: Colors.green.shade500,
          onTertiary: Colors.white,
          error: Colors.grey.shade700,
          onError: Colors.white,
          surface: Colors.grey.shade800,
          onSurface: Colors.white,
          onSurfaceVariant: Colors.grey.shade300,
          secondaryContainer: Colors.green.shade600,
          onSecondaryContainer: Colors.white,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green.shade600,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: Colors.green.shade400,
          ),
        ),
        scaffoldBackgroundColor: Colors.grey.shade900, // Abu-abu gelap untuk background
        appBarTheme: AppBarTheme(
          elevation: 4,
          centerTitle: false,
          backgroundColor: Colors.grey.shade900, // Hitam untuk AppBar
          foregroundColor: Colors.white, // Putih untuk teks AppBar
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          elevation: 8,
          backgroundColor: Colors.green.shade600, // Hijau emerald untuk FAB
          foregroundColor: Colors.white, // Putih untuk ikon FAB
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 2,
          color: Colors.grey.shade800, // Abu-abu gelap untuk card
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.grey.shade800, // Abu-abu gelap untuk input
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade700),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade700),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.green.shade600), // Hijau emerald untuk fokus
          ),
          hintStyle: TextStyle(color: Colors.grey.shade400), // Abu-abu untuk hint
          labelStyle: TextStyle(color: Colors.grey.shade200), // Abu-abu terang untuk label
        ),
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.grey.shade900, // Hitam untuk SnackBar
          contentTextStyle: const TextStyle(color: Colors.white), // Putih untuk teks
        ),
        chipTheme: ChipThemeData(
          backgroundColor: Colors.green.shade700, // Hijau emerald untuk chip
          selectedColor: Colors.green.shade600, // Hijau untuk chip terpilih
          labelStyle: TextStyle(color: Colors.white), // Putih untuk teks chip
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
