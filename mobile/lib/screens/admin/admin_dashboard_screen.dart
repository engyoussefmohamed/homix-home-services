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

final adminStatsProvider = FutureProvider.autoDispose<Map<String, dynamic>>((
  ref,
) async {
  final auth = ref.watch(authControllerProvider);
  final token = auth.token;
  final role = auth.user?.role;
  if (token == null || token.isEmpty || role != UserRole.admin) {
    return const <String, dynamic>{};
  }
  return ref.watch(apiServiceProvider).getAdminStats(token);
});

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    final stats = ref.watch(adminStatsProvider);

    return HomixPage(
      title: context.tr(ar: 'لوحة الإدارة', en: 'Admin dashboard'),
      header: AppBanner(
        title: context.tr(
          ar: 'مركز إدارة بمظهر أقوى',
          en: 'A stronger-looking admin control center',
        ),
        message: context.tr(
          ar: 'الواجهة الجديدة تعرض المؤشرات والإجراءات الحساسة بصورة أوضح وأسهل لاتخاذ القرار.',
          en: 'The refreshed admin view makes metrics and sensitive actions easier to scan and act on.',
        ),
        icon: Icons.admin_panel_settings_rounded,
        background: AppColors.primarySoft,
        foreground: AppColors.primaryDark,
      ),
      actions: [
        IconButton(
          tooltip: context.tr(ar: 'العودة للتطبيق', en: 'Back to app'),
          onPressed: () => context.go(AppRoutes.customerHome),
          icon: const Icon(Icons.home_rounded),
        ),
        IconButton(
          tooltip: context.tr(ar: 'تسجيل الخروج', en: 'Log out'),
          onPressed: () async {
            await ref.read(authControllerProvider).logout();
            if (context.mounted) context.go(AppRoutes.login);
          },
          icon: const Icon(Icons.logout_rounded),
        ),
      ],
      child: Builder(
        builder: (context) {
          if (auth.isBootstrapping) {
            return const Center(child: CircularProgressIndicator());
          }

          if (auth.user?.role != UserRole.admin) {
            return AsyncPlaceholder(
              message: context.tr(
                ar: 'هذه الصفحة متاحة فقط لحساب المدير.',
                en: 'This page is only available for admin accounts.',
              ),
              icon: Icons.admin_panel_settings_rounded,
            );
          }

          return stats.when(
            data: (data) => _AdminDashboardBody(data: data),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => AsyncPlaceholder(
              message: context.tr(
                ar: 'تعذر تحميل بيانات لوحة الإدارة.\n$error',
                en: 'Could not load admin dashboard data.\n$error',
              ),
              icon: Icons.error_outline_rounded,
            ),
          );
        },
      ),
    );
  }
}

