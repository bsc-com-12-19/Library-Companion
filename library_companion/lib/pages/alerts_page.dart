// ignore_for_file: use_super_parameters, library_private_types_in_public_api, await_only_futures, avoid_print

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class AlertsPage extends StatefulWidget {
  const AlertsPage({Key? key}) : super(key: key);

  @override
  _AlertsPageState createState() => _AlertsPageState();
}

class _AlertsPageState extends State<AlertsPage> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> alerts = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchAlerts();
  }

  Future<void> fetchAlerts() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      final response = await supabase
          .from('Alerts')
          .select(', Books(), Rentals(*)')
          .eq('user_id', userId)
          .eq('active', true);

      setState(() {
        alerts = List<Map<String, dynamic>>.from(response as Iterable);
        isLoading = false;
      });
    } catch (e) {
      print('Error fetching alerts: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  String formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat.yMMMd().format(date);
    } catch (e) {
      return dateStr;
    }
  }

  String countdownText(String? dueDateStr) {
    if (dueDateStr == null) return "No due date";
    try {
      final dueDate = DateTime.parse(dueDateStr);
      final now = DateTime.now();
      final daysLeft = dueDate.difference(now).inDays;

      if (daysLeft > 0) return "$daysLeft day(s) left";
      if (daysLeft == 0) return "Due today!";
      return "Overdue";
    } catch (e) {
      return "Invalid date";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('📢 Alerts'),
        backgroundColor: Colors.lightBlue,
      ),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : alerts.isEmpty
              ? const Center(child: Text('No alerts set'))
              : ListView.builder(
                itemCount: alerts.length,
                itemBuilder: (context, index) {
                  final alert = alerts[index];
                  final book = alert['Books'] ?? {};
                  final rental = alert['Rentals'] ?? {};

                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 3,
                    child: ListTile(
                      leading: const Icon(
                        Icons.notifications_active,
                        color: Colors.blueAccent,
                      ),
                      title: Text(
                        book['title'] ?? 'Unknown Book',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (rental['due_date'] != null)
                            Text("Due: ${formatDate(rental['due_date'])}"),
                          Text("⏳ ${countdownText(rental['due_date'])}"),
                        ],
                      ),
                    ),
                  );
                },
              ),
    );
  }
}
