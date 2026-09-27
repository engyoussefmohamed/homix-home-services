import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../constants/app_theme.dart';
import '../../core/app_localizations.dart';
import '../../models/shop_item.dart';
import '../../providers/auth_controller.dart';
import '../../services/api_service.dart';
import '../../widgets/app_widgets.dart';

final pendingShopsProvider = FutureProvider.autoDispose((ref) async {
  final token = ref.watch(authControllerProvider).token;
  if (token == null) return const <ShopItem>[];
  return ref.watch(apiServiceProvider).getPendingShops(token);
});

class ApproveShopsScreen extends ConsumerWidget {
  const ApproveShopsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shops = ref.watch(pendingShopsProvider);

    return HomixPage(
      title: context.tr(ar: 'مراجعة المحلات', en: 'Review shops'),
      header: AppBanner(
        title: context.tr(
          ar: 'مراجعة المحلات أصبحت أكثر تنظيمًا',
          en: 'Shop review is now more organized',
        ),
        message: context.tr(
          ar: 'رتبنا بيانات المتجر والمالك والموقع وخطة الاشتراك داخل بطاقات قرار أوضح للإدارة.',
          en: 'Shop, owner, location, and subscription details are now arranged into clearer admin decision cards.',
        ),
        icon: Icons.storefront_rounded,
        background: AppColors.primarySoft,
        foreground: AppColors.primaryDark,
      ),
      child: shops.when(
        data: (items) => RefreshIndicator(
          onRefresh: () async => ref.invalidate(pendingShopsProvider),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              DashboardHero(
                title: context.tr(
                  ar: 'اعتمد المحلات الجاهزة للظهور',
                  en: 'Approve shops that are ready to go live',
                ),
                subtitle: context.tr(
                  ar: 'البيانات الأساسية والاشتراك الحالي يظهران الآن في نظرة واحدة.',
                  en: 'Core shop details and the current subscription are now visible at a glance.',
                ),
                chips: [
                  HeroTagChip(
                    label: context.tr(
                      ar: '${items.length} طلب',
                      en: '${items.length} requests',
                    ),
                  ),
                  HeroTagChip(
                    label: context.tr(
                      ar: 'بانتظار المراجعة',
                      en: 'Pending review',
                    ),
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
                        context.tr(ar: 'تحتاج قرارًا', en: 'Need a decision'),
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
                        ar: 'طلبات حالية',
                        en: 'Current requests',
                      ),
                      value: '${items.length}',
                      color: AppColors.primary,
                      icon: Icons.approval_rounded,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: StatTile(
                      label: context.tr(
                        ar: 'تركيز المراجعة',
                        en: 'Review focus',
                      ),
                      value: context.tr(
                        ar: 'الثقة والجودة',
                        en: 'Trust & quality',
                      ),
                      color: AppColors.accent,
                      icon: Icons.policy_rounded,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: MetricPill(
                      label: context.tr(ar: 'الهدف', en: 'Goal'),
                      value: context.tr(ar: 'إطلاق آمن', en: 'Safe launch'),
                      background: AppColors.successSoft,
                      valueColor: AppColors.success,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: MetricPill(
                      label: context.tr(ar: 'القرار', en: 'Decision'),
                      value: context.tr(
                        ar: 'اعتماد / رفض',
                        en: 'Approve / Reject',
                      ),
                      background: AppColors.accentSoft,
                      valueColor: AppColors.accentDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (items.isEmpty)
                AsyncPlaceholder(
                  message: context.tr(
                    ar: 'لا توجد محلات بانتظار المراجعة.',
                    en: 'There are no shops waiting for review.',
                  ),
                  icon: Icons.store_mall_directory_outlined,
                )
              else
                ...items.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _ShopReviewCard(
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
        .updateShopStatus(token: token, shopId: id, status: status);
    ref.invalidate(pendingShopsProvider);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            status == 'approved'
                ? context.tr(ar: 'تمت الموافقة على المحل', en: 'Shop approved')
                : context.tr(ar: 'تم رفض المحل', en: 'Shop rejected'),
          ),
        ),
      );
    }
  }
}

class _ShopReviewCard extends StatelessWidget {
  const _ShopReviewCard({required this.item, required this.onUpdate});

  final ShopItem item;
  final Future<void> Function(String status) onUpdate;

  @override
  Widget build(BuildContext context) {
    final initial = item.name.isEmpty ? 'م' : item.name.characters.first;
    final planName = item.subscription.planName.isEmpty
        ? context.tr(ar: 'بدون باقة', en: 'No plan')
        : item.subscription.planName;

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
                  initial,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
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
                          label: context.tr(ar: 'بانتظار', en: 'Pending'),
                          foreground: AppColors.accentDark,
                          background: AppColors.accentSoft,
                        ),
                        AppStatusBadge(
                          label: planName,
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
                      item.city.isEmpty ? item.address : item.city,
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
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: MetricPill(
                  label: context.tr(ar: 'المالك', en: 'Owner'),
                  value: item.ownerName.isEmpty
                      ? context.tr(ar: 'غير متوفر', en: 'Unavailable')
                      : item.ownerName,
                  background: AppColors.backgroundTertiary,
                  valueColor: AppColors.textDark,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: MetricPill(
                  label: context.tr(ar: 'الهاتف', en: 'Phone'),
                  value: item.phone.isEmpty
                      ? context.tr(ar: 'غير متوفر', en: 'Unavailable')
                      : item.phone,
                  background: AppColors.secondarySoft,
                  valueColor: AppColors.secondary,
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
                _ShopDetailRow(
                  icon: Icons.location_on_outlined,
                  label: context.tr(ar: 'العنوان', en: 'Address'),
                  value: item.address.isEmpty ? item.city : item.address,
                ),
                const SizedBox(height: 10),
                _ShopDetailRow(
                  icon: Icons.description_outlined,
                  label: context.tr(ar: 'الوصف', en: 'Description'),
                  value: item.description.isEmpty
                      ? context.tr(ar: 'لا يوجد وصف', en: 'No description')
                      : item.description,
                ),
                const SizedBox(height: 10),
                _ShopDetailRow(
                  icon: Icons.workspace_premium_outlined,
                  label: context.tr(ar: 'الخطة الحالية', en: 'Current plan'),
                  value: planName,
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

class _ShopDetailRow extends StatelessWidget {
  const _ShopDetailRow({
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
        SizedBox(
          width: 88,
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(height: 1.6, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}
