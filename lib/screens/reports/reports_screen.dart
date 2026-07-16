import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/skeleton_loader.dart';
import '../../config/theme.dart';


class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _periods = ['daily', 'weekly', 'monthly', 'yearly'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _periods.length, vsync: this);
    _tabController.addListener(_handleTabSelection);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchData();
    });
  }

  void _handleTabSelection() {
    if (_tabController.indexIsChanging) {
      _fetchData();
    }
  }

  void _fetchData() {
    final period = _periods[_tabController.index];
    Provider.of<TransactionProvider>(context, listen: false).fetchReportsData(period);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final transProvider = Provider.of<TransactionProvider>(context);
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final currency = settingsProvider.currency;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Financial Analytics'),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: theme.colorScheme.primary,
          labelColor: theme.colorScheme.primary,
          unselectedLabelColor: theme.colorScheme.onSurface.withValues(alpha: 0.5),
          tabs: const [
            Tab(text: 'Daily'),
            Tab(text: 'Weekly'),
            Tab(text: 'Monthly'),
            Tab(text: 'Yearly'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: List.generate(
          _periods.length,
          (index) {
            if (transProvider.isLoading) {
              return const Padding(
                padding: EdgeInsets.all(24.0),
                child: SkeletonLoader(),
              );
            }

            final totalExp = transProvider.reportTotalExpense;
            final totalInc = transProvider.reportTotalIncome;
            final categories = transProvider.reportCategoryWiseExpenses;
            final chartPoints = transProvider.reportChartPoints;

            if (totalExp == 0 && totalInc == 0) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.pie_chart_outline_rounded,
                      size: 72,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.15),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No reports data available',
                      style: TextStyle(
                        fontSize: 16,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                      ),
                    ),
                  ],
                ),
              );
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Overview stats
                  Row(
                    children: [
                      Expanded(
                        child: _StatBox(
                          title: 'Total Income',
                          amount: totalInc,
                          color: theme.colorScheme.success,
                          currency: currency,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _StatBox(
                          title: 'Total Expense',
                          amount: totalExp,
                          color: theme.colorScheme.error,
                          currency: currency,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),

                  // Income vs Expense Graph (Bar Chart)
                  if (chartPoints.isNotEmpty) ...[
                    const Text(
                      'Cash Flow Overview',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      height: 220,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.cardTheme.color,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: BarChart(
                        BarChartData(
                          alignment: BarChartAlignment.spaceAround,
                          maxY: _getMaxY(chartPoints),
                          barTouchData: BarTouchData(enabled: true),
                          titlesData: FlTitlesData(
                            show: true,
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (double value, TitleMeta meta) {
                                  final int idx = value.toInt();
                                  if (idx >= 0 && idx < chartPoints.length) {
                                    final label = chartPoints[idx]['label'] as String;
                                    // Parse label to show month short name if label matches YYYY-MM
                                    final displayLabel = label.contains('-') ? label.split('-').last : label;
                                    return SideTitleWidget(
                                      axisSide: meta.axisSide,
                                      child: Text(
                                        displayLabel,
                                        style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold),
                                      ),
                                    );
                                  }
                                  return const Text('');
                                },
                              ),
                            ),
                            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          ),
                          gridData: const FlGridData(show: false),
                          borderData: FlBorderData(show: false),
                          barGroups: List.generate(
                            chartPoints.length,
                            (idx) {
                              final pt = chartPoints[idx];
                              return BarChartGroupData(
                                x: idx,
                                barRods: [
                                  BarChartRodData(
                                    toY: (pt['income'] as num).toDouble(),
                                    color: theme.colorScheme.success,
                                    width: 8,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  BarChartRodData(
                                    toY: (pt['expense'] as num).toDouble(),
                                    color: theme.colorScheme.error,
                                    width: 8,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                  ],

                  // Pie Chart split
                  if (categories.isNotEmpty) ...[
                    const Text(
                      'Expense Category Breakdown',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        // Chart
                        Expanded(
                          flex: 4,
                          child: SizedBox(
                            height: 160,
                            child: PieChart(
                              PieChartData(
                                sectionsSpace: 2,
                                centerSpaceRadius: 35,
                                sections: List.generate(
                                  categories.length,
                                  (idx) {
                                    final cat = categories[idx];
                                    return PieChartSectionData(
                                      color: _getCategoryColor(cat['category']),
                                      value: (cat['amount'] as num).toDouble(),
                                      title: '${cat['percentage']}%',
                                      radius: 40,
                                      titleStyle: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),
                        ),
                        
                        // Legends
                        Expanded(
                          flex: 5,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: categories.map((cat) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4.0),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 12,
                                      height: 12,
                                      decoration: BoxDecoration(
                                        color: _getCategoryColor(cat['category']),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        cat['category'],
                                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Text(
                                      '$currency${cat['amount']}',
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // List breakdown
                    const Text(
                      'Detailed Splitting',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: categories.length,
                      itemBuilder: (context, idx) {
                        final cat = categories[idx];
                        final color = _getCategoryColor(cat['category']);
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: color.withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(_getCategoryIcon(cat['category']), color: color, size: 18),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Text(
                                    cat['category'],
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '$currency${cat['amount']}',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                    ),
                                    Text(
                                      '${cat['percentage']}% of expenses',
                                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  double _getMaxY(List<Map<String, dynamic>> points) {
    double maxVal = 100.0;
    for (var pt in points) {
      final inc = (pt['income'] as num).toDouble();
      final exp = (pt['expense'] as num).toDouble();
      if (inc > maxVal) maxVal = inc;
      if (exp > maxVal) maxVal = exp;
    }
    return maxVal * 1.15; // Give 15% headroom
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Food':
        return Colors.orangeAccent;
      case 'Shopping':
        return Colors.purpleAccent;
      case 'Bills':
        return Colors.blueAccent;
      case 'Travel':
        return Colors.teal;
      case 'Education':
        return Colors.indigoAccent;
      case 'Entertainment':
        return Colors.pinkAccent;
      case 'Health':
        return Colors.greenAccent;
      default:
        return Colors.grey;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Food':
        return Icons.restaurant;
      case 'Shopping':
        return Icons.shopping_bag_outlined;
      case 'Bills':
        return Icons.electrical_services_rounded;
      case 'Travel':
        return Icons.directions_car_filled_rounded;
      case 'Education':
        return Icons.school_rounded;
      case 'Entertainment':
        return Icons.movie_filter_rounded;
      case 'Health':
        return Icons.health_and_safety_rounded;
      default:
        return Icons.widgets_rounded;
    }
  }
}

class _StatBox extends StatelessWidget {
  final String title;
  final double amount;
  final Color color;
  final String currency;

  const _StatBox({
    required this.title,
    required this.amount,
    required this.color,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$currency${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
