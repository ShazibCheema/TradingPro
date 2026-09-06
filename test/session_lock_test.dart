import 'package:flutter_test/flutter_test.dart';
import 'package:tradingpro/services/session_lock_service.dart';

void main() {
  group('SessionLockService Tests', () {
    test('Session starts unlocked', () {
      final notifier = SessionLockNotifier();
      expect(notifier.state, isFalse);
    });

    test('unlockSession resets locked state to false', () {
      final notifier = SessionLockNotifier();
      notifier.state = true;
      expect(notifier.state, isTrue);

      notifier.unlockSession();
      expect(notifier.state, isFalse);
    });

    test('setEnabled(false) cancels lock and unlocks state', () {
      final notifier = SessionLockNotifier();
      notifier.state = true;

      notifier.setEnabled(false);
      expect(notifier.state, isFalse);
    });
  });
}
