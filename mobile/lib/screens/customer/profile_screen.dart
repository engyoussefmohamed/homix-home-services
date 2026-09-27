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
import 'estimates_history_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    final estimatesAsync = ref.watch(myEstimatesProvider);
    final user = auth.user;

    if (user == null) {
      return AsyncPlaceholder(
        message: context.tr(
          ar: 'لا توجد بيانات مستخدم.',
          en: 'No user data available.',
        ),
      );
    }

    final initial = user.name.isNotEmpty ? user.name.characters.first : 'U';
    final estimatesCount = estimatesAsync.maybeWhen(
      data: (items) => items.length,
      orElse: () => 0,
    );
    final roleValue = switch (user.role) {
      UserRole.admin => context.tr(ar: 'مدير', en: 'Admin'),
      UserRole.shopOwner => context.tr(ar: 'صاحب متجر', en: 'Shop owner'),
      UserRole.technician => context.tr(ar: 'فني', en: 'Technician'),
      UserRole.customer => context.tr(ar: 'عميل', en: 'Customer'),
    };

    return ListView(
      children: [
        AppBanner(
          title: context.tr(ar: 'مركز الحساب الشخصي', en: 'Your account hub'),
          message: context.tr(
            ar: 'الوصول إلى نشاطك، التقديرات، الطلبات، والدفع أصبح أوضح داخل مساحة حساب واحدة.',
            en: 'Your activity, estimates, orders, and billing now live inside one clearer account space.',
          ),
          icon: Icons.person_rounded,
          background: AppColors.primarySoft,
          foreground: AppColors.primaryDark,
        ),
        const SizedBox(height: 16),
        DashboardHero(
          title: user.name,
          subtitle: context.tr(ar: 'حساب $roleValue', en: '$roleValue account'),
          chips: [
            HeroTagChip(label: roleValue, highlight: true),
            HeroTagChip(
              label: context.tr(ar: 'حساب نشط', en: 'Active account'),
            ),
            HeroTagChip(label: user.email),
          ],
          trailing: Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Center(
              child: Text(
                initial,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: StatTile(
                label: context.tr(ar: 'تقديرات محفوظة', en: 'Saved estimates'),
                value: '$estimatesCount',
                color: AppColors.primary,
                icon: Icons.auto_awesome_rounded,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StatTile(
                label: context.tr(ar: 'نوع الحساب', en: 'Account type'),
                value: roleValue,
                color: AppColors.accent,
                icon: Icons.verified_user_rounded,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        AppSectionCard(
          child: Row(
            children: [
              Expanded(
                child: MetricPill(
                  label: context.tr(ar: 'البريد', en: 'Email'),
                  value: user.email,
                  background: AppColors.primarySoft,
                  valueColor: AppColors.primaryDark,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: MetricPill(
                  label: context.tr(ar: 'الحالة', en: 'Status'),
                  value: context.tr(ar: 'نشط', en: 'Active'),
                  background: AppColors.successSoft,
                  valueColor: AppColors.success,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        SectionHeading(
          title: context.tr(ar: 'نشاطك', en: 'Your activity'),
          subtitle: context.tr(
            ar: 'وصول سريع إلى المسارات الأكثر استخدامًا داخل حسابك.',
            en: 'Fast access to the parts of the app you use the most.',
          ),
        ),
        const SizedBox(height: 12),
        _ProfileActionTile(
          title: context.tr(ar: 'تقديراتي', en: 'My estimates'),
          subtitle: context.tr(
            ar: 'راجع التقديرات المحفوظة وابدأ من جديد عند الحاجة',
            en: 'Review saved estimates and start a new one when needed',
          ),
          icon: Icons.history_rounded,
          color: AppColors.primary,
          onTap: () => context.go(AppRoutes.customerHome, extra: 1),
        ),
        const SizedBox(height: 10),
        _ProfileActionTile(
          title: context.tr(ar: 'متابعة الطلبات', en: 'Track orders'),
          subtitle: context.tr(
            ar: 'تابع حالة الطلبات وخط سيرها وتفاصيل كل طلب',
            en: 'Track order status, timeline, and details',
          ),
          icon: Icons.assignment_rounded,
          color: AppColors.accentDark,
          onTap: () => context.go(AppRoutes.customerHome, extra: 3),
        ),
        const SizedBox(height: 10),
        _ProfileActionTile(
          title: context.tr(ar: 'حجوزات الخدمات', en: 'Service bookings'),
          subtitle: context.tr(
            ar: 'راجع المواعيد الحالية وتقدم التنفيذ والمحادثات',
            en: 'Review current visits, progress, and chats',
          ),
          icon: Icons.home_repair_service_rounded,
          color: AppColors.secondary,
          onTap: () => context.push(AppRoutes.myBookings),
        ),
        const SizedBox(height: 18),
        SectionHeading(
          title: context.tr(ar: 'الحساب والفواتير', en: 'Account and billing'),
          subtitle: context.tr(
            ar: 'إعدادات الحساب والوصول إلى سجل المدفوعات والإدارة عند الحاجة.',
            en: 'Account settings, billing history, and admin access when needed.',
          ),
        ),
        const SizedBox(height: 12),
        _ProfileActionTile(
          title: context.tr(ar: 'سجل المدفوعات', en: 'Billing history'),
          subtitle: context.tr(
            ar: 'راجع كل المدفوعات والسجلات المالية المرتبطة بحسابك',
            en: 'Review all payments and financial records linked to your account',
          ),
          icon: Icons.payments_rounded,
          color: AppColors.primaryDark,
          onTap: () => context.push(AppRoutes.billingHistory),
        ),
        const SizedBox(height: 10),
        _ProfileActionTile(
          title: context.tr(ar: 'الإعدادات', en: 'Settings'),
          subtitle: context.tr(
            ar: 'تخصيصات إضافية ستتوفر قريبًا داخل مركز الحساب',
            en: 'Additional preferences will be available here soon',
          ),
          icon: Icons.settings_rounded,
          color: AppColors.info,
          onTap: () => ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                context.tr(
                  ar: 'شاشة الإعدادات التفصيلية قيد الإضافة',
                  en: 'Detailed settings are coming soon',
                ),
              ),
            ),
          ),
        ),
        if (user.role == UserRole.admin) ...[
          const SizedBox(height: 10),
          _ProfileActionTile(
            title: context.tr(ar: 'لوحة الإدارة', en: 'Admin dashboard'),
            subtitle: context.tr(
              ar: 'افتح مساحة المتابعة والقرارات الإدارية',
              en: 'Open the operations and decision dashboard',
            ),
            icon: Icons.admin_panel_settings_rounded,
            color: AppColors.accent,
            onTap: () => context.push(AppRoutes.adminDashboard),
          ),
        ],
        const SizedBox(height: 18),
        SectionHeading(
          title: context.tr(ar: 'الأمان', en: 'Security'),
          subtitle: context.tr(
            ar: 'خيارات الخروج وإنهاء الجلسات للحفاظ على الحساب.',
            en: 'Log out and session controls to keep the account secure.',
          ),
        ),
        const SizedBox(height: 12),
        _ProfileActionTile(
          title: context.tr(ar: 'إنهاء كل الجلسات', en: 'Log out all sessions'),
          subtitle: context.tr(
            ar: 'يسجل خروج كل الأجهزة والجلسات الحالية بما فيها هذه الجلسة',
            en: 'Logs out all devices and current sessions, including this one',
          ),
          icon: Icons.devices_other_rounded,
          color: AppColors.error,
          onTap: () async {
            final token = ref.read(authControllerProvider).token;
            if (token == null) return;
            final confirm = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: Text(
                  context.tr(
                    ar: 'إنهاء كل الجلسات',
                    en: 'Log out all sessions',
                  ),
                ),
                content: Text(
                  context.tr(
                    ar: 'سيتم تسجيل خروج كل الأجهزة والجلسات الحالية، بما فيها هذه الجلسة.',
                    en: 'All current devices and sessions, including this one, will be logged out.',
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: Text(context.tr(ar: 'إلغاء', en: 'Cancel')),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: Text(context.tr(ar: 'تأكيد', en: 'Confirm')),
                  ),
                ],
              ),
            );
            if (confirm != true || !context.mounted) return;
            try {
              await ref.read(apiServiceProvider).logoutAllSessions(token);
              await ref.read(authControllerProvider).logout();
              if (context.mounted) {
                context.go(AppRoutes.login);
              }
            } catch (error) {
              if (context.mounted) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(error.toString())));
              }
            }
          },
        ),
        const SizedBox(height: 10),
        _ProfileActionTile(
          title: context.tr(ar: 'تسجيل الخروج', en: 'Log out'),
          subtitle: context.tr(
            ar: 'الخروج من هذه الجلسة الحالية فقط',
            en: 'Log out from this current session only',
          ),
          icon: Icons.logout_rounded,
          color: AppColors.error,
          danger: true,
          onTap: () async {
            await ref.read(authControllerProvider).logout();
            if (context.mounted) {
              context.go(AppRoutes.login);
            }
          },
        ),
      ],
    );
  }
}

class _ProfileActionTile extends StatelessWidget {
  const _ProfileActionTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
    this.danger = false,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    return AppSectionCard(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(30),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: danger ? AppColors.error : AppColors.textDark,
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
                ],
              ),
            ),
            const SizedBox(width: 12),
            Icon(
              Icons.arrow_forward_rounded,
              color: danger ? AppColors.error : AppColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}
