import 'package:flutter/material.dart';
<<<<<<< HEAD
import 'package:supabase_flutter/supabase_flutter.dart';
import 'pages/home_page.dart';
=======
import 'package:library_companion/homescreen.dart';
import 'package:library_companion/loginscreen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
>>>>>>> tafadzwa

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
<<<<<<< HEAD
    url: 'https://aifoilqteioptnifjvfb.supabase.co',
=======
    url: 'https://aifoilqteioptnifjvfb.supabase.co', 
>>>>>>> tafadzwa
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFpZm9pbHF0ZWlvcHRuaWZqdmZiIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDkxMjY3NDMsImV4cCI6MjA2NDcwMjc0M30.zS4g8Kwyo02qdPJtSzptvwOq2SNAYbK3JCzloXM32rI',
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
<<<<<<< HEAD
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Library Companion',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: HomePage(),
    );
  }
}
=======
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Library App',
      initialRoute: '/',
      routes: {
        '/': (context) => LoginScreen(),
        '/home': (context) => HomeScreen(),
      },
    );
  }
}
>>>>>>> tafadzwa
