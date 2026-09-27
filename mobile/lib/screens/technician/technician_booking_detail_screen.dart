import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../constants/app_theme.dart';
import '../../core/app_localizations.dart';
import '../../models/service_booking.dart';
import '../../providers/auth_controller.dart';
import '../../services/api_service.dart';
import '../../widgets/app_widgets.dart';

class TechnicianBookingDetailScreen extends ConsumerStatefulWidget {
  const TechnicianBookingDetailScreen({
    super.key,
    required this.bookingId,
    this.initialTab = 0,
  });

  final String bookingId;
  final int initialTab;

  @override
  ConsumerState<TechnicianBookingDetailScreen> createState() =>
      _TechnicianBookingDetailScreenState();
}

class _TechnicianBookingDetailScreenState
    extends ConsumerState<TechnicianBookingDetailScreen> {
  int _tabIndex = 0;
  bool _isLoading = true;
  bool _isUpdatingStatus = false;
  bool _isSendingMessage = false;
  ServiceBooking? _booking;
  String? _error;
  final _messageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabIndex = widget.initialTab.clamp(0, 2);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadBooking());
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _loadBooking() async {
    final token = ref.read(authControllerProvider).token;
    if (token == null || token.isEmpty) {
      setState(() {
        _error = context.tr(
          ar: 'يجب تسجيل الدخول أولًا.',
          en: 'You need to sign in first.',
        );
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final booking = await ref
          .read(apiServiceProvider)
          .getBookingDetails(token: token, bookingId: widget.bookingId);
      if (!mounted) return;
      setState(() => _booking = booking);
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateStatus(String action) async {
    final token = ref.read(authControllerProvider).token;
    final booking = _booking;
    if (token == null || token.isEmpty || booking == null) return;
    final successMessage = context.tr(
      ar: 'تم تحديث حالة الحجز.',
      en: 'Booking status updated.',
    );
    setState(() => _isUpdatingStatus = true);
    try {
      await ref
          .read(apiServiceProvider)
          .updateTechnicianBookingStatus(
            token: token,
            bookingId: booking.id,
            action: action,
          );
      await _loadBooking();
      _showSnack(successMessage);
    } catch (error) {
      _showSnack(error.toString());
    } finally {
      if (mounted) setState(() => _isUpdatingStatus = false);
    }
  }

  Future<void> _sendMessage() async {
    final token = ref.read(authControllerProvider).token;
    final booking = _booking;
    final text = _messageController.text.trim();
    if (token == null || token.isEmpty || booking == null || text.isEmpty) {
      return;
    }
    setState(() => _isSendingMessage = true);
    try {
      await ref
          .read(apiServiceProvider)
          .sendBookingMessage(
            token: token,
            bookingId: booking.id,
            message: text,
          );
      _messageController.clear();
      await _loadBooking();
    } catch (error) {
      _showSnack(error.toString());
    } finally {
      if (mounted) setState(() => _isSendingMessage = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return HomixPage(
      title: context.tr(ar: 'تفاصيل الحجز', en: 'Booking details'),
      header: AppBanner(
        title: context.tr(
          ar: 'شاشة تشغيل أوضح للحجز',
          en: 'A clearer operating view for the booking',
        ),
        message: context.tr(
          ar: 'رتبنا ملخص الحجز والتتبع والمحادثة في شاشة واحدة تساعد الفني على التحرك والرد واتخاذ القرار بسرعة.',
          en: 'Summary, tracking, and chat are now organized into a single operating screen for faster technician decisions.',
        ),
        icon: Icons.handyman_rounded,
        background: AppColors.secondarySoft,
        foreground: AppColors.secondary,
      ),
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? AsyncPlaceholder(message: _error!)
          : RefreshIndicator(
              onRefresh: _loadBooking,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  _buildHero(),
                  const SizedBox(height: 16),
                  _buildQuickStats(),
                  const SizedBox(height: 12),
                  _buildTabBar(),
                  const SizedBox(height: 12),
                  switch (_tabIndex) {
                    0 => _buildOverviewTab(),
                    1 => _buildTrackingTab(),
                    _ => _buildChatTab(),
                  },
                ],
              ),
            ),
    );
  }

  Widget _buildHero() {
    final booking = _booking!;
    return DashboardHero(
      title: booking.customerName,
      subtitle: booking.problemDescription,
      chips: [
        HeroTagChip(label: _statusLabel(booking.status), highlight: true),
        HeroTagChip(
          label:
              '${booking.estimatedPrice.toStringAsFixed(0)} ${booking.currency}',
        ),
        HeroTagChip(label: _paymentStatusLabel(booking.paymentStatus)),
      ],
      trailing: Container(
        width: 118,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Column(
          children: [
            Text(
              booking.scheduledFor == null
                  ? '--'
                  : DateFormat('dd/MM').format(booking.scheduledFor!.toLocal()),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              booking.scheduledFor == null
                  ? context.tr(ar: 'بدون موعد', en: 'No schedule')
                  : context.tr(ar: 'الموعد', en: 'Schedule'),
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
    );
  }

  Widget _buildQuickStats() {
    final booking = _booking!;
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: StatTile(
                label: context.tr(ar: 'السعر التقديري', en: 'Estimated price'),
                value:
                    '${booking.estimatedPrice.toStringAsFixed(0)} ${booking.currency}',
                color: AppColors.primary,
                icon: Icons.payments_rounded,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StatTile(
                label: context.tr(ar: 'الدفع', en: 'Payment'),
                value: _paymentStatusLabel(booking.paymentStatus),
                color: AppColors.accent,
                icon: Icons.credit_card_rounded,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: MetricPill(
                label: context.tr(ar: 'الموعد', en: 'Schedule'),
                value: booking.scheduledFor == null
                    ? context.tr(ar: 'غير محدد', en: 'Not set')
                    : _formatDate(booking.scheduledFor!),
                background: AppColors.primarySoft,
                valueColor: AppColors.primaryDark,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: MetricPill(
                label: context.tr(ar: 'قناة الدفع', en: 'Payment method'),
                value: booking.paymentMethod.isEmpty
                    ? context.tr(ar: 'غير محددة', en: 'Not set')
                    : booking.paymentMethod,
                background: AppColors.secondarySoft,
                valueColor: AppColors.secondary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTabBar() {
    return AppSectionCard(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: List.generate(3, (index) {
          final selected = _tabIndex == index;
          return Expanded(
            child: Padding(
              padding: EdgeInsetsDirectional.only(end: index == 2 ? 0 : 8),
              child: GestureDetector(
                onTap: () => setState(() => _tabIndex = index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    gradient: selected
                        ? const LinearGradient(
                            colors: [AppColors.primaryDark, AppColors.primary],
                            begin: Alignment.topRight,
                            end: Alignment.bottomLeft,
                          )
                        : const LinearGradient(
                            colors: [
                              AppColors.cardWhite,
                              AppColors.backgroundTertiary,
                            ],
                          ),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: selected ? Colors.transparent : AppColors.border,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        _tabIcon(index),
                        color: selected ? Colors.white : AppColors.textMuted,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _tabLabel(index),
                        style: TextStyle(
                          color: selected ? Colors.white : AppColors.textDark,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildOverviewTab() {
    final booking = _booking!;
    final actions = _actionsForStatus(booking.status);

    return Column(
      children: [
        AppSectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionHeading(
                title: context.tr(ar: 'بيانات العميل', en: 'Customer details'),
                subtitle: context.tr(
                  ar: 'معلومات التواصل والعنوان ومرجع الدفع في نظرة واحدة.',
                  en: 'Contact, address, and payment reference in one place.',
                ),
              ),
              const SizedBox(height: 12),
              _InfoRow(
                label: context.tr(ar: 'الاسم', en: 'Name'),
                value: booking.customerName,
              ),
              _InfoRow(
                label: context.tr(ar: 'البريد', en: 'Email'),
                value: booking.customerEmail,
              ),
              _InfoRow(
                label: context.tr(ar: 'العنوان', en: 'Address'),
                value: booking.address,
              ),
              _InfoRow(
                label: context.tr(ar: 'الدفع', en: 'Payment'),
                value: _paymentStatusLabel(booking.paymentStatus),
              ),
              _InfoRow(
                label: context.tr(ar: 'المرجع', en: 'Reference'),
                value: booking.paymentReference.isEmpty
                    ? context.tr(ar: 'غير متوفر', en: 'Unavailable')
                    : booking.paymentReference,
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
                title: context.tr(ar: 'وصف الخدمة', en: 'Service brief'),
                subtitle: context.tr(
                  ar: 'الوصف الذي أدخله العميل للمشكلة الحالية.',
                  en: 'The customer-provided description of the issue.',
                ),
              ),
              const SizedBox(height: 12),
              Text(
                booking.problemDescription,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  height: 1.7,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        if (actions.isNotEmpty) ...[
          const SizedBox(height: 12),
          AppSectionCard(
            color: AppColors.accentSoft,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionHeading(
                  title: context.tr(ar: 'إجراءات الحجز', en: 'Booking actions'),
                  subtitle: context.tr(
                    ar: 'حدّث الحالة من هنا بناءً على تقدمك في المهمة.',
                    en: 'Update the booking state here based on your operational progress.',
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: actions
                      .map(
                        (action) => action.$1 == 'cancel'
                            ? OutlinedButton(
                                onPressed: _isUpdatingStatus
                                    ? null
                                    : () => _updateStatus(action.$1),
                                child: Text(action.$2),
                              )
                            : ElevatedButton(
                                onPressed: _isUpdatingStatus
                                    ? null
                                    : () => _updateStatus(action.$1),
                                child: Text(action.$2),
                              ),
                      )
                      .toList(),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTrackingTab() {
    final tracking = _booking!.tracking;
    if (tracking.isEmpty) {
      return AsyncPlaceholder(
        message: context.tr(
          ar: 'لا توجد تحديثات تتبع لهذا الحجز حتى الآن.',
          en: 'There are no tracking updates for this booking yet.',
        ),
        icon: Icons.timeline_rounded,
      );
    }

    return Column(
      children: tracking
          .asMap()
          .entries
          .map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _TrackingCard(
                item: entry.value,
                isLast: entry.key == tracking.length - 1,
                timestamp: _formatDate(entry.value.createdAt ?? DateTime.now()),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildChatTab() {
    final booking = _booking!;
    final messages = booking.messages;

    return Column(
      children: [
        if (messages.isEmpty)
          AppSectionCard(
            color: AppColors.primarySoft,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.chat_bubble_outline_rounded,
                  color: AppColors.primaryDark,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    context.tr(
                      ar: 'لا توجد رسائل بعد. ابدأ المحادثة مع العميل لتنسيق الوصول أو تأكيد التفاصيل.',
                      en: 'There are no messages yet. Start the conversation to coordinate arrival or confirm details.',
                    ),
                    style: const TextStyle(
                      color: AppColors.primaryDark,
                      height: 1.6,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          )
        else
          ...messages.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _MessageBubble(
                item: item,
                timestamp: item.createdAt == null
                    ? null
                    : DateFormat('hh:mm a').format(item.createdAt!.toLocal()),
              ),
            ),
          ),
        const SizedBox(height: 12),
        AppSectionCard(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: AppTextField(
                  controller: _messageController,
                  textDirection: context.appTextDirection,
                  maxLines: 4,
                  minLines: 1,
                  decoration: InputDecoration(
                    hintText: context.tr(
                      ar: 'اكتب رسالة للعميل...',
                      en: 'Write a message to the customer...',
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    filled: false,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.primary,
                child: IconButton(
                  onPressed: _isSendingMessage ? null : _sendMessage,
                  icon: const Icon(Icons.send_rounded, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  List<(String, String)> _actionsForStatus(String status) {
    switch (status) {
      case 'pending':
        return [
          ('confirm', context.tr(ar: 'قبول', en: 'Accept')),
          ('cancel', context.tr(ar: 'رفض', en: 'Reject')),
        ];
      case 'confirmed':
        return [
          ('start', context.tr(ar: 'بدء التحرك', en: 'Start moving')),
          ('cancel', context.tr(ar: 'إلغاء', en: 'Cancel')),
        ];
      case 'in_progress':
        return [('arrive', context.tr(ar: 'تم الوصول', en: 'Arrived'))];
      case 'arrived':
        return [('complete', context.tr(ar: 'تم الإنجاز', en: 'Complete'))];
      default:
        return const [];
    }
  }

  String _tabLabel(int index) {
    switch (index) {
      case 0:
        return context.tr(ar: 'الملخص', en: 'Summary');
      case 1:
        return context.tr(ar: 'التتبع', en: 'Tracking');
      default:
        return context.tr(ar: 'المحادثة', en: 'Chat');
    }
  }

  IconData _tabIcon(int index) {
    switch (index) {
      case 0:
        return Icons.dashboard_customize_rounded;
      case 1:
        return Icons.timeline_rounded;
      default:
        return Icons.chat_rounded;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'pending':
        return context.tr(ar: 'جديد', en: 'New');
      case 'confirmed':
        return context.tr(ar: 'مؤكد', en: 'Confirmed');
      case 'in_progress':
        return context.tr(ar: 'جاري', en: 'In progress');
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

  String _paymentStatusLabel(String status) {
    switch (status) {
      case 'paid':
        return context.tr(ar: 'مدفوع', en: 'Paid');
      case 'pending':
        return context.tr(ar: 'بانتظار الدفع', en: 'Pending payment');
      case 'failed':
        return context.tr(ar: 'فشل الدفع', en: 'Payment failed');
      default:
        return status.isEmpty
            ? context.tr(ar: 'غير محدد', en: 'Unknown')
            : status;
    }
  }

  String _formatDate(DateTime value) {
    return DateFormat('yyyy/MM/dd • hh:mm a').format(value.toLocal());
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
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
              style: const TextStyle(fontWeight: FontWeight.w700, height: 1.6),
            ),
          ),
        ],
      ),
    );
  }
}

class _TrackingCard extends StatelessWidget {
  const _TrackingCard({
    required this.item,
    required this.isLast,
    required this.timestamp,
  });

  final BookingTrackingEntry item;
  final bool isLast;
  final String timestamp;

  @override
  Widget build(BuildContext context) {
    final accent = _accentFor(item.status);

    return AppSectionCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 24,
            child: Column(
              children: [
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: accent,
                    shape: BoxShape.circle,
                  ),
                ),
                if (!isLast)
                  Container(
                    width: 2,
                    height: 72,
                    margin: const EdgeInsets.only(top: 6),
                    color: accent.withValues(alpha: 0.24),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
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
                const SizedBox(height: 6),
                Text(
                  item.details,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    height: 1.6,
                  ),
                ),
                if (item.etaMinutes != null) ...[
                  const SizedBox(height: 8),
                  AppStatusBadge(
                    label:
                        '${item.etaMinutes} ${context.tr(ar: 'دقيقة', en: 'min')}',
                    foreground: accent,
                    background: accent.withValues(alpha: 0.12),
                  ),
                ],
                const SizedBox(height: 8),
                Text(
                  timestamp,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _accentFor(String status) {
    switch (status) {
      case 'completed':
        return AppColors.success;
      case 'arrived':
        return AppColors.accentDark;
      default:
        return AppColors.primary;
    }
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.item, required this.timestamp});

  final BookingMessageItem item;
  final String? timestamp;

  @override
  Widget build(BuildContext context) {
    final isTechnician = item.senderType == 'technician';

    return Align(
      alignment: isTechnician ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 310),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: isTechnician
              ? const LinearGradient(
                  colors: [AppColors.primaryDark, AppColors.primary],
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                )
              : const LinearGradient(
                  colors: [AppColors.cardWhite, AppColors.backgroundTertiary],
                ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isTechnician ? Colors.transparent : AppColors.border,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.senderName,
              style: TextStyle(
                color: isTechnician ? Colors.white : AppColors.textDark,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              item.message,
              style: TextStyle(
                color: isTechnician ? Colors.white : AppColors.textDark,
                height: 1.6,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (timestamp != null) ...[
              const SizedBox(height: 8),
              Text(
                timestamp!,
                style: TextStyle(
                  color: isTechnician
                      ? Colors.white.withValues(alpha: 0.8)
                      : AppColors.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
