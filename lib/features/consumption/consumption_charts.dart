import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';

class MonthlyBars extends StatelessWidget {
  const MonthlyBars({super.key, required this.labels, required this.values, this.height = 190});
  final List<String> labels;
  final List<double> values;
  final double height;

  @override
  Widget build(BuildContext context) {
    final maxY = (values.fold<double>(0, (a, b) => a > b ? a : b) * 1.25).clamp(10, double.infinity);
    return SizedBox(
      height: height,
      child: BarChart(
        BarChartData(
          maxY: maxY.toDouble(),
          minY: 0,
          gridData: const FlGridData(show: true, drawVerticalLine: false),
          borderData: FlBorderData(show: false),
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => AppColors.navyDeep,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                return BarTooltipItem(formatKwh(rod.toY), const TextStyle(color: Colors.white, fontWeight: FontWeight.w600));
              },
            ),
          ),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= labels.length) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(labels[index], style: const TextStyle(fontSize: 10, color: AppColors.muted)),
                  );
                },
              ),
            ),
          ),
          barGroups: [
            for (var i = 0; i < values.length; i++)
              BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: values[i],
                    width: values.length > 8 ? 10 : 16,
                    color: i == values.length - 1 ? AppColors.orange : AppColors.navy,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class DailyLine extends StatelessWidget {
  const DailyLine({super.key, required this.values, this.height = 210});
  final List<double> values;
  final double height;

  @override
  Widget build(BuildContext context) {
    final maxY = (values.fold<double>(0, (a, b) => a > b ? a : b) * 1.3).clamp(1, double.infinity);
    return SizedBox(
      height: height,
      child: LineChart(
        LineChartData(
          minY: 0,
          maxY: maxY.toDouble(),
          gridData: const FlGridData(show: true, drawVerticalLine: false),
          borderData: FlBorderData(show: false),
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (_) => AppColors.navyDeep,
              getTooltipItems: (spots) {
                return [
                  for (final spot in spots)
                    LineTooltipItem(formatKwh(spot.y), const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                ];
              },
            ),
          ),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: values.length > 20 ? 5 : 4,
                reservedSize: 28,
                getTitlesWidget: (value, meta) {
                  final day = value.toInt() + 1;
                  if (day < 1 || day > values.length) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text('$day', style: const TextStyle(fontSize: 10, color: AppColors.muted)),
                  );
                },
              ),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: [for (var i = 0; i < values.length; i++) FlSpot(i.toDouble(), values[i])],
              isCurved: true,
              color: AppColors.orange,
              barWidth: 3,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(show: true, color: AppColors.orange.withValues(alpha: 0.14)),
            ),
          ],
        ),
      ),
    );
  }
}
