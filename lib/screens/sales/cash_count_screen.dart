import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/formatters.dart';
import '../../core/parse.dart';
import '../../services/cash_service.dart';
import '../../services/logic/sales_math.dart';
import '../../state/active_branch_provider.dart';
import '../../state/profile_provider.dart';

class CashCountScreen extends ConsumerStatefulWidget {
  const CashCountScreen({super.key});
  @override
  ConsumerState<CashCountScreen> createState() => _State();
}

class _State extends ConsumerState<CashCountScreen> {
  DateTime _date = DateTime.now();
  String _shift = 'day';
  final _bills = TextEditingController();
  final _coins = TextEditingController();
  bool _loading = true;
  bool _submitting = false;
  String? _error;

  num _sales = 0, _expenses = 0;
  bool _locked = false;

  String get _dateStr => DateFormat('yyyy-MM-dd').format(_date);

  bool get _isAdmin => ref.read(profileProvider).value?.isAdmin ?? false;
  bool get _nightMode => ref.read(activeBranchProvider)?.nightShiftEnabled ?? false;

  /// Staff are locked out of editing once submitted; admin never is.
  bool get _readOnly => !_isAdmin && _locked;

  DateTime _derivedDate(String shift) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return shift == 'night' ? today.subtract(const Duration(days: 1)) : today;
  }

  @override
  void initState() {
    super.initState();
    if (!_isAdmin) _date = _derivedDate(_shift);
    _load();
  }

  @override
  void dispose() { _bills.dispose(); _coins.dispose(); super.dispose(); }

  void _onShiftChanged(String shift) {
    setState(() {
      _shift = shift;
      if (!_isAdmin) _date = _derivedDate(shift);
    });
    _load();
  }

  Future<void> _load() async {
    final branch = ref.read(activeBranchProvider);
    if (branch == null) { setState(() => _loading = false); return; }
    setState(() { _loading = true; _error = null; });
    try {
      _sales = await cashService.salesTotal(branch.id, _dateStr, _shift);
      _expenses = await cashService.expensesTotal(branch.id, _dateStr, _shift);
      final report = await cashService.getReport(branch.id, _dateStr, _shift);
      _locked = (report?['is_locked'] ?? false) as bool;
      _bills.text = report?['counted_bills'] == null ? '' : qty(toNum(report!['counted_bills'])!);
      _coins.text = report?['counted_coins'] == null ? '' : qty(toNum(report!['counted_coins'])!);
      setState(() {});
    } catch (e) {
      setState(() => _error = 'Load failed: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  num get _billsVal => num.tryParse(_bills.text.trim()) ?? 0;
  num get _coinsVal => num.tryParse(_coins.text.trim()) ?? 0;
  num get _liveDisc => computeDiscrepancy(
      cash: _billsVal, coins: _coinsVal, expenses: _expenses, sales: _sales);

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context, initialDate: _date,
      firstDate: DateTime(2024), lastDate: DateTime(2030));
    if (picked != null) { setState(() => _date = picked); await _load(); }
  }

  Future<void> _submit() async {
    final branch = ref.read(activeBranchProvider);
    if (branch == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Submit cash count?'),
        content: Text(
            'Recording for ${DateFormat('EEE, MMM d').format(_date)} • ${_shift == 'night' ? 'Night' : 'Day'}.\n'
            '${_isAdmin ? 'You can edit this later.' : 'Once submitted you can’t change it — ask an admin to correct it if needed.'}'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Submit')),
        ],
      ),
    );
    if (ok != true) return;

    setState(() { _submitting = true; _error = null; });
    try {
      await cashService.submitCashCount(
        branchId: branch.id, date: _dateStr, shift: _shift,
        bills: _billsVal, coins: _coinsVal);
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cash count submitted.')));
      }
    } catch (e) {
      setState(() => _error = 'Submit failed: $e');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final disc = _liveDisc;
    final status = disc == 0 ? 'BALANCED' : (disc < 0 ? 'SHORT' : 'OVER');
    final statusColor = disc == 0 ? Colors.green : (disc < 0 ? Colors.red : Colors.blue);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cash Count'),
        actions: [
          if (_isAdmin)
            TextButton.icon(
              onPressed: _pickDate,
              icon: const Icon(Icons.calendar_today, size: 18),
              label: Text(DateFormat('MMM d').format(_date)),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'day', label: Text('Day')),
                    ButtonSegment(value: 'night', label: Text('Night')),
                  ],
                  selected: {_shift},
                  onSelectionChanged: (s) => _onShiftChanged(s.first),
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(_isAdmin ? Icons.event : Icons.lock_outline, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${_shift == 'night' ? '🌙 Night' : '☀️ Day'} • ${DateFormat('EEE, MMM d, yyyy').format(_date)}'
                          '${_isAdmin ? '' : '  (locked)'}',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Staff read-only banner once submitted.
                if (_readOnly)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      '🔒 Already submitted for this shift. Ask an admin to make changes.',
                      textAlign: TextAlign.center,
                    ),
                  ),

                // Admin-only locked banner (editable).
                if (_isAdmin && _locked)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text('🔒 Locked. Re-submitting updates it.',
                        textAlign: TextAlign.center),
                  ),

                // Sales preview + discrepancy: ADMIN ONLY.
                if (_isAdmin) ...[
                  Card(
                    color: _sales == 0 ? Colors.orange.withValues(alpha: 0.12) : null,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Sales for this shift',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: _sales == 0 ? Colors.orange.shade900 : null)),
                              Text('${DateFormat('EEE, MMM d').format(_date)} • ${_shift == 'night' ? '🌙 Night' : '☀️ Day'}',
                                  style: const TextStyle(fontSize: 12, color: Colors.grey)),
                            ],
                          ),
                          Text(peso.format(_sales),
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold,
                                  color: _sales == 0 ? Colors.orange.shade900 : null)),
                        ],
                      ),
                    ),
                  ),
                  if (_sales == 0)
                    const Padding(
                      padding: EdgeInsets.only(top: 6, left: 4, right: 4),
                      child: Text('⚠️ No sales found for this date + shift. Submitting now reads as a large OVER.',
                          style: TextStyle(color: Colors.orange, fontSize: 12)),
                    ),
                  const SizedBox(height: 16),
                ],

                TextField(
                  controller: _bills,
                  enabled: !_readOnly,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(labelText: 'Cash (bills) ₱', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _coins,
                  enabled: !_readOnly,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(labelText: 'Coins ₱', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 20),

                // Discrepancy card: ADMIN ONLY.
                if (_isAdmin)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _line('Bills + Coins', peso.format(_billsVal + _coinsVal)),
                          _line('Expenses', peso.format(_expenses)),
                          _line('Sales (expected)', peso.format(_sales)),
                          const Divider(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(status, style: TextStyle(fontWeight: FontWeight.bold, color: statusColor)),
                              Text(peso.format(disc),
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: statusColor)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!, style: const TextStyle(color: Colors.red)),
                ],
                const SizedBox(height: 16),

                // Submit hidden for staff once locked.
                if (!_readOnly)
                  FilledButton(
                    onPressed: _submitting ? null : _submit,
                    child: Text(_submitting
                        ? 'Submitting…'
                        : (_locked && _isAdmin ? 'Update cash count' : 'Submit cash count')),
                  ),
              ],
            ),
    );
  }

  Widget _line(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [Text(label), Text(value)],
        ),
      );
}