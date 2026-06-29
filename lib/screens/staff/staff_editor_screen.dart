import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/user_profile.dart';
import '../../services/staff_service.dart';
import '../../state/active_branch_provider.dart';

class StaffEditorScreen extends ConsumerStatefulWidget {
  final Profile user;
  const StaffEditorScreen({super.key, required this.user});
  @override
  ConsumerState<StaffEditorScreen> createState() => _State();
}

class _State extends ConsumerState<StaffEditorScreen> {
  late String? _branchId;
  late bool _dashboard, _delivery, _sales, _expenses, _reports;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final u = widget.user;
    _branchId = u.branchId;
    _dashboard = u.canAccessDashboard;
    _delivery = u.canAccessDelivery;
    _sales = u.canAccessSales;
    _expenses = u.canAccessExpenses;
    _reports = u.canAccessReports;
  }

  Future<void> _save() async {
    setState(() { _saving = true; _error = null; });
    try {
      await staffService.updateAccess(
        id: widget.user.id, branchId: _branchId,
        dashboard: _dashboard, delivery: _delivery, sales: _sales,
        expenses: _expenses, reports: _reports);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => _error = 'Save failed: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final branches = ref.watch(branchesProvider).value ?? const [];
    final u = widget.user;

    return Scaffold(
      appBar: AppBar(title: Text(u.fullName?.isNotEmpty == true ? u.fullName! : (u.email ?? 'Staff'))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (u.email != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(u.email!, style: const TextStyle(color: Colors.grey)),
            ),
          DropdownButtonFormField<String>(
            initialValue: branches.any((b) => b.id == _branchId) ? _branchId : null,
            decoration: const InputDecoration(labelText: 'Assigned branch'),
            items: branches
                .map((b) => DropdownMenuItem(value: b.id, child: Text(b.name)))
                .toList(),
            onChanged: (v) => setState(() => _branchId = v),
          ),
          const SizedBox(height: 8),
          const Divider(),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text('Module access', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          SwitchListTile(
            title: const Text('Dashboard'),
            subtitle: const Text('Home screen with stock counts'),
            value: _dashboard,
            onChanged: (v) => setState(() => _dashboard = v),
          ),
          SwitchListTile(
            title: const Text('Sales'),
            subtitle: const Text('Sales worksheet + cash count'),
            value: _sales,
            onChanged: (v) => setState(() => _sales = v),
          ),
          SwitchListTile(
            title: const Text('Delivery'),
            subtitle: const Text('Confirm cross-branch deliveries'),
            value: _delivery,
            onChanged: (v) => setState(() => _delivery = v),
          ),
          SwitchListTile(
            title: const Text('Expenses'),
            subtitle: const Text('Log drawer expenses'),
            value: _expenses,
            onChanged: (v) => setState(() => _expenses = v),
          ),
          SwitchListTile(
            title: const Text('Reports'),
            subtitle: const Text('View reports'),
            value: _reports,
            onChanged: (v) => setState(() => _reports = v),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: const TextStyle(color: Colors.red)),
          ],
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _saving ? null : _save,
            child: Text(_saving ? 'Saving…' : 'Save access'),
          ),
        ],
      ),
    );
  }
}