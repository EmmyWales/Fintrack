import 'package:fintrack/models/finance_transactions.dart';
import 'package:fintrack/provider/finance_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/transaction_form_dialog.dart';
import '../widgets/transaction_tile.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() =>
      _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  String _filter = 'All';
  String _search = '';

  Future<void> _editTransaction(
    FinanceTransaction transaction,
  ) async {
    final updated = await showTransactionFormDialog(
      context,
      transaction: transaction,
    );

    if (!mounted || updated == null) return;

    await context.read<FinanceProvider>().editTransaction(updated);
  }

  Future<void> _deleteTransaction(
    FinanceTransaction transaction,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete transaction?'),
        content: Text(
          'Delete "${transaction.title}" permanently?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (!mounted || confirmed != true) return;

    await context
        .read<FinanceProvider>()
        .deleteTransaction(transaction.id);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FinanceProvider>();

    final transactions = provider.transactions.where((item) {
      final matchesFilter = switch (_filter) {
        'Income' => item.isIncome,
        'Expenses' => !item.isIncome,
        _ => true,
      };

      final query = _search.trim().toLowerCase();

      final matchesSearch = item.title.toLowerCase().contains(query) ||
          item.category.toLowerCase().contains(query);

      return matchesFilter && matchesSearch;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Transactions',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              onChanged: (value) => setState(() => _search = value),
              decoration: const InputDecoration(
                hintText: 'Search transactions...',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              width: double.infinity,
              child: SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'All', label: Text('All')),
                  ButtonSegment(value: 'Income', label: Text('Income')),
                  ButtonSegment(
                    value: 'Expenses',
                    label: Text('Expenses'),
                  ),
                ],
                selected: {_filter},
                onSelectionChanged: (selection) {
                  setState(() => _filter = selection.first);
                },
              ),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: provider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : transactions.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.receipt_long_outlined,
                                size: 52,
                                color: Color(0xFF92999A),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                _search.isNotEmpty
                                    ? 'No matching transactions'
                                    : 'No transactions yet',
                                style: const TextStyle(fontSize: 17),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Add a transaction to see it here.',
                                style: TextStyle(
                                  color: Color(0xFF92999A),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(
                          12, 0, 12, 24,
                        ),
                        itemCount: transactions.length,
                        separatorBuilder: (_, __) =>
                            const Divider(
                          height: 1,
                          color: Color(0xFF29302F),
                        ),
                        itemBuilder: (context, index) {
                          final transaction = transactions[index];

                          return TransactionTile(
                            transaction: transaction,
                            onEdit: () =>
                                _editTransaction(transaction),
                            onDelete: () =>
                                _deleteTransaction(transaction),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}