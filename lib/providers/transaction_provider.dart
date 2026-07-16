import 'dart:io';
import 'package:flutter/material.dart';
import '../models/expense_model.dart';
import '../models/income_model.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';

class TransactionProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  final NotificationService _notificationService = NotificationService();

  List<ExpenseModel> _expenses = [];
  List<IncomeModel> _incomes = [];

  // Dashboard Aggregates
  double _totalBalance = 0.0;
  double _totalIncome = 0.0;
  double _totalExpense = 0.0;
  double _currentMonthIncome = 0.0;
  double _currentMonthExpense = 0.0;
  double _currentMonthSavings = 0.0;
  List<Map<String, dynamic>> _recentTransactions = [];
  List<Map<String, dynamic>> _categorySummary = [];

  // Reports
  double _reportTotalExpense = 0.0;
  double _reportTotalIncome = 0.0;
  List<Map<String, dynamic>> _reportCategoryWiseExpenses = [];
  List<Map<String, dynamic>> _reportChartPoints = [];

  bool _isLoading = false;

  // Getters
  List<ExpenseModel> get expenses => _expenses;
  List<IncomeModel> get incomes => _incomes;
  double get totalBalance => _totalBalance;
  double get totalIncome => _totalIncome;
  double get totalExpense => _totalExpense;
  double get currentMonthIncome => _currentMonthIncome;
  double get currentMonthExpense => _currentMonthExpense;
  double get currentMonthSavings => _currentMonthSavings;
  List<Map<String, dynamic>> get recentTransactions => _recentTransactions;
  List<Map<String, dynamic>> get categorySummary => _categorySummary;

  double get reportTotalExpense => _reportTotalExpense;
  double get reportTotalIncome => _reportTotalIncome;
  List<Map<String, dynamic>> get reportCategoryWiseExpenses => _reportCategoryWiseExpenses;
  List<Map<String, dynamic>> get reportChartPoints => _reportChartPoints;

  bool get isLoading => _isLoading;

  // Fetch Dashboard Metrics
  Future<void> fetchDashboardMetrics() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.get('/expenses/dashboard');
      if (response.data['success'] == true) {
        final d = response.data['data'];
        _totalBalance = (d['totalBalance'] as num?)?.toDouble() ?? 0.0;
        _totalIncome = (d['totalIncome'] as num?)?.toDouble() ?? 0.0;
        _totalExpense = (d['totalExpense'] as num?)?.toDouble() ?? 0.0;
        _currentMonthIncome = (d['currentMonthIncome'] as num?)?.toDouble() ?? 0.0;
        _currentMonthExpense = (d['currentMonthExpense'] as num?)?.toDouble() ?? 0.0;
        _currentMonthSavings = (d['currentMonthSavings'] as num?)?.toDouble() ?? 0.0;

        _recentTransactions = List<Map<String, dynamic>>.from(d['recentTransactions'] ?? []);
        _categorySummary = List<Map<String, dynamic>>.from(d['categorySummary'] ?? []);

        // Dynamic budget notification alert
        // If current month's expenses exceed 90% of current month's income, issue local alert
        if (_currentMonthIncome > 0 && (_currentMonthExpense / _currentMonthIncome) >= 0.9) {
          _notificationService.showNotification(
            id: 201,
            title: 'Budget Alert! ⚠️',
            body: 'You have spent ${((_currentMonthExpense / _currentMonthIncome) * 100).toStringAsFixed(0)}% of your monthly income.',
          );
        }
      }
    } catch (e) {
      debugPrint('Error fetching dashboard: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Fetch Expenses with filters
  Future<void> fetchExpenses({
    String? search,
    String? category,
    String? paymentMethod,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final params = <String, dynamic>{};
      if (search != null && search.isNotEmpty) params['search'] = search;
      if (category != null && category != 'All') params['category'] = category;
      if (paymentMethod != null && paymentMethod != 'All') params['paymentMethod'] = paymentMethod;
      if (startDate != null) params['startDate'] = startDate.toIso8601String();
      if (endDate != null) params['endDate'] = endDate.toIso8601String();

      final response = await _apiService.get('/expenses', queryParameters: params);
      if (response.data['success'] == true) {
        final list = response.data['data'] as List;
        _expenses = list.map((e) => ExpenseModel.fromJson(e)).toList();
      }
    } catch (e) {
      debugPrint('Error fetching expenses: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Fetch Reports Data
  Future<void> fetchReportsData(String period) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.get('/expenses/reports', queryParameters: {'period': period});
      if (response.data['success'] == true) {
        final d = response.data['data'];
        _reportTotalExpense = (d['totalExpense'] as num?)?.toDouble() ?? 0.0;
        _reportTotalIncome = (d['totalIncome'] as num?)?.toDouble() ?? 0.0;
        _reportCategoryWiseExpenses = List<Map<String, dynamic>>.from(d['categoryWiseExpenses'] ?? []);
        _reportChartPoints = List<Map<String, dynamic>>.from(d['chartData'] ?? []);
      }
    } catch (e) {
      debugPrint('Error fetching reports: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Add Expense
  Future<void> addExpense({
    required String title,
    required double amount,
    required String category,
    required String paymentMethod,
    required String notes,
    required DateTime date,
    File? receiptImage,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final fields = {
        'title': title,
        'amount': amount.toString(),
        'category': category,
        'paymentMethod': paymentMethod,
        'notes': notes,
        'date': date.toIso8601String(),
      };

      final response = await _apiService.multipartRequest(
        path: '/expenses',
        method: 'POST',
        fields: fields,
        file: receiptImage,
        fileFieldName: 'receiptImage',
      );

      if (response.data['success'] == true) {
        // Refresh local lists and totals
        await fetchDashboardMetrics();
      } else {
        throw response.data['message'] ?? 'Failed to add expense';
      }
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Edit Expense
  Future<void> editExpense({
    required String id,
    required String title,
    required double amount,
    required String category,
    required String paymentMethod,
    required String notes,
    required DateTime date,
    File? receiptImage,
    bool removeReceipt = false,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final fields = {
        'title': title,
        'amount': amount.toString(),
        'category': category,
        'paymentMethod': paymentMethod,
        'notes': notes,
        'date': date.toIso8601String(),
        'removeReceipt': removeReceipt.toString(),
      };

      final response = await _apiService.multipartRequest(
        path: '/expenses/$id',
        method: 'PUT',
        fields: fields,
        file: receiptImage,
        fileFieldName: 'receiptImage',
      );

      if (response.data['success'] == true) {
        await fetchDashboardMetrics();
      } else {
        throw response.data['message'] ?? 'Failed to edit expense';
      }
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Delete Expense
  Future<void> deleteExpense(String id) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.delete('/expenses/$id');
      if (response.data['success'] == true) {
        _expenses.removeWhere((e) => e.id == id);
        await fetchDashboardMetrics();
      } else {
        throw response.data['message'] ?? 'Failed to delete expense';
      }
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Fetch Incomes list
  Future<void> fetchIncomes() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.get('/income');
      if (response.data['success'] == true) {
        final list = response.data['data'] as List;
        _incomes = list.map((i) => IncomeModel.fromJson(i)).toList();
      }
    } catch (e) {
      debugPrint('Error fetching incomes: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Add Income
  Future<void> addIncome({
    required String title,
    required double amount,
    required String notes,
    required DateTime date,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.post('/income', data: {
        'title': title,
        'amount': amount,
        'notes': notes,
        'date': date.toIso8601String(),
      });

      if (response.data['success'] == true) {
        await fetchDashboardMetrics();
      } else {
        throw response.data['message'] ?? 'Failed to add income';
      }
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Edit Income
  Future<void> editIncome({
    required String id,
    required String title,
    required double amount,
    required String notes,
    required DateTime date,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.put('/income/$id', data: {
        'title': title,
        'amount': amount,
        'notes': notes,
        'date': date.toIso8601String(),
      });

      if (response.data['success'] == true) {
        await fetchDashboardMetrics();
      } else {
        throw response.data['message'] ?? 'Failed to edit income';
      }
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Delete Income
  Future<void> deleteIncome(String id) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.delete('/income/$id');
      if (response.data['success'] == true) {
        _incomes.removeWhere((i) => i.id == id);
        await fetchDashboardMetrics();
      } else {
        throw response.data['message'] ?? 'Failed to delete income';
      }
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
