import 'package:flutter/material.dart';
import '../../services/auth_service.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(icon: const Icon(Icons.logout), onPressed: authService.signOut),
        ],
      ),
      body: const Center(child: Text('Welcome, admin')),
    );
  }
}