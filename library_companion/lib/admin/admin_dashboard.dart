// ignore_for_file: use_key_in_widget_constructors, library_private_types_in_public_api, deprecated_member_use, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminDashboard extends StatefulWidget {
  @override
  _AdminDashboardState createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> with SingleTickerProviderStateMixin {
  final supabase = Supabase.instance.client;
  late TabController _tabController;
  
  List<Map<String, dynamic>> books = [];
  List<Map<String, dynamic>> users = [];
  List<Map<String, dynamic>> rentals = [];
  List<Map<String, dynamic>> overdueRentals = [];
  
  bool isLoading = true;
  int availableBooksCount = 0;
  int activeUsersCount = 0;
  int activeRentalsCount = 0;
  int overdueRentalsCount = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    setState(() => isLoading = true);
    
    try {
      final results = await Future.wait([
        supabase.from('books').select(),
        supabase.from('profiles').select(),
        supabase.from('rentals').select('*, books(*), profiles(*)'),
      ]);

      setState(() {
        books = List<Map<String, dynamic>>.from(results[0]);
        users = List<Map<String, dynamic>>.from(results[1]);
        rentals = List<Map<String, dynamic>>.from(results[2]);
        
        availableBooksCount = books.fold(0, (sum, book) => sum + (book['total_copies'] as int));
        activeUsersCount = users.length;
        activeRentalsCount = rentals.where((r) => r['returned_date'] == null).length;
        
        overdueRentals = rentals.where((rental) {
          final dueDate = DateTime.parse(rental['due_date'] as String);
          return rental['returned_date'] == null && dueDate.isBefore(DateTime.now());
        }).toList();
        
        overdueRentalsCount = overdueRentals.length;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching data: ${e.toString()}')),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Library Admin Dashboard', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        backgroundColor: const Color(0xFF00A651), // TNM green
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            tooltip: 'Refresh Data',
            onPressed: _fetchData,
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onSelected: (value) {
              if (value == 'logout') {
                supabase.auth.signOut();
                Navigator.pushReplacementNamed(context, '/');
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'logout',
                child: Text('Logout', style: TextStyle(color: Colors.black)),
              ),
            ],
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            color: const Color(0xFF008C45), // Darker TNM green
            child: TabBar(
              controller: _tabController,
              onTap: (index) => setState(() {}),
              indicatorColor: Colors.white,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white.withOpacity(0.7),
              tabs: const [
                Tab(icon: Icon(Icons.book), text: 'Books'),
                Tab(icon: Icon(Icons.people), text: 'Users'),
                Tab(icon: Icon(Icons.history), text: 'Rentals'),
              ],
            ),
          ),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildStatisticsOverview(),
                const Divider(height: 1),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildBooksTab(),
                      _buildUsersTab(),
                      _buildRentalsTab(),
                    ],
                  ),
                ),
              ],
            ),
      floatingActionButton: _tabController.index == 0
          ? FloatingActionButton(
              tooltip: 'Add New Book',
              backgroundColor: const Color(0xFF00A651), // TNM green
              child: const Icon(Icons.add, color: Colors.white),
              onPressed: () => _showBookDialog(context),
            )
          : null,
    );
  }

  Widget _buildStatisticsOverview() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF00A651).withOpacity(0.1),
            const Color(0xFF008C45).withOpacity(0.1),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Library Overview',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _buildStatCard(
                'Total Books',
                books.length.toString(),
                Icons.book,
                const Color(0xFF00A651),
              ),
              _buildStatCard(
                'Available Copies',
                availableBooksCount.toString(),
                Icons.library_books,
                const Color(0xFF008C45),
              ),
              _buildStatCard(
                'Active Users',
                activeUsersCount.toString(),
                Icons.people,
                const Color(0xFF00A651),
              ),
              _buildStatCard(
                'Active Rentals',
                activeRentalsCount.toString(),
                Icons.history,
                const Color(0xFF008C45),
              ),
              _buildStatCard(
                'Overdue Rentals',
                overdueRentalsCount.toString(),
                Icons.warning,
                Colors.red,
                isAlert: overdueRentalsCount > 0,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color, {bool isAlert = false}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        width: 160,
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isAlert ? Colors.red : color,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBooksTab() {
    return RefreshIndicator(
      onRefresh: _fetchData,
      child: books.isEmpty
          ? const Center(child: Text('No books available'))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: books.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final book = books[index];
                return _buildBookCard(book);
              },
            ),
    );
  }

  Widget _buildBookCard(Map<String, dynamic> book) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.book, size: 24, color: Color(0xFF00A651)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    book['title'] ?? 'Untitled',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') {
                      _showBookDialog(context, book: book);
                    } else if (value == 'delete') {
                      _confirmDeleteBook(book['id']);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Text('Edit Book'),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text('Delete Book', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Author: ${book['author'] ?? 'Unknown'}',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 4),
            Text(
              'ISBN: ${book['isbn'] ?? 'Not specified'}',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 4),
            Text(
              'Copies: ${book['total_copies']}',
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUsersTab() {
    return RefreshIndicator(
      onRefresh: _fetchData,
      child: users.isEmpty
          ? const Center(child: Text('No users registered'))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: users.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final user = users[index];
                return _buildUserCard(user);
              },
            ),
    );
  }

  Widget _buildUserCard(Map<String, dynamic> user) {
    final userRentals = rentals.where((r) => r['user_id'] == user['id']).toList();
    final activeRentals = userRentals.where((r) => r['returned_date'] == null).length;
    final overdue = userRentals.where((r) {
      final dueDate = DateTime.parse(r['due_date'] as String);
      return r['returned_date'] == null && dueDate.isBefore(DateTime.now());
    }).length;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF00A651).withOpacity(0.2),
          child: Text(
            user['full_name']?[0] ?? '?',
            style: const TextStyle(color: Color(0xFF00A651)),
          ),
        ),
        title: Text(
          user['full_name'] ?? 'Unknown User',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              'Email: ${user['email'] ?? 'Not provided'}',
              style: const TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Chip(
                  label: Text('$activeRentals active'),
                  backgroundColor: Colors.green.shade50,
                  labelStyle: TextStyle(color: Colors.green.shade800),
                ),
                const SizedBox(width: 8),
                if (overdue > 0)
                  Chip(
                    label: Text('$overdue overdue'),
                    backgroundColor: Colors.red.shade50,
                    labelStyle: TextStyle(color: Colors.red.shade800),
                  ),
              ],
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => _showUserDetails(user, userRentals),
      ),
    );
  }

  Widget _buildRentalsTab() {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          TabBar(
            indicatorColor: const Color(0xFF00A651),
            labelColor: const Color(0xFF00A651),
            unselectedLabelColor: Colors.grey,
            tabs: const [
              Tab(text: 'Active Rentals'),
              Tab(text: 'Overdue Rentals'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildActiveRentalsList(),
                _buildOverdueRentalsList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveRentalsList() {
    final activeRentals = rentals.where((r) => r['returned_date'] == null).toList();
    
    return RefreshIndicator(
      onRefresh: _fetchData,
      child: activeRentals.isEmpty
          ? const Center(child: Text('No active rentals'))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: activeRentals.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final rental = activeRentals[index];
                return _buildRentalCard(rental);
              },
            ),
    );
  }

  Widget _buildOverdueRentalsList() {
    return RefreshIndicator(
      onRefresh: _fetchData,
      child: overdueRentals.isEmpty
          ? const Center(child: Text('No overdue rentals'))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: overdueRentals.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final rental = overdueRentals[index];
                return _buildRentalCard(rental, isOverdue: true);
              },
            ),
    );
  }

  Widget _buildRentalCard(Map<String, dynamic> rental, {bool isOverdue = false}) {
    final book = rental['books'] as Map<String, dynamic>? ?? {};
    final user = rental['profiles'] as Map<String, dynamic>? ?? {};
    final dueDate = DateTime.parse(rental['due_date'] as String);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: isOverdue ? Colors.red.shade50 : null,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.book, size: 24, color: Color(0xFF00A651)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    book['title'] ?? 'Unknown Book',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                if (rental['returned_date'] == null)
                  TextButton(
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF00A651),
                    ),
                    child: const Text('MARK RETURNED'),
                    onPressed: () => _markRentalReturned(rental['id']),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Borrowed by: ${user['full_name'] ?? 'Unknown User'}',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 4),
            Text(
              'Due: ${dueDate.toLocal().toString().split(' ')[0]}',
              style: TextStyle(
                fontSize: 14,
                color: isOverdue ? Colors.red : null,
                fontWeight: isOverdue ? FontWeight.bold : null,
              ),
            ),
            if (isOverdue)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    const Icon(Icons.warning, size: 16, color: Colors.red),
                    const SizedBox(width: 4),
                    Text(
                      '${DateTime.now().difference(dueDate).inDays} days overdue',
                      style: const TextStyle(color: Colors.red),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _markRentalReturned(int rentalId) async {
    try {
      await supabase.from('rentals').update({
        'returned_date': DateTime.now().toIso8601String(),
      }).eq('id', rentalId);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Rental marked as returned')),
      );
      await _fetchData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  Future<void> _confirmDeleteBook(int bookId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Deletion'),
        content: const Text('Are you sure you want to delete this book? This action cannot be undone.'),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(context, false),
          ),
          TextButton(
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await supabase.from('books').delete().eq('id', bookId);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Book deleted successfully')),
        );
        await _fetchData();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  void _showBookDialog(BuildContext context, {Map<String, dynamic>? book}) {
    final isEditing = book != null;
    final formKey = GlobalKey<FormState>();
    
    final titleController = TextEditingController(text: book?['title']);
    final authorController = TextEditingController(text: book?['author']);
    final isbnController = TextEditingController(text: book?['isbn'] ?? '');
    final copiesController = TextEditingController(text: book?['total_copies']?.toString() ?? '1');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEditing ? 'Edit Book' : 'Add New Book'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Title*',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value!.isEmpty ? 'Required field' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: authorController,
                  decoration: const InputDecoration(
                    labelText: 'Author*',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value!.isEmpty ? 'Required field' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: isbnController,
                  decoration: const InputDecoration(
                    labelText: 'ISBN',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: copiesController,
                  decoration: const InputDecoration(
                    labelText: 'Copies*',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value!.isEmpty) return 'Required field';
                    if (int.tryParse(value) == null) return 'Must be a number';
                    if (int.parse(value) < 1) return 'Must be at least 1';
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00A651),
            ),
            child: Text(isEditing ? 'Update' : 'Add'),
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                try {
                  final bookData = {
                    'title': titleController.text,
                    'author': authorController.text,
                    'isbn': isbnController.text.isNotEmpty ? isbnController.text : null,
                    'total_copies': int.parse(copiesController.text),
                  };

                  if (isEditing) {
                    await supabase.from('books')
                        .update(bookData)
                        .eq('id', book['id']);
                  } else {
                    await supabase.from('books').insert(bookData);
                  }

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Book ${isEditing ? 'updated' : 'added'} successfully')),
                  );
                  Navigator.pop(context);
                  await _fetchData();
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: ${e.toString()}')),
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }

  void _showUserDetails(Map<String, dynamic> user, List<Map<String, dynamic>> userRentals) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(user['full_name'] ?? 'User Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.email),
                title: const Text('Email'),
                subtitle: Text(user['email'] ?? 'Not provided'),
              ),
              const Divider(),
              const Text(
                'Rental History',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              if (userRentals.isEmpty)
                const Text('No rental history'),
              ...userRentals.map((rental) {
                final book = rental['books'] as Map<String, dynamic>? ?? {};
                final dueDate = DateTime.parse(rental['due_date'] as String);
                final isOverdue = dueDate.isBefore(DateTime.now()) && rental['returned_date'] == null;
                
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.book, size: 20),
                  title: Text(book['title'] ?? 'Unknown Book'),
                  subtitle: Text(
                    'Due: ${dueDate.toLocal().toString().split(' ')[0]}'
                    '${rental['returned_date'] != null ? '\nReturned' : ''}'
                    '${isOverdue ? '\nOVERDUE' : ''}',
                    style: TextStyle(
                      color: isOverdue ? Colors.red : null,
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
        actions: [
          TextButton(
            child: const Text('Close'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}