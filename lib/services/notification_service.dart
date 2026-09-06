import 'dart:io';
import 'dart:ui';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:tradingpro/repositories/user_repository.dart';

// Top-level background message handler
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('FCM background message received: ${message.messageId}');
}

class NotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final UserRepository _userRepo;

  NotificationService({UserRepository? userRepo})
      : _userRepo = userRepo ?? UserRepository();

  static const AndroidNotificationChannel _channel =
      AndroidNotificationChannel(
    'tradingpro_high_importance',
    'TradingPro Alerts',
    description: 'Critical financial and trading notification updates.',
    importance: Importance.high,
    playSound: true,
  );

  Future<void> initialize() async {
    try {
      // 1. Request notification permissions
      final settings = await _fcm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        debugPrint('Notification permissions granted');
      }

      // 2. Initialize Local Notifications Plugin
      const androidInit =
          AndroidInitializationSettings('ic_notification');
      const iosInit = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );

      const initSettings = InitializationSettings(
        android: androidInit,
        iOS: iosInit,
      );

      await _localNotifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      // 3. Create High Importance Channel on Android
      if (!kIsWeb && Platform.isAndroid) {
        await _localNotifications
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>()
            ?.createNotificationChannel(_channel);
      }

      // 4. Set Foreground Presentation Options for iOS
      await _fcm.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      // 5. Listen to foreground messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // 6. Set background handler
      FirebaseMessaging.onBackgroundMessage(
          firebaseMessagingBackgroundHandler);
    } catch (e) {
      debugPrint('Notification service initialization note: $e');
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    final notification = message.notification;

    if (notification != null && !kIsWeb) {
      _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _channel.id,
            _channel.name,
            channelDescription: _channel.description,
            icon: 'ic_notification',
            color: Color(0xFF6C3FE0),
            largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
            importance: Importance.high,
            priority: Priority.high,
            styleInformation: const DefaultStyleInformation(true, true),
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: message.data['route'] ?? '/inbox',
      );
    }
  }

  void _onNotificationTapped(NotificationResponse response) {
    final payload = response.payload;
    debugPrint('User tapped notification with route: $payload');
    // Navigation can be dispatched via router if needed
  }

  /// Register FCM Token for logged-in user
  Future<void> registerDeviceToken(String uid) async {
    try {
      final token = await _fcm.getToken();
      if (token != null) {
        final platform = kIsWeb
            ? 'web'
            : Platform.isAndroid
                ? 'android'
                : Platform.isIOS
                    ? 'ios'
                    : 'desktop';
        await _userRepo.registerFcmToken(uid, token, platform);
        debugPrint('FCM Token registered for user: $uid');
      }

      // Listen for token refreshes
      _fcm.onTokenRefresh.listen((newToken) async {
        final platform = kIsWeb
            ? 'web'
            : Platform.isAndroid
                ? 'android'
                : Platform.isIOS
                    ? 'ios'
                    : 'desktop';
        await _userRepo.registerFcmToken(uid, newToken, platform);
      });
    } catch (e) {
      debugPrint('Error registering FCM token: $e');
    }
  }
}
