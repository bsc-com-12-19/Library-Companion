import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({Key? key}) : super(key: key);

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  final SupabaseClient _supabase = Supabase.instance.client;
  final User _user = Supabase.instance.client.auth.currentUser!;
  
  List<Map<String, dynamic>> _availableBooks = [];
  List<Map<String, dynamic>> _myRentals = [];
  List<Map<String, dynamic>> _myAlerts = [];
  bool _isLoading = true;
  int _selectedTabIndex = 0;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchDashboardData() async {
    if (!mounted) return;
    
    setState(() => _isLoading = true);
    
    try {
      final responses = await Future.wait([
        _fetchAvailableBooks(),
        _fetchCurrentRentals(),
        _fetchActiveAlerts(),
      ]);

      setState(() {
        _availableBooks = responses[0];
        _myRentals = responses[1];
        _myAlerts = responses[2];
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      _showErrorSnackBar('Failed to load dashboard data');
      setState(() => _isLoading = false);
    }
  }

  Future<List<Map<String, dynamic>>> _fetchAvailableBooks() async {
    final response = await _supabase
        .from('book_availability')
        .select()
        .gt('available_copies', 0);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<List<Map<String, dynamic>>> _fetchCurrentRentals() async {
    final response = await _supabase
        .from('rentals')
        .select('*, books(*)')
        .eq('user_id', _user.id)
        .order('due_date', ascending: true);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<List<Map<String, dynamic>>> _fetchActiveAlerts() async {
    final response = await _supabase
        .from('alerts')
        .select('*, books(*)')
        .eq('user_id', _user.id)
        .eq('active', true);
    return List<Map<String, dynamic>>.from(response);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                if (_selectedTabIndex == 0) _buildSearchBar(),
                _buildTabBar(),
                Expanded(child: _buildTabContent()),
              ],
            ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text('Library Dashboard'),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          tooltip: 'Refresh data',
          onPressed: _fetchDashboardData,
        ),
        IconButton(
          icon: const Icon(Icons.logout),
          tooltip: 'Logout',
          onPressed: _handleLogout,
        ),
      ],
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

  Widget _buildTabBar() {
    return TabBar(
      onTap: (index) => setState(() => _selectedTabIndex = index),
      labelColor: Theme.of(context).primaryColor,
      unselectedLabelColor: Colors.grey,
      indicatorColor: Theme.of(context).primaryColor,
      tabs: const [
        Tab(icon: Icon(Icons.menu_book), text: 'Available'),
        Tab(icon: Icon(Icons.book_online), text: 'My Rentals'),
        Tab(icon: Icon(Icons.notifications), text: 'Alerts'),
      ],
    );
  }

  Widget _buildTabContent() {
    return IndexedStack(
      index: _selectedTabIndex,
      children: [
        _buildAvailableBooksTab(),
        _buildMyRentalsTab(),
        _buildMyAlertsTab(),
      ],
    );
  }

  Widget _buildAvailableBooksTab() {
    final filteredBooks = _availableBooks.where((book) {
      if (_searchQuery.isEmpty) return true;
      return book['title'].toString().toLowerCase().contains(_searchQuery) ||
             book['author'].toString().toLowerCase().contains(_searchQuery) ||
             book['isbn']?.toString().toLowerCase().contains(_searchQuery) == true;
    }).toList();

    if (filteredBooks.isEmpty) {
      return _buildEmptyState(
        icon: Icons.book,
        message: _searchQuery.isEmpty 
            ? 'No books currently available'
            : 'No books match your search',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(12.0),
      itemCount: filteredBooks.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final book = filteredBooks[index];
        return BookCard(
          book: book,
          actionButton: ElevatedButton(
            onPressed: () => _rentBook(book['book_id']),
            child: const Text('Rent'),
          ),
        );
      },
    );
  }

  Widget _buildMyRentalsTab() {
    final currentRentals = _myRentals.where((r) => r['returned_date'] == null).toList();
    final pastRentals = _myRentals.where((r) => r['returned_date'] != null).toList();

    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          TabBar(
            labelColor: Theme.of(context).primaryColor,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Theme.of(context).primaryColor,
            tabs: [
              Tab(text: 'Current (${currentRentals.length})'),
              Tab(text: 'History (${pastRentals.length})'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildRentalList(currentRentals, isCurrent: true),
                _buildRentalList(pastRentals, isCurrent: false),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRentalList(List<Map<String, dynamic>> rentals, {required bool isCurrent}) {
    if (rentals.isEmpty) {
      return _buildEmptyState(
        icon: isCurrent ? Icons.history : Icons.history_toggle_off,
        message: isCurrent ? 'No current rentals' : 'No rental history',
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

        return RentalCard(
          rental: rental,
          book: book,
          isCurrent: isCurrent,
          isOverdue: isOverdue,
          onReturn: isCurrent ? () => _returnBook(rental['id']) : null,
        );
      },
    );
  }

  Widget _buildMyAlertsTab() {
    if (_myAlerts.isEmpty) {
      return _buildEmptyState(
        icon: Icons.notifications_off,
        message: 'No active alerts',
        actionButton: ElevatedButton(
          onPressed: _showSetAlertDialog,
          child: const Text('Set New Alert'),
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

        return AlertCard(
          alert: alert,
          book: book,
          onRemove: () => _removeAlert(alert['id']),
        );
      },
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String message,
    Widget? actionButton,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              message,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            if (actionButton != null) ...[
              const SizedBox(height: 16),
              actionButton,
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _rentBook(int bookId) async {
    try {
      final dueDate = DateTime.now().add(const Duration(days: 14))
          .toIso8601String()
          .split('T')
          .first;
      
      await _supabase.from('rentals').insert({
        'user_id': _user.id,
        'book_id': bookId,
        'due_date': dueDate,
      });
      
      _showSuccessSnackBar('Book rented successfully!');
      await _fetchDashboardData();
    } catch (e) {
      _showErrorSnackBar('Failed to rent book: ${e.toString()}');
    }
  }

  Future<void> _returnBook(int rentalId) async {
    try {
      await _supabase
          .from('rentals')
          .update({
            'returned_date': DateTime.now().toIso8601String().split('T').first
          })
          .eq('id', rentalId);
      
      _showSuccessSnackBar('Book returned successfully');
      await _fetchDashboardData();
    } catch (e) {
      _showErrorSnackBar('Failed to return book: ${e.toString()}');
    }
  }

  Future<void> _removeAlert(int alertId) async {
    try {
      await _supabase
          .from('alerts')
          .delete()
          .eq('id', alertId);
      
      _showSuccessSnackBar('Alert removed');
      await _fetchDashboardData();
    } catch (e) {
      _showErrorSnackBar('Failed to remove alert: ${e.toString()}');
    }
  }

  Future<void> _handleLogout() async {
    try {
      await _supabase.auth.signOut();
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/');
    } catch (e) {
      _showErrorSnackBar('Logout failed: ${e.toString()}');
    }
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() => _searchQuery = '');
    FocusScope.of(context).unfocus();
  }

  void _showSetAlertDialog() async {
    try {
      final booksResponse = await _supabase.from('books').select();
      final allBooks = List<Map<String, dynamic>>.from(booksResponse);
      
      final bookIdsWithAlerts = _myAlerts.map((a) => a['book_id']).toList();
      final availableForAlerts = allBooks.where((b) => !bookIdsWithAlerts.contains(b['id'])).toList();
      
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
                ? Center(child: Text('No books available for alerts'))
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
        'user_id': _user.id,
        'book_id': bookId,
      });
      
      if (!mounted) return;
      Navigator.pop(context);
      _showSuccessSnackBar('Alert set successfully');
      await _fetchDashboardData();
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

class BookCard extends StatelessWidget {
  final Map<String, dynamic> book;
  final Widget actionButton;

  const BookCard({
    Key? key,
    required this.book,
    required this.actionButton,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
            actionButton,
          ],
        ),
      ),
    );
  }
}

class RentalCard extends StatelessWidget {
  final Map<String, dynamic> rental;
  final Map<String, dynamic> book;
  final bool isCurrent;
  final bool isOverdue;
  final VoidCallback? onReturn;

  const RentalCard({
    Key? key,
    required this.rental,
    required this.book,
    required this.isCurrent,
    required this.isOverdue,
    this.onReturn,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
                if (onReturn != null)
                  ElevatedButton(
                    onPressed: onReturn,
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
                    ?.copyWith(color: Colors.red, fontWeight: FontWeight.bold),
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
  }
}

class AlertCard extends StatelessWidget {
  final Map<String, dynamic> alert;
  final Map<String, dynamic> book;
  final VoidCallback onRemove;

  const AlertCard({
    Key? key,
    required this.alert,
    required this.book,
    required this.onRemove,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
              onPressed: onRemove,
            ),
          ],
        ),
      ),
    );
  }
}