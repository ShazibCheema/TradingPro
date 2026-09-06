import 'package:flutter/material.dart';
import 'package:tradingpro/core/theme/app_colors.dart';

/// Centralized utility for showing user-friendly snackbars and logging actual errors to debug console
class AppSnackbar {
  AppSnackbar._();

  /// Logs the actual technical error to console and displays a friendly error snackbar
  static void showError(
    BuildContext context, {
    required dynamic error,
    StackTrace? stackTrace,
    String? fallbackMessage,
  }) {
    // Print raw error to debug console
    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    debugPrint('🚨 [TradingPro Error]: $error');
    if (stackTrace != null) {
      debugPrint('📍 [StackTrace]: $stackTrace');
    }
    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

    if (!context.mounted) return;

    final friendlyMsg = _formatFriendlyError(error, fallbackMessage);

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: Colors.white, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                friendlyMsg,
                style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.negative,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  /// Shows a user-friendly warning snackbar
  static void showWarning(
    BuildContext context, {
    required String message,
    dynamic error,
  }) {
    if (error != null) {
      debugPrint('⚠️ [TradingPro Warning]: $error');
    }

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.pending,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  /// Shows a success snackbar
  static void showSuccess(BuildContext context, String message) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline_rounded, color: Colors.white, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.positive,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Convert technical error strings into user-friendly explanations
  static String _formatFriendlyError(dynamic error, String? fallback) {
    final raw = error.toString();

    if (raw.contains('no-app') || raw.contains('No Firebase App')) {
      return 'Connecting to services... Please try again in a moment.';
    }
    if (raw.contains('network-request-failed') || raw.contains('SocketException') || raw.contains('Failed host lookup')) {
      return 'Network connection issue. Please check your internet connection.';
    }
    if (raw.contains('user-not-found') || raw.contains('wrong-password') || raw.contains('invalid-credential')) {
      return 'Incorrect email or password. Please try again.';
    }
    if (raw.contains('email-already-in-use')) {
      return 'An account with this email address already exists.';
    }
    if (raw.contains('user-disabled')) {
      return 'This account has been suspended. Please contact support.';
    }
    if (raw.contains('too-many-requests')) {
      return 'Too many login attempts. Please wait a moment and try again.';
    }
    if (raw.contains('requires-recent-login')) {
      return 'This operation is sensitive. Please log out and sign in again.';
    }
    if (raw.contains('permission-denied') || raw.contains('Access Denied')) {
      return 'Access denied. You do not have permission for this action.';
    }

    // Strip Exception: prefixes
    var cleaned = raw.replaceFirst('Exception: ', '').trim();
    if (cleaned.startsWith('[') && cleaned.contains('] ')) {
      cleaned = cleaned.substring(cleaned.indexOf('] ') + 2);
    }

    return cleaned.isNotEmpty ? cleaned : (fallback ?? 'Something went wrong. Please try again.');
  }
}
