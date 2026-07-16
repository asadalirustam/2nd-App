import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/settings_provider.dart';
import '../../config/constants.dart';
import '../../models/expense_model.dart';
import 'add_edit_expense_screen.dart';

class ExpenseDetailScreen extends StatelessWidget {
  final String expenseId;

  const ExpenseDetailScreen({super.key, required this.expenseId});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final transProvider = Provider.of<TransactionProvider>(context);
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final currency = settingsProvider.currency;

    // Find the expense locally from list
    final expense = transProvider.expenses.firstWhere(
      (e) => e.id == expenseId,
      orElse: () => transProvider.recentTransactions.any((e) => e['id'] == expenseId)
          ? ExpenseModel(
              id: expenseId,
              userId: '',
              title: transProvider.recentTransactions.firstWhere((e) => e['id'] == expenseId)['title'],
              amount: (transProvider.recentTransactions.firstWhere((e) => e['id'] == expenseId)['amount'] as num).toDouble(),
              category: transProvider.recentTransactions.firstWhere((e) => e['id'] == expenseId)['category'],
              paymentMethod: 'Cash',
              notes: '',
              receiptImage: '',
              date: DateTime.parse(transProvider.recentTransactions.firstWhere((e) => e['id'] == expenseId)['date']),
              createdAt: DateTime.now(),
            )
          : ExpenseModel(
              id: '',
              userId: '',
              title: 'Unknown',
              amount: 0.0,
              category: 'Others',
              paymentMethod: 'Cash',
              notes: '',
              receiptImage: '',
              date: DateTime.now(),
              createdAt: DateTime.now(),
            ),
    );

    if (expense.id.isEmpty) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Expense details not found.')),
      );
    }

    void onDelete() {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Confirm Delete'),
          content: const Text('Are you sure you want to delete this expense entry permanently?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context); // Close dialog
                try {
                  await transProvider.deleteExpense(expense.id);
                  if (!context.mounted) return;
                  Navigator.pop(context); // Pop detail screen
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to delete expense: $e')),
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: theme.colorScheme.error),
              child: const Text('Delete'),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Expense Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AddEditExpenseScreen(expense: expense),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded),
            onPressed: onDelete,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Amount Summary Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.04),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                ),
              ),
              child: Column(
                children: [
                  Text(
                    expense.category.toUpperCase(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    expense.title,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '-$currency${expense.amount.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                      color: theme.colorScheme.error,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Details List
            const Text(
              'TRANSACTION INFORMATION',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.1,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 16),

            _DetailRow(
              icon: Icons.calendar_today_outlined,
              label: 'Transaction Date',
              value: DateFormat('EEEE, MMMM dd, yyyy').format(expense.date),
            ),
            const Divider(height: 24),

            _DetailRow(
              icon: Icons.credit_card_outlined,
              label: 'Payment Method',
              value: expense.paymentMethod,
            ),
            const Divider(height: 24),

            _DetailRow(
              icon: Icons.notes_outlined,
              label: 'Notes / Remarks',
              value: expense.notes.isNotEmpty ? expense.notes : 'No extra notes provided.',
            ),
            const Divider(height: 32),

            // Receipt image display
            if (expense.receiptImage.isNotEmpty) ...[
              const Text(
                'ATTACHED RECEIPT',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: CachedNetworkImage(
                  imageUrl: '${AppConstants.uploadsUrl}/${expense.receiptImage}',
                  placeholder: (context, url) => Container(
                    height: 200,
                    width: double.infinity,
                    color: Colors.grey.withOpacity(0.1),
                    child: const Center(child: CircularProgressIndicator()),
                  ),
                  errorWidget: (context, url, error) => Container(
                    height: 120,
                    width: double.infinity,
                    color: Colors.grey.withOpacity(0.1),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, color: Colors.grey),
                        SizedBox(height: 8),
                        Text('Failed to load receipt image', style: TextStyle(fontSize: 12)),
                      ],
                    ),
                  ),
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: theme.colorScheme.primary.withOpacity(0.6), size: 22),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.onBackground.withOpacity(0.5),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
