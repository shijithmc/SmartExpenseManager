import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class SpendingTrendChart extends StatelessWidget {
  final Map<String, double> last7DaysSpending;

  const SpendingTrendChart({super.key, required this.last7DaysSpending});

  @override
  Widget build(BuildContext context) {
    if (last7DaysSpending.isEmpty) {
      return const Center(child: Text('No data'));
    }

    final entries = last7DaysSpending.entries.toList();
    final maxVal = last7DaysSpending.values.fold(0.0, (a, b) => a > b ? a : b);
    final primary = Theme.of(context).colorScheme.primary;

    return SizedBox(
      height: 160,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxVal > 0 ? maxVal * 1.2 : 100,
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                return BarTooltipItem(
                  '\$${rod.toY.toStringAsFixed(0)}',
                  TextStyle(
                      color: primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 12),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final idx = value.toInt();
                  if (idx >= 0 && idx < entries.length) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(entries[idx].key,
                          style: TextStyle(
                              fontSize: 10, color: Colors.grey.shade500)),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ),
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          barGroups: entries.asMap().entries.map((e) {
            final isToday = e.key == entries.length - 1;
            return BarChartGroupData(
              x: e.key,
              barRods: [
                BarChartRodData(
                  toY: e.value.value,
                  color: isToday ? primary : primary.withAlpha(100),
                  width: 20,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}
