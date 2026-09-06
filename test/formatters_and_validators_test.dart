import 'package:flutter_test/flutter_test.dart';
import 'package:tradingpro/core/utils/app_formatters.dart';
import 'package:tradingpro/core/utils/app_validators.dart';

void main() {
  group('AppFormatters Tests', () {
    test('Currency formatting', () {
      expect(AppFormatters.currency(1250.0), '\$1,250.00');
      expect(AppFormatters.currency(0.0), '\$0.00');
      expect(AppFormatters.currency(58.5), '\$58.50');
    });

    test('Profit / Signed currency formatting', () {
      expect(AppFormatters.currencyWithSign(250.0), '+\$250.00');
      expect(AppFormatters.currencyWithSign(-50.0), '-\$50.00');
      expect(AppFormatters.currencyWithSign(0.0), '+\$0.00');
    });

    test('Crypto price formatting', () {
      expect(AppFormatters.cryptoPrice(77424.05), '77,424.05');
      expect(AppFormatters.cryptoPrice(1.5798), '1.5798');
      expect(AppFormatters.cryptoPrice(0.09115), '0.09115');
    });

    test('Percentage change formatting', () {
      expect(AppFormatters.percentageChange(1.48), '+1.48%');
      expect(AppFormatters.percentageChange(-3.08), '-3.08%');
    });
  });

  group('AppValidators Tests', () {
    test('Email validation', () {
      expect(AppValidators.email(''), 'Email is required');
      expect(AppValidators.email('invalid-email'), 'Enter a valid email address');
      expect(AppValidators.email('dummy@gmail.com'), 'Please enter your real email address');
      expect(AppValidators.email('test@gmail.com'), 'Please enter your real email address');
      expect(AppValidators.email('someone@mailinator.com'), 'Disposable email addresses are not allowed');
      expect(AppValidators.email('trader.pro@tradingpro.com'), null);
      expect(AppValidators.email('john.doe@gmail.com'), null);
    });

    test('Password validation', () {
      expect(AppValidators.password(''), 'Password is required');
      expect(AppValidators.password('1234567'), 'Password must be at least 8 characters');
      expect(AppValidators.password('Secret1234!'), null);
    });

    test('Withdrawal amount validation', () {
      const availableBalance = 1250.0;
      const minWithdrawal = 50.0;

      expect(
        AppValidators.withdrawalAmount('20', availableBalance, minWithdrawal),
        'Minimum withdrawal is \$50.00',
      );
      expect(
        AppValidators.withdrawalAmount('2000', availableBalance, minWithdrawal),
        'Insufficient balance',
      );
      expect(
        AppValidators.withdrawalAmount('100', availableBalance, minWithdrawal),
        null,
      );
    });
  });
}
