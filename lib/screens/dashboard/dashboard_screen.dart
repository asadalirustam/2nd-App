import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/settings_provider.dart';
import '../../config/constants.dart';
import '../expenses/expense_list_screen.dart';
import '../expenses/expense_detail_screen.dart';
import '../expenses/add_edit_expense_screen.dart';
import '../income/add_edit_income_screen.dart';
import '../reports/reports_screen.dart';
import '../profile/profile_screen.dart';
import '../../config/theme.dart';
import '../../widgets/skeleton_loader.dart';


class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<TransactionProvider>(context, listen: false).fetchDashboardMetrics();
    });
  }

  // Define tabs
  List<Widget> get _tabs => [
        const DashboardHomeView(),
        const ExpenseListScreen(),
        const ReportsScreen(),
        const ProfileScreen(),
      ];

  void _onQuickAddExpense() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddEditExpenseScreen()),
    ).then((_) {
      // Refresh dashboard on pop back
      Provider.of<TransactionProvider>(context, listen: false).fetchDashboardMetrics();
    });
  }

  void _onQuickAddIncome() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddEditIncomeScreen()),
    ).then((_) {
      // Refresh dashboard on pop back
      Provider.of<TransactionProvider>(context, listen: false).fetchDashboardMetrics();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _tabs,
      ),
      floatingActionButton: _currentIndex == 0
          ? Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                FloatingActionButton.small(
                  heroTag: 'add_income_fab',
                  onPressed: _onQuickAddIncome,
                  backgroundColor: theme.colorScheme.success,
                  foregroundColor: Colors.white,
                  child: const Icon(Icons.add_card_rounded),
                ),
                const SizedBox(height: 8),
                FloatingActionButton(
                  heroTag: 'add_expense_fab',
                  onPressed: _onQuickAddExpense,
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                  child: const Icon(Icons.add_rounded),
                ),
              ],
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long_rounded),
            label: 'Transactions',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart_rounded),
            label: 'Reports',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

// Separate Subview for the Home Dashboard Tab
class DashboardHomeView extends StatelessWidget {
  const DashboardHomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final transProvider = Provider.of<TransactionProvider>(context);
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final currency = settingsProvider.currency;

    final user = authProvider.user;