class _AdminDashboardBody extends ConsumerWidget {
  const _AdminDashboardBody({required this.data});

  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingItems =
        (data['pending_shops'] ?? 0) +
        (data['pending_products'] ?? 0) +
        (data['pending_payout_requests'] ?? 0);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(adminStatsProvider);
        await ref.read(adminStatsProvider.future);
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  DashboardHero(
                    title: context.tr(
                      ar: 'مركز المتابعة والقرارات',
                      en: 'Operations and decision center',
                    ),
                    subtitle: context.tr(
                      ar: 'موافقات، إحصائيات، وعمليات حساسة في مساحة إدارية أوضح',
                      en: 'Approvals, metrics, and sensitive operations in one cleaner command view',
                    ),
                    chips: const [
                      HeroTagChip(label: 'Shops'),
                      HeroTagChip(label: 'Audit'),
                      HeroTagChip(label: 'Payouts', highlight: true),
                    ],
                    trailing: Container(
                      width: 104,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.08),
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            '$pendingItems',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 30,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          Text(
                            context.tr(
                              ar: 'عناصر تنتظر القرار',
                              en: 'Pending decisions',
                            ),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.82),
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (data.isEmpty)
                    AppBanner(
                      title: context.tr(
                        ar: 'لا توجد بيانات بعد',
                        en: 'No data yet',
                      ),
                      message: context.tr(
                        ar: 'تم فتح لوحة الإدارة لكن لا توجد إحصائيات متاحة حاليًا.',
                        en: 'The admin dashboard is open, but no metrics are available yet.',
                      ),
                      icon: Icons.insights_rounded,
                      background: AppColors.primarySoft,
                      foreground: AppColors.primaryDark,
                    )
                  else ...[
                    Row(
                      children: [
                        Expanded(
                          child: StatTile(
                            label: context.tr(ar: 'المستخدمون', en: 'Users'),
                            value: '${data['users'] ?? 0}',
                            color: AppColors.primary,
                            icon: Icons.people_alt_rounded,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: StatTile(
                            label: context.tr(ar: 'التقديرات', en: 'Estimates'),
                            value: '${data['total_estimates'] ?? 0}',
                            color: AppColors.secondary,
                            icon: Icons.auto_awesome_rounded,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: MetricPill(
                            label: context.tr(
                              ar: 'المحلات المعتمدة',
                              en: 'Approved shops',
                            ),
                            value: '${data['approved_shops'] ?? 0}',
                            background: AppColors.accentSoft,
                            valueColor: AppColors.accentDark,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: MetricPill(
                            label: context.tr(
                              ar: 'اشتراكات Pro',
                              en: 'Pro plans',
                            ),
                            value: '${data['active_pro_subscriptions'] ?? 0}',
                            background: AppColors.successSoft,
                            valueColor: AppColors.success,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: MetricPill(
                            label: context.tr(
                              ar: 'متجر أو منتج معلق',
                              en: 'Pending shops/products',
                            ),
                            value:
                                '${(data['pending_shops'] ?? 0) + (data['pending_products'] ?? 0)}',
                            background: AppColors.errorSoft,
                            valueColor: AppColors.error,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: MetricPill(
                            label: context.tr(
                              ar: 'طلبات السحب',
                              en: 'Payout requests',
                            ),
                            value: '${data['pending_payout_requests'] ?? 0}',
                            background: AppColors.primarySoft,
                            valueColor: AppColors.primaryDark,
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 18),
                  SectionHeading(
                    title: context.tr(
                      ar: 'مركز الإجراءات',
                      en: 'Action center',
                    ),
                    subtitle: context.tr(
                      ar: 'الإجراءات الأكثر أهمية مرتبة بصريًا لتقليل وقت القرار',
                      en: 'The most important actions, arranged to reduce decision time',
                    ),
                  ),
                  const SizedBox(height: 12),
                  _AdminActionTile(
                    title: context.tr(ar: 'مراجعة المحلات', en: 'Review shops'),
                    subtitle: context.tr(
                      ar: '${data['pending_shops'] ?? 0} طلبات جديدة',
                      en: '${data['pending_shops'] ?? 0} new requests',
                    ),
                    actionLabel: context.tr(ar: 'فتح', en: 'Open'),
                    icon: Icons.store_mall_directory_rounded,
                    color: AppColors.accent,
                    onTap: () => context.push(AppRoutes.approveShops),
                  ),
                  const SizedBox(height: 12),
                  _AdminActionTile(
                    title: context.tr(
                      ar: 'مراجعة المنتجات',
                      en: 'Review products',
                    ),
                    subtitle: context.tr(
                      ar: '${data['pending_products'] ?? 0} منتجات جديدة',
                      en: '${data['pending_products'] ?? 0} new products',
                    ),
                    actionLabel: context.tr(ar: 'فتح', en: 'Open'),
                    icon: Icons.inventory_2_rounded,
                    color: AppColors.primary,
                    onTap: () => context.push(AppRoutes.approveProducts),
                  ),
                  const SizedBox(height: 12),
                  _AdminActionTile(
                    title: context.tr(
                      ar: 'إدارة الحجوزات',
                      en: 'Manage bookings',
                    ),
                    subtitle: context.tr(
                      ar: 'متابعة حالات الحجوزات والتدخل التشغيلي عند الحاجة',
                      en: 'Track booking states and step in operationally when needed',
                    ),
                    actionLabel: context.tr(ar: 'إدارة', en: 'Manage'),
                    icon: Icons.event_note_rounded,
                    color: AppColors.secondary,
                    onTap: () => context.push(AppRoutes.adminBookings),
                  ),
                  const SizedBox(height: 12),
                  _AdminActionTile(
                    title: context.tr(ar: 'سجل التدقيق', en: 'Audit log'),
                    subtitle: context.tr(
                      ar: 'عرض تغييرات الحالات والموافقات والأنشطة الحساسة',
                      en: 'View state changes, approvals, and sensitive activities',
                    ),
                    actionLabel: context.tr(ar: 'عرض', en: 'View'),
                    icon: Icons.history_edu_rounded,
                    color: AppColors.primaryDark,
                    onTap: () => context.push(AppRoutes.auditLogs),
                  ),
                  const SizedBox(height: 12),
                  _AdminActionTile(
                    title: context.tr(
                      ar: 'اشتراكات الفنيين',
                      en: 'Technician subscriptions',
                    ),
                    subtitle: context.tr(
                      ar: 'إدارة خطط Basic وPro وترتيب الظهور',
                      en: 'Manage Basic and Pro plans and ranking order',
                    ),
                    actionLabel: context.tr(ar: 'إدارة', en: 'Manage'),
                    icon: Icons.workspace_premium_rounded,
                    color: AppColors.secondary,
                    onTap: () =>
                        context.push(AppRoutes.technicianSubscriptions),
                  ),
                  const SizedBox(height: 12),
                  _AdminActionTile(
                    title: context.tr(
                      ar: 'سجل المدفوعات',
                      en: 'Billing history',
                    ),
                    subtitle: context.tr(
                      ar: 'مراجعة مدفوعات الاشتراكات والعمليات التي ينفذها حساب الإدارة',
                      en: 'Review subscription payments and transactions performed by the admin account',
                    ),
                    actionLabel: context.tr(ar: 'عرض', en: 'View'),
                    icon: Icons.receipt_long_rounded,
                    color: AppColors.accent,
                    onTap: () => context.push(AppRoutes.billingHistory),
                  ),
                  const SizedBox(height: 12),
                  _AdminActionTile(
                    title: context.tr(ar: 'طلبات السحب', en: 'Payout requests'),
                    subtitle: context.tr(
                      ar: '${data['pending_payout_requests'] ?? 0} طلبات تحتاج مراجعة',
                      en: '${data['pending_payout_requests'] ?? 0} requests need review',
                    ),
                    actionLabel: context.tr(ar: 'إدارة', en: 'Manage'),
                    icon: Icons.account_balance_wallet_rounded,
                    color: AppColors.error,
                    onTap: () => context.push(AppRoutes.adminPayoutRequests),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _AdminActionTile extends StatelessWidget {
  const _AdminActionTile({
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final String actionLabel;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppSectionCard(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(28),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color.withValues(alpha: 0.78), color],
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                ),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(icon, color: Colors.white),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      height: 1.55,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      actionLabel,
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Icon(Icons.arrow_forward_rounded, color: color),
          ],
        ),
      ),
    );
  }
}
