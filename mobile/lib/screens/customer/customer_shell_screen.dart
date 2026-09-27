import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../constants/app_theme.dart';
import '../../core/app_localizations.dart';
import '../../core/app_router.dart';
import '../../models/app_user.dart';
import '../../providers/auth_controller.dart';
import '../../services/api_service.dart';
import '../../widgets/app_widgets.dart';
import 'customer_home_screen.dart';
import 'estimates_history_screen.dart';
import 'my_orders_screen.dart';
import 'profile_screen.dart';
import 'shop_screen.dart';

class CustomerShellScreen extends ConsumerStatefulWidget {
  const CustomerShellScreen({super.key, this.initialIndex = 0});

  final int initialIndex;

  @override
  ConsumerState<CustomerShellScreen> createState() =>
      _CustomerShellScreenState();
}

class _CustomerShellScreenState extends ConsumerState<CustomerShellScreen> {
  late int _index;
  int _unreadNotifications = 0;

  final _tabs = const [
    CustomerHomeScreen(),
    EstimatesHistoryScreen(),
    ShopScreen(),
    MyOrdersScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex.clamp(0, _tabs.length - 1);
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _loadUnreadNotifications(),
    );
  }

  Future<void> _loadUnreadNotifications() async {
    final token = ref.read(authControllerProvider).token;
    if (token == null || token.isEmpty) return;
    final unreadCount = await ref
        .read(apiServiceProvider)
        .getUnreadNotificationsCount(token);
    if (!mounted) return;
    setState(() {
      _unreadNotifications = unreadCount;
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider).user;
    final isAdmin = user?.role == UserRole.admin;
    final titles = [
      context.tr(ar: 'الرئيسية', en: 'Home'),
      context.tr(ar: 'تقديراتي', en: 'My estimates'),
      context.tr(ar: 'المتجر', en: 'Shop'),
      context.tr(ar: 'طلباتي', en: 'My orders'),
      context.tr(ar: 'حسابي', en: 'Profile'),
    ];

    return HomixPage(
      title: titles[_index],
      actions: [
        IconButton(
          onPressed: () async {
            await context.push(AppRoutes.customerNotifications);
            if (mounted) {
              await _loadUnreadNotifications();
            }
          },
          icon: Stack(
            clipBehavior: Clip.none,
            children: [
              const Icon(Icons.notifications_rounded),
              if (_unreadNotifications > 0)
                Positioned(
                  top: -4,
                  right: -6,
                  child: Container(
                    key: const Key('customer-notifications-badge'),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: const BoxDecoration(
                      color: AppColors.error,
                      borderRadius: BorderRadius.all(Radius.circular(999)),
                    ),
                    child: Text(
                      _unreadNotifications > 9 ? '9+' : '$_unreadNotifications',
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (isAdmin)
          IconButton(
            tooltip: context.tr(ar: 'لوحة الإدارة', en: 'Admin dashboard'),
            onPressed: () => context.push(AppRoutes.adminDashboard),
            icon: const Icon(Icons.admin_panel_settings_rounded),
          ),
      ],
      bottomNavigationBar: _ShellBottomBar(
        currentIndex: _index,
        onChanged: (value) => setState(() => _index = value),
      ),
      child: _tabs[_index],
    );
  }
}

class _ShellBottomBar extends StatelessWidget {
  const _ShellBottomBar({required this.currentIndex, required this.onChanged});

  final int currentIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final items = [
      (Icons.home_rounded, context.tr(ar: 'الرئيسية', en: 'Home')),
      (Icons.auto_awesome_rounded, context.tr(ar: 'تقديراتي', en: 'Estimates')),
      (Icons.store_rounded, context.tr(ar: 'المتجر', en: 'Shop')),
      (Icons.receipt_long_rounded, context.tr(ar: 'طلباتي', en: 'Orders')),
      (Icons.person_rounded, context.tr(ar: 'حسابي', en: 'Profile')),
    ];

    return Container(
      margin: const EdgeInsets.fromLTRB(18, 0, 18, 18),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.bottomBar, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withValues(alpha: 0.24),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Row(
        children: List.generate(items.length, (index) {
          final active = index == currentIndex;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 6,
                ),
                decoration: BoxDecoration(
                  gradient: active
                      ? const LinearGradient(
                          colors: [Colors.white, AppColors.accentSoft],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: active
                      ? [
                          BoxShadow(
                            color: AppColors.accent.withValues(alpha: 0.16),
                            blurRadius: 18,
                            offset: const Offset(0, 10),
                          ),
                        ]
                      : null,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: active
                            ? AppColors.primaryDark
                            : Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        items[index].$1,
                        size: 18,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      items[index].$2,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: active ? AppColors.primaryDark : Colors.white70,
                      ),
                    ),
                    if (active) ...[
                      const SizedBox(height: 6),
                      Container(
                        width: 18,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
