import 'package:tradingpro/models/transaction_model.dart';

class ExportService {
  /// Generate a clean CSV string from a list of user transactions
  static String generateTransactionsCsv({
    required String userName,
    required String userId7,
    required List<TransactionModel> transactions,
  }) {
    final buffer = StringBuffer();
    // CSV Header with metadata
    buffer.writeln('# TradingPro: I&T — Financial Account Statement');
    buffer.writeln('# Account Holder: $userName');
    buffer.writeln('# 7-Digit ID: $userId7');
    buffer.writeln('# Export Date: ${DateTime.now().toUtc().toIso8601String()}');
    buffer.writeln('');
    buffer.writeln(
        'Transaction ID,Type,Direction,Amount (USD),Balance Before,Balance After,Description,Reference ID,Date (UTC)');

    for (final tx in transactions) {
      final sanitizedDesc = tx.description.replaceAll(',', ';');
      buffer.writeln(
        '${tx.transactionId},'
        '${tx.type.name},'
        '${tx.direction.name},'
        '${tx.amount.toStringAsFixed(2)},'
        '${tx.balanceBefore.toStringAsFixed(2)},'
        '${tx.balanceAfter.toStringAsFixed(2)},'
        '"$sanitizedDesc",'
        '${tx.referenceId ?? "N/A"},'
        '${tx.createdAt.toUtc().toIso8601String()}',
      );
    }

    return buffer.toString();
  }
}
