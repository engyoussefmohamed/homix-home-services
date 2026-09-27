import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../constants/app_theme.dart';
import '../../core/app_localizations.dart';
import '../../core/app_router.dart';
import '../../providers/auth_controller.dart';
import '../../providers/locale_controller.dart';
import '../../widgets/app_widgets.dart';

class RegisterTechnicianScreen extends ConsumerStatefulWidget {
  const RegisterTechnicianScreen({super.key});

  @override
  ConsumerState<RegisterTechnicianScreen> createState() =>
      _RegisterTechnicianScreenState();
}

class _RegisterTechnicianScreenState
    extends ConsumerState<RegisterTechnicianScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _title = TextEditingController();
  final _category = TextEditingController();
  final _city = TextEditingController();
  final _hourlyRate = TextEditingController(text: '90');
  final _yearsExperience = TextEditingController(text: '3');
  final _bio = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _password.dispose();
    _title.dispose();
    _category.dispose();
    _city.dispose();
    _hourlyRate.dispose();
    _yearsExperience.dispose();
    _bio.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    String t(String ar, String en) => context.tr(ar: ar, en: en);

    return HomixPage(
      title: t('تسجيل فني', 'Technician registration'),
      header: AppBanner(
        title: t(
          'قدّم خبرتك داخل واجهة تليق بفني محترف',
          'Present your expertise in a flow fit for a pro technician',
        ),
        message: t(
          'رتبنا بياناتك المهنية، التسعير، والنبذة داخل رحلة أوضح تمهد للحجوزات والأرباح والتقييمات.',
          'Your profile, pricing, and bio are now organized for bookings, earnings, and reviews.',
        ),
        icon: Icons.engineering_rounded,
        background: AppColors.secondarySoft,
        foreground: AppColors.secondary,
      ),
      child: ListView(
        children: [
          DashboardHero(
            title: t(
              'افتح حسابك كفني وابدأ الظهور واستقبال الطلبات مباشرة',
              'Open your technician account and start receiving jobs directly',
            ),
            subtitle: t('رحلة الفني', 'Technician journey'),
            chips: [
              HeroTagChip(label: t('حجوزات', 'Bookings')),
              HeroTagChip(label: t('أرباح', 'Earnings')),
              HeroTagChip(label: t('تقييمات', 'Reviews'), highlight: true),
            ],
            trailing: Container(
              width: 106,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: Column(
                children: [
                  const Text(
                    'Pro',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    t('ظهور أفضل لاحقًا', 'Better ranking later'),
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
                  label: t('الملف المهني', 'Profile setup'),
                  value: t('أوضح', 'Clear'),
                  color: AppColors.secondary,
                  icon: Icons.badge_rounded,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatTile(
                  label: t('جاهزية الحجز', 'Booking readiness'),
                  value: t('سريعة', 'Fast'),
                  color: AppColors.primary,
                  icon: Icons.calendar_month_rounded,
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
                    title: t('بيانات الحساب', 'Account details'),
                    subtitle: t(
                      'هذه البيانات تُنشئ حساب الفني وتسمح لك بالدخول إلى لوحة التحكم.',
                      'These details create the technician account and let you access the dashboard.',
                    ),
                  ),
                  const SizedBox(height: 14),
                  _field(
                    _name,
                    t('الاسم الكامل', 'Full name'),
                    Icons.person_rounded,
                    hintLocales: const [arabicLocale],
                  ),
                  const SizedBox(height: 12),
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
                  const SizedBox(height: 12),
                  _field(
                    _phone,
                    t('رقم الهاتف', 'Phone number'),
                    Icons.phone_rounded,
                    textDirection: TextDirection.ltr,
                    hintLocales: supportedAppLocales,
                  ),
                  const SizedBox(height: 12),
                  AppTextFormField(
                    controller: _password,
                    hintLocales: supportedAppLocales,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: t('كلمة المرور', 'Password'),
                      prefixIcon: const Icon(Icons.lock_rounded),
                    ),
                    textDirection: TextDirection.ltr,
                    validator: (value) => (value == null || value.length < 8)
                        ? t('الحد الأدنى 8 أحرف', 'Minimum 8 characters')
                        : null,
                  ),
                  const SizedBox(height: 18),
                  SectionHeading(
                    title: t('الهوية المهنية', 'Professional identity'),
                    subtitle: t(
                      'حدد التخصص والمسمى والمنطقة حتى تظهر للعملاء بصورة أوضح.',
                      'Define your specialty, title, and area so you appear more clearly to customers.',
                    ),
                  ),
                  const SizedBox(height: 14),
                  _field(
                    _title,
                    t('المسمى المهني', 'Professional title'),
                    Icons.badge_rounded,
                    hintLocales: const [arabicLocale],
                  ),
                  const SizedBox(height: 12),
                  _field(
                    _category,
                    t('التخصص', 'Specialty'),
                    Icons.handyman_rounded,
                    hintLocales: const [arabicLocale],
                  ),
                  const SizedBox(height: 12),
                  _field(
                    _city,
                    t('المدينة / المنطقة', 'City / area'),
                    Icons.location_on_rounded,
                    hintLocales: const [arabicLocale],
                  ),
                  const SizedBox(height: 18),
                  SectionHeading(
                    title: t('التسعير والخبرة', 'Pricing and experience'),
                    subtitle: t(
                      'هذه المعلومات تظهر بوضوح للعميل وتساعده على اتخاذ القرار بسرعة.',
                      'These details help customers decide faster and build trust in your profile.',
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: AppTextFormField(
                          controller: _hourlyRate,
                          hintLocales: supportedAppLocales,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: t('سعر الساعة', 'Hourly rate'),
                            prefixIcon: const Icon(Icons.payments_rounded),
                          ),
                          textDirection: TextDirection.ltr,
                          validator: _required,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: AppTextFormField(
                          controller: _yearsExperience,
                          hintLocales: supportedAppLocales,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: t('سنوات الخبرة', 'Years of experience'),
                            prefixIcon: const Icon(
                              Icons.workspace_premium_rounded,
                            ),
                          ),
                          textDirection: TextDirection.ltr,
                          validator: _required,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  AppTextFormField(
                    controller: _bio,
                    hintLocales: const [arabicLocale],
                    maxLines: 4,
                    decoration: InputDecoration(
                      labelText: t('نبذة عنك', 'About you'),
                      prefixIcon: const Icon(Icons.notes_rounded),
                    ),
                    textDirection: TextDirection.rtl,
                    validator: (value) =>
                        (value == null || value.trim().length < 10)
                        ? t('اكتب نبذة أوضح', 'Write a clearer bio')
                        : null,
                  ),
                  if ((auth.errorMessage ?? '').isNotEmpty) ...[
                    const SizedBox(height: 14),
                    AppBanner(
                      title: t(
                        'تعذر إنشاء حساب الفني',
                        'Could not create technician account',
                      ),
                      message: auth.errorMessage!,
                      icon: Icons.error_outline_rounded,
                      background: AppColors.errorSoft,
                      foreground: AppColors.error,
                    ),
                  ],
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: auth.isLoading ? null : _submit,
                    icon: const Icon(Icons.engineering_rounded),
                    label: Text(
                      auth.isLoading
                          ? t('جارٍ إنشاء الحساب...', 'Creating account...')
                          : t('إنشاء حساب الفني', 'Create technician account'),
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
                  t(
                    'ما الذي سيفتحه هذا الحساب؟',
                    'What does this account unlock?',
                  ),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  t(
                    'بعد التسجيل ستحصل على لوحة فني لمتابعة الحجوزات، إدارة التوفر، مراجعة الأرباح، وطلب السحب.',
                    'After sign-up, you will access a technician dashboard for bookings, availability, earnings, and payout requests.',
                  ),
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    height: 1.7,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                _TechnicianBenefitRow(
                  icon: Icons.assignment_rounded,
                  color: AppColors.primary,
                  title: t('إدارة الحجوزات', 'Booking management'),
                  subtitle: t(
                    'اعرض الطلبات وحدث الحالة من لوحة واحدة',
                    'View requests and update status from one dashboard',
                  ),
                ),
                const SizedBox(height: 12),
                _TechnicianBenefitRow(
                  icon: Icons.attach_money_rounded,
                  color: AppColors.secondary,
                  title: t('الأرباح والسحب', 'Earnings and payouts'),
                  subtitle: t(
                    'راجع الرصيد واطلب السحب داخل واجهة مرتبة',
                    'Track balance and request payouts from a tidy interface',
                  ),
                ),
                const SizedBox(height: 12),
                _TechnicianBenefitRow(
                  icon: Icons.workspace_premium_rounded,
                  color: AppColors.accentDark,
                  title: t('الظهور والاشتراك', 'Visibility and plans'),
                  subtitle: t(
                    'طوّر ترتيبك داخل السوق لاحقًا عبر الباقات',
                    'Improve your marketplace ranking later through plans',
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

  Widget _field(
    TextEditingController controller,
    String label,
    IconData icon, {
    TextDirection textDirection = TextDirection.rtl,
    List<Locale>? hintLocales,
  }) {
    return AppTextFormField(
      controller: controller,
      decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
      textDirection: textDirection,
      hintLocales: hintLocales,
      validator: _required,
    );
  }

  String? _required(String? value) => (value == null || value.trim().isEmpty)
      ? context.tr(ar: 'هذا الحقل مطلوب', en: 'This field is required')
      : null;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final ok = await ref
        .read(authControllerProvider)
        .registerTechnician(
          name: _name.text.trim(),
          email: _email.text.trim(),
          password: _password.text.trim(),
          phone: _phone.text.trim(),
          title: _title.text.trim(),
          category: _category.text.trim(),
          city: _city.text.trim(),
          hourlyRate: double.tryParse(_hourlyRate.text.trim()) ?? 0,
          yearsExperience: double.tryParse(_yearsExperience.text.trim()) ?? 0,
          bio: _bio.text.trim(),
        );
    if (!mounted || !ok) return;
    context.go(AppRoutes.technicianDashboard);
  }
}

class _TechnicianBenefitRow extends StatelessWidget {
  const _TechnicianBenefitRow({
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
