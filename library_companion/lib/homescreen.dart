// ignore_for_file: unused_import

import 'package:flutter/material.dart';
import 'package:library_companion/admin/admin_dashboard.dart';
import 'package:library_companion/student/student_dashboard.dart';
=========
import 'package:library_companion/admin/admin_dashboard.dart';
import 'package:library_companion/student/studentDashboard.dart';
>>>>>>>>> Temporary merge branch 2
import 'package:supabase_flutter/supabase_flutter.dart';

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;
    final role = user?.userMetadata?['role'] ?? 'Guest';

    // Redirect admin users to the dashboard
    if (role == 'Library Manager') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => AdminDashboard()),
        );
      });
      return Scaffold(body: Center(child: CircularProgressIndicator()));
    }

     // Redirect students to student dashboard
    if (role == 'Student') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => StudentDashboard()),
        );
      });
      return Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Library App'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () async {
              await supabase.auth.signOut();
              Navigator.pushReplacementNamed(context, '/');
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Welcome to the Library App!', style: TextStyle(fontSize: 24)),
            SizedBox(height: 20),
            Text('Role: $role', style: TextStyle(fontSize: 18)),
          ],
        ),
      ),
    );
  }
}