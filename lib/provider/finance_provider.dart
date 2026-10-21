import 'dart:convert';
import 'dart:core';
import 'package:fintrack/models/finance_transactions.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FinanceProvider extends ChangeNotifier {
  static const String _storageKey = 'fintrack_transactions';

  List<FinanceTransaction> _transactions = [];
  bool _isLoading = true;

  List<FinanceTransaction> get transactions {
    final result = [...transactions];
    result.sort((a, b) => b.date.compareTo(a.date));
    return result;
  }

  bool get isLoading => _isLoading;

  double get totalIncome => _transactions
      .where((transaction) => transaction.isIncome)
      .fold(0.0, (sum, transaction) => sum + transaction.amount);

  double get totalExpenses => _transactions
      .where((transaction) => !transaction.isIncome)
      .fold(0.0, (sum, transaction) => sum + transaction.amount);

  double get balance => totalIncome - totalExpenses;

  FinanceProvider() {
    loadTransactions();
  }

  Future<void> loadTransactions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedData = prefs.getString(_storageKey);

      if (savedData != null) {
        final decoded = jsonDecode(savedData) as List<dynamic>;

        _transactions = decoded.map((item) {
          return FinanceTransaction.fromJson(
            Map<String, dynamic>.from(item as Map),
          );
        }).toList();
      } else {
        _transactions = _sampleTransactions();
        await _saveTransactions();
      }
    } catch (e) {
      debugPrint('Could not load transaction: $e');
      _transactions = _sampleTransactions();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addTransaction(FinanceTransaction transaction) async {
    _transactions.add(transaction);
    notifyListeners();

    await _saveTransactions();
  }

  Future<void> _saveTransactions() async {
    final prefs = await SharedPreferences.getInstance();

    final encoded = jsonEncode(
      _transactions.map((transaction) => transaction.toJson()).toList(),
    );

    await prefs.setString(_storageKey, encoded);
  }

  List<FinanceTransaction> _sampleTransactions() {
    final now = DateTime.now();

    return [
      FinanceTransaction(
        id: '1',
        title: 'Monthly salary',
        category: 'Salary',
        amount: 2400,
        isIncome: true,
        date: now,
      ),
      FinanceTransaction(
        id: '2',
        title: 'Groceries',
        category: 'Food',
        amount: 54.80,
        isIncome: false,
        date: now.subtract(const Duration(days: 1)),
      ),
      FinanceTransaction(
        id: '3',
        title: 'Transport',
        category: 'Travel',
        amount: 18.50,
        isIncome: false,
        date: now.subtract(const Duration(days: 2)),
      ),
      FinanceTransaction(
        id: '4',
        title: 'Freelance work',
        category: 'Extra income',
        amount: 150,
        isIncome: true,
        date: now.subtract(const Duration(days: 3)),
      ),
    ];
  }
}
