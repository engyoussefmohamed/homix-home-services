import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../constants/app_theme.dart';
import '../../core/app_localizations.dart';
import '../../models/store_order.dart';
import '../../providers/auth_controller.dart';
import '../../services/api_service.dart';
import '../../widgets/app_widgets.dart';

final myOrdersQueryProvider = StateProvider<String?>((ref) => null);
final myOrdersPageProvider = StateProvider<int>((ref) => 1);

final myOrdersProvider = FutureProvider.autoDispose<PaginatedOrders>((
  ref,
) async {
  final token = ref.watch(authControllerProvider).token;
  if (token == null) {
    return const PaginatedOrders(
      items: [],
      total: 0,
      page: 1,
      pageSize: 10,
      hasMore: false,
    );
  }
  final status = ref.watch(myOrdersQueryProvider);
  final page = ref.watch(myOrdersPageProvider);
  return ref
      .watch(apiServiceProvider)
      .getMyOrders(token, status: status, page: page, pageSize: 10);
});

class MyOrdersScreen extends ConsumerWidget {
  const MyOrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(myOrdersProvider);
    final selectedStatus = ref.watch(myOrdersQueryProvider);

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(myOrdersProvider),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          DashboardHero(
            title: context.tr(
              ar: 'طلباتك في واجهة أوضح وأسهل للتتبع',
              en: 'Your orders in a clearer tracking view',
            ),
            subtitle: context.tr(ar: 'مركز الطلبات', en: 'Order center'),
            chips: [
              HeroTagChip(
                label: context.tr(ar: 'فلترة سريعة', en: 'Quick filters'),
              ),
              HeroTagChip(
                label: context.tr(ar: 'تفاصيل أوضح', en: 'Clear details'),
                highlight: true,
              ),
            ],
            searchHint: context.tr(
              ar: 'تابع الحالة والإجمالي وآخر خطوة لكل طلب من نفس الشاشة',
              en: 'Track status, total, and latest step for every order from one screen',
            ),
          ),
          const SizedBox(height: 16),
          AppSectionCard(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _OrderFilterChip(
                  label: context.tr(ar: 'الكل', en: 'All'),
                  selected: selectedStatus == null,
                  onTap: () {
                    ref.read(myOrdersQueryProvider.notifier).state = null;
                    ref.read(myOrdersPageProvider.notifier).state = 1;
                  },
                ),
                for (final status in const [
                  'pending',
                  'confirmed',
                  'fulfilled',
                  'cancelled',
                ])
                  _OrderFilterChip(
                    label: _statusLabel(context, status),
                    selected: selectedStatus == status,
                    onTap: () {
                      ref.read(myOrdersQueryProvider.notifier).state = status;
                      ref.read(myOrdersPageProvider.notifier).state = 1;
                    },
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ordersAsync.when(
            data: (pageData) {
              final activeCount = pageData.items
                  .where(
                    (order) =>
                        order.status != 'fulfilled' &&
                        order.status != 'cancelled',
                  )
                  .length;
              final fulfilledCount = pageData.items
                  .where((order) => order.status == 'fulfilled')
                  .length;

              return Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: StatTile(
                          label: context.tr(
                            ar: 'إجمالي الطلبات',
                            en: 'Total orders',
                          ),
                          value: '${pageData.total}',
                          color: AppColors.primary,
                          icon: Icons.receipt_long_rounded,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: StatTile(
                          label: context.tr(
                            ar: 'قيد التنفيذ',
                            en: 'Active now',
                          ),
                          value: '$activeCount',
                          color: AppColors.accent,
                          icon: Icons.local_shipping_rounded,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: MetricPill(
                          label: context.tr(ar: 'مكتملة', en: 'Completed'),
                          value: '$fulfilledCount',
                          background: AppColors.successSoft,
                          valueColor: AppColors.success,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: MetricPill(
                          label: context.tr(
                            ar: 'صفحة حالية',
                            en: 'Current page',
                          ),
                          value: '${pageData.page}',
                          background: AppColors.primarySoft,
                          valueColor: AppColors.primaryDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (pageData.items.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 40),
                      child: AsyncPlaceholder(
                        message: context.tr(
                          ar: 'لا توجد طلبات مطابقة للفلاتر الحالية.',
                          en: 'There are no orders matching the current filters.',
                        ),
                        icon: Icons.receipt_long_outlined,
                      ),
                    )
                  else
                    ...pageData.items.map(
                      (order) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _CustomerOrderCard(order: order),
                      ),
                    ),
                  if (pageData.items.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    AppSectionCard(
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: pageData.page > 1
                                  ? () =>
                                        ref
                                                .read(
                                                  myOrdersPageProvider.notifier,
                                                )
                                                .state =
                                            pageData.page - 1
                                  : null,
                              child: Text(
                                context.tr(ar: 'السابق', en: 'Previous'),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: pageData.hasMore
                                  ? () =>
                                        ref
                                                .read(
                                                  myOrdersPageProvider.notifier,
                                                )
                                                .state =
                                            pageData.page + 1
                                  : null,
                              child: Text(context.tr(ar: 'التالي', en: 'Next')),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              );
            },
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 48),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (error, _) => AsyncPlaceholder(message: error.toString()),
          ),
        ],
      ),
    );
  }
}

class _CustomerOrderCard extends StatelessWidget {
  const _CustomerOrderCard({required this.order});

