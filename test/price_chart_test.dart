import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tradingpro/core/theme/app_theme.dart';
import 'package:tradingpro/shared_widgets/price_chart.dart';

void main() {
  testWidgets('PriceChartWidget renders positive price trend correctly',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: const Scaffold(
          body: PriceChartWidget(
            currentPrice: 77500.0,
            percentageChange: 3.45,
            isPositive: true,
            height: 200,
          ),
        ),
      ),
    );

    expect(find.byType(PriceChartWidget), findsOneWidget);
  });

  testWidgets('MiniSparkline renders compact view',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: const Scaffold(
          body: MiniSparkline(
            currentPrice: 3400.0,
            isPositive: false,
          ),
        ),
      ),
    );

    expect(find.byType(MiniSparkline), findsOneWidget);
  });
}
