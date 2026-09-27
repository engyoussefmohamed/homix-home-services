import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../constants/app_theme.dart';
import '../../core/app_localizations.dart';
import '../../core/app_router.dart';
import '../../models/estimate_record.dart';
import '../../widgets/app_widgets.dart';

class EstimationResultScreen extends StatelessWidget {
  const EstimationResultScreen({super.key, required this.estimate});

  final EstimateRecord estimate;

  @override
  Widget build(BuildContext context) {
    final savings = estimate.bestOffer.isEmpty ? '0%' : '12%';
    final liters = estimate.area <= 0
        ? '--'
        : (estimate.area / 10).toStringAsFixed(1);

    return HomixPage(
      title: context.tr(ar: 'نتيجة التقدير', en: 'Estimate result'),
      header: AppBanner(
        title: context.tr(
          ar: 'نتيجة جاهزة للمقارنة واتخاذ القرار',
          en: 'Your estimate is ready for comparison',
        ),
        message: context.tr(
          ar: 'التصميم الجديد يوضح التكلفة، المساحة، وأفضل مسار متابعة سواء إلى المتجر أو إلى محفوظات التقديرات.',
          en: 'The refreshed result view makes cost, size, and next steps clearer.',
        ),
        icon: Icons.insights_rounded,
        background: AppColors.secondarySoft,
        foreground: AppColors.secondary,
      ),
      child: ListView(
        children: [
          DashboardHero(
            title:
                '${estimate.totalCost.toStringAsFixed(0)} ${context.tr(ar: 'ج.م', en: 'EGP')}',
            subtitle: context.tr(
              ar: 'أفضل قراءة تقديرية حالية',
              en: 'Best current visual estimate',
            ),
            chips: [
              HeroTagChip(
                label: estimate.bestOffer.isEmpty
                    ? context.tr(ar: 'بدون عرض مباشر', en: 'No direct offer')
                    : estimate.bestOffer,
                highlight: true,
              ),
              HeroTagChip(
                label: context.tr(
                  ar: 'مساحة ${estimate.area.toStringAsFixed(1)} م²',
                  en: '${estimate.area.toStringAsFixed(1)} m² area',
                ),
              ),
              HeroTagChip(
                label: context.tr(
                  ar: 'تشققات ${estimate.crackCount}',
                  en: '${estimate.crackCount} cracks',
                ),
              ),
            ],
            trailing: Container(
              width: 110,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: Column(
                children: [
                  Text(
                    savings,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    context.tr(ar: 'توفير محتمل', en: 'Potential saving'),
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
                  label: context.tr(ar: 'التكلفة الإجمالية', en: 'Total cost'),
                  value: estimate.totalCost.toStringAsFixed(0),
                  color: AppColors.primary,
                  icon: Icons.payments_rounded,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatTile(
                  label: context.tr(ar: 'تكلفة المواد', en: 'Material cost'),
                  value: estimate.materialCost.toStringAsFixed(0),
                  color: AppColors.secondary,
                  icon: Icons.inventory_2_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: MetricPill(
                  label: context.tr(ar: 'المساحة', en: 'Area'),
                  value:
                      '${estimate.area.toStringAsFixed(1)} ${context.tr(ar: 'م²', en: 'm²')}',
                  background: AppColors.primarySoft,
                  valueColor: AppColors.primaryDark,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: MetricPill(
                  label: context.tr(ar: 'كمية متوقعة', en: 'Expected quantity'),
                  value: '$liters ${context.tr(ar: 'لتر', en: 'L')}',
                  background: AppColors.successSoft,
                  valueColor: AppColors.success,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: MetricPill(
                  label: context.tr(ar: 'تشققات', en: 'Cracks'),
                  value: '${estimate.crackCount}',
                  background: AppColors.accentSoft,
                  valueColor: AppColors.accentDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          AppSectionCard(
            color: AppColors.primarySoft,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr(
                    ar: 'ماذا تعني هذه النتيجة؟',
                    en: 'What does this result mean?',
                  ),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  context.tr(
                    ar: 'هذه قراءة بصرية سريعة تساعدك تقارن قبل الشراء أو الحجز. السعر النهائي قد يتغير حسب حالة الحائط الفعلية، نوع المنتج، ورسوم التنفيذ.',
                    en: 'This is a fast visual estimate to help comparison before buying or booking. Final cost may vary based on the real wall condition, product type, and service fees.',
                  ),
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    height: 1.65,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SectionHeading(
            title: context.tr(
              ar: 'مقارنة المنتجات المقترحة',
              en: 'Suggested product comparison',
            ),
            subtitle: context.tr(
              ar: 'عرض أوضح للخيارات حتى تصل لقرار أسرع داخل المتجر.',
              en: 'A clearer view of options before moving to the shop.',
            ),
          ),
          const SizedBox(height: 12),
          _ProductCompareCard(
            title: estimate.bestOffer.isEmpty
                ? context.tr(
                    ar: 'أفضل منتج متاح حاليًا',
                    en: 'Best currently available product',
                  )
                : estimate.bestOffer,
            price: estimate.totalCost.toStringAsFixed(0),
            volume: '3.5 ${context.tr(ar: 'لتر / عبوة', en: 'L / pack')}',
            badgeLabel: context.tr(ar: 'الأنسب', en: 'Best match'),
            badgeForeground: AppColors.success,
            badgeBackground: AppColors.successSoft,
            accent: AppColors.success,
          ),
          const SizedBox(height: 10),
          _ProductCompareCard(
            title: context.tr(ar: 'خيار اقتصادي', en: 'Budget option'),
            price: estimate.materialCost > 0
                ? (estimate.materialCost * 0.88).toStringAsFixed(0)
                : '710',
            volume: '4 ${context.tr(ar: 'لتر / عبوة', en: 'L / pack')}',
            badgeLabel: context.tr(ar: 'أقل تكلفة', en: 'Lower cost'),
            badgeForeground: AppColors.primary,
            badgeBackground: AppColors.primarySoft,
            accent: AppColors.primary,
          ),
          const SizedBox(height: 10),
          _ProductCompareCard(
            title: context.tr(
              ar: 'خيار تغطية أعلى',
              en: 'Higher coverage option',
            ),
            price: estimate.totalCost > 0
                ? (estimate.totalCost * 1.14).toStringAsFixed(0)
                : '1050',
            volume: '5 ${context.tr(ar: 'لتر / عبوة', en: 'L / pack')}',
            badgeLabel: context.tr(ar: 'تغطية أكبر', en: 'More coverage'),
            badgeForeground: AppColors.accentDark,
            badgeBackground: AppColors.accentSoft,
            accent: AppColors.accentDark,
          ),
          const SizedBox(height: 16),
          AppSectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr(ar: 'الخطوة التالية', en: 'Next step'),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  context.tr(
                    ar: 'يمكنك الآن الانتقال إلى المتجر لشراء المنتجات المناسبة، أو حفظ النتيجة ضمن تقديراتك والرجوع لها لاحقًا.',
                    en: 'You can now continue to the shop to buy matching products, or keep this result in your estimate history.',
                  ),
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    height: 1.65,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => context.go(AppRoutes.customerHome, extra: 2),
                  icon: const Icon(Icons.storefront_rounded),
                  label: Text(context.tr(ar: 'افتح المتجر', en: 'Open shop')),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: () => context.go(AppRoutes.customerHome, extra: 1),
                  icon: const Icon(Icons.history_rounded),
                  label: Text(
                    context.tr(
                      ar: 'اذهب إلى تقديراتي',
                      en: 'Go to my estimates',
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                TextButton.icon(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.refresh_rounded),
                  label: Text(
                    context.tr(
                      ar: 'عمل تقدير جديد',
                      en: 'Create another estimate',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductCompareCard extends StatelessWidget {
  const _ProductCompareCard({
    required this.title,
    required this.price,
    required this.volume,
    required this.badgeLabel,
    required this.badgeForeground,
    required this.badgeBackground,
    required this.accent,
  });

  final String title;
  final String price;
  final String volume;
  final String badgeLabel;
  final Color badgeForeground;
  final Color badgeBackground;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return AppSectionCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(Icons.format_color_fill_rounded, color: accent),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    AppStatusBadge(
                      label: badgeLabel,
                      foreground: badgeForeground,
                      background: badgeBackground,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '$price ${context.tr(ar: 'ج.م', en: 'EGP')}',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: accent,
                    fontSize: 28,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  volume,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
