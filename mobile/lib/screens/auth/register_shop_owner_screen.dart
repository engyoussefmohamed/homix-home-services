import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../constants/app_theme.dart';
import '../../core/app_localizations.dart';
import '../../core/app_router.dart';
import '../../providers/auth_controller.dart';
import '../../providers/locale_controller.dart';
import '../../widgets/app_widgets.dart';

class RegisterShopOwnerScreen extends ConsumerStatefulWidget {
  const RegisterShopOwnerScreen({super.key});

  @override
  ConsumerState<RegisterShopOwnerScreen> createState() =>
      _RegisterShopOwnerScreenState();
}

class _RegisterShopOwnerScreenState
    extends ConsumerState<RegisterShopOwnerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _shopName = TextEditingController();
  final _city = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _password.dispose();
    _shopName.dispose();
    _city.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    String t(String ar, String en) => context.tr(ar: ar, en: en);

    return HomixPage(
      title: t('تسجيل صاحب متجر', 'Shop owner registration'),
      header: AppBanner(
        title: t(
          'قدّم متجرك داخل واجهة أقوى وأكثر إقناعًا',
          'Present your shop in a stronger, more convincing flow',
        ),
        message: t(
          'جمعنا بيانات صاحب المتجر وهوية المتجر داخل مسار أوضح يمهد للموافقة ولوحة التحكم.',
          'Owner and shop identity are now organized in a clearer path toward approval and the dashboard.',
        ),
        icon: Icons.storefront_rounded,
        background: AppColors.accentSoft,
        foreground: AppColors.accentDark,
      ),
      child: ListView(
        children: [
          DashboardHero(
            title: t(
              'ابدأ حضور متجرك داخل Homix بشكل احترافي ومنظم',
              'Start your shop presence inside Homix with a polished setup',
            ),
            subtitle: t('رحلة المتجر', 'Shop journey'),
            chips: [
              HeroTagChip(label: t('منتجات', 'Products')),
              HeroTagChip(label: t('طلبات', 'Orders')),
              HeroTagChip(label: t('اعتماد', 'Approval'), highlight: true),
            ],
            trailing: Container(
              width: 104,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: Column(
                children: [
                  const Text(
                    '24h',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    t('انطباع أول أقوى', 'Stronger first impression'),
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
                  label: t('واجهة المتجر', 'Storefront'),
                  value: t('أوضح', 'Clear'),
                  color: AppColors.accent,
                  icon: Icons.window_rounded,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatTile(
                  label: t('رحلة الاعتماد', 'Approval path'),
                  value: t('مباشرة', 'Direct'),
                  color: AppColors.secondary,
                  icon: Icons.verified_rounded,
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
                  SectionHeading(
                    title: t('بيانات صاحب المتجر', 'Owner details'),
                    subtitle: t(
                      'هذه البيانات تستخدم لإنشاء الحساب وإدارة المتجر بعد الدخول.',
                      'These details are used to create the account and manage the shop later.',
                    ),
                  ),
                  const SizedBox(height: 14),
                  AppTextFormField(
                    controller: _name,
                    hintLocales: const [arabicLocale],
                    decoration: InputDecoration(
                      labelText: t('اسم صاحب المتجر', 'Owner name'),
                      prefixIcon: const Icon(Icons.person_outline_rounded),
                    ),
                    textDirection: TextDirection.rtl,
                    validator: _required,
                  ),
                  const SizedBox(height: 14),
                  AppTextFormField(
                    controller: _email,
                    hintLocales: const [englishLocale],
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: t('البريد الإلكتروني', 'Email address'),
                      prefixIcon: const Icon(Icons.alternate_email_rounded),
                    ),
                    textDirection: TextDirection.ltr,
                    validator: (value) =>
                        (value == null || !value.contains('@'))
                        ? t('أدخل بريدًا صالحًا', 'Enter a valid email')
                        : null,
                  ),
                  const SizedBox(height: 14),
                  AppTextFormField(
                    controller: _phone,
                    hintLocales: supportedAppLocales,
                    decoration: InputDecoration(
                      labelText: t('رقم الهاتف', 'Phone number'),
                      prefixIcon: const Icon(Icons.phone_rounded),
                    ),
                    textDirection: TextDirection.ltr,
                    validator: _required,
                  ),
                  const SizedBox(height: 14),
                  AppTextFormField(
                    controller: _password,
                    hintLocales: supportedAppLocales,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: t('كلمة المرور', 'Password'),
                      prefixIcon: const Icon(Icons.lock_rounded),
                    ),
                    textDirection: TextDirection.ltr,
                    validator: (value) => (value == null || value.length < 6)
                        ? t(
                            'يجب ألا تقل عن 6 أحرف',
                            'Must be at least 6 characters',
                          )
                        : null,
                  ),
                  const SizedBox(height: 18),
                  SectionHeading(
                    title: t('هوية المتجر', 'Shop identity'),
                    subtitle: t(
                      'ساعدنا نبني ظهورًا أوضح لمتجرك داخل السوق ولوحة التحكم.',
                      'Help us create a clearer presence for your shop inside the marketplace and dashboard.',
                    ),
                  ),
                  const SizedBox(height: 14),
                  AppTextFormField(
                    controller: _shopName,
                    hintLocales: const [arabicLocale],
                    decoration: InputDecoration(
                      labelText: t('اسم المتجر', 'Shop name'),
                      prefixIcon: const Icon(Icons.storefront_rounded),
                    ),
                    textDirection: TextDirection.rtl,
                    validator: _required,
                  ),
                  const SizedBox(height: 14),
                  AppTextFormField(
                    controller: _city,
                    hintLocales: const [arabicLocale],
                    decoration: InputDecoration(
                      labelText: t('المدينة / المنطقة', 'City / area'),
                      prefixIcon: const Icon(Icons.location_on_rounded),
                    ),
                    textDirection: TextDirection.rtl,
                    validator: _required,
                  ),
                  if ((auth.errorMessage ?? '').isNotEmpty) ...[
                    const SizedBox(height: 14),
                    AppBanner(
                      title: t('تعذر إرسال الطلب', 'Could not submit request'),
                      message: auth.errorMessage!,
                      icon: Icons.error_outline_rounded,
                      background: AppColors.errorSoft,
                      foreground: AppColors.error,
                    ),
                  ],
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: AppColors.primaryDark,
                    ),
                    onPressed: auth.isLoading ? null : _submit,
                    icon: const Icon(Icons.store_mall_directory_rounded),
                    label: Text(
                      auth.isLoading
                          ? t('جارٍ إرسال الطلب...', 'Submitting request...')
                          : t('إرسال طلب المتجر', 'Submit shop request'),
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
                  t('ماذا يحدث بعد التسجيل؟', 'What happens next?'),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  t(
                    'بعد إرسال الطلب ستدخل إلى مساحة المتجر، ويمكنك تجهيز المنتجات ومتابعة الحالة إلى أن يكتمل الاعتماد.',
                    'After submitting, you will enter the shop space where you can prepare products and follow approval progress.',
                  ),
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    height: 1.7,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                _RoleBenefitRow(
                  icon: Icons.inventory_2_rounded,
                  color: AppColors.primary,
                  title: t('إدارة المنتجات', 'Product management'),
                  subtitle: t(
                    'أضف المنتجات وراجع حالتها بوضوح',
                    'Add products and review their status clearly',
                  ),
                ),
                const SizedBox(height: 12),
                _RoleBenefitRow(
                  icon: Icons.receipt_long_rounded,
                  color: AppColors.secondary,
                  title: t('متابعة الطلبات', 'Order tracking'),
                  subtitle: t(
                    'اعرض الطلبات والمبيعات في لوحة نظيفة',
                    'View orders and sales in a cleaner dashboard',
                  ),
                ),
                const SizedBox(height: 12),
                _RoleBenefitRow(
                  icon: Icons.workspace_premium_rounded,
                  color: AppColors.accentDark,
                  title: t('إدارة الاشتراك', 'Plan management'),
                  subtitle: t(
                    'طوّر ظهور المتجر والباقات لاحقًا',
                    'Upgrade visibility and plans later',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: () => context.go(AppRoutes.login),
            icon: const Icon(Icons.login_rounded),
            label: Text(t('لدي حساب بالفعل', 'I already have an account')),
          ),
        ],
      ),
    );
  }

  String? _required(String? value) => (value == null || value.trim().isEmpty)
      ? context.tr(ar: 'هذا الحقل مطلوب', en: 'This field is required')
      : null;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final ok = await ref
        .read(authControllerProvider)
        .registerShopOwner(
          name: _name.text.trim(),
          email: _email.text.trim(),
          password: _password.text.trim(),
          phone: _phone.text.trim(),
          shopName: _shopName.text.trim(),
          city: _city.text.trim(),
        );
    if (!mounted || !ok) return;
    context.go(AppRoutes.shopDashboard);
  }
}

class _RoleBenefitRow extends StatelessWidget {
  const _RoleBenefitRow({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon, color: color),
        ),
        const SizedBox(width: 12),
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
                  height: 1.6,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
