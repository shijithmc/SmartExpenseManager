import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;
import '../theme/app_theme.dart';

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
    final monthName = DateFormat('MMMM yyyy').format(DateTime.now());

    String paceText;
    final spendRatio =
        projectedMonthlySpend > 0 ? totalThisMonth / projectedMonthlySpend : 0.0;
    if (totalThisMonth == 0) {
      paceText = 'No expenses yet';
    } else if (spendRatio < 0.8) {
      paceText = 'Below average';
    } else if (spendRatio <= 1.0) {
      paceText = 'On track';
    } else {
      paceText = 'Above average';
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppTokens.primaryGradient,
        borderRadius: BorderRadius.circular(AppTokens.radiusXl),
        boxShadow: AppTokens.shadowMedium,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  monthName,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '\$${totalThisMonth.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'spent this month',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _WhiteStat(
                      label: 'Daily avg',
                      value: '\$${dailyAverage.toStringAsFixed(2)}',
                    ),
                    const SizedBox(width: 20),
                    _WhiteStat(
                      label: 'Projected',
                      value: '\$${projectedMonthlySpend.toStringAsFixed(0)}',
                    ),
                    const SizedBox(width: 20),
                    _WhiteStat(
                      label: 'Pace',
                      value: paceText,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          SizedBox(
            width: 56,
            height: 56,
            child: CustomPaint(
              painter: _ProgressRingPainter(progress: progress.clamp(0.0, 1.0)),
              child: Center(
                child: Text(
                  '${(progress * 100).toInt()}%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WhiteStat extends StatelessWidget {
  final String label;
  final String value;

  const _WhiteStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}

class _ProgressRingPainter extends CustomPainter {
  final double progress;

  _ProgressRingPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 2;
    const strokeWidth = 4.0;

    // Background ring
    final bgPaint = Paint()
      ..color = Colors.white.withAlpha(51)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);

    // Progress arc
    final fgPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      progress * 2 * math.pi,
      false,
      fgPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _ProgressRingPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
