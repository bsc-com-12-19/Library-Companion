// ignore_for_file: avoid_print, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final SupabaseClient supabase = Supabase.instance.client;
  List<dynamic> books = [];

  @override
  void initState() {
    super.initState();
    fetchBooks();
  }

  Future<void> fetchBooks() async {
    final response =
        await supabase
            .from('book_availability')
            .select('book_id, title, author, available_copies')
            .execute(); //only fetch books available for renting
    if (response.error == null) {
      setState(() {
        books = response.data;
      });
    } else {
      // Handle error
      print('Error fetching books: ${response.error!.message}');
    }
  }

  void setAlert(String bookId) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;

    if (userId == null) {
      print('User not logged in');
      return;
    }

    final response =
        await Supabase.instance.client.from('alerts').insert({
          'user_id': userId,
          'book_id': int.parse(bookId),
          'alert_set_date': DateTime.now().toIso8601String(),
          'active': true,
        }).execute();

    if (response.error != null) {
      print('Error setting alert: ${response.error!.message}');
    } else {
      print('Alert set successfully for book ID: $bookId');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Alert set for this book')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Library Catalog')),
      body:
          books.isEmpty
              ? Center(child: CircularProgressIndicator())
              : ListView.builder(
                itemCount: books.length,
                itemBuilder: (context, index) {
                  final book = books[index];
                  return Card(
                    margin: EdgeInsets.all(8.0),
                    child: ListTile(
                      title: Text(book['title']),
                      subtitle: Text('Author: ${book['author']}'),
                      trailing:
                          (book['available_copies'] == 0)
                              ? ElevatedButton(
                                onPressed: () => setAlert(book['book_id']),
                                child: Text('Set Alert'),
                              )
                              : Text('Available'),
                    ),
                  );
                },
              ),
    );
  }
}
