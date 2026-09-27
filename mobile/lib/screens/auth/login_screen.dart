import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../constants/app_theme.dart';
import '../../core/app_localizations.dart';
import '../../core/app_router.dart';
import '../../providers/auth_controller.dart';
import '../../providers/locale_controller.dart';
import '../../widgets/app_widgets.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    String t(String ar, String en) => context.tr(ar: ar, en: en);

    return HomixPage(
      title: t('تسجيل الدخول', 'Login'),
      header: AppBanner(
        title: t(
          'واجهة مصممة لتُعرض بثقة',
          'Designed to be shown with confidence',
        ),
        message: t(
          'شكل أوضح، مسافات أنظف، وهوية أقوى من أول شاشة وحتى تنفيذ الطلب.',
          'Clearer spacing, stronger identity, and a more premium feel from the first screen.',
        ),
        icon: Icons.auto_awesome_rounded,
        background: AppColors.primarySoft,
        foreground: AppColors.primaryDark,
      ),
      child: ListView(
        children: [
          DashboardHero(
            title: t(
              'ادخل إلى تجربة Homix الجديدة واستكمل رحلتك بأناقة وسرعة',
              'Step into the new Homix experience and continue with speed and style',
            ),
            subtitle: t(
              'تسجيل دخول أنظف بصريًا وأكثر إقناعًا للعميل',
              'Cleaner sign-in, stronger first impression',
            ),
            chips: [
              HeroTagChip(label: t('تقديرات', 'Estimates')),
              HeroTagChip(label: t('فنيون', 'Technicians')),
              HeroTagChip(label: t('متجر', 'Shop'), highlight: true),
            ],
            trailing: Container(
              width: 92,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: Column(
                children: [
                  const Text(
                    '3',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    t('أدوار رئيسية', 'Core roles'),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.84),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: StatTile(
                  label: t('رحلة مرتبة بصريًا', 'Organized visual flow'),
                  value: t('واضح', 'Clear'),
                  color: AppColors.primary,
                  icon: Icons.layers_rounded,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatTile(
                  label: t('انتقال سلس بين المهام', 'Smooth transitions'),
                  value: t('سريع', 'Fast'),
                  color: AppColors.accent,
                  icon: Icons.flash_on_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          AppSectionCard(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          t('بيانات الدخول', 'Login details'),
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      AppStatusBadge(
                        label: t('آمن', 'Secure'),
                        foreground: AppColors.secondary,
                        background: AppColors.secondarySoft,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    t(
                      'سجل الدخول للوصول إلى التقديرات، الفنيين، الطلبات، والمتجر داخل تجربة موحّدة.',
                      'Sign in to reach estimates, technicians, orders, and the shop inside one unified experience.',
                    ),
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      height: 1.7,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 18),
                  AppTextFormField(
                    controller: _emailController,
                    textDirection: TextDirection.ltr,
                    hintLocales: const [englishLocale],
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: t('البريد الإلكتروني', 'Email address'),
                      prefixIcon: const Icon(Icons.alternate_email_rounded),
                    ),
                    validator: (value) =>
                        (value == null || !value.contains('@'))
                        ? t('أدخل بريدًا صحيحًا', 'Enter a valid email')
                        : null,
                  ),
                  const SizedBox(height: 14),
                  AppTextFormField(
                    controller: _passwordController,
                    textDirection: TextDirection.ltr,
                    hintLocales: supportedAppLocales,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: t('كلمة المرور', 'Password'),
                      prefixIcon: const Icon(Icons.lock_rounded),
                    ),
                    validator: (value) => (value == null || value.length < 6)
                        ? t('الحد الأدنى 6 أحرف', 'Minimum 6 characters')
                        : null,
                  ),
                  if ((auth.errorMessage ?? '').isNotEmpty) ...[
                    const SizedBox(height: 14),
                    AppBanner(
                      title: t('تعذر تسجيل الدخول', 'Login failed'),
                      message: auth.errorMessage!,
                      icon: Icons.error_outline_rounded,
                      background: AppColors.errorSoft,
                      foreground: AppColors.error,
                    ),
                  ],
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: auth.isLoading ? null : _submit,
                    icon: const Icon(Icons.login_rounded),
                    label: Text(
                      auth.isLoading
                          ? t('جارٍ تسجيل الدخول...', 'Signing in...')
                          : t('دخول', 'Login'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          AppSectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t('ابدأ حسب دورك', 'Choose the role that fits you'),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  t(
                    'لو هذه أول مرة تستخدم التطبيق، اختر نوع الحساب المناسب لك. صممنا كل مسار ليبدو مختلفًا ومناسبًا لدوره.',
                    'If this is your first time, choose the account type that fits you. Each journey is tailored to its role.',
                  ),
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    height: 1.7,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                _RoleEntryCard(
                  title: t('حساب عميل', 'Customer account'),
                  subtitle: t(
                    'للتقديرات، حجز الفنيين، ومتابعة الطلبات.',
                    'For estimates, technician booking, and order tracking.',
                  ),
                  icon: Icons.person_rounded,
                  color: AppColors.primary,
                  onTap: () => context.push(AppRoutes.registerCustomer),
                ),
                const SizedBox(height: 12),
                _RoleEntryCard(
                  title: t('حساب صاحب متجر', 'Shop owner account'),
                  subtitle: t(
                    'لإدارة المنتجات، الطلبات، ولوحة المتجر.',
                    'For products, orders, and your shop dashboard.',
                  ),
                  icon: Icons.storefront_rounded,
                  color: AppColors.accent,
                  onTap: () => context.push(AppRoutes.registerShopOwner),
                ),
                const SizedBox(height: 12),
                _RoleEntryCard(
                  title: t('حساب فني', 'Technician account'),
                  subtitle: t(
                    'للحجوزات، الأرباح، ومتابعة التقييمات.',
                    'For bookings, earnings, and review tracking.',
                  ),
                  icon: Icons.engineering_rounded,
                  color: AppColors.secondary,
                  onTap: () => context.push(AppRoutes.registerTechnician),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final ok = await ref
        .read(authControllerProvider)
        .login(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
    if (!mounted || !ok) return;
    final user = ref.read(authControllerProvider).user;
    if (user == null) return;
    context.go(AppRoutes.homeForRole(user.role));
  }
}

class _RoleEntryCard extends StatelessWidget {
  const _RoleEntryCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              color.withValues(alpha: 0.12),
              color.withValues(alpha: 0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: color.withValues(alpha: 0.14)),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.16),
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
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
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
            Icon(Icons.arrow_forward_rounded, color: color),
          ],
        ),
      ),
    );
  }
}
