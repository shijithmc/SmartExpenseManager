import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/category.dart';

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
          return Column(
            children: [
              SizedBox(
                height: 160,
                child: _buildPieChart(sortedEntries, total, 45, 30),
              ),
              const SizedBox(height: 12),
              _buildLegendWrap(sortedEntries, total),
            ],
          );
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

  Widget _buildLegendWrap(
      List<MapEntry<String, double>> entries, double total) {
    return Wrap(
      spacing: 12,
      runSpacing: 6,
      alignment: WrapAlignment.center,
      children: entries.take(6).map((entry) {
        final pct = (entry.value / total * 100).toStringAsFixed(0);
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: ExpenseCategory.getCategoryColor(entry.key),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              '${entry.key} $pct%',
              style: const TextStyle(fontSize: 11),
            ),
          ],
        );
      }).toList(),
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
