import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'available_books_page.dart';
import 'rented_books_page.dart';
import 'search_bar.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> books = [];
  String searchQuery = '';
  int bottomNavIndex = 0; // For Home, Alerts, Profile navigation
  int toggleIndex = 0; // 0 = Available, 1 = Rented
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchBooks();
  }

  Future<void> fetchBooks() async {
    final response = await supabase
        .from('book_availability')
        .select('book_id, title, author, available_copies')
        .execute();

    if (response.error == null) {
      setState(() {
        books = List<Map<String, dynamic>>.from(response.data as List);
        loading = false;
      });
    } else {
      print('Error fetching books: ${response.error!.message}');
      setState(() {
        loading = false;
      });
    }
  }

  List<Map<String, dynamic>> filterBooks(List<Map<String, dynamic>> bookList) {
    if (searchQuery.isEmpty) return bookList;
    final lowerQuery = searchQuery.toLowerCase();
    return bookList.where((book) {
      final title = book['title'].toString().toLowerCase();
      final author = book['author'].toString().toLowerCase();
      return title.contains(lowerQuery) || author.contains(lowerQuery);
    }).toList();
  }

  void setAlert(String bookId) async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('User not logged in')));
      return;
    }

    final response = await supabase.from('alerts').insert({
      'user_id': userId,
      'book_id': int.parse(bookId),
      'alert_set_date': DateTime.now().toIso8601String(),
      'active': true,
    }).execute();

    if (response.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error setting alert: ${response.error!.message}')),
      );
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Alert set for this book')));
    }
  }

  // Dummy placeholders for Alerts and Profile pages.
  // Replace these with your actual pages or widgets.
  Widget alertsPage() => const Center(child: Text('Alerts Page'));
  Widget profilePage() => const Center(child: Text('Profile Page'));

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
          body: Center(child: CircularProgressIndicator()));
    }

    final availableBooks =
        filterBooks(books.where((b) => (b['available_copies'] ?? 0) > 0).toList());
    final rentedBooks =
        filterBooks(books.where((b) => (b['available_copies'] ?? 0) == 0).toList());

    // Determine main body depending on bottom nav index
    Widget bodyContent;

    if (bottomNavIndex == 0) {
      // Home page with toggle and book lists
      bodyContent = Column(
        children: [
          const SizedBox(height: 8),
          BuildSearchBar(onSearch: (val) {
            setState(() {
              searchQuery = val;
            });
          }),
          const SizedBox(height: 8),
          // Top toggle between Available and Rented
          ToggleButtons(
            isSelected: [toggleIndex == 0, toggleIndex == 1],
            onPressed: (index) {
              setState(() {
                toggleIndex = index;
              });
            },
            borderRadius: BorderRadius.circular(8),
            selectedColor: Colors.white,
            fillColor: Colors.blue,
            children: const [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text('Available'),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text('Rented'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: toggleIndex == 0
                ? AvailableBooksList(books: availableBooks)
                : RentedBooksList(books: rentedBooks, setAlert: setAlert),
          )
        ],
      );
    } else if (bottomNavIndex == 1) {
      bodyContent = alertsPage();
    } else {
      bodyContent = profilePage();
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Library Companion')),
      body: bodyContent,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: bottomNavIndex,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.notifications), label: 'Alerts'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
        onTap: (index) {
          setState(() {
            bottomNavIndex = index;
            // Reset search and toggle only when going back to home tab
            if (index == 0) {
              searchQuery = '';
              toggleIndex = 0;
            }
          });
        },
      ),
    );
  }
}

extension on PostgrestFilterBuilder {
  execute() {}
}