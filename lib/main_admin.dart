import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:tradingpro/firebase_options.dart';
import 'package:tradingpro/core/theme/app_theme.dart';
import 'package:tradingpro/core/constants/app_constants.dart';
import 'package:tradingpro/router/admin_router.dart';
import 'package:tradingpro/services/app_check_service.dart';
import 'package:tradingpro/services/connectivity_service.dart';
import 'package:tradingpro/providers/app_providers.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  bool isInitialized = false;
  Object? initError;
  StackTrace? initStackTrace;

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await AppCheckService.initialize();
    debugPrint(
        '✅ [Firebase Admin] Initialized successfully for ${kIsWeb ? "Web" : defaultTargetPlatform.name}');
    isInitialized = true;
  } catch (e, stack) {
    debugPrint('🚨 [Firebase Admin Init Error]: $e');
    debugPrint('📍 [StackTrace]: $stack');
    initError = e;
    initStackTrace = stack;
  }

  if (!isInitialized) {
    runApp(
        InitializationErrorApp(error: initError, stackTrace: initStackTrace));
    return;
  }

  runApp(
    ProviderScope(
      overrides: [
        flavorProvider.overrideWithValue(AppFlavor.admin),
      ],
      child: const TradingProAdminApp(),
    ),
  );
}

class TradingProAdminApp extends ConsumerStatefulWidget {
  const TradingProAdminApp({super.key});

  @override
  ConsumerState<TradingProAdminApp> createState() => _TradingProAdminAppState();
}

class _TradingProAdminAppState extends ConsumerState<TradingProAdminApp> {
  @override
  void initState() {
    super.initState();
    // Initialize notification service once after app starts
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(notificationServiceProvider).initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(adminRouterProvider);

    // Register FCM device token whenever admin signs in (Safe Side Effect)
    ref.listen(userProvider, (previous, next) {
      final user = next.valueOrNull;
      if (user != null && previous?.valueOrNull?.uid != user.uid) {
        ref.read(notificationServiceProvider).registerDeviceToken(user.uid);
      }
    });

    return MaterialApp.router(
      title: AppConstants.adminAppName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: router,
      builder: (context, child) {
        if (child == null) return const SizedBox.shrink();
        return OfflineBannerWrapper(
          child: child,
        );
      },
    );
  }
}

/// Fallback app to show errors if Firebase fails to initialize
class InitializationErrorApp extends StatelessWidget {
  final Object? error;
  final StackTrace? stackTrace;

  const InitializationErrorApp({super.key, this.error, this.stackTrace});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 64),
                const SizedBox(height: 24),
                const Text(
                  'Admin Initialization Failed',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Text(
                  'The Admin app could not start. This is often caused by missing '
                  'Firebase configuration for the admin flavor in google-services.json.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[700]),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SingleChildScrollView(
                    child: Text(
                      error?.toString() ?? 'Unknown error',
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                        color: Colors.red,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
