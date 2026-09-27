import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../constants/app_theme.dart';
import '../../core/app_localizations.dart';
import '../../models/estimate_record.dart';
import '../../providers/auth_controller.dart';
import '../../services/api_service.dart';
import '../../widgets/app_widgets.dart';

final myEstimatesProvider = FutureProvider.autoDispose<List<EstimateRecord>>((
  ref,
) async {
  final token = ref.watch(authControllerProvider).token;
  if (token == null) return const <EstimateRecord>[];
  return ref.watch(apiServiceProvider).getMyEstimates(token);
});

class EstimatesHistoryScreen extends ConsumerWidget {
  const EstimatesHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final estimates = ref.watch(myEstimatesProvider);

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(myEstimatesProvider),
      child: estimates.when(
        data: (items) {
          if (items.isEmpty) {
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                DashboardHero(
                  title: context.tr(
                    ar: 'كل تقديراتك ستظهر هنا بشكل أوضح',
                    en: 'All your estimates will appear here clearly',
                  ),
                  subtitle: context.tr(
                    ar: 'محفوظات التقدير',
                    en: 'Estimate history',
                  ),
                  chips: [
                    HeroTagChip(
                      label: context.tr(
                        ar: 'ابدأ تقديرًا جديدًا',
                        en: 'Start a new estimate',
                      ),
                      highlight: true,
                    ),
                  ],
                ),
                const SizedBox(height: 30),
                AsyncPlaceholder(
                  message: context.tr(
                    ar: 'لا توجد تقديرات محفوظة حتى الآن.',
                    en: 'There are no saved estimates yet.',
                  ),
                  icon: Icons.auto_awesome_outlined,
                ),
              ],
            );
          }

          final latest = items.first;

          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              DashboardHero(
                title: context.tr(
                  ar: 'تقديراتك محفوظة وجاهزة للمراجعة',
                  en: 'Your estimates are saved and ready to review',
                ),
                subtitle: context.tr(
                  ar: 'محفوظات التقدير',
                  en: 'Estimate history',
                ),
                chips: [
                  HeroTagChip(
                    label: context.tr(
                      ar: '${items.length} تقديرات',
                      en: '${items.length} estimates',
                    ),
                    highlight: true,
                  ),
                  HeroTagChip(
                    label: context.tr(
                      ar: 'أحدث تقدير محفوظ',
                      en: 'Latest estimate saved',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: StatTile(
                      label: context.tr(
                        ar: 'إجمالي التقديرات',
                        en: 'Total estimates',
                      ),
                      value: '${items.length}',
                      color: AppColors.primary,
                      icon: Icons.history_rounded,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: StatTile(
                      label: context.tr(ar: 'أحدث تكلفة', en: 'Latest total'),
                      value: latest.totalCost.toStringAsFixed(0),
                      color: AppColors.accent,
                      icon: Icons.payments_rounded,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: MetricPill(
                      label: context.tr(ar: 'أفضل عرض', en: 'Best offer'),
                      value: latest.bestOffer.isEmpty
                          ? context.tr(ar: 'غير متاح', en: 'Unavailable')
                          : latest.bestOffer,
                      background: AppColors.primarySoft,
                      valueColor: AppColors.primaryDark,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: MetricPill(
                      label: context.tr(ar: 'المساحة', en: 'Area'),
                      value:
                          '${latest.area.toStringAsFixed(1)} ${context.tr(ar: 'م²', en: 'm²')}',
                      background: AppColors.accentSoft,
                      valueColor: AppColors.accentDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              SectionHeading(
                title: context.tr(ar: 'كل التقديرات', en: 'All estimates'),
                subtitle: context.tr(
                  ar: 'راجع النتائج المحفوظة وقارن بينها قبل اتخاذ القرار.',
                  en: 'Review saved results and compare them before deciding.',
                ),
              ),
              const SizedBox(height: 12),
              ...items.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: EstimateTile(estimate: item),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => AsyncPlaceholder(message: error.toString()),
      ),
    );
  }
}
