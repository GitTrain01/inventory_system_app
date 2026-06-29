import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/formatters.dart';
import '../../models/expense.dart';
import '../../services/expenses_service.dart';
import '../../state/active_branch_provider.dart';
import '../../state/profile_provider.dart';

class ExpensesScreen extends ConsumerStatefulWidget {
  final bool openAddOnStart;
  const ExpensesScreen({super.key, this.openAddOnStart = false});
  @override
  ConsumerState<ExpensesScreen> createState() => _State();
}

class _State extends ConsumerState<ExpensesScreen> {
  DateTime _date = DateTime.now();
  bool _loading = true;
  List<Expense> _todays = [];

  String get _dateStr => DateFormat('yyyy-MM-dd').format(_date);
  bool get _isAdmin => ref.read(profileProvider).value?.isAdmin ?? false;
  bool get _nightMode => ref.read(activeBranchProvider)?.nightShiftEnabled ?? false;

  @override
  void initState() {
    super.initState();
    _load().then((_) {
      if (widget.openAddOnStart && mounted) _expenseDialog();
    });
  }

  Future<void> _load() async {
    final branch = ref.read(activeBranchProvider);
    if (branch == null) { setState(() => _loading = false); return; }
    setState(() => _loading = true);
    final list = await expensesService.listForDate(branch.id, _dateStr);
    setState(() { _todays = list; _loading = false; });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context, initialDate: _date,
      firstDate: DateTime(2024), lastDate: DateTime(2030));
    if (picked != null) { setState(() => _date = picked); await _load(); }
  }

  Future<void> _expenseDialog({Expense? existing}) async {
    final item = TextEditingController(text: existing?.item ?? '');
    final desc = TextEditingController(text: existing?.description ?? '');
    final value = TextEditingController(text: existing == null ? '' : existing.value.toString());
    String? shift = existing?.shift ?? (_nightMode ? null : 'day');
    String? err;

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: Text(existing == null ? 'Add expense' : 'Edit expense'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: item, decoration: const InputDecoration(labelText: 'Item')),
                const SizedBox(height: 8),
                TextField(controller: desc, decoration: const InputDecoration(labelText: 'Description (optional)')),
                const SizedBox(height: 8),
                TextField(
                  controller: value,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Value ₱'),
                ),
                if (_nightMode) ...[
                  const SizedBox(height: 16),
                  const Align(alignment: Alignment.centerLeft, child: Text('Shift (required)')),
                  const SizedBox(height: 4),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'day', label: Text('☀️ Day')),
                      ButtonSegment(value: 'night', label: Text('🌙 Night')),
                    ],
                    selected: shift == null ? {} : {shift!},
                    emptySelectionAllowed: true,
                    onSelectionChanged: (s) => setLocal(() => shift = s.isEmpty ? null : s.first),
                  ),
                ],
                if (err != null) ...[
                  const SizedBox(height: 8),
                  Text(err!, style: const TextStyle(color: Colors.red)),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            FilledButton(
              onPressed: () {
                final v = num.tryParse(value.text.trim());
                if (item.text.trim().isEmpty || v == null) {
                  setLocal(() => err = 'Item and a numeric value are required.');
                  return;
                }
                if (shift == null) {
                  setLocal(() => err = 'Pick Day or Night.');
                  return;
                }
                Navigator.pop(ctx, true);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );

    if (saved == true) {
      final branch = ref.read(activeBranchProvider)!;
      final v = num.tryParse(value.text.trim()) ?? 0;
      if (existing == null) {
        await expensesService.add(
          branchId: branch.id, date: _dateStr, shift: shift!,
          item: item.text.trim(),
          description: desc.text.trim().isEmpty ? null : desc.text.trim(), value: v);
      } else {
        await expensesService.edit(
          id: existing.id, branchId: branch.id, date: _dateStr, shift: existing.shift,
          item: item.text.trim(),
          description: desc.text.trim().isEmpty ? null : desc.text.trim(), value: v);
      }
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = _isAdmin ? 'Expense History' : 'Expenses';
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          if (_isAdmin)
            TextButton.icon(
              onPressed: _pickDate,
              icon: const Icon(Icons.calendar_today, size: 18),
              label: Text(DateFormat('MMM d').format(_date)),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _expenseDialog(),
        icon: const Icon(Icons.add),
        label: const Text('Add expense'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _todays.isEmpty
              ? Center(child: Text('No expenses for ${DateFormat('MMM d').format(_date)}.'))
              : ListView.separated(
                  itemCount: _todays.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final e = _todays[i];
                    final tag = _nightMode ? (e.shift == 'night' ? '🌙 ' : '☀️ ') : '';
                    return ListTile(
                      title: Text('$tag${e.item}'),
                      subtitle: (e.description == null || e.description!.isEmpty) ? null : Text(e.description!),
                      onTap: () => _expenseDialog(existing: e),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(peso.format(e.value), style: const TextStyle(fontWeight: FontWeight.w600)),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, size: 20),
                            onPressed: () async {
                              await expensesService.delete(
                                  id: e.id, branchId: e.branchId, date: _dateStr, shift: e.shift);
                              await _load();
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}