import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class StudentDashboard extends StatefulWidget {
  @override
  _StudentDashboardState createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  final supabase = Supabase.instance.client;
  final user = Supabase.instance.client.auth.currentUser!;
  
  List<Map<String, dynamic>> availableBooks = [];
  List<Map<String, dynamic>> myRentals = [];
  List<Map<String, dynamic>> myAlerts = [];
  bool isLoading = true;
  int selectedTabIndex = 0;
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => isLoading = true);
    
    // Fetch available books
    final booksResponse = await supabase
        .from('book_availability')
        .select()
        .gt('available_copies', 0);
    setState(() => availableBooks = List<Map<String, dynamic>>.from(booksResponse));
    
    // Fetch current rentals
    final rentalsResponse = await supabase
        .from('rentals')
        .select('*, books(*)')
        .eq('user_id', user.id)
        .order('due_date', ascending: true);
    setState(() => myRentals = List<Map<String, dynamic>>.from(rentalsResponse));
    
    // Fetch alerts
    final alertsResponse = await supabase
        .from('alerts')
        .select('*, books(*)')
        .eq('user_id', user.id)
        .eq('active', true);
    setState(() => myAlerts = List<Map<String, dynamic>>.from(alertsResponse));
    
    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Student Dashboard'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _fetchData,
          ),
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
                // Search bar for books
                if (selectedTabIndex == 0) _buildSearchBar(),
                
                // Tab Bar
                TabBar(
                  onTap: (index) => setState(() => selectedTabIndex = index),
                  labelColor: Theme.of(context).primaryColor,
                  tabs: [
                    Tab(text: 'Available Books'),
                    Tab(text: 'My Rentals'),
                    Tab(text: 'My Alerts'),
                  ],
                ),
                
                // Tab Content
                Expanded(
                  child: IndexedStack(
                    index: selectedTabIndex,
                    children: [
                      _buildAvailableBooksTab(),
                      _buildMyRentalsTab(),
                      _buildMyAlertsTab(),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Search books...',
          prefixIcon: Icon(Icons.search),
          border: OutlineInputBorder(),
          suffixIcon: searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear),
                  onPressed: () {
                    setState(() => searchQuery = '');
                    FocusScope.of(context).unfocus();
                  },
                )
              : null,
        ),
        onChanged: (value) => setState(() => searchQuery = value.toLowerCase()),
      ),
    );
  }

  Widget _buildAvailableBooksTab() {
    final filteredBooks = availableBooks.where((book) {
      if (searchQuery.isEmpty) return true;
      return book['title'].toString().toLowerCase().contains(searchQuery) ||
             book['author'].toString().toLowerCase().contains(searchQuery) ||
             book['isbn']?.toString().toLowerCase().contains(searchQuery) == true;
    }).toList();

    return ListView.builder(
      itemCount: filteredBooks.length,
      itemBuilder: (context, index) {
        final book = filteredBooks[index];
        return Card(
          margin: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
          child: ListTile(
            leading: Icon(Icons.book, size: 40),
            title: Text(book['title']),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Author: ${book['author']}'),
                Text('ISBN: ${book['isbn'] ?? 'N/A'}'),
                Text('Available: ${book['available_copies']} of ${book['total_copies']}'),
              ],
            ),
            trailing: ElevatedButton(
              child: Text('Rent'),
              onPressed: () => _rentBook(book['book_id']),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMyRentalsTab() {
    final currentRentals = myRentals.where((r) => r['returned_date'] == null).toList();
    final pastRentals = myRentals.where((r) => r['returned_date'] != null).toList();

    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          TabBar(
            labelColor: Theme.of(context).primaryColor,
            tabs: [
              Tab(text: 'Current (${currentRentals.length})'),
              Tab(text: 'History (${pastRentals.length})'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildRentalList(currentRentals, true),
                _buildRentalList(pastRentals, false),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRentalList(List<Map<String, dynamic>> rentals, bool isCurrent) {
    if (rentals.isEmpty) {
      return Center(
        child: Text('No ${isCurrent ? 'current' : 'past'} rentals'),
      );
    }

    return ListView.builder(
      itemCount: rentals.length,
      itemBuilder: (context, index) {
        final rental = rentals[index];
        final book = rental['books'] as Map<String, dynamic>? ?? {};
        final dueDate = DateTime.parse(rental['due_date']);
        final isOverdue = isCurrent && dueDate.isBefore(DateTime.now());

        return Card(
          margin: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
          color: isOverdue ? Colors.red[50] : null,
          child: ListTile(
            leading: Icon(
              isCurrent ? Icons.history : Icons.check_circle,
              color: isOverdue ? Colors.red : Colors.green,
            ),
            title: Text(book['title'] ?? 'Unknown Book'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Due: ${rental['due_date']}'),
                if (isOverdue) 
                  Text('OVERDUE!', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                if (rental['returned_date'] != null)
                  Text('Returned: ${rental['returned_date']}'),
              ],
            ),
            trailing: isCurrent
                ? ElevatedButton(
                    child: Text('Return'),
                    onPressed: () => _returnBook(rental['id']),
                  )
                : null,
          ),
        );
      },
    );
  }

  Widget _buildMyAlertsTab() {
    if (myAlerts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_off, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No active alerts'),
            SizedBox(height: 16),
            ElevatedButton(
              child: Text('Set New Alert'),
              onPressed: _showSetAlertDialog,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: myAlerts.length,
      itemBuilder: (context, index) {
        final alert = myAlerts[index];
        final book = alert['books'] as Map<String, dynamic>? ?? {};

        return Card(
          margin: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
          child: ListTile(
            leading: Icon(Icons.notifications_active, color: Colors.orange),
            title: Text(book['title'] ?? 'Unknown Book'),
            subtitle: Text('Set on: ${alert['alert_set_date']}'),
            trailing: IconButton(
              icon: Icon(Icons.delete, color: Colors.red),
              onPressed: () => _removeAlert(alert['id']),
            ),
          ),
        );
      },
    );
  }

  Future<void> _rentBook(int bookId) async {
    try {
      // Calculate due date (2 weeks from now)
      final dueDate = DateTime.now().add(Duration(days: 14)).toIso8601String().split('T').first;
      
      await supabase.from('rentals').insert({
        'user_id': user.id,
        'book_id': bookId,
        'due_date': dueDate,
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Book rented successfully!')),
      );
      await _fetchData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  Future<void> _returnBook(int rentalId) async {
    try {
      await supabase
          .from('rentals')
          .update({'returned_date': DateTime.now().toIso8601String().split('T').first})
          .eq('id', rentalId);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Book returned successfully')),
      );
      await _fetchData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  Future<void> _removeAlert(int alertId) async {
    try {
      await supabase
          .from('alerts')
          .delete()
          .eq('id', alertId);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Alert removed')),
      );
      await _fetchData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  void _showSetAlertDialog() async {
    // Fetch all books (including unavailable ones)
    final booksResponse = await supabase.from('books').select();
    final allBooks = List<Map<String, dynamic>>.from(booksResponse);
    
    // Filter out books that are already in alerts
    final bookIdsWithAlerts = myAlerts.map((a) => a['book_id']).toList();
    final availableForAlerts = allBooks.where((b) => !bookIdsWithAlerts.contains(b['id'])).toList();
    
    if (availableForAlerts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No books available for alerts')),
      );
      return;
    }
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Set Book Alert'),
        content: Container(
          width: double.maxFinite,
          height: 300,
          child: ListView.builder(
            itemCount: availableForAlerts.length,
            itemBuilder: (context, index) {
              final book = availableForAlerts[index];
              return ListTile(
                title: Text(book['title']),
                subtitle: Text('Author: ${book['author']}'),
                trailing: IconButton(
                  icon: Icon(Icons.add_alert),
                  onPressed: () => _addAlert(book['id']),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            child: Text('Cancel'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Future<void> _addAlert(int bookId) async {
    try {
      await supabase.from('alerts').insert({
        'user_id': user.id,
        'book_id': bookId,
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Alert set for this book')),
      );
      Navigator.pop(context); // Close the dialog
      await _fetchData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }
}
