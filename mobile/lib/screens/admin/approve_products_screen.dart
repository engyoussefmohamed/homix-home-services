import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../constants/app_theme.dart';
import '../../core/app_localizations.dart';
import '../../models/product_item.dart';
import '../../providers/auth_controller.dart';
import '../../services/api_service.dart';
import '../../widgets/app_widgets.dart';

final pendingProductsProvider = FutureProvider.autoDispose((ref) async {
  final token = ref.watch(authControllerProvider).token;
  if (token == null) return const <ProductItem>[];
  return ref.watch(apiServiceProvider).getPendingProducts(token);
});

class ApproveProductsScreen extends ConsumerWidget {
  const ApproveProductsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final products = ref.watch(pendingProductsProvider);

    return HomixPage(
      title: context.tr(ar: 'مراجعة المنتجات', en: 'Review products'),
      header: AppBanner(
        title: context.tr(
          ar: 'لوحة اعتماد المنتجات أصبحت أوضح',
          en: 'Product approval is now easier to review',
        ),
        message: context.tr(
          ar: 'رتبنا حالة كل منتج وسعره ووصفه وإجراءات الموافقة أو الرفض داخل شاشة أسرع للمسح البصري.',
          en: 'Each product now surfaces its price, description, and moderation actions in a faster visual review flow.',
        ),
        icon: Icons.fact_check_rounded,
        background: AppColors.accentSoft,
        foreground: AppColors.accentDark,
      ),
      child: products.when(
        data: (items) => RefreshIndicator(
          onRefresh: () async => ref.invalidate(pendingProductsProvider),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              DashboardHero(
                title: context.tr(
                  ar: 'اعتمد المنتجات الجاهزة للنشر',
                  en: 'Approve products that are ready to go live',
                ),
                subtitle: context.tr(
                  ar: 'كل بطاقة الآن تعرض القرار والسياق التجاري بشكل أسرع.',
                  en: 'Each card now gives you the decision context faster.',
                ),
                chips: [
                  HeroTagChip(
                    label: context.tr(
                      ar: '${items.length} منتج',
                      en: '${items.length} products',
                    ),
                  ),
                  HeroTagChip(
                    label: context.tr(ar: 'جاهزة للمراجعة', en: 'Review-ready'),
                    highlight: true,
                  ),
                ],
                trailing: Container(
                  width: 112,
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
                        '${items.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        context.tr(ar: 'بانتظارك الآن', en: 'Waiting now'),
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
                        ar: 'إجمالي المراجعة',
                        en: 'Total in review',
                      ),
                      value: '${items.length}',
                      color: AppColors.accent,
                      icon: Icons.inventory_2_rounded,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: StatTile(
                      label: context.tr(ar: 'حالة التدفق', en: 'Flow status'),
                      value: context.tr(ar: 'نشط', en: 'Active'),
                      color: AppColors.primary,
                      icon: Icons.auto_awesome_motion_rounded,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              AppSectionCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: MetricPill(
                        label: context.tr(ar: 'قرار سريع', en: 'Fast decision'),
                        value: context.tr(
                          ar: 'موافقة / رفض',
                          en: 'Approve / Reject',
                        ),
                        background: AppColors.successSoft,
                        valueColor: AppColors.success,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: MetricPill(
                        label: context.tr(ar: 'الهدف', en: 'Goal'),
                        value: context.tr(
                          ar: 'وضوح + جودة',
                          en: 'Clarity + quality',
                        ),
                        background: AppColors.primarySoft,
                        valueColor: AppColors.primaryDark,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (items.isEmpty)
                AsyncPlaceholder(
                  message: context.tr(
                    ar: 'لا توجد منتجات بانتظار الموافقة.',
                    en: 'There are no products waiting for approval.',
                  ),
                  icon: Icons.inventory_2_outlined,
                )
              else
                ...items.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _PendingProductCard(
                      item: item,
                      onUpdate: (status) =>
                          _updateStatus(context, ref, item.id, status),
                    ),
                  ),
                ),
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => AsyncPlaceholder(message: error.toString()),
      ),
    );
  }

  Future<void> _updateStatus(
    BuildContext context,
    WidgetRef ref,
    String id,
    String status,
  ) async {
    final token = ref.read(authControllerProvider).token;
    if (token == null) return;
    await ref
        .read(apiServiceProvider)
        .updateProductStatus(token: token, productId: id, status: status);
    ref.invalidate(pendingProductsProvider);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            status == 'approved'
                ? context.tr(
                    ar: 'تمت الموافقة على المنتج',
                    en: 'Product approved',
                  )
                : context.tr(ar: 'تم رفض المنتج', en: 'Product rejected'),
          ),
        ),
      );
    }
  }
}

class _PendingProductCard extends StatelessWidget {
  const _PendingProductCard({required this.item, required this.onUpdate});

  final ProductItem item;
  final Future<void> Function(String status) onUpdate;

  @override
  Widget build(BuildContext context) {
    return AppSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.accentDark, AppColors.accent],
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                  ),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.inventory_2_rounded,
                  color: Colors.white,
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
                          label: context.tr(ar: 'معلق', en: 'Pending'),
                          foreground: AppColors.accentDark,
                          background: AppColors.accentSoft,
                        ),
                        if (item.category.isNotEmpty)
                          AppStatusBadge(
                            label: item.category,
                            foreground: AppColors.primaryDark,
                            background: AppColors.primarySoft,
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      item.name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.description.isEmpty
                          ? item.category
                          : item.description,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        height: 1.6,
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
                  label: context.tr(ar: 'الحجم', en: 'Volume'),
                  value: item.volumeLiters > 0
                      ? '${item.volumeLiters.toStringAsFixed(item.volumeLiters.truncateToDouble() == item.volumeLiters ? 0 : 1)} ${context.tr(ar: 'لتر', en: 'L')}'
                      : '--',
                  background: AppColors.primarySoft,
                  valueColor: AppColors.primaryDark,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: MetricPill(
                  label: context.tr(ar: 'السعر', en: 'Price'),
                  value: '${item.price.toStringAsFixed(0)} ${item.currency}',
                  background: AppColors.successSoft,
                  valueColor: AppColors.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.backgroundTertiary,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                _DecisionRow(
                  icon: Icons.tune_rounded,
                  label: context.tr(ar: 'معيار المراجعة', en: 'Review focus'),
                  value: context.tr(
                    ar: 'الوضوح التجاري',
                    en: 'Commercial clarity',
                  ),
                ),
                const SizedBox(height: 10),
                _DecisionRow(
                  icon: Icons.rule_folder_rounded,
                  label: context.tr(ar: 'إجراءك', en: 'Your action'),
                  value: context.tr(
                    ar: 'اعتماد أو رفض مباشر',
                    en: 'Approve or reject directly',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                  ),
                  onPressed: () => onUpdate('approved'),
                  child: Text(context.tr(ar: 'موافقة', en: 'Approve')),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.errorSoft,
                    foregroundColor: AppColors.error,
                  ),
                  onPressed: () => onUpdate('rejected'),
                  child: Text(context.tr(ar: 'رفض', en: 'Reject')),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DecisionRow extends StatelessWidget {
  const _DecisionRow({
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
