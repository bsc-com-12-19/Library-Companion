// pages/rented_books_page.dart

import 'package:flutter/material.dart';

class RentedBooksList extends StatelessWidget {
  final List<Map<String, dynamic>> books;
  final void Function(String) setAlert;

  const RentedBooksList({super.key, required this.books, required this.setAlert});

  @override
  Widget build(BuildContext context) {
    if (books.isEmpty) {
      return const Center(child: Text('No rented books found.'));
    }

    return ListView.builder(
      itemCount: books.length,
      itemBuilder: (context, index) {
        final book = books[index];
        return ListTile(
          leading: const Icon(Icons.lock, color: Colors.orange),
          title: Text(book['title']),
          subtitle: Text('Author: ${book['author']}'),
          trailing: ElevatedButton(
            onPressed: () => setAlert(book['book_id'].toString()),
            child: const Text('Set Alert'),
          ),
        );
      },
    );
  }
}