import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../constants/app_theme.dart';
import '../../core/app_localizations.dart';
import '../../core/app_router.dart';
import '../../models/subscription_models.dart';
import '../../providers/auth_controller.dart';
import '../../services/api_service.dart';
import '../../widgets/app_widgets.dart';
import 'technician_dashboard_screen.dart';

final technicianPlansProvider =
    FutureProvider.autoDispose<List<SubscriptionPlanItem>>(
      (ref) => ref.watch(apiServiceProvider).getSubscriptionPlans(),
    );

final myTechnicianSubscriptionProvider =
    FutureProvider.autoDispose<SubscriptionSnapshot>((ref) async {
      final token = ref.watch(authControllerProvider).token;
      if (token == null || token.isEmpty) {
        throw Exception('يجب تسجيل الدخول بحساب فني.');
      }
      return ref.watch(apiServiceProvider).getMyTechnicianSubscription(token);
    });

class TechnicianSubscriptionScreen extends ConsumerStatefulWidget {
  const TechnicianSubscriptionScreen({super.key});

  @override
  ConsumerState<TechnicianSubscriptionScreen> createState() =>
      _TechnicianSubscriptionScreenState();
}

class _TechnicianSubscriptionScreenState
    extends ConsumerState<TechnicianSubscriptionScreen> {
  bool _busy = false;
  String? _selectedCode;
  int _durationMonths = 1;

  @override
  Widget build(BuildContext context) {
    final token = ref.watch(authControllerProvider).token;
    final plansAsync = ref.watch(technicianPlansProvider);
    final currentAsync = ref.watch(myTechnicianSubscriptionProvider);

    return HomixPage(
      title: context.tr(ar: 'اشتراك الفني', en: 'Technician subscription'),
      header: AppBanner(
        title: context.tr(
          ar: 'اختيار الباقة صار أوضح وأسهل للمقارنة',
          en: 'Choosing a plan is now clearer and easier to compare',
        ),
        message: context.tr(
          ar: 'رتبنا مزايا كل باقة ومدتها والتكلفة الإجمالية داخل واجهة تساعد الفني على اتخاذ قرار أسرع.',
          en: 'Plan benefits, duration, and total pricing are now easier to compare and decide on.',
        ),
        icon: Icons.workspace_premium_rounded,
        background: AppColors.secondarySoft,
        foreground: AppColors.secondary,
      ),
      child: plansAsync.when(
        data: (plans) => currentAsync.when(
          data: (current) {
            if (plans.isEmpty) {
              return AsyncPlaceholder(
                message: context.tr(
                  ar: 'لا توجد باقات متاحة حاليًا.',
                  en: 'There are no plans available right now.',
                ),
              );
            }

            final selectedCode =
                _selectedCode ??
                (current.isPro
                    ? current.planCode
                    : (plans.any((plan) => plan.code == 'pro')
                          ? 'pro'
                          : plans.first.code));
            final selectedPlan = plans.firstWhere(
              (plan) => plan.code == selectedCode,
              orElse: () => plans.first,
            );
            if (!selectedPlan.supportedDurations.contains(_durationMonths)) {
              _durationMonths = selectedPlan.supportedDurations.first;
            }
            final totalPrice = selectedPlan.totalPriceFor(_durationMonths);
            final commissionDelta =
                current.commissionRate - selectedPlan.commissionRate;

            return ListView(
              children: [
                DashboardHero(
                  title: context.tr(
                    ar: 'اختر الباقة المناسبة لظهورك وشغلك',
                    en: 'Choose the right plan for your visibility and work',
                  ),
                  subtitle: context.tr(
                    ar: 'الباقة الحالية: ${current.planName}',
                    en: 'Current plan: ${current.planName}',
                  ),
                  chips: [
                    HeroTagChip(
                      label: current.planName,
                      highlight: current.isPro,
                    ),
                    HeroTagChip(
                      label: context.tr(
                        ar: 'عمولة ${current.commissionRate.toStringAsFixed(0)}%',
                        en: 'Commission ${current.commissionRate.toStringAsFixed(0)}%',
                      ),
                    ),
                    HeroTagChip(
                      label: current.verifiedBadge
                          ? context.tr(ar: 'شارة موثقة', en: 'Verified badge')
                          : context.tr(ar: 'بدون شارة', en: 'No badge'),
                    ),
                  ],
                  trailing: Container(
                    width: 114,
                    padding: const EdgeInsets.all(16),
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
                          current.monthlyPrice.toStringAsFixed(0),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          context.tr(ar: 'السعر الشهري', en: 'Monthly price'),
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
                Row(
                  children: [
                    Expanded(
                      child: StatTile(
                        label: context.tr(
                          ar: 'الخطة الحالية',
                          en: 'Current plan',
                        ),
                        value: current.planName,
                        color: AppColors.secondary,
                        icon: Icons.verified_rounded,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: StatTile(
                        label: context.tr(ar: 'العمولة', en: 'Commission'),
                        value: '${current.commissionRate.toStringAsFixed(0)}%',
                        color: AppColors.accent,
                        icon: Icons.percent_rounded,
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
                          ar: 'الشارة الموثقة',
                          en: 'Verified badge',
                        ),
                        value: current.verifiedBadge
                            ? context.tr(ar: 'مفعلة', en: 'Enabled')
                            : context.tr(ar: 'غير مفعلة', en: 'Disabled'),
                        background: AppColors.successSoft,
                        valueColor: AppColors.success,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: MetricPill(
                        label: context.tr(
                          ar: 'الدعم الفني',
                          en: 'Support level',
                        ),
                        value: current.guaranteedSupport
                            ? context.tr(ar: 'أولوية', en: 'Priority')
                            : context.tr(ar: 'قياسي', en: 'Standard'),
                        background: AppColors.secondarySoft,
                        valueColor: AppColors.secondary,
                      ),
                    ),
                  ],
                ),
                if (current.expiresAt != null) ...[
                  const SizedBox(height: 12),
                  AppSectionCard(
                    color: AppColors.primarySoft,
                    child: Row(
                      children: [
                        const Icon(
                          Icons.calendar_today_rounded,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            context.tr(
                              ar: 'ينتهي الاشتراك الحالي: ${_formatDate(current.expiresAt!)}',
                              en: 'Current plan expires: ${_formatDate(current.expiresAt!)}',
                            ),
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 18),
                SectionHeading(
                  title: context.tr(
                    ar: 'مقارنة الباقات',
                    en: 'Plan comparison',
                  ),
                  subtitle: context.tr(
                    ar: 'كل بطاقة توضح التأثير العملي على الظهور والعمولة والدعم حتى تختار بثقة.',
                    en: 'Each card highlights visibility, commission, and support so you can choose confidently.',
                  ),
                ),
                const SizedBox(height: 12),
                ...plans.map(
                  (plan) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _TechnicianPlanCard(
                      plan: plan,
                      isCurrent: current.planCode == plan.code,
                      selected: selectedCode == plan.code,
                      onSelect: () => setState(() => _selectedCode = plan.code),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                AppSectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SectionHeading(
                        title: context.tr(
                          ar: 'مدة الاشتراك',
                          en: 'Subscription duration',
                        ),
                        subtitle: context.tr(
                          ar: 'اختر المدة المناسبة ليظهر لك السعر الإجمالي مباشرة مع ملخص واضح للقرار.',
                          en: 'Choose a duration to instantly preview the full cost with a clear decision summary.',
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: selectedPlan.supportedDurations
                            .map(
                              (months) => _DurationChip(
                                label: _durationLabel(context, months),
                                selected: _durationMonths == months,
                                onTap: () =>
                                    setState(() => _durationMonths = months),
                              ),
                            )
                            .toList(),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.primaryDark.withValues(alpha: 0.98),
                              AppColors.primary.withValues(alpha: 0.92),
                            ],
                            begin: Alignment.topRight,
                            end: Alignment.bottomLeft,
                          ),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: const Icon(
                                    Icons.auto_graph_rounded,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        selectedPlan.name,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        context.tr(
                                          ar: 'ملخص قرار الاشتراك لمدة ${_durationLabel(context, _durationMonths)}',
                                          en: 'Decision summary for ${_durationLabel(context, _durationMonths)}',
                                        ),
                                        style: TextStyle(
                                          color: Colors.white.withValues(
                                            alpha: 0.8,
                                          ),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: _DecisionMetric(
                                    label: context.tr(
                                      ar: 'إجمالي السعر',
                                      en: 'Total price',
                                    ),
                                    value:
                                        '${totalPrice.toStringAsFixed(0)} ${context.tr(ar: 'ج.م', en: 'EGP')}',
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _DecisionMetric(
                                    label: context.tr(
                                      ar: 'العمولة الجديدة',
                                      en: 'New commission',
                                    ),
                                    value:
                                        '${selectedPlan.commissionRate.toStringAsFixed(0)}%',
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: _DecisionMetric(
                                    label: context.tr(
                                      ar: 'أولوية الظهور',
                                      en: 'Visibility priority',
                                    ),
                                    value: selectedPlan.priorityRank > 0
                                        ? context.tr(ar: 'مرتفعة', en: 'High')
                                        : context.tr(
                                            ar: 'قياسية',
                                            en: 'Standard',
                                          ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _DecisionMetric(
                                    label: context.tr(
                                      ar: 'فرق العمولة',
                                      en: 'Commission delta',
                                    ),
                                    value: commissionDelta > 0
                                        ? context.tr(
                                            ar: '-${commissionDelta.toStringAsFixed(0)}%',
                                            en: '-${commissionDelta.toStringAsFixed(0)}%',
                                          )
                                        : commissionDelta < 0
                                        ? context.tr(
                                            ar: '+${commissionDelta.abs().toStringAsFixed(0)}%',
                                            en: '+${commissionDelta.abs().toStringAsFixed(0)}%',
                                          )
                                        : context.tr(
                                            ar: 'بدون تغيير',
                                            en: 'No change',
                                          ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                AppSectionCard(
                  color: AppColors.accentSoft,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.75),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.tips_and_updates_rounded,
                          color: AppColors.accentDark,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              context.tr(
                                ar: 'ما الذي ستحصل عليه عمليًا؟',
                                en: 'What changes in practice?',
                              ),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: AppColors.accentDark,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              context.tr(
                                ar: 'الباقة المختارة تعطيك ${selectedPlan.priorityRank > 0 ? 'أفضلية أعلى في الظهور' : 'ظهورًا قياسيًا'} مع ${selectedPlan.guaranteedSupport ? 'دعم سريع' : 'دعم قياسي'} و${selectedPlan.verifiedBadge ? 'شارة موثقة تقوي الثقة' : 'بدون شارة موثقة'}.',
                                en: 'The selected plan gives you ${selectedPlan.priorityRank > 0 ? 'higher visibility priority' : 'standard visibility'}, ${selectedPlan.guaranteedSupport ? 'priority support' : 'standard support'}, and ${selectedPlan.verifiedBadge ? 'a verified badge for trust' : 'no verified badge'}.',
                              ),
                              style: const TextStyle(
                                color: AppColors.accentDark,
                                height: 1.6,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: token == null || _busy
                            ? null
                            : () => _subscribe(token, selectedPlan.code),
                        child: Text(
                          _busy
                              ? context.tr(
                                  ar: 'جارٍ تنفيذ الاشتراك...',
                                  en: 'Updating subscription...',
                                )
                              : context.tr(
                                  ar: 'تأكيد الاشتراك',
                                  en: 'Confirm subscription',
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => context.push(AppRoutes.billingHistory),
                        child: Text(
                          context.tr(
                            ar: 'سجل المدفوعات',
                            en: 'Billing history',
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => AsyncPlaceholder(message: error.toString()),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => AsyncPlaceholder(message: error.toString()),
      ),
    );
  }

  Future<void> _subscribe(String token, String planCode) async {
    setState(() => _busy = true);
    try {
      await ref
          .read(apiServiceProvider)
          .subscribeCurrentTechnician(
            token: token,
            planCode: planCode,
            durationMonths: _durationMonths,
          );
      ref.invalidate(myTechnicianSubscriptionProvider);
      ref.invalidate(myTechnicianProfileProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.tr(
              ar: 'تم تحديث الاشتراك بنجاح',
              en: 'Subscription updated successfully',
            ),
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _formatDate(DateTime value) {
    return DateFormat('yyyy/MM/dd • hh:mm a').format(value.toLocal());
  }
}

class _TechnicianPlanCard extends StatelessWidget {
  const _TechnicianPlanCard({
    required this.plan,
    required this.isCurrent,
    required this.selected,
    required this.onSelect,
  });

  final SubscriptionPlanItem plan;
  final bool isCurrent;
  final bool selected;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    final isPremium = plan.code == 'pro';

    return GestureDetector(
      onTap: onSelect,
      child: AppSectionCard(
        color: selected ? AppColors.primarySoft : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          if (isPremium)
                            AppStatusBadge(
                              label: context.tr(
                                ar: 'موصى بها',
                                en: 'Recommended',
                              ),
                              foreground: AppColors.accentDark,
                              background: AppColors.accentSoft,
                            ),
                          if (isCurrent)
                            AppStatusBadge(
                              label: context.tr(
                                ar: 'الخطة الحالية',
                                en: 'Current plan',
                              ),
                              foreground: AppColors.success,
                              background: AppColors.successSoft,
                            ),
                        ],
                      ),
                      if (isPremium || isCurrent) const SizedBox(height: 10),
                      Text(
                        plan.name,
                        style: const TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        plan.description,
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          height: 1.6,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    gradient: selected
                        ? const LinearGradient(
                            colors: [AppColors.primaryDark, AppColors.primary],
                            begin: Alignment.topRight,
                            end: Alignment.bottomLeft,
                          )
                        : const LinearGradient(
                            colors: [
                              AppColors.backgroundTertiary,
                              AppColors.cardWhite,
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: selected ? Colors.transparent : AppColors.border,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        plan.monthlyPrice.toStringAsFixed(0),
                        style: TextStyle(
                          color: selected ? Colors.white : AppColors.primary,
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        context.tr(ar: 'ج / شهر', en: 'EGP / month'),
                        style: TextStyle(
                          color: selected
                              ? Colors.white.withValues(alpha: 0.84)
                              : AppColors.textMuted,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: MetricPill(
                    label: context.tr(ar: 'العمولة', en: 'Commission'),
                    value: '${plan.commissionRate.toStringAsFixed(0)}%',
                    background: AppColors.accentSoft,
                    valueColor: AppColors.accentDark,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: MetricPill(
                    label: context.tr(ar: 'أولوية الظهور', en: 'Priority'),
                    value: plan.priorityRank > 0
                        ? context.tr(ar: 'مرتفعة', en: 'High')
                        : context.tr(ar: 'قياسية', en: 'Standard'),
                    background: AppColors.primarySoft,
                    valueColor: AppColors.primaryDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: selected
                    ? Colors.white.withValues(alpha: 0.6)
                    : AppColors.backgroundTertiary,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  _PlanBenefitRow(
                    icon: plan.verifiedBadge
                        ? Icons.verified_rounded
                        : Icons.remove_moderator_outlined,
                    label: context.tr(ar: 'شارة موثقة', en: 'Verified badge'),
                    value: plan.verifiedBadge
                        ? context.tr(ar: 'نعم', en: 'Yes')
                        : context.tr(ar: 'لا', en: 'No'),
                  ),
                  const SizedBox(height: 10),
                  _PlanBenefitRow(
                    icon: plan.guaranteedSupport
                        ? Icons.support_agent_rounded
                        : Icons.support_outlined,
                    label: context.tr(ar: 'دعم مميز', en: 'Priority support'),
                    value: plan.guaranteedSupport
                        ? context.tr(ar: 'متاح', en: 'Included')
                        : context.tr(ar: 'غير متاح', en: 'Not included'),
                  ),
                  const SizedBox(height: 10),
                  _PlanBenefitRow(
                    icon: Icons.calendar_view_week_rounded,
                    label: context.tr(ar: 'مدد الدفع', en: 'Billing durations'),
                    value: plan.supportedDurations
                        .map((months) => _durationLabel(context, months))
                        .join(' • '),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlanBenefitRow extends StatelessWidget {
  const _PlanBenefitRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.textMuted),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
      ],
    );
  }
}

class _DurationChip extends StatelessWidget {
  const _DurationChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          gradient: selected
              ? const LinearGradient(
                  colors: [AppColors.primaryDark, AppColors.primary],
                )
              : const LinearGradient(
                  colors: [AppColors.cardWhite, AppColors.backgroundTertiary],
                ),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? Colors.transparent : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : AppColors.textDark,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _DecisionMetric extends StatelessWidget {
  const _DecisionMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.74),
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

String _durationLabel(BuildContext context, int months) {
  switch (months) {
    case 1:
      return context.tr(ar: 'شهر', en: '1 month');
    case 3:
      return context.tr(ar: '3 شهور', en: '3 months');
    case 6:
      return context.tr(ar: '6 شهور', en: '6 months');
    case 12:
      return context.tr(ar: 'سنة', en: '12 months');
    default:
      return context.tr(ar: '$months شهر', en: '$months months');
  }
}
