import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tradingpro/providers/app_providers.dart';
import 'package:tradingpro/core/constants/app_constants.dart';
import 'package:tradingpro/core/theme/app_colors.dart';
import 'package:tradingpro/core/theme/app_text_styles.dart';
import 'package:tradingpro/shared_widgets/app_widgets.dart';

class AdminShell extends ConsumerStatefulWidget {
  final Widget child;
  const AdminShell({super.key, required this.child});

  @override
  ConsumerState<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends ConsumerState<AdminShell> {
  static const _routes = [
    '/admin/dashboard',
    '/admin/users',
    '/admin/deposits',
    '/admin/withdrawals',
    '/admin/trades',
    '/admin/coins',
    '/admin/support',
    '/admin/notifications',
    '/admin/audit-logs',
    '/admin/settings',
  ];

  int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).matchedLocation;
    for (int i = 0; i < _routes.length; i++) {
      if (location.startsWith(_routes[i])) {
        return i;
      }
    }
    return 0;
  }

  void _onDestinationSelected(int index) {
    context.go(_routes[index]);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 800;
    final selectedIndex = _calculateSelectedIndex(context);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const AppLogo(size: 30, borderRadius: 7, showShadow: false),
            const SizedBox(width: 8),
            Text(
              AppConstants.adminAppName,
              style: AppTextStyles.h4.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'ADMIN',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Sign Out',
            icon: const Icon(Icons.logout_rounded, color: AppColors.negative),
            onPressed: () async {
              final confirmed = await ConfirmDialog.show(
                context,
                title: 'Confirm Sign Out',
                message:
                    'Are you sure you want to end your administrative session and log out?',
                confirmLabel: 'Log Out',
                isDestructive: true,
                onConfirm: () {},
              );

              if (confirmed == true) {
                await ref.read(authRepositoryProvider).signOut();
              }
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      drawer: isDesktop
          ? null
          : Drawer(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  DrawerHeader(
                    decoration: const BoxDecoration(color: AppColors.primary),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        const AppLogo(size: 48, borderRadius: 12, showShadow: false),
                        const SizedBox(height: 10),
                        Text(
                          AppConstants.adminAppName,
                          style: AppTextStyles.h3
                              .copyWith(color: Colors.white),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Platform Management Console',
                          style: AppTextStyles.caption
                              .copyWith(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                  _drawerItem(0, 'Dashboard', Icons.dashboard_outlined, selectedIndex),
                  _drawerItem(1, 'Users', Icons.people_outline_rounded, selectedIndex),
                  _drawerItem(2, 'Deposits', Icons.arrow_downward_rounded, selectedIndex),
                  _drawerItem(3, 'Withdrawals', Icons.arrow_upward_rounded, selectedIndex),
                  _drawerItem(4, 'Trades', Icons.candlestick_chart_outlined, selectedIndex),
                  _drawerItem(5, 'Coins / Markets', Icons.monetization_on_outlined, selectedIndex),
                  _drawerItem(6, 'Customer Support', Icons.headset_mic_outlined, selectedIndex),
                  _drawerItem(7, 'Notifications', Icons.campaign_outlined, selectedIndex),
                  _drawerItem(8, 'Audit Logs', Icons.security_rounded, selectedIndex),
                  _drawerItem(9, 'Settings', Icons.settings_outlined, selectedIndex),
                ],
              ),
            ),
      body: Row(
        children: [
          if (isDesktop)
            LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints:
                        BoxConstraints(minHeight: constraints.maxHeight),
                    child: IntrinsicHeight(
                      child: NavigationRail(
                        selectedIndex: selectedIndex,
                        onDestinationSelected: _onDestinationSelected,
                        labelType: NavigationRailLabelType.all,
                        backgroundColor: AppColors.surface,
                        selectedIconTheme:
                            const IconThemeData(color: AppColors.primary),
                        selectedLabelTextStyle:
                            AppTextStyles.captionMedium.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                        unselectedLabelTextStyle: AppTextStyles.caption.copyWith(
                          color: AppColors.textSecondary,
                        ),
                        destinations: const [
                          NavigationRailDestination(
                            icon: Icon(Icons.dashboard_outlined),
                            selectedIcon: Icon(Icons.dashboard_rounded),
                            label: Text('Dashboard'),
                          ),
                          NavigationRailDestination(
                            icon: Icon(Icons.people_outline_rounded),
                            selectedIcon: Icon(Icons.people_rounded),
                            label: Text('Users'),
                          ),
                          NavigationRailDestination(
                            icon: Icon(Icons.arrow_downward_rounded),
                            selectedIcon: Icon(Icons.arrow_downward_rounded),
                            label: Text('Deposits'),
                          ),
                          NavigationRailDestination(
                            icon: Icon(Icons.arrow_upward_rounded),
                            selectedIcon: Icon(Icons.arrow_upward_rounded),
                            label: Text('Withdrawals'),
                          ),
                          NavigationRailDestination(
                            icon: Icon(Icons.candlestick_chart_outlined),
                            selectedIcon: Icon(Icons.candlestick_chart_rounded),
                            label: Text('Trades'),
                          ),
                          NavigationRailDestination(
                            icon: Icon(Icons.monetization_on_outlined),
                            selectedIcon: Icon(Icons.monetization_on_rounded),
                            label: Text('Coins'),
                          ),
                          NavigationRailDestination(
                            icon: Icon(Icons.headset_mic_outlined),
                            selectedIcon: Icon(Icons.headset_mic_rounded),
                            label: Text('Support'),
                          ),
                          NavigationRailDestination(
                            icon: Icon(Icons.campaign_outlined),
                            selectedIcon: Icon(Icons.campaign_rounded),
                            label: Text('Alerts'),
                          ),
                          NavigationRailDestination(
                            icon: Icon(Icons.security_outlined),
                            selectedIcon: Icon(Icons.security_rounded),
                            label: Text('Audit'),
                          ),
                          NavigationRailDestination(
                            icon: Icon(Icons.settings_outlined),
                            selectedIcon: Icon(Icons.settings_rounded),
                            label: Text('Settings'),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          if (isDesktop) const VerticalDivider(thickness: 1, width: 1),
          Expanded(child: widget.child),
        ],
      ),
    );
  }

  Widget _drawerItem(int index, String title, IconData icon, int selectedIndex) {
    return ListTile(
      leading: Icon(icon,
          color: selectedIndex == index
              ? AppColors.primary
              : AppColors.textSecondary),
      title: Text(
        title,
        style: TextStyle(
          color: selectedIndex == index
              ? AppColors.primary
              : AppColors.textPrimary,
          fontWeight:
              selectedIndex == index ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
      selected: selectedIndex == index,
      onTap: () {
        Navigator.of(context).pop();
        _onDestinationSelected(index);
      },
    );
  }
}
