import 'package:flutter_test/flutter_test.dart';
import 'package:tradingpro/core/constants/app_constants.dart';
import 'package:tradingpro/router/user_router.dart';

void main() {
  group('Router & Navigation Constants Tests', () {
    test('AppRoutes constants match specified paths', () {
      expect(AppRoutes.login, '/login');
      expect(AppRoutes.register, '/register');
      expect(AppRoutes.home, '/home');
      expect(AppRoutes.account, '/account');
      expect(AppRoutes.inbox, '/inbox');
      expect(AppRoutes.profile, '/profile');
      expect(AppRoutes.deposit, '/deposit');
      expect(AppRoutes.withdrawal, '/withdrawal');
      expect(AppRoutes.trading, '/trading');
      expect(AppRoutes.market, '/market');
      expect(AppRoutes.support, '/support');
    });

    test('AppConstants collection names and limits', () {
      expect(AppConstants.usersCollection, 'users');
      expect(AppConstants.coinsCollection, 'coins');
      expect(AppConstants.depositsSubCollection, 'deposits');
      expect(AppConstants.withdrawalsSubCollection, 'withdrawals');
      expect(AppConstants.tradesSubCollection, 'trades');
      expect(AppConstants.transactionsSubCollection, 'transactions');
      expect(AppConstants.notificationsSubCollection, 'notifications');
      expect(AppConstants.displayCurrency, 'USD');
      expect(AppConstants.displayCurrencySymbol, '\$');
      expect(AppConstants.maxFeaturedCoins, 3);
    });
  });
}
