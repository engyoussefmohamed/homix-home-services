import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../constants/app_theme.dart';
import '../../core/app_localizations.dart';
import '../../models/app_user.dart';
import '../../models/subscription_models.dart';
import '../../providers/auth_controller.dart';
import '../../services/api_service.dart';
import '../../widgets/app_widgets.dart';

class BillingHistoryScreen extends ConsumerStatefulWidget {
  const BillingHistoryScreen({super.key});

  @override
  ConsumerState<BillingHistoryScreen> createState() =>
      _BillingHistoryScreenState();
}

class _BillingHistoryScreenState extends ConsumerState<BillingHistoryScreen> {
  bool _isLoading = true;
  String _filter = '';
  int _page = 1;
  PaginatedPaymentTransactions? _transactions;
  PaymentSummary? _summary;

  String? get _token => ref.read(authControllerProvider).token;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final token = _token;
    if (token == null || token.isEmpty) return;
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        ref.read(apiServiceProvider).getMyPaymentSummary(token),
        ref
            .read(apiServiceProvider)
            .getMyPaymentTransactions(
              token,
              transactionType: _filter.isEmpty ? null : _filter,
              page: _page,
              pageSize: 10,
            ),
      ]);
      if (!mounted) return;
      setState(() {
        _summary = results[0] as PaymentSummary;
        _transactions = results[1] as PaginatedPaymentTransactions;
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final role =
        ref.watch(authControllerProvider).user?.role ?? UserRole.customer;

    return HomixPage(
      title: _titleForRole(context, role),
      header: AppBanner(
        title: context.tr(
          ar: 'سجل مدفوعات أوضح وأكثر احترافية',
          en: 'A clearer, more professional billing history',
        ),
        message: context.tr(
          ar: 'رتبنا الملخصات، أنواع العمليات، وسجل المدفوعات داخل واجهة أسهل للمراجعة والمتابعة.',
          en: 'Summaries, transaction types, and billing records are now organized into an easier review flow.',
        ),
        icon: Icons.receipt_long_rounded,
        background: AppColors.primarySoft,
        foreground: AppColors.primaryDark,
      ),
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _transactions == null || _summary == null
          ? AsyncPlaceholder(
              message: context.tr(
                ar: 'تعذر تحميل سجل المدفوعات.',
                en: 'Could not load billing history.',
              ),
            )
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  DashboardHero(
                    title: context.tr(
                      ar: 'كل مدفوعاتك في عرض واحد أوضح',
                      en: 'All your payments in one clearer view',
                    ),
                    subtitle: _titleForRole(context, role),
                    chips: [
                      HeroTagChip(
                        label: context.tr(
                          ar: '${_transactions!.total} عملية',
                          en: '${_transactions!.total} transactions',
                        ),
                      ),
                      HeroTagChip(
                        label: _filterLabel(context, _filter),
                        highlight: true,
                      ),
                    ],
                    trailing: Container(
                      width: 112,
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
                          Text(
                            _summary!.totalPaid.toStringAsFixed(0),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          Text(
                            context.tr(ar: 'إجمالي مدفوع', en: 'Total paid'),
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
                            ar: 'إجمالي المدفوع',
                            en: 'Total paid',
                          ),
                          value: _summary!.totalPaid.toStringAsFixed(0),
                          color: AppColors.primary,
                          icon: Icons.payments_rounded,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: StatTile(
                          label: context.tr(ar: 'آخر باقة', en: 'Latest plan'),
                          value: _summary!.latestSubscriptionPlan.isEmpty
                              ? context.tr(ar: 'لا يوجد', en: 'None')
                              : _summary!.latestSubscriptionPlan,
                          color: AppColors.accent,
                          icon: Icons.workspace_premium_rounded,
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
                            ar: 'الاشتراكات',
                            en: 'Subscriptions',
                          ),
                          value:
                              '${_summary!.subscriptionPaid.toStringAsFixed(0)} ${_summary!.currency}',
                          background: AppColors.successSoft,
                          valueColor: AppColors.success,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: MetricPill(
                          label: context.tr(ar: 'الحجوزات', en: 'Bookings'),
                          value:
                              '${_summary!.bookingPaid.toStringAsFixed(0)} ${_summary!.currency}',
                          background: AppColors.accentSoft,
                          valueColor: AppColors.accentDark,
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
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _BillingFilterChip(
                          label: context.tr(ar: 'الكل', en: 'All'),
                          selected: _filter.isEmpty,
                          onTap: () {
                            setState(() {
                              _filter = '';
                              _page = 1;
                            });
                            _load();
                          },
                        ),
                        _BillingFilterChip(
                          label: context.tr(
                            ar: 'اشتراكات',
                            en: 'Subscriptions',
                          ),
                          selected: _filter == 'subscription',
                          onTap: () {
                            setState(() {
                              _filter = 'subscription';
                              _page = 1;
                            });
                            _load();
                          },
                        ),
                        _BillingFilterChip(
                          label: context.tr(ar: 'حجوزات', en: 'Bookings'),
                          selected: _filter == 'booking',
                          onTap: () {
                            setState(() {
                              _filter = 'booking';
                              _page = 1;
                            });
                            _load();
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_transactions!.items.isEmpty)
                    AsyncPlaceholder(
                      message: context.tr(
                        ar: 'لا توجد مدفوعات مطابقة لهذا الفلتر.',
                        en: 'There are no payments matching this filter.',
                      ),
                      icon: Icons.receipt_long_outlined,
                    )
                  else
                    ..._transactions!.items.map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _PaymentCard(item: item),
                      ),
                    ),
                  if (_transactions!.items.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    AppSectionCard(
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _transactions!.page > 1
                                  ? () {
                                      setState(() => _page -= 1);
                                      _load();
                                    }
                                  : null,
                              child: Text(
                                context.tr(ar: 'السابق', en: 'Previous'),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _transactions!.hasMore
                                  ? () {
                                      setState(() => _page += 1);
                                      _load();
                                    }
                                  : null,
                              child: Text(context.tr(ar: 'التالي', en: 'Next')),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  String _titleForRole(BuildContext context, UserRole role) {
    switch (role) {
      case UserRole.shopOwner:
        return context.tr(ar: 'فواتير المتجر', en: 'Shop billing');
      case UserRole.technician:
        return context.tr(ar: 'فواتير الفني', en: 'Technician billing');
      case UserRole.admin:
        return context.tr(ar: 'سجل المدفوعات', en: 'Billing history');
      case UserRole.customer:
        return context.tr(ar: 'مدفوعاتي', en: 'My payments');
    }
  }

  String _filterLabel(BuildContext context, String filter) {
    switch (filter) {
      case 'subscription':
        return context.tr(ar: 'اشتراكات', en: 'Subscriptions');
      case 'booking':
        return context.tr(ar: 'حجوزات', en: 'Bookings');
      default:
        return context.tr(ar: 'كل العمليات', en: 'All transactions');
    }
  }
}

class _BillingFilterChip extends StatelessWidget {
  const _BillingFilterChip({
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

class _PaymentCard extends StatelessWidget {
  const _PaymentCard({required this.item});

  final PaymentTransactionItem item;

  @override
  Widget build(BuildContext context) {
    final title = item.transactionType == 'subscription'
        ? (item.subscription?.planName.isNotEmpty == true
              ? item.subscription!.planName
              : context.tr(ar: 'دفع اشتراك', en: 'Subscription payment'))
        : (item.booking?.technicianName.isNotEmpty == true
              ? item.booking!.technicianName
              : context.tr(ar: 'دفع حجز', en: 'Booking payment'));
    final subtitle = item.description.isNotEmpty
        ? item.description
        : item.externalReference;

    return AppSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: _transactionForeground(item).withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(
                  _transactionIcon(item.transactionType),
                  color: _transactionForeground(item),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _createdAt(item.createdAt, context),
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              AppStatusBadge(
                label: _statusLabel(context, item.status),
                foreground: _statusForeground(item.status),
                background: _statusBackground(item.status),
              ),
            ],
          ),
          if (subtitle.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              subtitle,
              style: const TextStyle(
                color: AppColors.textMuted,
                height: 1.6,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: MetricPill(
                  label: context.tr(ar: 'المبلغ', en: 'Amount'),
                  value: '${item.amount.toStringAsFixed(0)} ${item.currency}',
                  background: AppColors.primarySoft,
                  valueColor: AppColors.primaryDark,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: MetricPill(
                  label: context.tr(ar: 'الطريقة', en: 'Method'),
                  value: item.paymentMethod.isEmpty
                      ? context.tr(ar: 'غير محددة', en: 'Unspecified')
                      : item.paymentMethod,
                  background: AppColors.accentSoft,
                  valueColor: AppColors.accentDark,
                ),
              ),
            ],
          ),
          if (item.externalReference.isNotEmpty ||
              item.subscription?.expiresAt != null ||
              item.booking?.scheduledFor != null) ...[
            const SizedBox(height: 14),
            if (item.externalReference.isNotEmpty)
              _MetaRow(
                label: context.tr(ar: 'المرجع', en: 'Reference'),
                value: item.externalReference,
              ),
            if (item.subscription?.expiresAt != null) ...[
              const SizedBox(height: 8),
              _MetaRow(
                label: context.tr(ar: 'ينتهي', en: 'Expires'),
                value: _formatDate(item.subscription!.expiresAt!),
              ),
            ],
            if (item.booking?.scheduledFor != null) ...[
              const SizedBox(height: 8),
              _MetaRow(
                label: context.tr(ar: 'الموعد', en: 'Scheduled'),
                value: _formatDate(item.booking!.scheduledFor!),
              ),
            ],
          ],
        ],
      ),
    );
  }

  String _createdAt(DateTime? value, BuildContext context) {
    if (value == null) return context.tr(ar: 'الآن', en: 'Now');
    return DateFormat('yyyy/MM/dd • hh:mm a').format(value.toLocal());
  }

  String _formatDate(DateTime value) {
    return DateFormat('yyyy/MM/dd • hh:mm a').format(value.toLocal());
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          '$label: ',
          style: const TextStyle(
            color: AppColors.textMuted,
            fontWeight: FontWeight.w700,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}

IconData _transactionIcon(String type) {
  switch (type) {
    case 'subscription':
      return Icons.workspace_premium_rounded;
    case 'booking':
      return Icons.event_note_rounded;
    default:
      return Icons.receipt_long_rounded;
  }
}

Color _transactionForeground(PaymentTransactionItem item) {
  if (item.status == 'paid') {
    return item.transactionType == 'subscription'
        ? AppColors.accentDark
        : AppColors.primary;
  }
  return AppColors.textDark;
}

String _statusLabel(BuildContext context, String status) {
  switch (status) {
    case 'paid':
      return context.tr(ar: 'مدفوع', en: 'Paid');
    case 'pending':
      return context.tr(ar: 'قيد الانتظار', en: 'Pending');
    case 'failed':
      return context.tr(ar: 'فشل', en: 'Failed');
    default:
      return status;
  }
}

Color _statusForeground(String status) {
  switch (status) {
    case 'paid':
      return AppColors.success;
    case 'failed':
      return AppColors.error;
    default:
      return AppColors.primaryDark;
  }
}

Color _statusBackground(String status) {
  switch (status) {
    case 'paid':
      return AppColors.successSoft;
    case 'failed':
      return AppColors.errorSoft;
    default:
      return AppColors.primarySoft;
  }
}
