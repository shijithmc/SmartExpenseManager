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

    return SizedBox(
      height: 180,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxVal > 0 ? maxVal * 1.3 : 100,
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                return BarTooltipItem(
                  '\$${rod.toY.toStringAsFixed(0)}',
                  const TextStyle(
                      color: Color(0xFF6366F1),
                      fontWeight: FontWeight.w600,
                      fontSize: 12),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            topTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 24,
                getTitlesWidget: (value, meta) {
                  final idx = value.toInt();
                  if (idx >= 0 && idx < entries.length) {
                    final amount = entries[idx].value;
                    if (amount > 0) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          '\$${amount.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: 9,
                            color: Colors.grey.shade500,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    }
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
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
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: isToday
                        ? [const Color(0xFF6366F1), const Color(0xFF8B5CF6)]
                        : [
                            const Color(0xFF6366F1).withAlpha(102),
                            const Color(0xFF8B5CF6).withAlpha(102),
                          ],
                  ),
                  width: 24,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}
