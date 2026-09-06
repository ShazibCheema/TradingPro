import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

class AnalyticsService {
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  FirebaseAnalyticsObserver get analyticsObserver =>
      FirebaseAnalyticsObserver(analytics: _analytics);

  Future<void> logScreenView(String screenName) async {
    try {
      await _analytics.logScreenView(screenName: screenName);
    } catch (e) {
      debugPrint('Analytics screen view error: $e');
    }
  }

  Future<void> logLogin(String method) async {
    try {
      await _analytics.logLogin(loginMethod: method);
    } catch (e) {
      debugPrint('Analytics login error: $e');
    }
  }

  Future<void> logSignUp(String method) async {
    try {
      await _analytics.logSignUp(signUpMethod: method);
    } catch (e) {
      debugPrint('Analytics sign up error: $e');
    }
  }

  Future<void> logDepositSubmitted({
    required double amount,
    required String asset,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'deposit_submitted',
        parameters: {
          'amount': amount,
          'asset': asset,
          'currency': 'USD',
        },
      );
    } catch (e) {
      debugPrint('Analytics deposit error: $e');
    }
  }

  Future<void> logWithdrawalRequested({
    required double amount,
    required String asset,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'withdrawal_requested',
        parameters: {
          'amount': amount,
          'asset': asset,
          'currency': 'USD',
        },
      );
    } catch (e) {
      debugPrint('Analytics withdrawal error: $e');
    }
  }

  Future<void> logTradeExecuted({
    required String symbol,
    required double investmentAmount,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'trade_executed',
        parameters: {
          'symbol': symbol,
          'investment_amount': investmentAmount,
        },
      );
    } catch (e) {
      debugPrint('Analytics trade error: $e');
    }
  }
}
