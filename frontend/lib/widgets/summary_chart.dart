import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/category.dart';
import '../theme/app_theme.dart';

class SummaryChart extends StatelessWidget {
  final Map<String, double> expensesByCategory;

  const SummaryChart({super.key, required this.expensesByCategory});

  @override
  Widget build(BuildContext context) {
    if (expensesByCategory.isEmpty) {
      return const Center(child: Text('No data to display'));
    }

    final total = expensesByCategory.values.fold(0.0, (a, b) => a + b);
    final sortedEntries = expensesByCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 500;

        if (isMobile) {
          return _buildCategoryCards(context, sortedEntries, total);
        }

        return Row(
          children: [
            Expanded(
              flex: 3,
              child: _buildPieChart(sortedEntries, total, 60, 40),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 2,
              child: _buildLegendColumn(sortedEntries, total),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCategoryCards(BuildContext context,
      List<MapEntry<String, double>> entries, double total) {
    final maxAmount = entries.first.value;

    return SizedBox(
      height: 140,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        itemCount: entries.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final entry = entries[index];
          final color = ExpenseCategory.getCategoryColor(entry.key);
          final iconName = ExpenseCategory.defaults
                  .where((c) => c.name == entry.key)
                  .firstOrNull
                  ?.icon ??
              'more_horiz';
          final pct = (entry.value / total * 100).toStringAsFixed(0);
          final progressRatio = maxAmount > 0 ? entry.value / maxAmount : 0.0;

          return Container(
            width: 140,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color ?? Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: AppTokens.shadowLow,

            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: color.withAlpha(30),
                  child: Icon(
                    ExpenseCategory.getIcon(iconName),
                    color: color,
                    size: 16,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  entry.key,
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w500),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                const SizedBox(height: 2),
                Text(
                  '\$${entry.value.toStringAsFixed(0)} ($pct%)',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
                const Spacer(),
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: progressRatio.clamp(0.0, 1.0),
                    minHeight: 3,
                    backgroundColor: color.withAlpha(30),
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPieChart(List<MapEntry<String, double>> entries, double total,
      double radius, double centerRadius) {
    return PieChart(
      PieChartData(
        sectionsSpace: 2,
        centerSpaceRadius: centerRadius,
        sections: entries.map((entry) {
          final percentage = (entry.value / total * 100);
          return PieChartSectionData(
            value: entry.value,
            title: percentage >= 5 ? '${percentage.toStringAsFixed(0)}%' : '',
            color: ExpenseCategory.getCategoryColor(entry.key),
            radius: radius,
            titleStyle: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.white),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildLegendColumn(
      List<MapEntry<String, double>> entries, double total) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: entries.take(6).map((entry) {
        final pct = (entry.value / total * 100).toStringAsFixed(0);
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: ExpenseCategory.getCategoryColor(entry.key),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '$pct% ${entry.key}',
                  style: const TextStyle(fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
