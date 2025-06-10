import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class StudentDashboard extends StatefulWidget {
  @override
  _StudentDashboardState createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> with SingleTickerProviderStateMixin {
  final supabase = Supabase.instance.client;
  final user = Supabase.instance.client.auth.currentUser!;
  
  List<Map<String, dynamic>> availableBooks = [];
  List<Map<String, dynamic>> myRentals = [];
  List<Map<String, dynamic>> myAlerts = [];
  bool isLoading = true;
  int selectedTabIndex = 0;
  int _currentRentalsTabIndex = 0;
  String searchQuery = '';
  late TabController _tabController;

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
        _fetchAvailableBooks(),
        _fetchMyRentals(),
        _fetchMyAlerts(),
      ]);

      setState(() {
        availableBooks = results[0];
        myRentals = results[1];
        myAlerts = results[2];
        isLoading = false;
      });
    } catch (e, stackTrace) {
      setState(() => isLoading = false);
      _showErrorSnackBar('Failed to load data. Please try again.');
      debugPrint('Error fetching data: $e\n$stackTrace');
    }
  }

  Future<List<Map<String, dynamic>>> _fetchAvailableBooks() async {
    final response = await supabase
        .from('book_availability')
        .select('book_id, title, author, isbn, available_copies, total_copies, description')
        .gt('available_copies', 0)
        .order('title');
    return List<Map<String, dynamic>>.from(response);
  }

  Future<List<Map<String, dynamic>>> _fetchMyRentals() async {
    final response = await supabase
        .from('rentals')
        .select('*, books(title, author)')
        .eq('user_id', user.id)
        .order('due_date', ascending: true);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<List<Map<String, dynamic>>> _fetchMyAlerts() async {
    final response = await supabase
        .from('alerts')
        .select('*, books(title)')
        .eq('user_id', user.id)
        .eq('active', true)
        .order('alert_set_date', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
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
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(),
          SizedBox(height: 16),
          _buildTabBar(),
          SizedBox(height: 16),
          Expanded(child: _buildTabContent()),
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

  Widget _buildTabBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: TabBar(
        controller: _tabController,
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
    );
  }

  Widget _buildTabContent() {
    return Card(
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
      return _buildEmptyState(
        icon: Icons.search_off,
        message: searchQuery.isEmpty 
          ? 'No books available' 
          : 'No books matching "$searchQuery"',
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
      itemBuilder: (context, index) => BookCard(
        book: filteredBooks[index],
        onTap: () => _showBookDetails(filteredBooks[index]),
        onRent: () => _rentBook(filteredBooks[index]['book_id']),
      ),
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
            onTap: (index) {
              setState(() {
                _currentRentalsTabIndex = index;
              });
            },
            labelColor: Theme.of(context).primaryColor,
            unselectedLabelColor: Colors.black54,
            indicator: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: Colors.white,
            ),
            tabs: [
              Tab(text: 'Current (${currentRentals.length})'),
              Tab(text: 'History (${pastRentals.length})'),
            ],
          ),
        ),
        SizedBox(height: 12),
        Expanded(
          child: IndexedStack(
            index: _currentRentalsTabIndex,
            children: [
              _buildRentalList(currentRentals, isCurrent: true),
              _buildRentalList(pastRentals, isCurrent: false),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRentalList(List<Map<String, dynamic>> rentals, {required bool isCurrent}) {
    if (rentals.isEmpty) {
      return _buildEmptyState(
        icon: isCurrent ? Icons.history_edu : Icons.history,
        message: isCurrent ? 'No current rentals' : 'No rental history',
      );
    }

    return ListView.builder(
      itemCount: rentals.length,
      itemBuilder: (context, index) => RentalListItem(
        rental: rentals[index],
        isCurrent: isCurrent,
        onReturn: isCurrent ? () => _returnBook(rentals[index]['id']) : null,
      ),
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
            itemBuilder: (context, index) => AlertListItem(
              alert: myAlerts[index],
              onRemove: () => _removeAlert(myAlerts[index]['id']),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState({required IconData icon, required String message}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
        ],
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
              try {
                await supabase.auth.signOut();
                Navigator.pushReplacementNamed(context, '/');
              } catch (e) {
                _showErrorSnackBar('Failed to logout. Please try again.');
              }
            },
          ),
        ],
      ),
    );
  }

  Future<void> _rentBook(int bookId) async {
    try {
      final dueDate = DateTime.now().add(Duration(days: 14)).toIso8601String().split('T').first;
      
      await supabase.from('rentals').insert({
        'user_id': user.id,
        'book_id': bookId,
        'due_date': dueDate,
      });
      
      _showSuccessSnackBar('Book rented successfully!');
      await _fetchData();
    } catch (e) {
      _showErrorSnackBar('Failed to rent book. Please try again.');
    }
  }

  Future<void> _returnBook(int rentalId) async {
    try {
      await supabase
          .from('rentals')
          .update({'returned_date': DateTime.now().toIso8601String().split('T').first})
          .eq('id', rentalId);
      
      _showSuccessSnackBar('Book returned successfully');
      await _fetchData();
    } catch (e) {
      _showErrorSnackBar('Failed to return book. Please try again.');
    }
  }

  Future<void> _removeAlert(int alertId) async {
    try {
      await supabase
          .from('alerts')
          .delete()
          .eq('id', alertId);
      
      _showSuccessSnackBar('Alert removed');
      await _fetchData();
    } catch (e) {
      _showErrorSnackBar('Failed to remove alert. Please try again.');
    }
  }

  void _showBookDetails(Map<String, dynamic> book) {
    showDialog(
      context: context,
      builder: (context) => BookDetailsDialog(
        book: book,
        onRent: () {
          Navigator.pop(context);
          _rentBook(book['book_id']);
        },
      ),
    );
  }

  void _showSetAlertDialog() async {
    try {
      final booksResponse = await supabase.from('books').select('id, title, author');
      final allBooks = List<Map<String, dynamic>>.from(booksResponse);
      
      final bookIdsWithAlerts = myAlerts.map((a) => a['book_id']).toList();
      final availableForAlerts = allBooks.where((b) => !bookIdsWithAlerts.contains(b['id'])).toList();
      
      if (availableForAlerts.isEmpty) {
        _showErrorSnackBar('No books available for alerts');
        return;
      }
      
      showDialog(
        context: context,
        builder: (context) => SetAlertDialog(
          books: availableForAlerts,
          onAddAlert: (bookId) {
            Navigator.pop(context);
            _addAlert(bookId);
          },
        ),
      );
    } catch (e) {
      _showErrorSnackBar('Failed to load books for alerts');
    }
  }

  Future<void> _addAlert(int bookId) async {
    try {
      await supabase.from('alerts').insert({
        'user_id': user.id,
        'book_id': bookId,
        'alert_set_date': DateTime.now().toIso8601String(),
      });
      
      _showSuccessSnackBar('Alert set for this book');
      await _fetchData();
    } catch (e) {
      _showErrorSnackBar('Failed to set alert');
    }
  }
}

// Widget classes
class BookCard extends StatelessWidget {
  final Map<String, dynamic> book;
  final VoidCallback onTap;
  final VoidCallback onRent;

  const BookCard({
    required this.book,
    required this.onTap,
    required this.onRent,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
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
                onPressed: onRent,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class RentalListItem extends StatelessWidget {
  final Map<String, dynamic> rental;
  final bool isCurrent;
  final VoidCallback? onReturn;

  const RentalListItem({
    required this.rental,
    required this.isCurrent,
    this.onReturn,
  });

  @override
  Widget build(BuildContext context) {
    final book = rental['books'] as Map<String, dynamic>? ?? {};
    final dueDate = DateTime.parse(rental['due_date']);
    final isOverdue = isCurrent && dueDate.isBefore(DateTime.now());

    return Card(
      elevation: 2,
      margin: EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
            if (isCurrent && onReturn != null)
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isOverdue ? Colors.red : null,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: Text('Return'),
                onPressed: onReturn,
              ),
          ],
        ),
      ),
    );
  }
}

