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
    final response = await supabase.from('books').select().execute();
    if (response.error == null) {
      setState(() {
        books = response.data;
      });
    } else {
      // Handle error
      print('Error fetching books: ${response.error!.message}');
    }
  }

  void setAlert(String bookId) {
    // Logic to set an alert for the book
    // This could involve saving the alert in a database or local storage
    print('Alert set for book ID: $bookId');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Library Catalog'),
      ),
      body: books.isEmpty
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
                    trailing: (book['available'] ?? false)
                        ? ElevatedButton(
                            onPressed: () => setAlert(book['id']),
                            child: Text('Set Alert'),
                          )
                        : Text('Currently Rented'),
                  ),
                );
              },
            ),
    );
  }
}