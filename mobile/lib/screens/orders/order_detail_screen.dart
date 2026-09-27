import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../constants/app_theme.dart';
import '../../core/app_localizations.dart';
import '../../models/store_order.dart';
import '../../providers/auth_controller.dart';
import '../../services/api_service.dart';
import '../../widgets/app_widgets.dart';

final orderDetailsProvider = FutureProvider.family
    .autoDispose<StoreOrder, String>((ref, orderId) async {
      final token = ref.watch(authControllerProvider).token;
      if (token == null) {
        throw const ApiException('يجب تسجيل الدخول أولًا.');
      }
      return ref
          .watch(apiServiceProvider)
          .getOrderDetails(token: token, orderId: orderId);
    });

class OrderDetailScreen extends ConsumerWidget {
  const OrderDetailScreen({super.key, required this.orderId});

  final String orderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderAsync = ref.watch(orderDetailsProvider(orderId));

    return HomixPage(
      title: context.tr(ar: 'تفاصيل الطلب', en: 'Order details'),
      header: AppBanner(
        title: context.tr(
          ar: 'تفاصيل الطلب بخط زمني أوضح',
          en: 'Order details with a clearer timeline',
        ),
        message: context.tr(
          ar: 'راجع الحالة، العناصر، والخطوات المنجزة داخل عرض أكثر ترتيبًا وراحة.',
          en: 'Review status, items, and completed steps in a more organized layout.',
        ),
        icon: Icons.local_shipping_rounded,
        background: AppColors.secondarySoft,
        foreground: AppColors.secondary,
      ),
      child: orderAsync.when(
        data: (order) => ListView(
          children: [
            DashboardHero(
              title: context.tr(
                ar: 'طلب #${_short(order.id)}',
                en: 'Order #${_short(order.id)}',
              ),
              subtitle: _statusLabel(context, order.status),
              chips: [
                HeroTagChip(
                  label: context.tr(
                    ar: '${order.items.length} عناصر',
                    en: '${order.items.length} items',
                  ),
                ),
                HeroTagChip(
                  label:
                      '${order.totalPrice.toStringAsFixed(0)} ${order.currency}',
                  highlight: true,
                ),
                HeroTagChip(label: _createdAtLabel(context, order.createdAt)),
              ],
              trailing: Container(
                width: 106,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      _statusIcon(order.status),
                      color: Colors.white,
                      size: 26,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _statusLabel(context, order.status),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
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
                    label: context.tr(ar: 'الإجمالي', en: 'Total'),
                    value: order.totalPrice.toStringAsFixed(0),
                    color: AppColors.primary,
                    icon: Icons.payments_rounded,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: StatTile(
                    label: context.tr(ar: 'العناصر', en: 'Items'),
                    value: '${order.items.length}',
                    color: AppColors.accent,
                    icon: Icons.inventory_2_rounded,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            AppSectionCard(
              child: Row(
                children: [
                  Expanded(
                    child: MetricPill(
                      label: context.tr(ar: 'الحالة', en: 'Status'),
                      value: _statusLabel(context, order.status),
                      background: _statusBackground(order.status),
                      valueColor: _statusForeground(order.status),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: MetricPill(
                      label: context.tr(ar: 'تاريخ الإنشاء', en: 'Created'),
                      value: _shortDate(order.createdAt),
                      background: AppColors.primarySoft,
                      valueColor: AppColors.primaryDark,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            AppSectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SectionHeading(
                    title: context.tr(ar: 'خط سير الطلب', en: 'Order timeline'),
                    subtitle: context.tr(
                      ar: 'المراحل التي مر بها الطلب حتى الآن.',
                      en: 'The stages your order has gone through so far.',
                    ),
                  ),
                  const SizedBox(height: 14),
                  if (order.timeline.isEmpty)
                    Text(
                      context.tr(
                        ar: 'لا توجد تحديثات زمنية متاحة بعد.',
                        en: 'No timeline updates are available yet.',
                      ),
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    )
                  else
                    ...order.timeline.asMap().entries.map((entry) {
                      final index = entry.key;
                      final item = entry.value;
                      final isLast = index == order.timeline.length - 1;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Column(
                              children: [
                                Container(
                                  width: 14,
                                  height: 14,
                                  decoration: BoxDecoration(
                                    color: index == order.timeline.length - 1
                                        ? AppColors.success
                                        : AppColors.primary,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                if (!isLast)
                                  Container(
                                    width: 2,
                                    height: 54,
                                    color: AppColors.border,
                                  ),
                              ],
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.label,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    item.at == null
                                        ? context.tr(
                                            ar: 'التوقيت غير متاح',
                                            en: 'Time unavailable',
                                          )
                                        : DateFormat(
                                            'yyyy/MM/dd • hh:mm a',
                                          ).format(item.at!.toLocal()),
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
                    }),
                ],
              ),
            ),
            const SizedBox(height: 12),
            AppSectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SectionHeading(
                    title: context.tr(
                      ar: 'العناصر المطلوبة',
                      en: 'Ordered items',
                    ),
                    subtitle: context.tr(
                      ar: 'عرض منظم للكميات والسعر لكل عنصر.',
                      en: 'An organized view of quantities and price per item.',
                    ),
                  ),
                  const SizedBox(height: 14),
                  ...order.items.map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _OrderItemRow(
                        item: item,
                        currency: order.currency,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            AppSectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SectionHeading(
                    title: context.tr(
                      ar: 'الملخص النهائي',
                      en: 'Final summary',
                    ),
                    subtitle: context.tr(
                      ar: 'بيانات العميل والملاحظات والإجمالي النهائي.',
                      en: 'Customer details, notes, and the final total.',
                    ),
                  ),
                  const SizedBox(height: 14),
                  _DetailRow(
                    icon: Icons.person_rounded,
                    title: context.tr(ar: 'العميل', en: 'Customer'),
                    value: order.customerName.isEmpty
                        ? context.tr(ar: 'غير متاح', en: 'Unavailable')
                        : order.customerName,
                  ),
                  if (order.customerEmail.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _DetailRow(
                      icon: Icons.alternate_email_rounded,
                      title: context.tr(ar: 'البريد', en: 'Email'),
                      value: order.customerEmail,
                    ),
                  ],
                  const SizedBox(height: 12),
                  _DetailRow(
                    icon: Icons.sticky_note_2_rounded,
                    title: context.tr(ar: 'ملاحظات', en: 'Notes'),
                    value: order.notes.isEmpty
                        ? context.tr(
                            ar: 'لا توجد ملاحظات مضافة على هذا الطلب.',
                            en: 'There are no notes on this order.',
                          )
                        : order.notes,
                  ),
                  const SizedBox(height: 16),
                  AppSectionCard(
                    color: AppColors.primarySoft,
                    padding: const EdgeInsets.all(18),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            context.tr(
                              ar: 'الإجمالي النهائي',
                              en: 'Final total',
                            ),
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        Text(
                          '${order.totalPrice.toStringAsFixed(0)} ${order.currency}',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: AppColors.primaryDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => AsyncPlaceholder(message: error.toString()),
      ),
    );
  }
}

class _OrderItemRow extends StatelessWidget {
  const _OrderItemRow({required this.item, required this.currency});

  final StoreOrderItem item;
  final String currency;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundTertiary,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.accentSoft,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.inventory_2_rounded,
              color: AppColors.accentDark,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${item.quantity.toStringAsFixed(0)} × ${item.unitPrice.toStringAsFixed(0)} $currency',
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '${item.lineTotal.toStringAsFixed(0)} $currency',
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              color: AppColors.primaryDark,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: AppColors.primarySoft,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: AppColors.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  height: 1.6,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

String _short(String id) => id.length > 8 ? id.substring(0, 8) : id;

String _createdAtLabel(BuildContext context, DateTime? value) {
  if (value == null) {
    return context.tr(ar: 'تاريخ غير متاح', en: 'Date unavailable');
  }
  return DateFormat('yyyy/MM/dd').format(value.toLocal());
}

String _shortDate(DateTime? value) {
  if (value == null) return '--';
  return DateFormat('yyyy/MM/dd').format(value.toLocal());
}

String _statusLabel(BuildContext context, String status) {
  switch (status) {
    case 'confirmed':
      return context.tr(ar: 'تم التأكيد', en: 'Confirmed');
    case 'fulfilled':
      return context.tr(ar: 'مكتمل', en: 'Fulfilled');
    case 'cancelled':
      return context.tr(ar: 'ملغي', en: 'Cancelled');
    default:
      return context.tr(ar: 'قيد المراجعة', en: 'Pending');
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
