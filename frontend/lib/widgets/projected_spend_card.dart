import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ProjectedSpendCard extends StatelessWidget {
  final double totalThisMonth;
  final double dailyAverage;
  final double projectedMonthlySpend;
  final int daysElapsed;
  final int daysInMonth;

  const ProjectedSpendCard({
    super.key,
    required this.totalThisMonth,
    required this.dailyAverage,
    required this.projectedMonthlySpend,
    required this.daysElapsed,
    required this.daysInMonth,
  });

  @override
  Widget build(BuildContext context) {
    final progress = daysInMonth > 0 ? daysElapsed / daysInMonth : 0.0;
    final spendRatio =
        projectedMonthlySpend > 0 ? totalThisMonth / projectedMonthlySpend : 0.0;

    // Color logic based on projected vs actual pace
    Color accentColor;
    String paceText;
    if (totalThisMonth == 0) {
      accentColor = Colors.grey;
      paceText = 'No expenses yet';
    } else if (spendRatio < 0.8) {
      accentColor = const Color(0xFF4CAF50); // green
      paceText = 'Below average pace';
    } else if (spendRatio <= 1.0) {
      accentColor = const Color(0xFFFFA726); // amber
      paceText = 'On track';
    } else {
      accentColor = const Color(0xFFEF5350); // red
      paceText = 'Above average pace';
    }

    final monthName = DateFormat('MMMM yyyy').format(DateTime.now());

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: accentColor.withAlpha(60)),
      ),
      color: accentColor.withAlpha(15),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  monthName,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: accentColor, fontWeight: FontWeight.w600),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: accentColor.withAlpha(30),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Day $daysElapsed of $daysInMonth',
                    style: TextStyle(
                        fontSize: 12,
                        color: accentColor,
                        fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '\$${totalThisMonth.toStringAsFixed(2)}',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface),
            ),
            const SizedBox(height: 4),
            Text(
              'spent this month',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Colors.grey),
            ),
            const SizedBox(height: 16),

            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: progress.clamp(0.0, 1.0),
                minHeight: 8,
                backgroundColor: accentColor.withAlpha(30),
                valueColor: AlwaysStoppedAnimation<Color>(accentColor),
              ),
            ),
            const SizedBox(height: 12),

            // Bottom stats row
            Row(
              children: [
                Expanded(
                  child: _StatItem(
                    label: 'Daily avg',
                    value: '\$${dailyAverage.toStringAsFixed(2)}',
                    icon: Icons.trending_up,
                    color: accentColor,
                  ),
                ),
                Container(width: 1, height: 32, color: Colors.grey.withAlpha(50)),
                Expanded(
                  child: _StatItem(
                    label: 'Projected',
                    value: '\$${projectedMonthlySpend.toStringAsFixed(0)}',
                    icon: Icons.calendar_month,
                    color: accentColor,
                  ),
                ),
                Container(width: 1, height: 32, color: Colors.grey.withAlpha(50)),
                Expanded(
                  child: _StatItem(
                    label: 'Pace',
                    value: paceText,
                    icon: Icons.speed,
                    color: accentColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
              fontSize: 12, fontWeight: FontWeight.w600, color: color),
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          label,
          style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
        ),
      ],
    );
  }
}
