import 'package:flutter/material.dart';
import '../../services/auth_service.dart';

class StaffDashboard extends StatelessWidget {
  const StaffDashboard({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Staff Dashboard'),
        actions: [
          IconButton(icon: const Icon(Icons.logout), onPressed: authService.signOut),
        ],
      ),
      body: const Center(child: Text('Welcome, staff')),
    );
  }
}