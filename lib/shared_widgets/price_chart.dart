import 'dart:math';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:tradingpro/core/theme/app_colors.dart';

class PriceChartWidget extends StatelessWidget {
  final double currentPrice;
  final double percentageChange;
  final bool isPositive;
  final double height;
  final bool showAxes;
  final List<FlSpot>? customSpots;

  const PriceChartWidget({
    super.key,
    required this.currentPrice,
    required this.percentageChange,
    required this.isPositive,
    this.height = 180,
    this.showAxes = true,
    this.customSpots,
  });

  List<FlSpot> _generateSimulatedSpots() {
    if (customSpots != null && customSpots!.isNotEmpty) {
      return customSpots!;
    }

    final spots = <FlSpot>[];
    final random = Random((currentPrice * 100).toInt());
    const count = 12;
    final base = isPositive
        ? currentPrice / (1 + (percentageChange.abs() / 100))
        : currentPrice / (1 - (percentageChange.abs() / 100));

    final diff = currentPrice - base;

    for (int i = 0; i < count; i++) {
      final progress = i / (count - 1);
      final jitter = (random.nextDouble() - 0.5) * (diff.abs() * 0.4);
      final val = base + (diff * progress) + jitter;
      spots.add(FlSpot(i.toDouble(), val));
    }
    // Ensure final spot matches currentPrice
    spots[count - 1] = FlSpot((count - 1).toDouble(), currentPrice);
    return spots;
  }

  @override
  Widget build(BuildContext context) {
    final spots = _generateSimulatedSpots();
    final primaryColor = isPositive ? AppColors.positive : AppColors.negative;

    final minY = spots.map((s) => s.y).reduce(min);
    final maxY = spots.map((s) => s.y).reduce(max);
    final padding = (maxY - minY) * 0.1;

    return SizedBox(
      height: height,
      child: LineChart(
        LineChartData(
          minY: (minY - padding).clamp(0, double.infinity),
          maxY: maxY + padding,
          gridData: FlGridData(
            show: showAxes,
            drawVerticalLine: false,
            horizontalInterval: (maxY - minY) > 0 ? (maxY - minY) / 3 : 1,
            getDrawingHorizontalLine: (value) => FlLine(
              color: AppColors.divider.withOpacity(0.5),
              strokeWidth: 1,
            ),
          ),
          titlesData: FlTitlesData(
            show: showAxes,
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: showAxes,
                reservedSize: 22,
                interval: 3,
                getTitlesWidget: (value, meta) {
                  final hours = ['24h', '18h', '12h', '6h', 'Now'];
                  final idx = (value / 3).round().clamp(0, hours.length - 1);
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      hours[idx],
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.textTertiary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: showAxes,
                reservedSize: 45,
                getTitlesWidget: (value, meta) {
                  return Text(
                    '\$${value.toStringAsFixed(value < 10 ? 2 : 0)}',
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.textTertiary,
                      fontWeight: FontWeight.w500,
                    ),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          lineTouchData: LineTouchData(
            handleBuiltInTouches: true,
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((spot) {
                  return LineTooltipItem(
                    '\$${spot.y.toStringAsFixed(2)}',
                    const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  );
                }).toList();
              },
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              curveSmoothness: 0.35,
              color: primaryColor,
              barWidth: 2.5,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    primaryColor.withOpacity(0.25),
                    primaryColor.withOpacity(0.0),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MiniSparkline extends StatelessWidget {
  final double currentPrice;
  final bool isPositive;
  final double width;
  final double height;

  const MiniSparkline({
    super.key,
    required this.currentPrice,
    required this.isPositive,
    this.width = 60,
    this.height = 28,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: PriceChartWidget(
        currentPrice: currentPrice,
        percentageChange: isPositive ? 2.5 : -2.5,
        isPositive: isPositive,
        height: height,
        showAxes: false,
      ),
    );
  }
}
