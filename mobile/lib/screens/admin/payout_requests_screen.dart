import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../constants/app_theme.dart';
import '../../core/app_localizations.dart';
import '../../providers/auth_controller.dart';
import '../../services/api_service.dart';
import '../../widgets/app_widgets.dart';
import 'admin_dashboard_screen.dart';

class PayoutRequestsScreen extends ConsumerStatefulWidget {
  const PayoutRequestsScreen({super.key});

  @override
  ConsumerState<PayoutRequestsScreen> createState() =>
      _PayoutRequestsScreenState();
}

class _PayoutRequestsScreenState extends ConsumerState<PayoutRequestsScreen> {
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String _status = '';
  int _page = 1;
  int _total = 0;
  bool _hasMore = false;
  String? _busyPayoutId;
  List<Map<String, dynamic>> _items = const [];
  Map<String, dynamic> _summary = const {};

  static const _filters = [
    ('', 'all'),
    ('pending', 'pending'),
    ('approved', 'approved'),
    ('paid', 'paid'),
    ('rejected', 'rejected'),
  ];

  String? get _token => ref.read(authControllerProvider).token;

  ApiService get _api => ref.read(apiServiceProvider);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load(reset: true));
  }

  Future<void> _load({required bool reset}) async {
    final token = _token;
    if (token == null || token.isEmpty) return;
    setState(() {
      if (reset) {
        _isLoading = true;
        _page = 1;
      } else {
        _isLoadingMore = true;
      }
    });
    try {
      final response = await _api.getAdminPayoutRequests(
        token,
        page: _page,
        pageSize: 10,
        status: _status,
      );
      final items = (response['items'] as List<dynamic>? ?? const [])
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();
      if (!mounted) return;
      setState(() {
        _total = (response['total'] as num?)?.toInt() ?? items.length;
        _hasMore = response['has_more'] == true;
        _items = reset ? items : [..._items, ...items];
        _summary = Map<String, dynamic>.from(
          response['summary'] as Map? ?? const {},
        );
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isLoadingMore = false;
        });
      }
    }
  }

  Future<void> _updatePayout(String payoutId, String action) async {
    final token = _token;
    if (token == null || token.isEmpty) return;

    String? rejectionReason;
    String? paymentReference;
    if (action == 'reject') {
      rejectionReason = await _showInputDialog(
        title: context.tr(ar: 'سبب الرفض', en: 'Rejection reason'),
        hint: context.tr(ar: 'اختياري', en: 'Optional'),
      );
      if (!mounted) return;
      if (rejectionReason == null) return;
    } else if (action == 'mark_paid') {
      paymentReference = await _showInputDialog(
        title: context.tr(ar: 'مرجع التحويل', en: 'Transfer reference'),
        hint: context.tr(ar: 'اختياري', en: 'Optional'),
      );
      if (!mounted) return;
      if (paymentReference == null) return;
    }

    final successMessage = context.tr(
      ar: 'تم تحديث طلب السحب',
      en: 'Payout request updated',
    );

    setState(() => _busyPayoutId = payoutId);
    try {
      await _api.updateAdminPayoutRequest(
        token: token,
        payoutId: payoutId,
        action: action,
        rejectionReason: rejectionReason,
        paymentReference: paymentReference,
      );
      await _load(reset: true);
      ref.invalidate(adminStatsProvider);
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
      if (mounted) {
        setState(() => _busyPayoutId = null);
      }
    }
  }

  Future<String?> _showInputDialog({
    required String title,
    required String hint,
  }) async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          textDirection: context.appTextDirection,
          decoration: InputDecoration(hintText: hint),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(null),
            child: Text(context.tr(ar: 'إلغاء', en: 'Cancel')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: Text(context.tr(ar: 'حفظ', en: 'Save')),
          ),
        ],
      ),
    );
    controller.dispose();
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return HomixPage(
      title: context.tr(ar: 'طلبات السحب', en: 'Payout requests'),
      header: AppBanner(
        title: context.tr(
          ar: 'لوحة إدارة مالية أوضح',
          en: 'A clearer financial operations board',
        ),
        message: context.tr(
          ar: 'طلبات السحب وحالاتها وإجراءات الاعتماد أو الدفع أصبحت مرتبة داخل تجربة متابعة أسرع.',
          en: 'Payout requests, statuses, approvals, and payment actions are now organized into a faster review flow.',
        ),
        icon: Icons.account_balance_wallet_rounded,
        background: AppColors.accentSoft,
        foreground: AppColors.accentDark,
      ),
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => _load(reset: true),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  DashboardHero(
                    title: context.tr(
                      ar: 'كل طلبات السحب في عرض واحد',
                      en: 'All payout requests in one operational view',
                    ),
                    subtitle: _filterLabel(_status, context),
                    chips: [
                      HeroTagChip(
                        label: context.tr(
                          ar: '$_total طلب',
                          en: '$_total requests',
                        ),
                      ),
                      HeroTagChip(
                        label: _filterLabel(_status, context),
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
                            '${_summary['pending_count'] ?? 0}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          Text(
                            context.tr(ar: 'قيد المراجعة', en: 'In review'),
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
                  AppSectionCard(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _filters
                          .map(
                            (filter) => _PayoutFilterChip(
                              label: _filterLabel(filter.$1, context),
                              selected: _status == filter.$1,
                              onTap: () async {
                                setState(() => _status = filter.$1);
                                await _load(reset: true);
                              },
                            ),
                          )
                          .toList(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: MetricPill(
                          label: context.tr(ar: 'معلّق', en: 'Pending'),
                          value: '${_summary['pending_count'] ?? 0}',
                          background: AppColors.accentSoft,
                          valueColor: AppColors.accentDark,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: MetricPill(
                          label: context.tr(ar: 'معتمد', en: 'Approved'),
                          value: '${_summary['approved_count'] ?? 0}',
                          background: AppColors.primarySoft,
                          valueColor: AppColors.primaryDark,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: MetricPill(
                          label: context.tr(ar: 'مدفوع', en: 'Paid'),
                          value: '${_summary['paid_total'] ?? 0}',
                          background: AppColors.successSoft,
                          valueColor: AppColors.success,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (_items.isEmpty)
                    AsyncPlaceholder(
                      message: context.tr(
                        ar: 'لا توجد طلبات سحب مطابقة للفلاتر الحالية.',
                        en: 'There are no payout requests matching the current filters.',
                      ),
                      icon: Icons.payments_outlined,
                    )
                  else
                    ..._items.map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _PayoutCard(
                          item: item,
                          busy: _busyPayoutId == (item['id'] ?? '').toString(),
                          onApprove: () => _updatePayout(
                            (item['id'] ?? '').toString(),
                            'approve',
                          ),
                          onReject: () => _updatePayout(
                            (item['id'] ?? '').toString(),
                            'reject',
                          ),
                          onMarkPaid: () => _updatePayout(
                            (item['id'] ?? '').toString(),
                            'mark_paid',
                          ),
                        ),
                      ),
                    ),
                  if (_hasMore) ...[
                    const SizedBox(height: 8),
                    AppSectionCard(
                      child: OutlinedButton(
                        onPressed: _isLoadingMore
                            ? null
                            : () async {
                                setState(() => _page += 1);
                                await _load(reset: false);
                              },
                        child: Text(
                          _isLoadingMore
                              ? context.tr(
                                  ar: 'جارٍ التحميل...',
                                  en: 'Loading...',
                                )
                              : context.tr(ar: 'عرض المزيد', en: 'Load more'),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  String _filterLabel(String status, BuildContext context) {
    switch (status) {
      case 'pending':
        return context.tr(ar: 'معلّق', en: 'Pending');
      case 'approved':
        return context.tr(ar: 'معتمد', en: 'Approved');
      case 'paid':
        return context.tr(ar: 'مدفوع', en: 'Paid');
      case 'rejected':
        return context.tr(ar: 'مرفوض', en: 'Rejected');
      default:
        return context.tr(ar: 'الكل', en: 'All');
    }
  }
}

class _PayoutFilterChip extends StatelessWidget {
  const _PayoutFilterChip({
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

class _PayoutCard extends StatelessWidget {
  const _PayoutCard({
    required this.item,
    required this.busy,
    required this.onApprove,
    required this.onReject,
    required this.onMarkPaid,
  });

  final Map<String, dynamic> item;
  final bool busy;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final VoidCallback onMarkPaid;

  @override
  Widget build(BuildContext context) {
    final technician = Map<String, dynamic>.from(
      item['technician'] as Map? ?? const {},
    );
    final status = (item['status'] ?? '').toString();
    final amount = (item['amount'] ?? 0).toString();
    final currency = (item['currency'] ?? 'EGP').toString();
    final createdAt = DateTime.tryParse((item['created_at'] ?? '').toString());
    final createdLabel = createdAt == null
        ? null
        : DateFormat('yyyy/MM/dd • hh:mm a').format(createdAt.toLocal());
    final canMutate = status != 'paid';

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
                    colors: [AppColors.secondary, AppColors.primary],
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                  ),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.account_balance_wallet_rounded,
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
                          label: _statusLabel(status, context),
                          foreground: _statusForeground(status),
                          background: _statusBackground(status),
                        ),
                        if (createdLabel != null)
                          AppStatusBadge(
                            label: createdLabel,
                            foreground: AppColors.primaryDark,
                            background: AppColors.primarySoft,
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      (technician['name'] ??
                              context.tr(ar: 'فني', en: 'Technician'))
                          .toString(),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${(technician['category'] ?? '').toString()} • ${(technician['city'] ?? '').toString()}',
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
                  label: context.tr(ar: 'قيمة السحب', en: 'Payout amount'),
                  value: '$amount $currency',
                  background: AppColors.successSoft,
                  valueColor: AppColors.success,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: MetricPill(
                  label: context.tr(ar: 'الوجهة', en: 'Destination'),
                  value: (item['destination_label'] ?? '').toString().isEmpty
                      ? context.tr(ar: 'غير محددة', en: 'Not set')
                      : (item['destination_label'] ?? '').toString(),
                  background: AppColors.backgroundTertiary,
                  valueColor: AppColors.textDark,
                ),
              ),
            ],
          ),
          if ((item['notes'] ?? '').toString().isNotEmpty ||
              (item['rejection_reason'] ?? '').toString().isNotEmpty ||
              (item['payment_reference'] ?? '').toString().isNotEmpty) ...[
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
                  if ((item['notes'] ?? '').toString().isNotEmpty)
                    _PayoutInfoRow(
                      label: context.tr(ar: 'ملاحظات', en: 'Notes'),
                      value: (item['notes'] ?? '').toString(),
                    ),
                  if ((item['notes'] ?? '').toString().isNotEmpty &&
                      (((item['rejection_reason'] ?? '')
                              .toString()
                              .isNotEmpty) ||
                          ((item['payment_reference'] ?? '')
                              .toString()
                              .isNotEmpty)))
                    const SizedBox(height: 10),
                  if ((item['rejection_reason'] ?? '').toString().isNotEmpty)
                    _PayoutInfoRow(
                      label: context.tr(
                        ar: 'سبب الرفض',
                        en: 'Rejection reason',
                      ),
                      value: (item['rejection_reason'] ?? '').toString(),
                      valueColor: AppColors.error,
                    ),
                  if ((item['rejection_reason'] ?? '').toString().isNotEmpty &&
                      (item['payment_reference'] ?? '').toString().isNotEmpty)
                    const SizedBox(height: 10),
                  if ((item['payment_reference'] ?? '').toString().isNotEmpty)
                    _PayoutInfoRow(
                      label: context.tr(ar: 'مرجع الدفع', en: 'Payment ref'),
                      value: (item['payment_reference'] ?? '').toString(),
                    ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton(
                onPressed: busy || !canMutate ? null : onApprove,
                child: Text(
                  busy
                      ? context.tr(ar: 'جارٍ...', en: 'Working...')
                      : context.tr(ar: 'اعتماد', en: 'Approve'),
                ),
              ),
              OutlinedButton(
                onPressed: busy || !canMutate ? null : onReject,
                child: Text(context.tr(ar: 'رفض', en: 'Reject')),
              ),
              ElevatedButton(
                onPressed: busy || !canMutate ? null : onMarkPaid,
                child: Text(context.tr(ar: 'تم الدفع', en: 'Mark paid')),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _statusLabel(String status, BuildContext context) {
    switch (status) {
      case 'approved':
        return context.tr(ar: 'معتمد', en: 'Approved');
      case 'paid':
        return context.tr(ar: 'مدفوع', en: 'Paid');
      case 'rejected':
        return context.tr(ar: 'مرفوض', en: 'Rejected');
      default:
        return context.tr(ar: 'معلّق', en: 'Pending');
    }
  }

  Color _statusForeground(String status) {
    switch (status) {
      case 'approved':
        return AppColors.info;
      case 'paid':
        return AppColors.success;
      case 'rejected':
        return AppColors.error;
      default:
        return AppColors.accentDark;
    }
  }

  Color _statusBackground(String status) {
    switch (status) {
      case 'approved':
        return AppColors.secondarySoft;
      case 'paid':
        return AppColors.successSoft;
      case 'rejected':
        return AppColors.errorSoft;
      default:
        return AppColors.accentSoft;
    }
  }
}

class _PayoutInfoRow extends StatelessWidget {
  const _PayoutInfoRow({
    required this.label,
    required this.value,
    this.valueColor = AppColors.textDark,
  });

  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 92,
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
            style: TextStyle(
              color: valueColor,
              height: 1.6,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}
