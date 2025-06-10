// ignore_for_file: use_key_in_widget_constructors, library_private_types_in_public_api, avoid_print, sort_child_properties_last, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final SupabaseClient supabase = Supabase.instance.client;
  List books = [];
  int _selectedIndex = 0;

  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    fetchBooks();
  }

  Future fetchBooks() async {
    final response = await supabase
        .from('book_availability')
        .select('book_id, title, author, available_copies')
        .execute();

    if (response.error == null) {
      setState(() {
        books = response.data;
      });
    } else {
      print('Error fetching books: ${response.error!.message}');
    }
  }

  void setAlert(String bookId) async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) {
      print('User not logged in');
      return;
    }

    final response = await supabase.from('alerts').insert({
      'user_id': userId,
      'book_id': int.parse(bookId),
      'alert_set_date': DateTime.now().toIso8601String(),
      'active': true,
    }).execute();

    if (response.error != null) {
      print('Error setting alert: ${response.error!.message}');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Alert set for this book')),
      );
    }
  }

  // Helper to filter books by search query
  List filterBooks(List bookList) {
    if (_searchQuery.isEmpty) return bookList;
    return bookList.where((book) {
      final title = book['title'].toString().toLowerCase();
      final author = book['author'].toString().toLowerCase();
      final query = _searchQuery.toLowerCase();
      return title.contains(query) || author.contains(query);
    }).toList();
  }

  Widget buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Search by title or author',
          prefixIcon: Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 16),
        ),
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
      ),
    );
  }

  Widget availableBooksList() {
    final availableBooks =
        books.where((book) => (book['available_copies'] ?? 0) > 0).toList();
    final filteredBooks = filterBooks(availableBooks);

    if (filteredBooks.isEmpty) {
      return Center(
        child: Text(
          'No available books found.',
          style: TextStyle(fontSize: 16, color: Colors.grey[700]),
        ),
      );
    }

    return Expanded(
      child: RefreshIndicator(
        onRefresh: fetchBooks,
        child: ListView.separated(
          padding: EdgeInsets.symmetric(horizontal: 12),
          itemCount: filteredBooks.length,
          separatorBuilder: (BuildContext context , int index) => SizedBox(height: 12),
          itemBuilder: (context, index) {
            final book = filteredBooks[index];
            return Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              elevation: 3,
              shadowColor: Colors.blueAccent.withOpacity(0.2),
              child: ListTile(
                leading: Icon(Icons.book, color: Colors.blue[700]),
                title: Text(
                  book['title'],
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                subtitle: Text('Author: ${book['author']}'),
                trailing: Icon(Icons.check_circle, color: Colors.green[600]),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget rentedBooksList() {
    final rentedBooks =
        books.where((book) => (book['available_copies'] ?? 0) == 0).toList();
    final filteredBooks = filterBooks(rentedBooks);

    if (filteredBooks.isEmpty) {
      return Center(
        child: Text(
          'No rented books found.',
          style: TextStyle(fontSize: 16, color: Colors.grey[700]),
        ),
      );
    }

    return Expanded(
      child: RefreshIndicator(
        onRefresh: fetchBooks,
        child: ListView.separated(
          padding: EdgeInsets.symmetric(horizontal: 12),
          itemCount: filteredBooks.length,
          separatorBuilder: (BuildContext context, int index) => SizedBox(height: 12),
          itemBuilder: (context, index) {
            final book = filteredBooks[index];
            return Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              elevation: 3,
              shadowColor: Colors.orangeAccent.withOpacity(0.3),
              child: ListTile(
                leading: Icon(Icons.lock, color: Colors.orange[700]),
                title: Text(
                  book['title'],
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                subtitle: Text('Author: ${book['author']}'),
                trailing: ElevatedButton(
                  onPressed: () => setAlert(book['book_id'].toString()),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  ),
                  child: Text('Set Alert'),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget getBody() {
    if (books.isEmpty) {
      return Center(child: CircularProgressIndicator());
    }

    switch (_selectedIndex) {
      case 0:
        // Home - Available Books only
        return Column(
          children: [
            buildSearchBar(),
            availableBooksList(),
          ],
        );
      case 1:
        // Rented Books
        return Column(
          children: [
            buildSearchBar(),
            rentedBooksList(),
          ],
        );
      case 2:
        return Center(child: Text('Admin Page - Under Construction'));
      case 3:
        return Center(child: Text('User Profile - Under Construction'));
      default:
        return Center(child: Text('Page not found'));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue[50],
      appBar: AppBar(
        title: Text('Library Companion'),
        backgroundColor: Colors.blue[700],
        elevation: 4,
        shadowColor: Colors.blueAccent,
      ),
      body: getBody(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
            _searchQuery = ''; // Reset search when switching tabs
          });
        },
        selectedItemColor: Colors.blue[700],
        unselectedItemColor: Colors.grey[600],
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.lock), label: 'Rented'),
          BottomNavigationBarItem(
              icon: Icon(Icons.admin_panel_settings), label: 'Admin'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'User'),
        ],
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}