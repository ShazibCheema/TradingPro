import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tradingpro/providers/app_providers.dart';
import 'package:tradingpro/features/auth/screens/login_screen.dart';
import 'package:tradingpro/features/auth/screens/register_screen.dart';
import 'package:tradingpro/features/auth/screens/forgot_password_screen.dart';
import 'package:tradingpro/features/home/screens/home_screen.dart';
import 'package:tradingpro/features/account/screens/account_screen.dart';
import 'package:tradingpro/features/inbox/screens/inbox_screen.dart';
import 'package:tradingpro/features/profile/screens/profile_screen.dart';
import 'package:tradingpro/features/profile/screens/settings_screen.dart';
import 'package:tradingpro/features/profile/screens/change_password_screen.dart';
import 'package:tradingpro/features/profile/screens/withdraw_details_screen.dart';
import 'package:tradingpro/features/support/screens/support_screen.dart';
import 'package:tradingpro/features/deposit/screens/deposit_screen.dart';
import 'package:tradingpro/features/withdrawal/screens/withdrawal_screen.dart';
import 'package:tradingpro/features/trading/screens/trading_screen.dart';
import 'package:tradingpro/features/market/screens/market_screen.dart';
import 'package:tradingpro/shared_widgets/user_shell.dart';

// Route names
class AppRoutes {
  static const login = '/login';
  static const register = '/register';
  static const forgotPassword = '/forgot-password';
  static const home = '/home';
  static const account = '/account';
  static const inbox = '/inbox';
  static const profile = '/profile';
  static const settings = '/settings';
  static const changePassword = '/change-password';
  static const withdrawDetails = '/withdraw-details';
  static const support = '/support';
  static const deposit = '/deposit';
  static const withdrawal = '/withdrawal';
  static const trading = '/trading';
  static const market = '/market';
}

final userRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: AppRoutes.home,
    redirect: (context, state) {
      final isLoggedIn = authState.valueOrNull != null;
      final isAuthRoute = state.matchedLocation == AppRoutes.login ||
          state.matchedLocation == AppRoutes.register ||
          state.matchedLocation == AppRoutes.forgotPassword;

      if (!isLoggedIn && !isAuthRoute) return AppRoutes.login;
      if (isLoggedIn && isAuthRoute) return AppRoutes.home;
      return null;
    },
    routes: [
      // ─── Auth Routes ──────────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.login,
        name: 'login',
        pageBuilder: (context, state) => _fadeTransition(
          state,
          const LoginScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.register,
        name: 'register',
        pageBuilder: (context, state) => _slideTransition(
          state,
          const RegisterScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        name: 'forgotPassword',
        pageBuilder: (context, state) => _slideTransition(
          state,
          const ForgotPasswordScreen(),
        ),
      ),

      // ─── Main Shell (Bottom Navigation) ───────────────────────────────────
      ShellRoute(
        builder: (context, state, child) => UserShell(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.home,
            name: 'home',
            pageBuilder: (context, state) =>
                _noTransition(state, const HomeScreen()),
          ),
          GoRoute(
            path: AppRoutes.account,
            name: 'account',
            pageBuilder: (context, state) =>
                _noTransition(state, const AccountScreen()),
          ),
          GoRoute(
            path: AppRoutes.inbox,
            name: 'inbox',
            pageBuilder: (context, state) =>
                _noTransition(state, const InboxScreen()),
          ),
          GoRoute(
            path: AppRoutes.profile,
            name: 'profile',
            pageBuilder: (context, state) =>
                _noTransition(state, const ProfileScreen()),
          ),
        ],
      ),

      // ─── Feature Routes (Full Screen) ─────────────────────────────────────
      GoRoute(
        path: AppRoutes.settings,
        name: 'settings',
        pageBuilder: (context, state) =>
            _slideTransition(state, const SettingsScreen()),
      ),
      GoRoute(
        path: AppRoutes.changePassword,
        name: 'changePassword',
        pageBuilder: (context, state) =>
            _slideTransition(state, const ChangePasswordScreen()),
      ),
      GoRoute(
        path: AppRoutes.withdrawDetails,
        name: 'withdrawDetails',
        pageBuilder: (context, state) =>
            _slideTransition(state, const WithdrawDetailsScreen()),
      ),
      GoRoute(
        path: AppRoutes.support,
        name: 'support',
        pageBuilder: (context, state) =>
            _slideTransition(state, const SupportScreen()),
      ),
      GoRoute(
        path: AppRoutes.deposit,
        name: 'deposit',
        pageBuilder: (context, state) =>
            _slideTransition(state, const DepositScreen()),
      ),
      GoRoute(
        path: AppRoutes.withdrawal,
        name: 'withdrawal',
        pageBuilder: (context, state) =>
            _slideTransition(state, const WithdrawalScreen()),
      ),
      GoRoute(
        path: AppRoutes.trading,
        name: 'trading',
        pageBuilder: (context, state) =>
            _slideTransition(state, const TradingScreen()),
      ),
      GoRoute(
        path: AppRoutes.market,
        name: 'market',
        pageBuilder: (context, state) =>
            _slideTransition(state, const MarketScreen()),
      ),
    ],
  );
});

// ─── Page Transitions ─────────────────────────────────────────────────────────

CustomTransitionPage<void> _fadeTransition(GoRouterState state, Widget child) {
  return CustomTransitionPage(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
        child: child,
      );
    },
    transitionDuration: const Duration(milliseconds: 200),
  );
}

CustomTransitionPage<void> _slideTransition(GoRouterState state, Widget child) {
  return CustomTransitionPage(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(1, 0),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut)),
        child: child,
      );
    },
    transitionDuration: const Duration(milliseconds: 280),
  );
}

CustomTransitionPage<void> _noTransition(GoRouterState state, Widget child) {
  return NoTransitionPage(key: state.pageKey, child: child);
}
