import 'package:fintrack/models/finance_transactions.dart';
import 'package:flutter/material.dart';



Future<FinanceTransaction?> showTransactionFormDialog(
  BuildContext context, {
  FinanceTransaction? transaction,
}) {
  return showDialog<FinanceTransaction>(
    context: context,
    builder: (_) => TransactionFormDialog(
      transaction: transaction,
    ),
  );
}

class TransactionFormDialog extends StatefulWidget {
  final FinanceTransaction? transaction;

  const TransactionFormDialog({
    super.key,
    this.transaction,
  });

  @override
  State<TransactionFormDialog> createState() =>
      _TransactionFormDialogState();
}

class _TransactionFormDialogState
    extends State<TransactionFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _titleController;
  late final TextEditingController _amountController;

  late bool _isIncome;
  late String _category;

  final List<String> _categories = [
    'Salary',
    'Extra income',
    'Food',
    'Travel',
    'Shopping',
    'Bills',
    'Entertainment',
    'Health',
    'Education',
    'Other',
  ];

  @override
  void initState() {
    super.initState();

    final transaction = widget.transaction;

    _titleController = TextEditingController(
      text: transaction?.title ?? '',
    );

    _amountController = TextEditingController(
      text: transaction?.amount.toString() ?? '',
    );

    _isIncome = transaction?.isIncome ?? false;

    final savedCategory = transaction?.category ?? 'Food';

    _category = _categories.contains(savedCategory)
        ? savedCategory
        : 'Other';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final amount = double.parse(
      _amountController.text.trim(),
    );

    final existing = widget.transaction;

    final result = FinanceTransaction(
      id: existing?.id ??
          DateTime.now().microsecondsSinceEpoch.toString(),
      title: _titleController.text.trim(),
      category: _category,
      amount: amount,
      isIncome: _isIncome,
      date: existing?.date ?? DateTime.now(),
    );

    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.transaction != null;

    const accent = Color(0xFF45D483);

    return AlertDialog(
      backgroundColor: const Color(0xFF1B2020),
      title: Text(
        isEditing ? 'Edit transaction' : 'New transaction',
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment<bool>(
                    value: false,
                    label: Text('Expense'),
                    icon: Icon(Icons.arrow_downward),
                  ),
                  ButtonSegment<bool>(
                    value: true,
                    label: Text('Income'),
                    icon: Icon(Icons.arrow_upward),
                  ),
                ],
                selected: {_isIncome},
                onSelectionChanged: (selection) {
                  setState(() {
                    _isIncome = selection.first;
                  });
                },
              ),
              const SizedBox(height: 18),
              TextFormField(
                controller: _titleController,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Transaction title',
                  hintText: 'e.g. Weekly groceries',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Enter a transaction title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _amountController,
                keyboardType:
                    const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Amount (£)',
                  prefixText: '£ ',
                ),
                validator: (value) {
                  final amount = double.tryParse(
                    value?.trim() ?? '',
                  );

                  if (amount == null || amount <= 0) {
                    return 'Enter an amount greater than zero';
                  }

                  return null;
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _category,
                decoration: const InputDecoration(
                  labelText: 'Category',
                ),
                items: _categories.map((category) {
                  return DropdownMenuItem<String>(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _category = value);
                  }
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: accent,
            foregroundColor: Colors.black,
          ),
          onPressed: _save,
          child: Text(isEditing ? 'Save changes' : 'Add transaction'),
        ),
      ],
    );
  }
}