    return RefreshIndicator(
      onRefresh: () async {
        await transProvider.fetchDashboardMetrics();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                backgroundImage: user?.profileImage != null && user!.profileImage.isNotEmpty
                    ? NetworkImage('${AppConstants.uploadsUrl}/${user.profileImage}')
                    : null,
                child: user?.profileImage == null || user!.profileImage.isEmpty
                    ? Icon(Icons.person, color: theme.colorScheme.primary)
                    : null,
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hello,',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.normal,
                      color: theme.colorScheme.onBackground.withOpacity(0.5),
                    ),
                  ),
                  Text(
                    user?.name ?? 'User',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.notifications_outlined),
              onPressed: () {
                // Dummy notifications list click
              },
            ),
          ],
        ),
        body: transProvider.isLoading && transProvider.recentTransactions.isEmpty
            ? const Padding(
                padding: EdgeInsets.all(20.0),
                child: SkeletonLoader(),
              )
            : SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Total Balance Hero Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            theme.colorScheme.primary,
                            theme.colorScheme.primary.withOpacity(0.8),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: theme.colorScheme.primary.withOpacity(0.3),
                            blurRadius: 15,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Total Balance',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '$currency${transProvider.totalBalance.toStringAsFixed(2)}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.15),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.arrow_downward_rounded,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Income',
                                        style: TextStyle(
                                          color: Colors.white60,
                                          fontSize: 11,
                                        ),
                                      ),
                                      Text(
                                        '$currency${transProvider.totalIncome.toStringAsFixed(0)}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.15),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.arrow_upward_rounded,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Expenses',
                                        style: TextStyle(
                                          color: Colors.white60,
                                          fontSize: 11,
                                        ),
                                      ),
                                      Text(
                                        '$currency${transProvider.totalExpense.toStringAsFixed(0)}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          )
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Monthly Overview Cards Row
                    Row(
                      children: [
                        Expanded(
                          child: _OverviewMiniCard(
                            title: 'Monthly Income',
                            amount: transProvider.currentMonthIncome,
                            icon: Icons.add_circle_outline_rounded,
                            iconColor: theme.colorScheme.success,
                            currency: currency,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _OverviewMiniCard(
                            title: 'Monthly Expense',
                            amount: transProvider.currentMonthExpense,
                            icon: Icons.remove_circle_outline_rounded,
                            iconColor: theme.colorScheme.error,
                            currency: currency,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _SavingsCard(
                      savings: transProvider.currentMonthSavings,
                      currency: currency,
                    ),
                    const SizedBox(height: 28),

                    // Category summaries
                    if (transProvider.categorySummary.isNotEmpty) ...[
                      const Text(
                        'Category Summary',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 110,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: transProvider.categorySummary.length,
                          itemBuilder: (context, index) {
                            final cat = transProvider.categorySummary[index];
                            return Container(
                              width: 120,
                              margin: const EdgeInsets.only(right: 14),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: theme.cardTheme.color,
                                border: Border.all(
                                  color: theme.colorScheme.onBackground.withOpacity(0.05),
                                ),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    cat['category'],
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: theme.colorScheme.onBackground.withOpacity(0.6),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    '$currency${cat['amount']}',
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${cat['percentage']}% of total',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 28),
                    ],

                    // Recent Transactions Title
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Recent Transactions',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (transProvider.recentTransactions.isNotEmpty)
                          TextButton(
                            onPressed: () {
                              // Direct navigation inside dashboard shell is handled by changing parent index
                              final state = context.findAncestorStateOfType<_DashboardScreenState>();
                              state?.setState(() {
                                state._currentIndex = 1;
                              });
                            },
                            child: const Text('See All'),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Transactions list
                    if (transProvider.recentTransactions.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 32.0),
                          child: Column(
                            children: [
                              Icon(
                                Icons.hourglass_empty_rounded,
                                size: 48,
                                color: theme.colorScheme.onBackground.withOpacity(0.2),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'No recent transactions',
                                style: TextStyle(
                                  color: theme.colorScheme.onBackground.withOpacity(0.4),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: transProvider.recentTransactions.length,
                        itemBuilder: (context, index) {
                          final item = transProvider.recentTransactions[index];
                          final isExpense = item['type'] == 'expense';
                          final date = DateTime.parse(item['date']);

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: isExpense
                                    ? theme.colorScheme.error.withOpacity(0.1)
                                    : theme.colorScheme.success.withOpacity(0.1),
                                child: Icon(
                                  isExpense ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                                  color: isExpense ? theme.colorScheme.error : theme.colorScheme.success,
                                ),
                              ),
                              title: Text(
                                item['title'],
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                              subtitle: Text(
                                '${item['category']} • ${DateFormat('MMM dd, yyyy').format(date)}',
                                style: const TextStyle(fontSize: 12),
                              ),
                              trailing: Text(
                                '${isExpense ? '-' : '+'}$currency${item['amount']}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: isExpense ? theme.colorScheme.error : theme.colorScheme.success,
                                ),
                              ),
                              onTap: () {
                                if (isExpense) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => ExpenseDetailScreen(
                                        expenseId: item['id'],
                                      ),
                                    ),
                                  ).then((_) {
                                    transProvider.fetchDashboardMetrics();
                                  });
                                } else {
                                  // For income, go to edit screen
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => AddEditIncomeScreen(
                                        incomeId: item['id'],
                                        prefilledTitle: item['title'],
                                        prefilledAmount: (item['amount'] as num).toDouble(),
                                        prefilledDate: date,
                                      ),
                                    ),
                                  ).then((_) {
                                    transProvider.fetchDashboardMetrics();
                                  });
                                }
                              },
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
      ),
    );
  }
}

class _OverviewMiniCard extends StatelessWidget {
  final String title;
  final double amount;
  final IconData icon;
  final Color iconColor;
  final String currency;

  const _OverviewMiniCard({
    required this.title,
    required this.amount,
    required this.icon,
    required this.iconColor,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: theme.colorScheme.onBackground.withOpacity(0.04),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 18),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.onBackground.withOpacity(0.5),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '$currency${amount.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _SavingsCard extends StatelessWidget {
  final double savings;
  final String currency;

  const _SavingsCard({required this.savings, required this.currency});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.1),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.savings_rounded,
            color: theme.colorScheme.primary,
            size: 24,
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'This Month\'s Savings',
                style: TextStyle(
                  fontSize: 11,
                  color: theme.colorScheme.onBackground.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '$currency${savings.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
