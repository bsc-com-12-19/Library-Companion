// pages/search_bar.dart

import 'package:flutter/material.dart';

class BuildSearchBar extends StatelessWidget {
  final Function(String) onSearch;

  const BuildSearchBar({super.key, required this.onSearch});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Search by title or author',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          filled: true,
          fillColor: Colors.white,
        ),
        onChanged: onSearch,
      ),
    );
  }
}