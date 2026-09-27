import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../constants/app_theme.dart';
import '../../core/app_localizations.dart';
import '../../models/subscription_models.dart';
import '../../providers/auth_controller.dart';
import '../../services/api_service.dart';
import '../../widgets/app_widgets.dart';
import '../customer/customer_home_screen.dart';

final technicianSubscriptionsProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
      final token = ref.watch(authControllerProvider).token;
      if (token == null || token.isEmpty) {
        throw Exception('يجب تسجيل الدخول بحساب مدير.');
      }
      return ref.watch(apiServiceProvider).getTechnicianSubscriptions(token);
    });

final planCatalogProvider =
    FutureProvider.autoDispose<List<SubscriptionPlanItem>>((ref) async {
      return ref.watch(apiServiceProvider).getSubscriptionPlans();
    });

class TechnicianSubscriptionsScreen extends ConsumerStatefulWidget {
  const TechnicianSubscriptionsScreen({super.key});

  @override
  ConsumerState<TechnicianSubscriptionsScreen> createState() =>
      _TechnicianSubscriptionsScreenState();
}

class _TechnicianSubscriptionsScreenState
    extends ConsumerState<TechnicianSubscriptionsScreen> {
  String _selectedPlan = 'pro';
  String? _busyTechnicianId;

  @override
  Widget build(BuildContext context) {
    final token = ref.watch(authControllerProvider).token;
    final techniciansAsync = ref.watch(technicianSubscriptionsProvider);
    final plansAsync = ref.watch(planCatalogProvider);

    return HomixPage(
      title: context.tr(ar: 'اشتراكات الفنيين', en: 'Technician subscriptions'),
      header: AppBanner(
        title: context.tr(
          ar: 'إدارة اشتراكات الفنيين أصبحت أوضح',
          en: 'Technician subscription control is now clearer',
        ),
        message: context.tr(
          ar: 'مقارنة الخطة المختارة مع الخطط الحالية للفنيين أصبحت أسرع، مع بطاقات أوضح للترقية والتفعيل.',
          en: 'Comparing the selected plan with each technician’s current subscription is now faster and clearer.',
        ),
        icon: Icons.workspace_premium_rounded,
        background: AppColors.secondarySoft,
        foreground: AppColors.secondary,
      ),
      child: plansAsync.when(
        data: (plans) {
          if (plans.isEmpty) {
            return AsyncPlaceholder(
              message: context.tr(
                ar: 'لا توجد باقات متاحة حاليًا.',
                en: 'There are no plans available right now.',
              ),
            );
          }

          final selectedPlan = plans.firstWhere(
            (plan) => plan.code == _selectedPlan,
            orElse: () => plans.first,
          );

          return techniciansAsync.when(
            data: (items) {
              final verifiedCount = items.where((item) {
                final subscription = SubscriptionSnapshot.fromJson(
                  Map<String, dynamic>.from(
                    item['subscription'] as Map? ?? const {},
                  ),
                );
                return subscription.verifiedBadge;
              }).length;
              final selectedPlanCount = items.where((item) {
                final subscription = SubscriptionSnapshot.fromJson(
                  Map<String, dynamic>.from(
                    item['subscription'] as Map? ?? const {},
                  ),
                );
                return subscription.planCode == selectedPlan.code;
              }).length;

              return ListView(
                children: [
                  DashboardHero(
                    title: context.tr(
                      ar: 'تحكم أسرع في باقات الفنيين',
                      en: 'Faster control over technician plans',
                    ),
                    subtitle: context.tr(
                      ar: 'الخطة المختارة: ${selectedPlan.name}',
                      en: 'Selected plan: ${selectedPlan.name}',
                    ),
                    chips: [
                      HeroTagChip(
                        label: context.tr(
                          ar: '${items.length} فني',
                          en: '${items.length} technicians',
                        ),
                      ),
                      HeroTagChip(label: selectedPlan.name, highlight: true),
                    ],
                    trailing: Container(
                      width: 118,
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
                            selectedPlan.monthlyPrice.toStringAsFixed(0),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          Text(
                            context.tr(ar: 'سعر شهري', en: 'Monthly fee'),
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
                            ar: 'إجمالي الفنيين',
                            en: 'Total technicians',
                          ),
                          value: '${items.length}',
                          color: AppColors.primary,
                          icon: Icons.groups_rounded,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: StatTile(
                          label: context.tr(ar: 'الموثقون', en: 'Verified'),
                          value: '$verifiedCount',
                          color: AppColors.success,
                          icon: Icons.verified_rounded,
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
                            ar: 'على الخطة المختارة',
                            en: 'On selected plan',
                          ),
                          value: '$selectedPlanCount',
                          background: AppColors.accentSoft,
                          valueColor: AppColors.accentDark,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: MetricPill(
                          label: context.tr(ar: 'العمولة', en: 'Commission'),
                          value:
                              '${selectedPlan.commissionRate.toStringAsFixed(0)}%',
                          background: AppColors.primarySoft,
                          valueColor: AppColors.primaryDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  AppSectionCard(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SectionHeading(
                          title: context.tr(
                            ar: 'اختيار الخطة',
                            en: 'Choose plan',
                          ),
                          subtitle: context.tr(
                            ar: 'اختر الخطة التي تريد تفعيلها، ثم استخدمها مباشرة من بطاقات الفنيين بالأسفل.',
                            en: 'Pick the plan you want to activate, then apply it directly from the technician cards below.',
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: plans
                              .map(
                                (plan) => _PlanSelectorChip(
                                  label: plan.name,
                                  selected: _selectedPlan == plan.code,
                                  onTap: () =>
                                      setState(() => _selectedPlan = plan.code),
                                ),
                              )
                              .toList(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (items.isEmpty)
                    AsyncPlaceholder(
                      message: context.tr(
                        ar: 'لا توجد اشتراكات فنيين لعرضها.',
                        en: 'There are no technician subscriptions to display.',
                      ),
                      icon: Icons.workspace_premium_outlined,
                    )
                  else
                    ...items.map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _TechnicianSubscriptionCard(
                          item: item,
                          selectedPlan: selectedPlan,
                          busy:
                              _busyTechnicianId ==
                              (item['id'] ?? '').toString(),
                          canUpgrade: token != null,
                          onUpgrade: () =>
                              _upgrade(token!, (item['id'] ?? '').toString()),
                        ),
                      ),
                    ),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => AsyncPlaceholder(message: error.toString()),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => AsyncPlaceholder(message: error.toString()),
      ),
    );
  }

  Future<void> _upgrade(String token, String technicianId) async {
    final successMessage = context.tr(
      ar: 'تم تحديث اشتراك الفني',
      en: 'Technician subscription updated',
    );

    setState(() => _busyTechnicianId = technicianId);
    try {
      await ref
          .read(apiServiceProvider)
          .subscribeTechnician(
            token: token,
            technicianId: technicianId,
            planCode: _selectedPlan,
          );
      ref.invalidate(technicianSubscriptionsProvider);
      ref.invalidate(techniciansProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(successMessage)));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) setState(() => _busyTechnicianId = null);
    }
  }
}

class _PlanSelectorChip extends StatelessWidget {
  const _PlanSelectorChip({
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

class _TechnicianSubscriptionCard extends StatelessWidget {
  const _TechnicianSubscriptionCard({
    required this.item,
    required this.selectedPlan,
    required this.busy,
    required this.canUpgrade,
    required this.onUpgrade,
  });

  final Map<String, dynamic> item;
  final SubscriptionPlanItem selectedPlan;
  final bool busy;
  final bool canUpgrade;
  final VoidCallback onUpgrade;

  @override
  Widget build(BuildContext context) {
    final subscription = SubscriptionSnapshot.fromJson(
      Map<String, dynamic>.from(item['subscription'] as Map? ?? const {}),
    );
    final name = (item['name'] ?? '').toString();
    final category = (item['category'] ?? '').toString();
    final city = (item['city'] ?? '').toString();
    final expiresAt = subscription.expiresAt;

    return AppSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 62,
                height: 62,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primaryDark, AppColors.primary],
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                  ),
                  borderRadius: BorderRadius.circular(18),
                ),
                alignment: Alignment.center,
                child: Text(
                  name.isEmpty ? 'ف' : name.characters.first,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        AppStatusBadge(
                          label: subscription.planName,
                          foreground: AppColors.primaryDark,
                          background: AppColors.primarySoft,
                        ),
                        if (subscription.verifiedBadge)
                          AppStatusBadge(
                            label: context.tr(ar: 'موثق', en: 'Verified'),
                            foreground: AppColors.success,
                            background: AppColors.successSoft,
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '$category • $city',
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: MetricPill(
                  label: context.tr(
                    ar: 'العمولة الحالية',
                    en: 'Current commission',
                  ),
                  value: '${subscription.commissionRate.toStringAsFixed(0)}%',
                  background: AppColors.accentSoft,
                  valueColor: AppColors.accentDark,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: MetricPill(
                  label: context.tr(ar: 'الخطة المستهدفة', en: 'Target plan'),
                  value: selectedPlan.name,
                  background: AppColors.secondarySoft,
                  valueColor: AppColors.secondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.backgroundTertiary,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                _SubscriptionRow(
                  label: context.tr(ar: 'الحالة الحالية', en: 'Current state'),
                  value: subscription.status,
                ),
                const SizedBox(height: 10),
                _SubscriptionRow(
                  label: context.tr(ar: 'الدعم', en: 'Support'),
                  value: subscription.guaranteedSupport
                      ? context.tr(ar: 'أولوية', en: 'Priority')
                      : context.tr(ar: 'قياسي', en: 'Standard'),
                ),
                const SizedBox(height: 10),
                _SubscriptionRow(
                  label: context.tr(ar: 'ينتهي في', en: 'Expires on'),
                  value: expiresAt == null
                      ? context.tr(ar: 'غير محدد', en: 'Not set')
                      : DateFormat('yyyy/MM/dd').format(expiresAt.toLocal()),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          ElevatedButton(
            onPressed: !canUpgrade || busy ? null : onUpgrade,
            child: Text(
              busy
                  ? context.tr(ar: 'جارٍ التفعيل...', en: 'Applying...')
                  : context.tr(
                      ar: 'تفعيل ${selectedPlan.name}',
                      en: 'Activate ${selectedPlan.name}',
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SubscriptionRow extends StatelessWidget {
  const _SubscriptionRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
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
        Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
      ],
    );
  }
}