  final StoreOrder order;

  @override
  Widget build(BuildContext context) {
    final shortId = order.id.length > 8 ? order.id.substring(0, 8) : order.id;
    final createdAt = order.createdAt == null
        ? context.tr(ar: 'غير متاح', en: 'Unavailable')
        : DateFormat('yyyy/MM/dd • hh:mm a').format(order.createdAt!.toLocal());
    final latestStep = order.timeline.isEmpty
        ? context.tr(ar: 'غير متاحة', en: 'Unavailable')
        : order.timeline.last.label;

    return AppSectionCard(
      child: InkWell(
        onTap: () => context.push('/orders/${order.id}'),
        borderRadius: BorderRadius.circular(30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: _statusForeground(
                      order.status,
                    ).withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(
                    _statusIcon(order.status),
                    color: _statusForeground(order.status),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.tr(ar: 'طلب #$shortId', en: 'Order #$shortId'),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        createdAt,
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                AppStatusBadge(
                  label: _statusLabel(context, order.status),
                  foreground: _statusForeground(order.status),
                  background: _statusBackground(order.status),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: MetricPill(
                    label: context.tr(ar: 'الإجمالي', en: 'Total'),
                    value:
                        '${order.totalPrice.toStringAsFixed(0)} ${order.currency}',
                    background: AppColors.primarySoft,
                    valueColor: AppColors.primaryDark,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: MetricPill(
                    label: context.tr(ar: 'العناصر', en: 'Items'),
                    value: '${order.items.length}',
                    background: AppColors.accentSoft,
                    valueColor: AppColors.accentDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              context.tr(
                ar: 'آخر خطوة: $latestStep',
                en: 'Latest step: $latestStep',
              ),
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              order.notes.isEmpty
                  ? context.tr(
                      ar: 'لا توجد ملاحظات مضافة على هذا الطلب.',
                      en: 'There are no notes on this order.',
                    )
                  : order.notes,
              style: const TextStyle(
                color: AppColors.textMuted,
                height: 1.6,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 14),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton.icon(
                onPressed: () => context.push('/orders/${order.id}'),
                icon: const Icon(Icons.arrow_outward_rounded),
                label: Text(context.tr(ar: 'عرض التفاصيل', en: 'View details')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderFilterChip extends StatelessWidget {
  const _OrderFilterChip({
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

String _statusLabel(BuildContext context, String status) {
  switch (status) {
    case 'confirmed':
      return context.tr(ar: 'مؤكد', en: 'Confirmed');
    case 'fulfilled':
      return context.tr(ar: 'مكتمل', en: 'Fulfilled');
    case 'cancelled':
      return context.tr(ar: 'ملغي', en: 'Cancelled');
    default:
      return context.tr(ar: 'جديد', en: 'Pending');
  }
}

IconData _statusIcon(String status) {
  switch (status) {
    case 'confirmed':
      return Icons.inventory_2_rounded;
    case 'fulfilled':
      return Icons.check_circle_rounded;
    case 'cancelled':
      return Icons.cancel_rounded;
    default:
      return Icons.pending_actions_rounded;
  }
}

Color _statusForeground(String status) {
  switch (status) {
    case 'confirmed':
      return AppColors.primary;
    case 'fulfilled':
      return AppColors.success;
    case 'cancelled':
      return AppColors.error;
    default:
      return AppColors.accentDark;
  }
}

Color _statusBackground(String status) {
  switch (status) {
    case 'confirmed':
      return AppColors.primarySoft;
    case 'fulfilled':
      return AppColors.successSoft;
    case 'cancelled':
      return AppColors.errorSoft;
    default:
      return AppColors.accentSoft;
  }
}
