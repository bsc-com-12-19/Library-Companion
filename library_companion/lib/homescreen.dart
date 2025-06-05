import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // CORRECTED: Use Supabase.instance.client.auth
    final user = Supabase.instance.client.auth.currentUser;
    final role = user?.userMetadata?['role'] ?? 'Guest';

    return Scaffold(
      appBar: AppBar(
        title: Text('Library App'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () async {
              // CORRECTED: Use Supabase.instance.client.auth
              await Supabase.instance.client.auth.signOut();
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