class AlertListItem extends StatelessWidget {
  final Map<String, dynamic> alert;
  final VoidCallback onRemove;

  const AlertListItem({
    required this.alert,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final book = alert['books'] as Map<String, dynamic>? ?? {};

    return Card(
      elevation: 2,
      margin: EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
          onPressed: onRemove,
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 12),
      ),
    );
  }
}

class BookDetailsDialog extends StatelessWidget {
  final Map<String, dynamic> book;
  final VoidCallback onRent;

  const BookDetailsDialog({
    required this.book,
    required this.onRent,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
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
          onPressed: onRent,
        ),
      ],
    );
  }
}

class SetAlertDialog extends StatelessWidget {
  final List<Map<String, dynamic>> books;
  final Function(int) onAddAlert;

  const SetAlertDialog({
    required this.books,
    required this.onAddAlert,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Set Book Alert'),
      content: Container(
        width: double.maxFinite,
        height: 300,
        child: ListView.builder(
          itemCount: books.length,
          itemBuilder: (context, index) {
            final book = books[index];
            return Card(
              elevation: 1,
              margin: EdgeInsets.symmetric(vertical: 4),
              child: ListTile(
                leading: Icon(Icons.book, color: Theme.of(context).primaryColor),
                title: Text(book['title']),
                subtitle: Text('Author: ${book['author']}'),
                trailing: IconButton(
                  icon: Icon(Icons.add_alert, color: Colors.orange),
                  onPressed: () => onAddAlert(book['id']),
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
    );
  }
}