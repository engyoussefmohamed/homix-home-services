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
import 'shop_dashboard_screen.dart';

final shopPlansProvider =
    FutureProvider.autoDispose<List<SubscriptionPlanItem>>(
      (ref) => ref.watch(apiServiceProvider).getSubscriptionPlans(),
    );

class ShopSubscriptionScreen extends ConsumerStatefulWidget {
  const ShopSubscriptionScreen({super.key});

  @override
  ConsumerState<ShopSubscriptionScreen> createState() =>
      _ShopSubscriptionScreenState();
}

class _ShopSubscriptionScreenState
    extends ConsumerState<ShopSubscriptionScreen> {
  bool _busy = false;
  String? _selectedCode;
  int _durationMonths = 1;

  @override
  Widget build(BuildContext context) {
    final token = ref.watch(authControllerProvider).token;
    final plansAsync = ref.watch(shopPlansProvider);
    final shopAsync = ref.watch(myShopProvider);

    return HomixPage(
      title: context.tr(ar: 'اشتراك المتجر', en: 'Shop subscription'),
      header: AppBanner(
        title: context.tr(
          ar: 'اختيار الباقة المناسبة لظهور متجرك',
          en: 'Choose the right plan for your shop visibility',
        ),
        message: context.tr(
          ar: 'رتبنا المقارنة بين الباقات والمزايا والتكلفة الإجمالية في شاشة أوضح لصاحب المتجر.',
          en: 'Plan comparison, benefits, and total pricing are now clearer for shop owners.',
        ),
        icon: Icons.storefront_rounded,
        background: AppColors.accentSoft,
        foreground: AppColors.accentDark,
      ),
      child: plansAsync.when(
        data: (plans) => shopAsync.when(
          data: (shop) {
            if (plans.isEmpty) {
              return AsyncPlaceholder(
                message: context.tr(
                  ar: 'لا توجد باقات متاحة حاليًا.',
                  en: 'There are no plans available right now.',
                ),
              );
            }

            final current = shop?.subscription;
            final selectedCode =
                _selectedCode ??
                (current?.isPro == true
                    ? current!.planCode
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
            final currentCommission = current?.commissionRate ?? 10;
            final commissionDelta =
                currentCommission - selectedPlan.commissionRate;

            return ListView(
              children: [
                DashboardHero(
                  title: context.tr(
                    ar: 'طوّر ظهور متجرك وبنيته التجارية',
                    en: 'Upgrade your shop visibility and commercial presence',
                  ),
                  subtitle: current == null
                      ? context.tr(
                          ar: 'لا توجد باقة مفعلة حاليًا',
                          en: 'There is no active plan right now',
                        )
                      : context.tr(
                          ar: 'الباقة الحالية: ${current.planName}',
                          en: 'Current plan: ${current.planName}',
                        ),
                  chips: [
                    HeroTagChip(
                      label:
                          current?.planName ??
                          context.tr(ar: 'بدون باقة', en: 'No plan'),
                      highlight: current?.isPro == true,
                    ),
                    HeroTagChip(
                      label: context.tr(
                        ar: 'عمولة ${currentCommission.toStringAsFixed(0)}%',
                        en: 'Commission ${currentCommission.toStringAsFixed(0)}%',
                      ),
                    ),
                    HeroTagChip(
                      label: current?.verifiedBadge == true
                          ? context.tr(ar: 'متجر موثق', en: 'Verified shop')
                          : context.tr(ar: 'متجر عادي', en: 'Standard shop'),
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
                          (current?.monthlyPrice ?? selectedPlan.monthlyPrice)
                              .toStringAsFixed(0),
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
                        value:
                            current?.planName ??
                            context.tr(ar: 'لا يوجد', en: 'None'),
                        color: AppColors.accent,
                        icon: Icons.workspace_premium_rounded,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: StatTile(
                        label: context.tr(ar: 'العمولة', en: 'Commission'),
                        value: '${currentCommission.toStringAsFixed(0)}%',
                        color: AppColors.primary,
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
                        value: current?.verifiedBadge == true
                            ? context.tr(ar: 'مفعلة', en: 'Enabled')
                            : context.tr(ar: 'غير مفعلة', en: 'Disabled'),
                        background: AppColors.successSoft,
                        valueColor: AppColors.success,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: MetricPill(
                        label: context.tr(ar: 'الدعم', en: 'Support'),
                        value: current?.guaranteedSupport == true
                            ? context.tr(ar: 'أولوية', en: 'Priority')
                            : context.tr(ar: 'قياسي', en: 'Standard'),
                        background: AppColors.secondarySoft,
                        valueColor: AppColors.secondary,
                      ),
                    ),
                  ],
                ),
                if (current?.expiresAt != null) ...[
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
                              ar: 'ينتهي الاشتراك الحالي: ${_formatDate(current!.expiresAt!)}',
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
                    ar: 'ركزنا على ما يهم المتجر فعلًا: الظهور والثقة والدعم والعمولة.',
                    en: 'We focused on what matters most for shops: visibility, trust, support, and commission.',
                  ),
                ),
                const SizedBox(height: 12),
                ...plans.map(
                  (plan) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _ShopPlanCard(
                      plan: plan,
                      isCurrent: current?.planCode == plan.code,
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
                          ar: 'اختر المدة الأنسب ليظهر لك إجمالي التكلفة وملخص القيمة التجارية مباشرة.',
                          en: 'Choose the right duration to preview total pricing and commercial value instantly.',
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: selectedPlan.supportedDurations
                            .map(
                              (months) => _ShopDurationChip(
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
                                    Icons.inventory_2_rounded,
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
                                  child: _ShopDecisionMetric(
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
                                  child: _ShopDecisionMetric(
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
                                  child: _ShopDecisionMetric(
                                    label: context.tr(
                                      ar: 'مستوى الدعم',
                                      en: 'Support level',
                                    ),
                                    value: selectedPlan.guaranteedSupport
                                        ? context.tr(
                                            ar: 'أولوية',
                                            en: 'Priority',
                                          )
                                        : context.tr(
                                            ar: 'قياسي',
                                            en: 'Standard',
                                          ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _ShopDecisionMetric(
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
                          Icons.store_mall_directory_rounded,
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
                                ar: 'أثر الباقة على المتجر',
                                en: 'Commercial impact',
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
                                ar: 'الباقة المختارة تمنح متجرك ${selectedPlan.priorityRank > 0 ? 'أفضلية أعلى في الظهور' : 'ظهورًا قياسيًا'} مع ${selectedPlan.verifiedBadge ? 'شارة موثقة تزيد الثقة' : 'تجربة متجر أساسية'} و${selectedPlan.guaranteedSupport ? 'دعمًا أسرع عند الحاجة' : 'دعمًا قياسيًا'}.',
                                en: 'The selected plan gives your shop ${selectedPlan.priorityRank > 0 ? 'higher visibility priority' : 'standard visibility'}, ${selectedPlan.verifiedBadge ? 'a verified badge that boosts trust' : 'a standard store presence'}, and ${selectedPlan.guaranteedSupport ? 'faster support when needed' : 'standard support'}.',
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
          .subscribeShop(
            token: token,
            planCode: planCode,
            durationMonths: _durationMonths,
          );
      ref.invalidate(myShopProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.tr(
              ar: 'تم تحديث اشتراك المتجر بنجاح',
              en: 'Shop subscription updated successfully',
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

class _ShopPlanCard extends StatelessWidget {
  const _ShopPlanCard({
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
                                ar: 'الأقوى نموًا',
                                en: 'Growth pick',
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
                    label: context.tr(ar: 'الظهور', en: 'Visibility'),
                    value: plan.priorityRank > 0
                        ? context.tr(ar: 'مرتفع', en: 'High')
                        : context.tr(ar: 'قياسي', en: 'Standard'),
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
                  _ShopPlanBenefitRow(
                    icon: plan.verifiedBadge
                        ? Icons.verified_rounded
                        : Icons.remove_moderator_outlined,
                    label: context.tr(ar: 'شارة موثقة', en: 'Verified badge'),
                    value: plan.verifiedBadge
                        ? context.tr(ar: 'نعم', en: 'Yes')
                        : context.tr(ar: 'لا', en: 'No'),
                  ),
                  const SizedBox(height: 10),
                  _ShopPlanBenefitRow(
                    icon: plan.guaranteedSupport
                        ? Icons.support_agent_rounded
                        : Icons.support_outlined,
                    label: context.tr(ar: 'دعم مميز', en: 'Priority support'),
                    value: plan.guaranteedSupport
                        ? context.tr(ar: 'متاح', en: 'Included')
                        : context.tr(ar: 'غير متاح', en: 'Not included'),
                  ),
                  const SizedBox(height: 10),
                  _ShopPlanBenefitRow(
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

class _ShopPlanBenefitRow extends StatelessWidget {
  const _ShopPlanBenefitRow({
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

class _ShopDurationChip extends StatelessWidget {
  const _ShopDurationChip({
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

class _ShopDecisionMetric extends StatelessWidget {
  const _ShopDecisionMetric({required this.label, required this.value});

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
