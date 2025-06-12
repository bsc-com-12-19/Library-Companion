// ignore_for_file: unused_import

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'pages/home_page.dart';
import 'package:library_companion/homescreen.dart';
import 'package:library_companion/loginscreen.dart';
import 'package:library_companion/pages/home_page.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://aifoilqteioptnifjvfb.supabase.co', 
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFpZm9pbHF0ZWlvcHRuaWZqdmZiIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDkxMjY3NDMsImV4cCI6MjA2NDcwMjc0M30.zS4g8Kwyo02qdPJtSzptvwOq2SNAYbK3JCzloXM32rI',
  );
  runApp(MyApp());
}

 class MyApp extends StatelessWidget {

   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Library Companion',
//       theme: ThemeData(
//         primarySwatch: Colors.blue,
//       ),
//       home: HomePage(),
//     );
//   }
// }

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
