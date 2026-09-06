import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart';

class AppCheckService {
  static Future<void> initialize() async {
    try {
      // In debug/emulator builds we use the debug provider.
      // In production builds, use Play Integrity (Android) / DeviceCheck (iOS).
      await FirebaseAppCheck.instance.activate(
        androidProvider:
            kDebugMode ? AndroidProvider.debug : AndroidProvider.playIntegrity,
        appleProvider:
            kDebugMode ? AppleProvider.debug : AppleProvider.deviceCheck,
        webProvider: ReCaptchaV3Provider('recaptcha-v3-site-key'),
      );
      debugPrint('[AppCheck] Activated (debug=$kDebugMode)');
    } catch (e) {
      // App Check failure is non-fatal — app continues to function.
      // In development this is expected if the debug token isn't registered.
      debugPrint('[AppCheck] Skipped: $e');
    }
  }
}

