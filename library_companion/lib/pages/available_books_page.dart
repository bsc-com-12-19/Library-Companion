// pages/available_books_page.dart

import 'package:flutter/material.dart';

class AvailableBooksList extends StatelessWidget {
  final List<Map<String, dynamic>> books;

  const AvailableBooksList({super.key, required this.books});

  @override
  Widget build(BuildContext context) {
    if (books.isEmpty) {
      return const Center(child: Text('No available books found.'));
    }

    return ListView.builder(
      itemCount: books.length,
      itemBuilder: (context, index) {
        final book = books[index];
        return ListTile(
          leading: const Icon(Icons.menu_book_rounded, color: Colors.blue),
          title: Text(book['title']),
          subtitle: Text('Author: ${book['author']}'),
          trailing: const Icon(Icons.check_circle, color: Colors.green),
        );
      },
    );
  }
}