import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tradingpro/providers/app_providers.dart';
import 'package:tradingpro/shared_widgets/admin_shell.dart';
import 'package:tradingpro/features/admin/auth/screens/admin_login_screen.dart';
import 'package:tradingpro/features/admin/dashboard/screens/admin_dashboard_screen.dart';
import 'package:tradingpro/features/admin/users/screens/admin_users_screen.dart';
import 'package:tradingpro/features/admin/users/screens/admin_user_detail_screen.dart';
import 'package:tradingpro/features/admin/deposits/screens/admin_deposits_screen.dart';
import 'package:tradingpro/features/admin/withdrawals/screens/admin_withdrawals_screen.dart';
import 'package:tradingpro/features/admin/trades/screens/admin_trades_screen.dart';
import 'package:tradingpro/features/admin/coins/screens/admin_coins_screen.dart';
import 'package:tradingpro/features/admin/support/screens/admin_support_screen.dart';
import 'package:tradingpro/features/admin/notifications/screens/admin_notifications_screen.dart';
import 'package:tradingpro/features/admin/audit_logs/screens/admin_audit_logs_screen.dart';
import 'package:tradingpro/features/admin/settings/screens/admin_settings_screen.dart';

final adminRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/admin/dashboard',
    redirect: (context, state) {
      final isLoggedIn = authState.valueOrNull != null;
      final isAuthRoute = state.matchedLocation == '/admin/login';

      if (!isLoggedIn && !isAuthRoute) return '/admin/login';
      if (isLoggedIn && isAuthRoute) return '/admin/dashboard';
      return null;
    },
    routes: [
      GoRoute(
        path: '/admin/login',
        name: 'adminLogin',
        builder: (context, state) => const AdminLoginScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => AdminShell(child: child),
        routes: [
          GoRoute(
            path: '/admin/dashboard',
            name: 'adminDashboard',
            builder: (context, state) => const AdminDashboardScreen(),
          ),
          GoRoute(
            path: '/admin/users',
            name: 'adminUsers',
            builder: (context, state) => const AdminUsersScreen(),
            routes: [
              GoRoute(
                path: ':userId',
                name: 'adminUserDetail',
                builder: (context, state) {
                  final userId = state.pathParameters['userId']!;
                  return AdminUserDetailScreen(userId: userId);
                },
              ),
            ],
          ),
          GoRoute(
            path: '/admin/deposits',
            name: 'adminDeposits',
            builder: (context, state) => const AdminDepositsScreen(),
          ),
          GoRoute(
            path: '/admin/withdrawals',
            name: 'adminWithdrawals',
            builder: (context, state) => const AdminWithdrawalsScreen(),
          ),
          GoRoute(
            path: '/admin/trades',
            name: 'adminTrades',
            builder: (context, state) => const AdminTradesScreen(),
          ),
          GoRoute(
            path: '/admin/coins',
            name: 'adminCoins',
            builder: (context, state) => const AdminCoinsScreen(),
          ),
          GoRoute(
            path: '/admin/support',
            name: 'adminSupport',
            builder: (context, state) => const AdminSupportScreen(),
          ),
          GoRoute(
            path: '/admin/notifications',
            name: 'adminNotifications',
            builder: (context, state) => const AdminNotificationsScreen(),
          ),
          GoRoute(
            path: '/admin/audit-logs',
            name: 'adminAuditLogs',
            builder: (context, state) => const AdminAuditLogsScreen(),
          ),
          GoRoute(
            path: '/admin/settings',
            name: 'adminSettings',
            builder: (context, state) => const AdminSettingsScreen(),
          ),
        ],
      ),
    ],
  );
});
