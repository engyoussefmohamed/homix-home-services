import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../constants/app_theme.dart';
import '../../core/app_localizations.dart';
import '../../core/app_router.dart';
import '../../providers/auth_controller.dart';
import '../../providers/locale_controller.dart';
import '../../widgets/app_widgets.dart';

class RegisterCustomerScreen extends ConsumerStatefulWidget {
  const RegisterCustomerScreen({super.key});

  @override
  ConsumerState<RegisterCustomerScreen> createState() =>
      _RegisterCustomerScreenState();
}

class _RegisterCustomerScreenState
    extends ConsumerState<RegisterCustomerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    String t(String ar, String en) => context.tr(ar: ar, en: en);

    return HomixPage(
      title: t('حساب عميل جديد', 'New customer account'),
      header: AppBanner(
        title: t(
          'ابدأ رحلتك مع Homix من أول شاشة بشكل يليق بالعميل',
          'Start your Homix journey with a premium first impression',
        ),
        message: t(
          'فتح الحساب صار أوضح، أسرع، وأسهل تمهيدًا للتقدير، الحجز، والشراء داخل تجربة موحدة.',
          'Account creation is now clearer and faster before estimation, booking, and shopping.',
        ),
        icon: Icons.person_add_alt_1_rounded,
        background: AppColors.primarySoft,
        foreground: AppColors.primaryDark,
      ),
      child: ListView(
        children: [
          DashboardHero(
            title: t(
              'أنشئ حسابك وانطلق إلى التقدير والحجز والمتجر بثقة',
              'Create your account and move to estimates, booking, and shopping with confidence',
            ),
            subtitle: t('رحلة العميل', 'Customer journey'),
            chips: [
              HeroTagChip(label: t('تقديرات', 'Estimates')),
              HeroTagChip(label: t('فنيون', 'Technicians')),
              HeroTagChip(label: t('متجر', 'Shop'), highlight: true),
            ],
            trailing: Container(
              width: 102,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: Column(
                children: [
                  const Text(
                    '1',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    t('خطوة البداية', 'Start step'),
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
                  label: t('تجربة التسجيل', 'Sign-up flow'),
                  value: t('أوضح', 'Clearer'),
                  color: AppColors.primary,
                  icon: Icons.layers_rounded,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatTile(
                  label: t('الانطلاق', 'Get started'),
                  value: t('أسرع', 'Faster'),
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
                          t('بيانات الحساب', 'Account details'),
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      AppStatusBadge(
                        label: t('مؤمن', 'Secure'),
                        foreground: AppColors.secondary,
                        background: AppColors.secondarySoft,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    t(
                      'املأ بياناتك مرة واحدة لتبدأ استخدام التقديرات، متابعة الطلبات، والحجز مع الفنيين داخل حساب واحد.',
                      'Fill in your details once to access estimates, order tracking, and technician booking inside one account.',
                    ),
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      height: 1.7,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 18),
                  AppTextFormField(
                    controller: _name,
                    hintLocales: const [arabicLocale],
                    decoration: InputDecoration(
                      labelText: t('الاسم الكامل', 'Full name'),
                      prefixIcon: const Icon(Icons.person_rounded),
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
                  if ((auth.errorMessage ?? '').isNotEmpty) ...[
                    const SizedBox(height: 14),
                    AppBanner(
                      title: t('تعذر إنشاء الحساب', 'Could not create account'),
                      message: auth.errorMessage!,
                      icon: Icons.error_outline_rounded,
                      background: AppColors.errorSoft,
                      foreground: AppColors.error,
                    ),
                  ],
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: auth.isLoading ? null : _submit,
                    icon: const Icon(Icons.person_add_alt_1_rounded),
                    label: Text(
                      auth.isLoading
                          ? t('جارٍ إنشاء الحساب...', 'Creating account...')
                          : t('إنشاء الحساب', 'Create account'),
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
                  t('ما الذي ستحصل عليه؟', 'What do you unlock?'),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  t(
                    'بعد إنشاء الحساب يمكنك بدء التقديرات، استكشاف الفنيين، والشراء من المتجر من نفس المساحة.',
                    'After account creation, you can start estimates, explore technicians, and shop from the same place.',
                  ),
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    height: 1.7,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                _RegisterBenefitTile(
                  icon: Icons.auto_awesome_rounded,
                  color: AppColors.primary,
                  title: t('تقدير بصري سريع', 'Fast visual estimate'),
                  subtitle: t(
                    'ارفع الصورة وخذ قراءة أولية قبل الشراء أو الحجز',
                    'Upload an image and get an early read before buying or booking',
                  ),
                ),
                const SizedBox(height: 12),
                _RegisterBenefitTile(
                  icon: Icons.engineering_rounded,
                  color: AppColors.accentDark,
                  title: t('الوصول إلى الفنيين', 'Access technicians'),
                  subtitle: t(
                    'راجع الملفات، احجز، وتابع الحالة داخل تجربة واحدة',
                    'Review profiles, book, and track status in one journey',
                  ),
                ),
                const SizedBox(height: 12),
                _RegisterBenefitTile(
                  icon: Icons.storefront_rounded,
                  color: AppColors.secondary,
                  title: t('متجر مرتب وواضح', 'A clearer shop'),
                  subtitle: t(
                    'اطلب المنتجات وتابع الطلبات بسهولة من حسابك',
                    'Order products and follow orders easily from your account',
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
        .registerCustomer(
          name: _name.text.trim(),
          email: _email.text.trim(),
          password: _password.text.trim(),
          phone: _phone.text.trim(),
        );
    if (!mounted || !ok) return;
    context.go(AppRoutes.customerHome);
  }
}

class _RegisterBenefitTile extends StatelessWidget {
  const _RegisterBenefitTile({
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
