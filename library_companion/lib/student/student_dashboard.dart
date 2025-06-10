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
    
    try {
      // Fetch available books
      final booksResponse = await supabase
          .from('book_availability')
          .select()
          .gt('available_copies', 0);
      
      // Fetch current rentals
      final rentalsResponse = await supabase
          .from('rentals')
          .select('*, books(*)')
          .eq('user_id', user.id)
          .order('due_date', ascending: true);
      
      // Fetch alerts
      final alertsResponse = await supabase
          .from('alerts')
          .select('*, books(*)')
          .eq('user_id', user.id)
          .eq('active', true);
      
      setState(() {
        availableBooks = List<Map<String, dynamic>>.from(booksResponse);
        myRentals = List<Map<String, dynamic>>.from(rentalsResponse);
        myAlerts = List<Map<String, dynamic>>.from(alertsResponse);
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching data: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Library Dashboard', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 2,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _fetchData,
          ),
        ],
      ),
      drawer: _buildDrawer(),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Welcome message and search bar
                  _buildHeader(),
                  SizedBox(height: 16),
                  
                  // Tab Bar
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: TabBar(
                      onTap: (index) => setState(() => selectedTabIndex = index),
                      indicator: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: Theme.of(context).primaryColor,
                      ),
                      labelColor: Colors.white,
                      unselectedLabelColor: Colors.black54,
                      tabs: [
                        Tab(icon: Icon(Icons.book), text: 'Available Books'),
                        Tab(icon: Icon(Icons.history), text: 'My Rentals'),
                        Tab(icon: Icon(Icons.notifications), text: 'My Alerts'),
                      ],
                    ),
                  ),
                  SizedBox(height: 16),
                  
                  // Tab Content
                  Expanded(
                    child: Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: IndexedStack(
                          index: selectedTabIndex,
                          children: [
                            _buildAvailableBooksTab(),
                            _buildMyRentalsTab(),
                            _buildMyAlertsTab(),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                CircleAvatar(
                  radius: 30,
                  child: Icon(Icons.person, size: 30),
                ),
                SizedBox(height: 10),
                Text(
                  user.email ?? 'Student',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: Icon(Icons.book),
            title: Text('Available Books'),
            onTap: () {
              setState(() => selectedTabIndex = 0);
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: Icon(Icons.history),
            title: Text('My Rentals'),
            onTap: () {
              setState(() => selectedTabIndex = 1);
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: Icon(Icons.notifications),
            title: Text('My Alerts'),
            onTap: () {
              setState(() => selectedTabIndex = 2);
              Navigator.pop(context);
            },
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.logout),
            title: Text('Logout'),
            onTap: () async {
              await supabase.auth.signOut();
              Navigator.pushReplacementNamed(context, '/');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Welcome back,',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[600],
          ),
        ),
        Text(
          user.email ?? 'Student',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (selectedTabIndex == 0) SizedBox(height: 16),
        if (selectedTabIndex == 0) _buildSearchBar(),
      ],
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      decoration: InputDecoration(
        hintText: 'Search books by title, author or ISBN...',
        prefixIcon: Icon(Icons.search),
        filled: true,
        fillColor: Colors.grey[100],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
        contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 20),
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
    );
  }

  Widget _buildAvailableBooksTab() {
    final filteredBooks = availableBooks.where((book) {
      if (searchQuery.isEmpty) return true;
      return book['title'].toString().toLowerCase().contains(searchQuery) ||
             book['author'].toString().toLowerCase().contains(searchQuery) ||
             book['isbn']?.toString().toLowerCase().contains(searchQuery) == true;
    }).toList();

    if (filteredBooks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              searchQuery.isEmpty 
                ? 'No books available'
                : 'No books matching "$searchQuery"',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: MediaQuery.of(context).size.width > 600 ? 2 : 1,
        childAspectRatio: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: filteredBooks.length,
      itemBuilder: (context, index) {
        final book = filteredBooks[index];
        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () => _showBookDetails(book),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 70,
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Icon(Icons.book, size: 30, color: Theme.of(context).primaryColor),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          book['title'],
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 4),
                        Text(
                          'by ${book['author']}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.library_books, size: 14, color: Colors.grey),
                            SizedBox(width: 4),
                            Text(
                              '${book['available_copies']}/${book['total_copies']} available',
                              style: TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 12),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: Text('Rent'),
                    onPressed: () => _rentBook(book['book_id']),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMyRentalsTab() {
    final currentRentals = myRentals.where((r) => r['returned_date'] == null).toList();
    final pastRentals = myRentals.where((r) => r['returned_date'] != null).toList();

    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: TabBar(
            labelColor: Theme.of(context).primaryColor,
            unselectedLabelColor: Colors.black54,
            indicator: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: Colors.white,
            ),
            tabs: [
              Tab(
                icon: Icon(Icons.timer),
                text: 'Current (${currentRentals.length})',
              ),
              Tab(
                icon: Icon(Icons.history),
                text: 'History (${pastRentals.length})',
              ),
            ],
          ),
        ),
        SizedBox(height: 12),
        Expanded(
          child: TabBarView(
            children: [
              _buildRentalList(currentRentals, true),
              _buildRentalList(pastRentals, false),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRentalList(List<Map<String, dynamic>> rentals, bool isCurrent) {
    if (rentals.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isCurrent ? Icons.history_edu : Icons.history,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              isCurrent ? 'No current rentals' : 'No rental history',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
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
          elevation: 2,
          margin: EdgeInsets.only(bottom: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          color: isOverdue ? Colors.red[50] : null,
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 70,
                  decoration: BoxDecoration(
                    color: isOverdue 
                      ? Colors.red[100]
                      : isCurrent 
                        ? Colors.blue[50]
                        : Colors.green[50],
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Icon(
                    isCurrent 
                      ? isOverdue 
                        ? Icons.warning 
                        : Icons.timer
                      : Icons.check_circle,
                    color: isOverdue 
                      ? Colors.red 
                      : isCurrent 
                        ? Colors.blue 
                        : Colors.green,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        book['title'] ?? 'Unknown Book',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Due: ${rental['due_date']}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                      if (isOverdue) 
                        Text(
                          'OVERDUE - PLEASE RETURN',
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      if (rental['returned_date'] != null)
                        Text(
                          'Returned: ${rental['returned_date']}',
                          style: TextStyle(
                            color: Colors.green[800],
                            fontSize: 14,
                          ),
                        ),
                    ],
                  ),
                ),
                if (isCurrent)
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      primary: isOverdue ? Colors.red : null,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: Text('Return'),
                    onPressed: () => _returnBook(rental['id']),
                  ),
              ],
            ),
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
            Text(
              'No active alerts',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            SizedBox(height: 24),
            ElevatedButton.icon(
              icon: Icon(Icons.add_alert),
              label: Text('Set New Alert'),
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              onPressed: _showSetAlertDialog,
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: ElevatedButton.icon(
            icon: Icon(Icons.add, size: 18),
            label: Text('New Alert'),
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            onPressed: _showSetAlertDialog,
          ),
        ),
        SizedBox(height: 12),
        Expanded(
          child: ListView.builder(
            itemCount: myAlerts.length,
            itemBuilder: (context, index) {
              final alert = myAlerts[index];
              final book = alert['books'] as Map<String, dynamic>? ?? {};

              return Card(
                elevation: 2,
                margin: EdgeInsets.only(bottom: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: ListTile(
                  leading: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.orange[50],
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Icon(Icons.notifications_active, color: Colors.orange),
                  ),
                  title: Text(
                    book['title'] ?? 'Unknown Book',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    'Alert set on: ${alert['alert_set_date']}',
                    style: TextStyle(fontSize: 12),
                  ),
                  trailing: IconButton(
                    icon: Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _removeAlert(alert['id']),
                  ),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showBookDetails(Map<String, dynamic> book) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(book['title']),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'by ${book['author']}',
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  Icon(Icons.confirmation_number, size: 16, color: Colors.grey),
                  SizedBox(width: 8),
                  Text('ISBN: ${book['isbn'] ?? 'N/A'}'),
                ],
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.library_books, size: 16, color: Colors.grey),
                  SizedBox(width: 8),
                  Text('Available: ${book['available_copies']}/${book['total_copies']}'),
                ],
              ),
              SizedBox(height: 16),
              if (book['description'] != null)
                Text(book['description']),
            ],
          ),
        ),
        actions: [
          TextButton(
            child: Text('Close'),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            child: Text('Rent Book'),
            onPressed: () {
              Navigator.pop(context);
              _rentBook(book['book_id']);
            },
          ),
        ],
      ),
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
        SnackBar(
          content: Text('Book rented successfully!'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      await _fetchData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
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
        SnackBar(
          content: Text('Book returned successfully'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      await _fetchData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
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
        SnackBar(
          content: Text('Alert removed'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      await _fetchData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
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
        SnackBar(
          content: Text('No books available for alerts'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
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
          child: availableForAlerts.isEmpty
              ? Center(child: Text('No books available for alerts'))
              : ListView.builder(
                  itemCount: availableForAlerts.length,
                  itemBuilder: (context, index) {
                    final book = availableForAlerts[index];
                    return Card(
                      elevation: 1,
                      margin: EdgeInsets.symmetric(vertical: 4),
                      child: ListTile(
                        leading: Icon(Icons.book, color: Theme.of(context).primaryColor),
                        title: Text(book['title']),
                        subtitle: Text('Author: ${book['author']}'),
                        trailing: IconButton(
                          icon: Icon(Icons.add_alert, color: Colors.orange),
                          onPressed: () => _addAlert(book['id']),
                        ),
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
        SnackBar(
          content: Text('Alert set for this book'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      Navigator.pop(context); // Close the dialog
      await _fetchData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }
}