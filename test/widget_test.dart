import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tradingpro/core/theme/app_theme.dart';
import 'package:tradingpro/shared_widgets/app_widgets.dart';

void main() {
  testWidgets('StatusBadge and UI Component test', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: const Scaffold(
          body: Column(
            children: [
              StatusBadge(label: 'ACTIVE', type: StatusType.success),
              StatusBadge(label: 'PENDING', type: StatusType.pending),
              StatusBadge(label: 'SUSPENDED', type: StatusType.error),
            ],
          ),
        ),
      ),
    );

    expect(find.text('ACTIVE'), findsOneWidget);
    expect(find.text('PENDING'), findsOneWidget);
    expect(find.text('SUSPENDED'), findsOneWidget);
  });

  testWidgets('PrimaryButton renders and triggers callback', (WidgetTester tester) async {
    bool tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: PrimaryButton(
            label: 'Submit Deposit',
            onPressed: () {
              tapped = true;
            },
          ),
        ),
      ),
    );

    expect(find.text('Submit Deposit'), findsOneWidget);
    await tester.tap(find.text('Submit Deposit'));
    await tester.pump();
    expect(tapped, isTrue);
  });
}
