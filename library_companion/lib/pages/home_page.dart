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

  void setAlert(String bookId) async{
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;

      if (userId == null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('you must be logged in to set alerts')),
        );
        return;
      }
      final response = await
      supabase.from('alerts').insert({
        'book_id': bookId,
        'user_id':userId,
        'alert_set_date': DateTime.now().toIso8601String(),
        'active': true,

      });

      
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Alert successfully set for this book!')),
        );
        } catch (e) {
           print('Error inserting alert: $e');
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to set alert. Please try again')),
        );   

    }   
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
                        : Text('Rented'),
                  ),
                );
              },
            ),
    );
  }
}