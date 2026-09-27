import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../constants/app_theme.dart';
import '../../core/app_localizations.dart';
import '../../core/app_router.dart';
import '../../providers/auth_controller.dart';
import '../../services/api_service.dart';
import '../../widgets/app_widgets.dart';

class AdminBookingsScreen extends ConsumerStatefulWidget {
  const AdminBookingsScreen({super.key});

  @override
  ConsumerState<AdminBookingsScreen> createState() =>
      _AdminBookingsScreenState();
}

class _AdminBookingsScreenState extends ConsumerState<AdminBookingsScreen> {
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String _status = '';
  int _page = 1;
  int _total = 0;
  bool _hasMore = false;
  String? _busyBookingId;
  List<Map<String, dynamic>> _items = const [];

  static const _filters = [
    ('', 'all'),
    ('pending', 'pending'),
    ('confirmed', 'confirmed'),
    ('in_progress', 'in_progress'),
    ('completed', 'completed'),
    ('cancelled', 'cancelled'),
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
      final response = await _api.getAdminBookings(
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

  Future<void> _updateStatus(String bookingId, String action) async {
    final token = _token;
    if (token == null || token.isEmpty) return;
    final successMessage = context.tr(
      ar: 'تم تحديث حالة الحجز',
      en: 'Booking status updated',
    );
    setState(() => _busyBookingId = bookingId);
    try {
      await _api.updateServiceBookingStatus(
        token: token,
        bookingId: bookingId,
        action: action,
      );
      await _load(reset: true);
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
      if (mounted) setState(() => _busyBookingId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return HomixPage(
      title: context.tr(ar: 'إدارة الحجوزات', en: 'Manage bookings'),
      header: AppBanner(
        title: context.tr(
          ar: 'لوحة متابعة الحجوزات أصبحت أنضج',
          en: 'Booking operations are now easier to review',
        ),
        message: context.tr(
          ar: 'الفلاتر، الحالات، بيانات العميل والفني، وإجراءات التحديث أصبحت مرتبة داخل شاشة تشغيل أوضح.',
          en: 'Filters, statuses, customer and technician info, and update actions are now organized into a clearer operations screen.',
        ),
        icon: Icons.assignment_turned_in_rounded,
        background: AppColors.primarySoft,
        foreground: AppColors.primaryDark,
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
                      ar: 'كل الحجوزات في لوحة متابعة واحدة',
                      en: 'All bookings in one review board',
                    ),
                    subtitle: _filterLabel(_status, context),
                    chips: [
                      HeroTagChip(
                        label: context.tr(
                          ar: '$_total حجز',
                          en: '$_total bookings',
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
                            '${_items.length}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          Text(
                            context.tr(ar: 'في هذه الصفحة', en: 'On this page'),
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
                            (filter) => _BookingFilterChip(
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
                        child: StatTile(
                          label: context.tr(
                            ar: 'إجمالي الحجوزات',
                            en: 'Total bookings',
                          ),
                          value: '$_total',
                          color: AppColors.primary,
                          icon: Icons.event_note_rounded,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: StatTile(
                          label: context.tr(
                            ar: 'الفلتر الحالي',
                            en: 'Current filter',
                          ),
                          value: _filterLabel(_status, context),
                          color: AppColors.accent,
                          icon: Icons.filter_alt_rounded,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (_items.isEmpty)
                    AsyncPlaceholder(
                      message: context.tr(
                        ar: 'لا توجد حجوزات مطابقة للفلاتر الحالية.',
                        en: 'There are no bookings matching the current filters.',
                      ),
                      icon: Icons.calendar_month_outlined,
                    )
                  else
                    ..._items.map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _BookingAdminCard(
                          item: item,
                          busy: _busyBookingId == (item['id'] ?? '').toString(),
                          onOpenDetails: () => context.push(
                            AppRoutes.customerBookingDetailsPath(
                              (item['id'] ?? '').toString(),
                            ),
                          ),
                          onAction: (action) => _updateStatus(
                            (item['id'] ?? '').toString(),
                            action,
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
        return context.tr(ar: 'مراجعة', en: 'Pending');
      case 'confirmed':
        return context.tr(ar: 'مؤكد', en: 'Confirmed');
      case 'in_progress':
        return context.tr(ar: 'تنفيذ', en: 'In progress');
      case 'completed':
        return context.tr(ar: 'مكتمل', en: 'Completed');
      case 'cancelled':
        return context.tr(ar: 'ملغي', en: 'Cancelled');
      default:
        return context.tr(ar: 'الكل', en: 'All');
    }
  }
}

class _BookingFilterChip extends StatelessWidget {
  const _BookingFilterChip({
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

class _BookingAdminCard extends StatelessWidget {
  const _BookingAdminCard({
    required this.item,
    required this.busy,
    required this.onOpenDetails,
    required this.onAction,
  });

  final Map<String, dynamic> item;
  final bool busy;
  final VoidCallback onOpenDetails;
  final void Function(String action) onAction;

  @override
  Widget build(BuildContext context) {
    final status = (item['status'] ?? '').toString();
    final paymentStatus = (item['payment_status'] ?? '').toString();
    final scheduledFor = DateTime.tryParse(
      (item['scheduled_for'] ?? '').toString(),
    );
    final actions = _allowedActions(status, context);

    return AppSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primaryDark, AppColors.secondary],
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                  ),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(Icons.handyman_rounded, color: Colors.white),
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
                        AppStatusBadge(
                          label: _paymentStatusLabel(paymentStatus, context),
                          foreground: AppColors.secondary,
                          background: AppColors.secondarySoft,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      (item['problem_description'] ?? '').toString(),
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${(item['customer_name'] ?? '').toString()} • ${(item['technician_name'] ?? '').toString()}',
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
                  label: context.tr(ar: 'السعر', en: 'Price'),
                  value:
                      '${item['estimated_price'] ?? 0} ${(item['currency'] ?? 'EGP').toString()}',
                  background: AppColors.accentSoft,
                  valueColor: AppColors.accentDark,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: MetricPill(
                  label: context.tr(ar: 'الموعد', en: 'Schedule'),
                  value: scheduledFor == null
                      ? context.tr(ar: 'غير محدد', en: 'Not set')
                      : DateFormat('yyyy/MM/dd').format(scheduledFor.toLocal()),
                  background: AppColors.primarySoft,
                  valueColor: AppColors.primaryDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton(
                onPressed: onOpenDetails,
                child: Text(context.tr(ar: 'تفاصيل', en: 'Details')),
              ),
              ...actions.map(
                (action) => ElevatedButton(
                  onPressed: busy ? null : () => onAction(action.$1),
                  child: Text(
                    busy
                        ? context.tr(ar: 'جارٍ...', en: 'Working...')
                        : action.$2,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<(String, String)> _allowedActions(String status, BuildContext context) {
    switch (status) {
      case 'pending':
        return [
          ('confirm', context.tr(ar: 'تأكيد', en: 'Confirm')),
          ('cancel', context.tr(ar: 'إلغاء', en: 'Cancel')),
        ];
      case 'confirmed':
        return [('start', context.tr(ar: 'بدء', en: 'Start'))];
      case 'in_progress':
        return [('arrive', context.tr(ar: 'وصول', en: 'Arrive'))];
      case 'arrived':
        return [('complete', context.tr(ar: 'إنهاء', en: 'Complete'))];
      default:
        return const [];
    }
  }

  String _statusLabel(String status, BuildContext context) {
    switch (status) {
      case 'pending':
        return context.tr(ar: 'مراجعة', en: 'Pending');
      case 'confirmed':
        return context.tr(ar: 'مؤكد', en: 'Confirmed');
      case 'in_progress':
        return context.tr(ar: 'تنفيذ', en: 'In progress');
      case 'arrived':
        return context.tr(ar: 'وصل', en: 'Arrived');
      case 'completed':
        return context.tr(ar: 'مكتمل', en: 'Completed');
      case 'cancelled':
        return context.tr(ar: 'ملغي', en: 'Cancelled');
      default:
        return status;
    }
  }

  String _paymentStatusLabel(String status, BuildContext context) {
    switch (status) {
      case 'paid':
        return context.tr(ar: 'مدفوع', en: 'Paid');
      case 'pending':
        return context.tr(ar: 'بانتظار الدفع', en: 'Pending payment');
      default:
        return status.isEmpty
            ? context.tr(ar: 'غير محدد', en: 'Unknown')
            : status;
    }
  }

  Color _statusForeground(String status) {
    switch (status) {
      case 'completed':
        return AppColors.success;
      case 'cancelled':
        return AppColors.error;
      case 'confirmed':
      case 'in_progress':
      case 'arrived':
        return AppColors.primaryDark;
      default:
        return AppColors.accentDark;
    }
  }

  Color _statusBackground(String status) {
    switch (status) {
      case 'completed':
        return AppColors.successSoft;
      case 'cancelled':
        return AppColors.errorSoft;
      case 'confirmed':
      case 'in_progress':
      case 'arrived':
        return AppColors.primarySoft;
      default:
        return AppColors.accentSoft;
    }
  }
}
