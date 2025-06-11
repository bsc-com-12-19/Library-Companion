import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminDashboard extends StatefulWidget {
  @override
  _AdminDashboardState createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> books = [];
  List<Map<String, dynamic>> users = [];
  List<Map<String, dynamic>> rentals = [];
  bool isLoading = true;
  int selectedTabIndex = 0;
  int availableBooks = 0;
  int activeRentals = 0;
  int overdueRentals = 0;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => isLoading = true);
    
    // Fetch books
    final booksResponse = await supabase.from('books').select();
    setState(() => books = List<Map<String, dynamic>>.from(booksResponse));
    
    // Fetch users
    final usersResponse = await supabase.from('profiles').select();
    setState(() => users = List<Map<String, dynamic>>.from(usersResponse));
    
    // Fetch rentals
    final rentalsResponse = await supabase.from('rentals').select();
    setState(() => rentals = List<Map<String, dynamic>>.from(rentalsResponse));
    
    // Calculate stats
    availableBooks = books.fold(0, (sum, book) => sum + (book['total_copies'] as int));
    activeRentals = rentals.where((rental) => rental['returned_date'] == null).length;
    overdueRentals = rentals.where((rental) {
      final dueDate = DateTime.parse(rental['due_date'] as String);
      return rental['returned_date'] == null && dueDate.isBefore(DateTime.now());
    }).length;
    
    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () async {
              await supabase.auth.signOut();
              Navigator.pushReplacementNamed(context, '/');
            },
          ),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Stats Cards
                _buildStatsCards(),
                
                // Tab Bar
                TabBar(
                  onTap: (index) => setState(() => selectedTabIndex = index),
                  labelColor: Theme.of(context).primaryColor,
                  tabs: [
                    Tab(text: 'Books'),
                    Tab(text: 'Users'),
                    Tab(text: 'Rentals'),
                  ],
                ),
                
                // Tab Content
                Expanded(
                  child: IndexedStack(
                    index: selectedTabIndex,
                    children: [
                      _buildBooksTab(),
                      _buildUsersTab(),
                      _buildRentalsTab(),
                    ],
                  ),
                ),
              ],
            ),
      floatingActionButton: selectedTabIndex == 0
          ? FloatingActionButton(
              child: Icon(Icons.add),
              onPressed: () => _showAddBookDialog(context),
            )
          : null,
    );
  }

  Widget _buildStatsCards() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          _buildStatCard('Total Books', books.length.toString(), Icons.book),
          _buildStatCard('Available Books', availableBooks.toString(), Icons.library_books),
          _buildStatCard('Active Rentals', activeRentals.toString(), Icons.history),
          _buildStatCard('Overdue Rentals', overdueRentals.toString(), Icons.warning),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40, color: Colors.blue),
            SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 16)),
                Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBooksTab() {
    return ListView.builder(
      itemCount: books.length,
      itemBuilder: (context, index) {
        final book = books[index];
        return Card(
          margin: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
          child: ListTile(
            leading: Icon(Icons.book, size: 40),
            title: Text(book['title'] ?? 'No Title'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Author: ${book['author']}'),
                Text('ISBN: ${book['isbn'] ?? 'N/A'}'),
                Text('Copies: ${book['total_copies']}'),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(Icons.edit, color: Colors.blue),
                  onPressed: () => _showEditBookDialog(context, book),
                ),
                IconButton(
                  icon: Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _deleteBook(book['id']),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildUsersTab() {
    return ListView.builder(
      itemCount: users.length,
      itemBuilder: (context, index) {
        final user = users[index];
        final userRentals = rentals.where((rental) => rental['user_id'] == user['id']).toList();
        final activeRentals = userRentals.where((rental) => rental['returned_date'] == null).length;
        
        return Card(
          margin: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
          child: ListTile(
            leading: CircleAvatar(child: Text(user['full_name'][0])),
            title: Text(user['full_name']),
            subtitle: Text('Active Rentals: $activeRentals'),
            trailing: Icon(Icons.chevron_right),
          ),
        );
      },
    );
  }

  Widget _buildRentalsTab() {
    return ListView.builder(
      itemCount: rentals.length,
      itemBuilder: (context, index) {
        final rental = rentals[index];
        final book = books.firstWhere((b) => b['id'] == rental['book_id'], orElse: () => {});
        final user = users.firstWhere((u) => u['id'] == rental['user_id'], orElse: () => {});
        final dueDate = DateTime.parse(rental['due_date']);
        final isOverdue = dueDate.isBefore(DateTime.now()) && rental['returned_date'] == null;
        
        return Card(
          margin: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
          color: isOverdue ? Colors.red[50] : null,
          child: ListTile(
            leading: Icon(Icons.history, color: isOverdue ? Colors.red : Colors.grey),
            title: Text(book['title'] ?? 'Unknown Book'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('User: ${user['full_name'] ?? 'Unknown'}'),
                Text('Due: ${rental['due_date']}'),
                Text('Status: ${rental['returned_date'] == null ? 'Active' : 'Returned'}'),
                if (isOverdue) Text('OVERDUE!', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
              ],
            ),
            trailing: rental['returned_date'] == null
                ? ElevatedButton(
                    child: Text('Mark Returned'),
                    onPressed: () => _markReturned(rental['id']),
                  )
                : null,
          ),
        );
      },
    );
  }

  Future<void> _markReturned(int rentalId) async {
    try {
      await supabase
          .from('rentals')
          .update({'returned_date': DateTime.now().toIso8601String()})
          .eq('id', rentalId);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Book marked as returned')),
      );
      await _fetchData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  Future<void> _deleteBook(int bookId) async {
    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirm Delete'),
        content: Text('Are you sure you want to delete this book?'),
        actions: [
          TextButton(
            child: Text('Cancel'),
            onPressed: () => Navigator.pop(context, false),
          ),
          TextButton(
            child: Text('Delete', style: TextStyle(color: Colors.red)),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await supabase.from('books').delete().eq('id', bookId);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Book deleted successfully')),
        );
        await _fetchData();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  void _showAddBookDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    TextEditingController titleController = TextEditingController();
    TextEditingController authorController = TextEditingController();
    TextEditingController isbnController = TextEditingController();
    TextEditingController copiesController = TextEditingController(text: '1');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add New Book'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: titleController,
                  decoration: InputDecoration(labelText: 'Title*'),
                  validator: (value) => value!.isEmpty ? 'Required' : null,
                ),
                TextFormField(
                  controller: authorController,
                  decoration: InputDecoration(labelText: 'Author*'),
                  validator: (value) => value!.isEmpty ? 'Required' : null,
                ),
                TextFormField(
                  controller: isbnController,
                  decoration: InputDecoration(labelText: 'ISBN'),
                ),
                TextFormField(
                  controller: copiesController,
                  decoration: InputDecoration(labelText: 'Copies*'),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value!.isEmpty) return 'Required';
                    if (int.tryParse(value) == null) return 'Must be a number';
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            child: Text('Cancel'),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            child: Text('Add Book'),
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                try {
                  await supabase.from('books').insert({
                    'title': titleController.text,
                    'author': authorController.text,
                    'isbn': isbnController.text.isNotEmpty ? isbnController.text : null,
                    'total_copies': int.parse(copiesController.text),
                  });
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Book added successfully')),
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

  void _showEditBookDialog(BuildContext context, Map<String, dynamic> book) {
    final formKey = GlobalKey<FormState>();
    TextEditingController titleController = TextEditingController(text: book['title']);
    TextEditingController authorController = TextEditingController(text: book['author']);
    TextEditingController isbnController = TextEditingController(text: book['isbn'] ?? '');
    TextEditingController copiesController = TextEditingController(text: book['total_copies'].toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Book'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: titleController,
                  decoration: InputDecoration(labelText: 'Title*'),
                  validator: (value) => value!.isEmpty ? 'Required' : null,
                ),
                TextFormField(
                  controller: authorController,
                  decoration: InputDecoration(labelText: 'Author*'),
                  validator: (value) => value!.isEmpty ? 'Required' : null,
                ),
                TextFormField(
                  controller: isbnController,
                  decoration: InputDecoration(labelText: 'ISBN'),
                ),
                TextFormField(
                  controller: copiesController,
                  decoration: InputDecoration(labelText: 'Copies*'),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value!.isEmpty) return 'Required';
                    if (int.tryParse(value) == null) return 'Must be a number';
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            child: Text('Cancel'),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            child: Text('Update'),
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                try {
                  await supabase.from('books').update({
                    'title': titleController.text,
                    'author': authorController.text,
                    'isbn': isbnController.text.isNotEmpty ? isbnController.text : null,
                    'total_copies': int.parse(copiesController.text),
                  }).eq('id', book['id']);
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Book updated successfully')),
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
}
