import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:library_companion/homescreen.dart';
import 'package:library_companion/loginscreen.dart';
import 'package:library_companion/student/student_dashboard.dart';
//import 'package:library_companion/available_books_screen.dart';
//import 'package:library_companion/my_rentals_screen.dart';
//import 'package:library_companion/my_alerts_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Supabase.initialize(
    url: 'https://aifoilqteioptnifjvfb.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFpZm9pbHF0ZWlvcHRuaWZqdmZiIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDkxMjY3NDMsImV4cCI6MjA2NDcwMjc0M30.zS4g8Kwyo02qdPJtSzptvwOq2SNAYbK3JCzloXM32rI',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Library Companion',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 2,
        ),
        cardTheme: CardTheme(
          elevation: 1,
          margin: const EdgeInsets.symmetric(vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) =>  LoginScreen(),
        '/home': (context) =>  HomeScreen(),
        '/dashboard': (context) => const StudentDashboard(),
        '/available-books': (context) => const AvailableBooksScreen(),
        '/my-rentals': (context) => const MyRentalsScreen(),
        '/my-alerts': (context) => const MyAlertsScreen(),
      },
      debugShowCheckedModeBanner: false,
      onGenerateRoute: (settings) {
        // Handle any undefined routes by redirecting to login
        return MaterialPageRoute(
          builder: (context) =>  LoginScreen(),
        );
      },
    );
  }
}