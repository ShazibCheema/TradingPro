import 'package:flutter_test/flutter_test.dart';
import 'package:tradingpro/models/transaction_model.dart';
import 'package:tradingpro/services/export_service.dart';

void main() {
  group('ExportService Tests', () {
    test('generateTransactionsCsv produces valid formatted CSV string', () {
      final List<TransactionModel> transactions = [
        TransactionModel(
          transactionId: 'TX_1001',
          userId: 'USER_1',
          type: TransactionType.deposit,
          direction: TransactionDirection.credit,
          amount: 500.0,
          asset: 'USDT',
          balanceBefore: 0.0,
          balanceAfter: 500.0,
          description: 'USDT Deposit Approved',
          createdAt: DateTime.utc(2026, 8, 27, 10, 0),
          referenceId: 'DEP_999',
        ),
        TransactionModel(
          transactionId: 'TX_1002',
          userId: 'USER_1',
          type: TransactionType.profit,
          direction: TransactionDirection.credit,
          amount: 50.0,
          asset: 'USD',
          balanceBefore: 500.0,
          balanceAfter: 550.0,
          description: 'Weekly Performance Profit',
          createdAt: DateTime.utc(2026, 8, 27, 12, 0),
        ),
      ];

      final csv = ExportService.generateTransactionsCsv(
        userName: 'Alex Mercer',
        userId7: '8492013',
        transactions: transactions,
      );

      expect(csv.contains('# Account Holder: Alex Mercer'), isTrue);
      expect(csv.contains('# 7-Digit ID: 8492013'), isTrue);
      expect(csv.contains('TX_1001,deposit,credit,500.00,0.00,500.00'), isTrue);
      expect(csv.contains('TX_1002,profit,credit,50.00,500.00,550.00'), isTrue);
    });
  });
}
