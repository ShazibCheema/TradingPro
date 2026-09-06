import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:tradingpro/services/connectivity_service.dart';

void main() {
  group('Connectivity Service Tests', () {
    test('isOnlineProvider defaults to true when connected to wifi', () async {
      final container = ProviderContainer(
        overrides: [
          connectivityStreamProvider.overrideWith(
            (ref) => Stream.value([ConnectivityResult.wifi]),
          ),
        ],
      );

      // Wait for stream to emit value
      await container.read(connectivityStreamProvider.future);

      final isOnline = container.read(isOnlineProvider);
      expect(isOnline, isTrue);
    });

    test('isOnlineProvider evaluates to false when connectivity is none', () async {
      final container = ProviderContainer(
        overrides: [
          connectivityStreamProvider.overrideWith(
            (ref) => Stream.value([ConnectivityResult.none]),
          ),
        ],
      );

      // Wait for stream to emit value
      await container.read(connectivityStreamProvider.future);

      final isOnline = container.read(isOnlineProvider);
      expect(isOnline, isFalse);
    });

    test('isOnlineProvider evaluates to true on mobile data', () async {
      final container = ProviderContainer(
        overrides: [
          connectivityStreamProvider.overrideWith(
            (ref) => Stream.value([ConnectivityResult.mobile]),
          ),
        ],
      );

      // Wait for stream to emit value
      await container.read(connectivityStreamProvider.future);

      final isOnline = container.read(isOnlineProvider);
      expect(isOnline, isTrue);
    });
  });
}
