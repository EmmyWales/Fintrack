import 'package:fintrack/models/finance_transactions.dart';
import 'package:fintrack/provider/finance_provider.dart';
import 'package:fintrack/widgets/summary_card.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../widgets/transaction_form_dialog.dart';
import '../widgets/transaction_tile.dart';
import 'transactions_screen.dart';

const Color backgroundColor = Color(0xFF101313);
const Color surfaceColor = Color(0xFF1B2020);
const Color accentColor = Color(0xFF45D483);
const Color mutedColor = Color(0xFF92999A);

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<void> _addTransaction(BuildContext context) async {
    final transaction = await showTransactionFormDialog(context);

    if (!context.mounted || transaction == null) return;

    await context.read<FinanceProvider>().addTransaction(transaction);
  }

  Future<void> _editTransaction(
    BuildContext context,
    FinanceTransaction transaction,
  ) async {
    final updated = await showTransactionFormDialog(
      context,
      transaction: transaction,
    );

    if (!context.mounted || updated == null) return;

    await context.read<FinanceProvider>().editTransaction(updated);
  }

  Future<void> _deleteTransaction(
    BuildContext context,
    FinanceTransaction transaction,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete transaction?'),
        content: Text('Delete "${transaction.title}"?'),
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

    if (!context.mounted || confirmed != true) return;

    await context.read<FinanceProvider>().deleteTransaction(transaction.id);
  }

  Future<void> _clearTransactions(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Clear all transactions?'),
        content: const Text(
          'This permanently deletes all saved transactions '
          'from this device. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Clear all'),
          ),
        ],
      ),
    );

    if (!context.mounted || confirmed != true) return;

    await context.read<FinanceProvider>().clearAllTransactions();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FinanceProvider>();
    final recentTransactions = provider.transactions.take(5).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.account_balance_wallet, color: accentColor),
            SizedBox(width: 10),
            Text('FinTrack', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'clear') {
                _clearTransactions(context);
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'clear',
                child: Text('Clear all transactions'),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addTransaction(context),
        backgroundColor: accentColor,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.add),
        label: const Text('Add transaction'),
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: provider.loadTransactions,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                children: [
                  const Text(
                    'YOUR FINANCES',
                    style: TextStyle(
                      color: mutedColor,
                      letterSpacing: 2,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF243B30), Color(0xFF1B2020)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: accentColor.withValues(alpha: 0.22),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Total balance',
                          style: TextStyle(color: mutedColor),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '£${NumberFormat('#,##0.00').format(provider.balance)}',
                          //'£${provider.balance.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -1,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Row(
                          children: [
                            Icon(Icons.sync, size: 15, color: accentColor),
                            SizedBox(width: 6),
                            Text(
                              'Updates with your transactions',
                              style: TextStyle(color: mutedColor, fontSize: 12),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: SummaryCard(
                          title: 'Income',
                          amount:  provider.totalIncome,
                          icon: Icons.south_west,
                          color: accentColor,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SummaryCard(
                          title: 'Expenses',
                          amount: provider.totalExpenses,
                          icon: Icons.north_east,
                          color: const Color(0xFFFF7777),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Recent transactions',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const TransactionsScreen(),
                            ),
                          );
                        },
                        child: const Text(
                          'See all',
                          style: TextStyle(color: accentColor),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (recentTransactions.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: surfaceColor,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Column(
                        children: [
                          Icon(
                            Icons.receipt_long_outlined,
                            size: 36,
                            color: mutedColor,
                          ),
                          SizedBox(height: 10),
                          Text('No transactions yet'),
                          SizedBox(height: 4),
                          Text(
                            'Add your first income or expense.',
                            style: TextStyle(color: mutedColor),
                          ),
                        ],
                      ),
                    )
                  else
                    Container(
                      decoration: BoxDecoration(
                        color: surfaceColor,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Column(
                        children: [
                          for (
                            var i = 0;
                            i < recentTransactions.length;
                            i++
                          ) ...[
                            TransactionTile(
                              transaction: recentTransactions[i],
                              onEdit: () => _editTransaction(
                                context,
                                recentTransactions[i],
                              ),
                              onDelete: () => _deleteTransaction(
                                context,
                                recentTransactions[i],
                              ),
                            ),
                            if (i < recentTransactions.length - 1)
                              const Divider(
                                height: 1,
                                indent: 16,
                                endIndent: 16,
                                color: Color(0xFF29302F),
                              ),
                          ],
                        ],
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}
