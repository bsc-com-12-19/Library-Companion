// ignore_for_file: unused_field

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Define TNM green color
const Color tnmGreen = Color(0xFF00A859);

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({Key? key}) : super(key: key);

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  final SupabaseClient _supabase = Supabase.instance.client;
  late final User _user;

  @override
  void initState() {
    super.initState();
    _user = _supabase.auth.currentUser!;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Library Dashboard'),
        backgroundColor: tnmGreen,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: _handleLogout,
          ),
        ],
      ),
      body: _buildDashboardContent(),
    );
  }

  Widget _buildDashboardContent() {
    return Column(
      children: [
        const SizedBox(height: 16),
        _buildDashboardCard(
          icon: Icons.menu_book,
          title: 'Available Books',
          description: 'Browse and rent available books',
          onTap: () => Navigator.pushNamed(context, '/available-books'),
        ),
        _buildDashboardCard(
          icon: Icons.book_online,
          title: 'My Rentals',
          description: 'View your current and past rentals',
          onTap: () => Navigator.pushNamed(context, '/my-rentals'),
        ),
        _buildDashboardCard(
          icon: Icons.notifications,
          title: 'My Alerts',
          description: 'Manage your book availability alerts',
          onTap: () => Navigator.pushNamed(context, '/my-alerts'),
        ),
      ],
    );
  }

  Widget _buildDashboardCard({
    required IconData icon,
    required String title,
    required String description,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Icon(icon, size: 40, color: Theme.of(context).primaryColor),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleLogout() async {
    try {
      await _supabase.auth.signOut();
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Logout failed: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

// Available Books Screen
class AvailableBooksScreen extends StatefulWidget {
  const AvailableBooksScreen({Key? key}) : super(key: key);

  @override
  State<AvailableBooksScreen> createState() => _AvailableBooksScreenState();
}

class _AvailableBooksScreenState extends State<AvailableBooksScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _availableBooks = [];
  bool _isLoading = true;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchAvailableBooks();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchAvailableBooks() async {
    setState(() => _isLoading = true);
    try {
      final response = await _supabase
          .from('book_availability')
          .select()
          .gt('available_copies', 0);
      setState(() {
        _availableBooks = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Failed to load available books');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Available Books'),
        backgroundColor: tnmGreen,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildBookList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _fetchAvailableBooks,
        tooltip: 'Refresh',
        child: const Icon(Icons.refresh),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search by title, author, or ISBN...',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: _clearSearch,
                )
              : null,
        ),
        onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
      ),
    );
  }

  Widget _buildBookList() {
    final filteredBooks = _availableBooks.where((book) {
      if (_searchQuery.isEmpty) return true;
      return book['title'].toString().toLowerCase().contains(_searchQuery) ||
          book['author'].toString().toLowerCase().contains(_searchQuery) ||
          book['isbn']?.toString().toLowerCase().contains(_searchQuery) == true;
    }).toList();

    if (filteredBooks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.book, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isEmpty
                  ? 'No books currently available'
                  : 'No books match your search',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(12.0),
      itemCount: filteredBooks.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final book = filteredBooks[index];
        return Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                const Icon(Icons.book, size: 40),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        book['title'] ?? 'Untitled',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Author: ${book['author'] ?? 'Unknown'}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'ISBN: ${book['isbn'] ?? 'N/A'}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Available: ${book['available_copies']} of ${book['total_copies']}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: () => _rentBook(book['book_id']),
                  child: const Text('Rent'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _rentBook(int bookId) async {
    try {
      final dueDate = DateTime.now()
          .add(const Duration(days: 14))
          .toIso8601String()
          .split('T')
          .first;

      await _supabase.from('rentals').insert({
        'user_id': _supabase.auth.currentUser!.id,
        'book_id': bookId,
        'due_date': dueDate,
      });

      _showSuccessSnackBar('Book rented successfully!');
      await _fetchAvailableBooks();
    } catch (e) {
      _showErrorSnackBar('Failed to rent book: ${e.toString()}');
    }
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() => _searchQuery = '');
    FocusScope.of(context).unfocus();
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
}

// My Rentals Screen
class MyRentalsScreen extends StatefulWidget {
  const MyRentalsScreen({Key? key}) : super(key: key);

  @override
  State<MyRentalsScreen> createState() => _MyRentalsScreenState();
}

class _MyRentalsScreenState extends State<MyRentalsScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _myRentals = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchCurrentRentals();
  }

  Future<void> _fetchCurrentRentals() async {
    setState(() => _isLoading = true);
    try {
      final response = await _supabase
          .from('rentals')
          .select('*, books(*)')
          .eq('user_id', _supabase.auth.currentUser!.id)
          .order('due_date', ascending: true);
      setState(() {
        _myRentals = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Failed to load rentals');
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('My Rentals'),
          backgroundColor: tnmGreen,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
          bottom: TabBar(
            tabs: [
              Tab(text: 'Current (${_currentRentals.length})'),
              Tab(text: 'History (${_pastRentals.length})'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildRentalList(_currentRentals, isCurrent: true),
            _buildRentalList(_pastRentals, isCurrent: false),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _fetchCurrentRentals,
          tooltip: 'Refresh',
          child: const Icon(Icons.refresh),
        ),
      ),
    );
  }

  List<Map<String, dynamic>> get _currentRentals =>
      _myRentals.where((r) => r['returned_date'] == null).toList();

  List<Map<String, dynamic>> get _pastRentals =>
      _myRentals.where((r) => r['returned_date'] != null).toList();

  Widget _buildRentalList(List<Map<String, dynamic>> rentals,
      {required bool isCurrent}) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (rentals.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isCurrent ? Icons.history_toggle_off : Icons.history,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              isCurrent ? 'No current rentals' : 'No rental history',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(12.0),
      itemCount: rentals.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final rental = rentals[index];
        final book = rental['books'] as Map<String, dynamic>? ?? {};
        final dueDate = DateTime.parse(rental['due_date']);
        final isOverdue = isCurrent && dueDate.isBefore(DateTime.now());

        return Card(
          elevation: 2,
          color: isOverdue ? Colors.red[50] : null,
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      isCurrent ? Icons.history : Icons.check_circle,
                      color: isOverdue ? Colors.red : Colors.green,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        book['title'] ?? 'Unknown Book',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    if (isCurrent)
                      ElevatedButton(
                        onPressed: () => _returnBook(rental['id']),
                        child: const Text('Return'),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Due: ${rental['due_date']}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                if (isOverdue) ...[
                  const SizedBox(height: 4),
                  Text(
                    'OVERDUE!',
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(
                            color: Colors.red, fontWeight: FontWeight.bold),
                  ),
                ],
                if (rental['returned_date'] != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Returned: ${rental['returned_date']}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _returnBook(int rentalId) async {
    try {
      await _supabase
          .from('rentals')
          .update({
            'returned_date':
                DateTime.now().toIso8601String().split('T').first
          })
          .eq('id', rentalId);

      _showSuccessSnackBar('Book returned successfully');
      await _fetchCurrentRentals();
    } catch (e) {
      _showErrorSnackBar('Failed to return book: ${e.toString()}');
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
}

// My Alerts Screen
class MyAlertsScreen extends StatefulWidget {
  const MyAlertsScreen({Key? key}) : super(key: key);

  @override
  State<MyAlertsScreen> createState() => _MyAlertsScreenState();
}

class _MyAlertsScreenState extends State<MyAlertsScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _myAlerts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchActiveAlerts();
  }

  Future<void> _fetchActiveAlerts() async {
    setState(() => _isLoading = true);
    try {
      final response = await _supabase
          .from('alerts')
          .select('*, books(*)')
          .eq('user_id', _supabase.auth.currentUser!.id)
          .eq('active', true);
      setState(() {
        _myAlerts = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Failed to load alerts');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Alerts'),
        backgroundColor: tnmGreen,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showSetAlertDialog,
            tooltip: 'Add new alert',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildAlertsList(),
      floatingActionButton: FloatingActionButton(
        onPressed: _fetchActiveAlerts,
        tooltip: 'Refresh',
        child: const Icon(Icons.refresh),
      ),
    );
  }

  Widget _buildAlertsList() {
    if (_myAlerts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.notifications_off, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'No active alerts',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _showSetAlertDialog,
              child: const Text('Set New Alert'),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(12.0),
      itemCount: _myAlerts.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final alert = _myAlerts[index];
        final book = alert['books'] as Map<String, dynamic>? ?? {};

        return Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                const Icon(Icons.notifications_active, color: Colors.orange),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        book['title'] ?? 'Unknown Book',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Set on: ${alert['alert_set_date']}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _removeAlert(alert['id']),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _removeAlert(int alertId) async {
    try {
      await _supabase.from('alerts').delete().eq('id', alertId);

      _showSuccessSnackBar('Alert removed');
      await _fetchActiveAlerts();
    } catch (e) {
      _showErrorSnackBar('Failed to remove alert: ${e.toString()}');
    }
  }

  Future<void> _showSetAlertDialog() async {
    try {
      final booksResponse = await _supabase.from('books').select();
      final allBooks = List<Map<String, dynamic>>.from(booksResponse);

      final bookIdsWithAlerts = _myAlerts.map((a) => a['book_id']).toList();
      final availableForAlerts =
          allBooks.where((b) => !bookIdsWithAlerts.contains(b['id'])).toList();

      if (availableForAlerts.isEmpty) {
        _showInfoSnackBar('All books already have alerts');
        return;
      }

      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Set Book Alert'),
          content: SizedBox(
            width: double.maxFinite,
            height: 300,
            child: availableForAlerts.isEmpty
                ? const Center(child: Text('No books available for alerts'))
                : ListView.builder(
                    itemCount: availableForAlerts.length,
                    itemBuilder: (context, index) {
                      final book = availableForAlerts[index];
                      return ListTile(
                        title: Text(book['title']),
                        subtitle: Text('Author: ${book['author']}'),
                        trailing: IconButton(
                          icon: const Icon(Icons.add_alert),
                          onPressed: () => _addAlert(book['id']),
                        ),
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        ),
      );
    } catch (e) {
      _showErrorSnackBar('Failed to load books: ${e.toString()}');
    }
  }

  Future<void> _addAlert(int bookId) async {
    try {
      await _supabase.from('alerts').insert({
        'user_id': _supabase.auth.currentUser!.id,
        'book_id': bookId,
      });

      if (!mounted) return;
      Navigator.pop(context);
      _showSuccessSnackBar('Alert set successfully');
      await _fetchActiveAlerts();
    } catch (e) {
      _showErrorSnackBar('Failed to set alert: ${e.toString()}');
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showInfoSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}