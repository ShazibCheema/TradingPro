import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tradingpro/core/theme/app_colors.dart';
import 'package:tradingpro/core/theme/app_text_styles.dart';

final sessionLockProvider =
    StateNotifierProvider<SessionLockNotifier, bool>((ref) {
  return SessionLockNotifier();
});

class SessionLockNotifier extends StateNotifier<bool> {
  SessionLockNotifier() : super(false);

  Timer? _inactivityTimer;
  Duration _lockTimeout = const Duration(minutes: 10);
  bool _isEnabled = true;

  void setLockTimeout(Duration timeout) {
    _lockTimeout = timeout;
    resetTimer();
  }

  void setEnabled(bool enabled) {
    _isEnabled = enabled;
    if (!enabled) {
      _inactivityTimer?.cancel();
      state = false;
    } else {
      resetTimer();
    }
  }

  void userActivityDetected() {
    if (!_isEnabled || state) return;
    resetTimer();
  }

  void resetTimer() {
    _inactivityTimer?.cancel();
    if (!_isEnabled) return;
    _inactivityTimer = Timer(_lockTimeout, () {
      state = true; // Lock session
    });
  }

  void unlockSession() {
    state = false;
    resetTimer();
  }
}

class SessionLockWrapper extends ConsumerWidget {
  final Widget child;
  const SessionLockWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLocked = ref.watch(sessionLockProvider);

    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) =>
          ref.read(sessionLockProvider.notifier).userActivityDetected(),
      onPointerMove: (_) =>
          ref.read(sessionLockProvider.notifier).userActivityDetected(),
      child: Stack(
        children: [
          child,
          if (isLocked)
            Positioned.fill(
              child: _SessionLockOverlay(
                onUnlock: () {
                  ref.read(sessionLockProvider.notifier).unlockSession();
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _SessionLockOverlay extends StatefulWidget {
  final VoidCallback onUnlock;
  const _SessionLockOverlay({required this.onUnlock});

  @override
  State<_SessionLockOverlay> createState() => _SessionLockOverlayState();
}

class _SessionLockOverlayState extends State<_SessionLockOverlay> {
  final _pinCtrl = TextEditingController();

  @override
  void dispose() {
    _pinCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.background.withOpacity(0.98),
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.lock_rounded,
                    color: AppColors.primary,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 20),
                Text('Session Locked', style: AppTextStyles.h2),
                const SizedBox(height: 8),
                Text(
                  'Your session was locked due to inactivity to protect your financial assets.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodySmall,
                ),
                const SizedBox(height: 28),
                ElevatedButton.icon(
                  icon: const Icon(Icons.lock_open_rounded, size: 18),
                  label: const Text('Resume Session'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    minimumSize: const Size(220, 50),
                  ),
                  onPressed: widget.onUnlock,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
