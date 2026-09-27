import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../constants/app_theme.dart';
import '../../core/app_localizations.dart';
import '../../models/service_booking.dart';
import '../../providers/auth_controller.dart';
import '../../services/api_service.dart';
import '../../widgets/app_widgets.dart';

class CustomerBookingDetailScreen extends ConsumerStatefulWidget {
  const CustomerBookingDetailScreen({
    super.key,
    required this.bookingId,
    this.initialTab = 0,
  });

  final String bookingId;
  final int initialTab;

  @override
  ConsumerState<CustomerBookingDetailScreen> createState() =>
      _CustomerBookingDetailScreenState();
}

class _CustomerBookingDetailScreenState
    extends ConsumerState<CustomerBookingDetailScreen> {
  late int _tabIndex;
  bool _isLoading = true;
  bool _isSendingMessage = false;
  bool _isSubmittingReview = false;
  bool _isSubmittingPayment = false;
  bool _isSubmittingBookingChange = false;
  ServiceBooking? _booking;
  final _messageController = TextEditingController();
  final _reviewController = TextEditingController();
  int _selectedRating = 5;

  @override
  void initState() {
    super.initState();
    _tabIndex = widget.initialTab.clamp(0, 3);
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _messageController.dispose();
    _reviewController.dispose();
    super.dispose();
  }

  String? get _token => ref.read(authControllerProvider).token;

  List<String> _tabs(BuildContext context) => [
    context.tr(ar: 'الملخص', en: 'Summary'),
    context.tr(ar: 'التتبع', en: 'Tracking'),
    context.tr(ar: 'المحادثة', en: 'Chat'),
    context.tr(ar: 'التقييم', en: 'Review'),
  ];

  Future<void> _load() async {
    final token = _token;
    if (token == null || token.isEmpty) return;
    setState(() => _isLoading = true);
    try {
      final booking = await ref
          .read(apiServiceProvider)
          .getBookingDetails(token: token, bookingId: widget.bookingId);
      if (!mounted) return;
      setState(() => _booking = booking);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _sendMessage() async {
    final token = _token;
    final booking = _booking;
    final message = _messageController.text.trim();
    if (token == null || token.isEmpty || booking == null || message.isEmpty) {
      return;
    }
    setState(() => _isSendingMessage = true);
    try {
      await ref
          .read(apiServiceProvider)
          .sendBookingMessage(
            token: token,
            bookingId: booking.id,
            message: message,
          );
      _messageController.clear();
      await _load();
    } finally {
      if (mounted) setState(() => _isSendingMessage = false);
    }
  }

  Future<void> _pay() async {
    final token = _token;
    final booking = _booking;
    if (token == null || token.isEmpty || booking == null) return;
    setState(() => _isSubmittingPayment = true);
    try {
      await ref
          .read(apiServiceProvider)
          .payForBooking(token: token, bookingId: booking.id, method: 'card');
      await _load();
    } finally {
      if (mounted) setState(() => _isSubmittingPayment = false);
    }
  }

  Future<void> _cancelBooking() async {
    final token = _token;
    final booking = _booking;
    if (token == null || token.isEmpty || booking == null) return;
    setState(() => _isSubmittingBookingChange = true);
    try {
      await ref
          .read(apiServiceProvider)
          .cancelBooking(token: token, bookingId: booking.id);
      await _load();
    } finally {
      if (mounted) setState(() => _isSubmittingBookingChange = false);
    }
  }

  Future<void> _rescheduleBooking() async {
    final token = _token;
    final booking = _booking;
    if (token == null || token.isEmpty || booking == null) return;
    final scheduledFor = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      initialDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (scheduledFor == null) return;

    setState(() => _isSubmittingBookingChange = true);
    try {
      final updated = await ref
          .read(apiServiceProvider)
          .rescheduleBooking(
            token: token,
            bookingId: booking.id,
            scheduledFor: DateTime(
              scheduledFor.year,
              scheduledFor.month,
              scheduledFor.day,
              12,
              0,
            ),
          );
      if (!mounted) return;
      setState(() => _booking = updated);
    } finally {
      if (mounted) setState(() => _isSubmittingBookingChange = false);
    }
  }

  Future<void> _submitReview() async {
    final token = _token;
    final booking = _booking;
    if (token == null || token.isEmpty || booking == null) return;
    setState(() => _isSubmittingReview = true);
    try {
      final updated = await ref
          .read(apiServiceProvider)
          .submitBookingReview(
            token: token,
            bookingId: booking.id,
            rating: _selectedRating,
            comment: _reviewController.text.trim(),
          );
      if (!mounted) return;
      setState(() => _booking = updated);
    } finally {
      if (mounted) setState(() => _isSubmittingReview = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return HomixPage(
      title: context.tr(ar: 'تفاصيل الحجز', en: 'Booking details'),
      header: AppBanner(
        title: context.tr(
          ar: 'حالة الحجز والدفع والمحادثة في شاشة أوضح',
          en: 'Status, payment, and chat in one clearer screen',
        ),
        message: context.tr(
          ar: 'أعدنا تنظيم رحلة الحجز لتكون أسهل في المتابعة وأسرع في المسح البصري.',
          en: 'The booking journey is reorganized to be easier to scan and follow.',
        ),
        icon: Icons.event_note_rounded,
        background: AppColors.primarySoft,
        foreground: AppColors.primaryDark,
      ),
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _booking == null
          ? AsyncPlaceholder(
              message: context.tr(
                ar: 'تعذر تحميل بيانات الحجز.',
                en: 'Could not load booking details.',
              ),
            )
          : Column(
              children: [
                _BookingTabs(
                  tabs: _tabs(context),
                  currentIndex: _tabIndex,
                  onChanged: (value) => setState(() => _tabIndex = value),
                ),
                const SizedBox(height: 14),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: switch (_tabIndex) {
                      0 => _buildSummaryTab(_booking!),
                      1 => _buildTrackingTab(_booking!),
                      2 => _buildChatTab(_booking!),
                      _ => _buildReviewTab(_booking!),
                    },
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildSummaryTab(ServiceBooking booking) {
    return Column(
      children: [
        DashboardHero(
          title: booking.technician.name,
          subtitle: context.tr(ar: 'ملخص الحجز الحالي', en: 'Current booking'),
          chips: [
            HeroTagChip(
              label: _statusLabel(context, booking.status),
              highlight: true,
            ),
            HeroTagChip(label: _paymentLabel(context, booking.paymentStatus)),
            HeroTagChip(label: _formatDateTime(booking.scheduledFor)),
          ],
          trailing: Container(
            width: 112,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Column(
              children: [
                Text(
                  booking.estimatedPrice.toStringAsFixed(0),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  context.tr(ar: 'تكلفة متوقعة', en: 'Estimated cost'),
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
          child: Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: booking.technician.accent,
                child: Icon(
                  booking.technician.icon,
                  color: AppColors.primaryDark,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      booking.technician.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${booking.technician.title} • ${booking.technician.city}',
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        AppStatusBadge(
                          label: _statusLabel(context, booking.status),
                          foreground: _statusForeground(booking.status),
                          background: _statusBackground(booking.status),
                        ),
                        AppStatusBadge(
                          label: _paymentLabel(context, booking.paymentStatus),
                          foreground: _paymentForeground(booking.paymentStatus),
                          background: _paymentBackground(booking.paymentStatus),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: StatTile(
                label: context.tr(ar: 'السعر', en: 'Price'),
                value: booking.estimatedPrice.toStringAsFixed(0),
                color: AppColors.primary,
                icon: Icons.payments_rounded,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StatTile(
                label: context.tr(ar: 'التقييم', en: 'Review'),
                value: booking.review == null
                    ? context.tr(ar: 'لاحقًا', en: 'Later')
                    : '${booking.review!.rating}/5',
                color: AppColors.accent,
                icon: Icons.star_rounded,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        AppSectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionHeading(
                title: context.tr(
                  ar: 'تفاصيل التنفيذ',
                  en: 'Execution details',
                ),
                subtitle: context.tr(
                  ar: 'العنوان، الوصف، وخيارات التحكم السريع في الحجز.',
                  en: 'Address, issue description, and quick controls.',
                ),
              ),
              const SizedBox(height: 14),
              _DetailRow(
                icon: Icons.location_on_rounded,
                title: context.tr(ar: 'العنوان', en: 'Address'),
                value: booking.address,
              ),
              const SizedBox(height: 12),
              _DetailRow(
                icon: Icons.schedule_rounded,
                title: context.tr(ar: 'الموعد', en: 'Scheduled'),
                value: _formatDateTime(booking.scheduledFor),
              ),
              const SizedBox(height: 12),
              _DetailRow(
                icon: Icons.description_rounded,
                title: context.tr(ar: 'وصف المشكلة', en: 'Issue'),
                value: booking.problemDescription,
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  if (booking.paymentStatus != 'paid')
                    ElevatedButton.icon(
                      onPressed: _isSubmittingPayment ? null : _pay,
                      icon: const Icon(Icons.credit_card_rounded),
                      label: Text(
                        _isSubmittingPayment
                            ? context.tr(ar: 'جارٍ الدفع...', en: 'Paying...')
                            : context.tr(
                                ar: 'تأكيد الدفع',
                                en: 'Confirm payment',
                              ),
                      ),
                    ),
                  if (!_isLockedStatus(booking.status))
                    OutlinedButton.icon(
                      key: const Key('customer-reschedule-booking-button'),
                      onPressed: _isSubmittingBookingChange
                          ? null
                          : _rescheduleBooking,
                      icon: const Icon(Icons.event_repeat_rounded),
                      label: Text(
                        context.tr(ar: 'إعادة الجدولة', en: 'Reschedule'),
                      ),
                    ),
                  if (!_isLockedStatus(booking.status))
                    OutlinedButton.icon(
                      key: const Key('customer-cancel-booking-button'),
                      onPressed: _isSubmittingBookingChange
                          ? null
                          : _cancelBooking,
                      icon: const Icon(Icons.cancel_outlined),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: const BorderSide(color: AppColors.error),
                      ),
                      label: Text(
                        context.tr(ar: 'إلغاء الحجز', en: 'Cancel booking'),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTrackingTab(ServiceBooking booking) {
    return Column(
      children: [
        DashboardHero(
          title: context.tr(ar: 'تتبع الحجز', en: 'Booking tracking'),
          subtitle: _statusLabel(context, booking.status),
          chips: [
            HeroTagChip(label: _paymentLabel(context, booking.paymentStatus)),
            HeroTagChip(
              label: context.tr(
                ar: '${booking.tracking.length} تحديثات',
                en: '${booking.tracking.length} updates',
              ),
              highlight: true,
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (booking.tracking.isEmpty)
          AppSectionCard(
            child: Text(
              context.tr(
                ar: 'لا توجد تحديثات تتبع بعد. سيظهر تقدم الحجز هنا بمجرد بدء التنفيذ.',
                en: 'No tracking updates yet. Progress will appear here once work begins.',
              ),
              style: const TextStyle(
                color: AppColors.textMuted,
                height: 1.6,
                fontWeight: FontWeight.w600,
              ),
            ),
          )
        else
          ...booking.tracking.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            final isLast = index == booking.tracking.length - 1;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: AppSectionCard(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      children: [
                        Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            color: index == 0
                                ? AppColors.success
                                : AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                        if (!isLast)
                          Container(
                            width: 2,
                            height: 56,
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
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            item.details,
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              height: 1.6,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (item.etaMinutes != null) ...[
                            const SizedBox(height: 8),
                            AppStatusBadge(
                              label: context.tr(
                                ar: 'الوصول خلال ${item.etaMinutes} دقيقة',
                                en: 'Arriving in ${item.etaMinutes} min',
                              ),
                              foreground: AppColors.primary,
                              background: AppColors.primarySoft,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }

  Widget _buildChatTab(ServiceBooking booking) {
    return Column(
      children: [
        DashboardHero(
          title: context.tr(ar: 'المحادثة', en: 'Conversation'),
          subtitle: booking.technician.name,
          chips: [
            HeroTagChip(
              label: context.tr(
                ar: '${booking.messages.length} رسائل',
                en: '${booking.messages.length} messages',
              ),
              highlight: true,
            ),
          ],
        ),
        const SizedBox(height: 16),
        AppSectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionHeading(
                title: context.tr(
                  ar: 'تحديثات التواصل',
                  en: 'Conversation updates',
                ),
                subtitle: context.tr(
                  ar: 'تابع الرسائل مع الفني من نفس شاشة الحجز.',
                  en: 'Track your messages with the technician from the same screen.',
                ),
              ),
              const SizedBox(height: 14),
              if (booking.messages.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundTertiary,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text(
                    context.tr(
                      ar: 'لا توجد رسائل حتى الآن. يمكنك بدء المحادثة هنا عند الحاجة.',
                      en: 'No messages yet. You can start the conversation here when needed.',
                    ),
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w600,
                      height: 1.6,
                    ),
                  ),
                )
              else
                ...booking.messages.map(
                  (message) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Align(
                      alignment: message.senderType == 'customer'
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 290),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          gradient: message.senderType == 'customer'
                              ? const LinearGradient(
                                  colors: [
                                    AppColors.primaryDark,
                                    AppColors.primary,
                                  ],
                                )
                              : const LinearGradient(
                                  colors: [
                                    AppColors.cardWhite,
                                    AppColors.backgroundTertiary,
                                  ],
                                ),
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                            color: message.senderType == 'customer'
                                ? Colors.white.withValues(alpha: 0.06)
                                : AppColors.border,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              message.senderName,
                              style: TextStyle(
                                color: message.senderType == 'customer'
                                    ? Colors.white
                                    : AppColors.textDark,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              message.message,
                              style: TextStyle(
                                color: message.senderType == 'customer'
                                    ? Colors.white
                                    : AppColors.textDark,
                                height: 1.55,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.backgroundTertiary,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: AppTextField(
                        controller: _messageController,
                        textDirection: context.appTextDirection,
                        decoration: InputDecoration(
                          hintText: context.tr(
                            ar: 'اكتب رسالة...',
                            en: 'Write a message...',
                          ),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          filled: false,
                        ),
                      ),
                    ),
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.primaryDark, AppColors.primary],
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: IconButton(
                        onPressed: _isSendingMessage ? null : _sendMessage,
                        icon: const Icon(
                          Icons.send_rounded,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReviewTab(ServiceBooking booking) {
    if (booking.review != null) {
      return AppSectionCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeading(
              title: context.tr(ar: 'تقييمك المسجل', en: 'Your review'),
              subtitle: context.tr(
                ar: 'تم حفظ التقييم ضمن سجل الحجز الحالي.',
                en: 'Your review has been saved for this booking.',
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: List.generate(
                5,
                (index) => Icon(
                  Icons.star_rounded,
                  color: index < booking.review!.rating
                      ? AppColors.accent
                      : AppColors.border,
                  size: 22,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              booking.review!.comment,
              style: const TextStyle(height: 1.65, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      );
    }

    if (booking.status != 'completed') {
      return AppBanner(
        title: context.tr(
          ar: 'التقييم متاح بعد اكتمال الخدمة',
          en: 'Review is available after completion',
        ),
        message: context.tr(
          ar: 'بمجرد انتهاء الزيارة بنجاح ستتمكن من إضافة تقييمك هنا مباشرة.',
          en: 'Once the visit is completed successfully, you can leave your review here.',
        ),
        icon: Icons.rate_review_rounded,
        background: AppColors.accentSoft,
        foreground: AppColors.accentDark,
      );
    }

    return AppSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeading(
            title: context.tr(ar: 'أضف تقييمك', en: 'Leave your review'),
            subtitle: context.tr(
              ar: 'رأيك يساعد العملاء الآخرين ويقوي الثقة داخل المنصة.',
              en: 'Your feedback helps other customers and strengthens trust.',
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(5, (index) {
              final value = index + 1;
              final selected = _selectedRating == value;
              return GestureDetector(
                onTap: () => setState(() => _selectedRating = value),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    gradient: selected
                        ? const LinearGradient(
                            colors: [AppColors.primaryDark, AppColors.primary],
                          )
                        : const LinearGradient(
                            colors: [
                              AppColors.cardWhite,
                              AppColors.backgroundTertiary,
                            ],
                          ),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: selected ? Colors.transparent : AppColors.border,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.star_rounded,
                        color: selected ? Colors.white : AppColors.accent,
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '$value',
                        style: TextStyle(
                          color: selected ? Colors.white : AppColors.textDark,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 14),
          AppTextField(
            controller: _reviewController,
            maxLines: 4,
            textDirection: context.appTextDirection,
            decoration: InputDecoration(
              labelText: context.tr(ar: 'تعليقك', en: 'Your comment'),
            ),
          ),
          const SizedBox(height: 14),
          ElevatedButton.icon(
            onPressed: _isSubmittingReview ? null : _submitReview,
            icon: const Icon(Icons.rate_review_rounded),
            label: Text(
              _isSubmittingReview
                  ? context.tr(
                      ar: 'جارٍ حفظ التقييم...',
                      en: 'Saving review...',
                    )
                  : context.tr(ar: 'حفظ التقييم', en: 'Save review'),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime? value) {
    if (value == null) return context.tr(ar: 'غير محدد', en: 'Not scheduled');
    final local = value.toLocal();
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '${local.year}-$month-$day • $hour:$minute';
  }

  String _statusLabel(BuildContext context, String status) {
    switch (status) {
      case 'pending':
        return context.tr(ar: 'قيد المراجعة', en: 'Pending');
      case 'confirmed':
        return context.tr(ar: 'مؤكد', en: 'Confirmed');
      case 'in_progress':
        return context.tr(ar: 'جارٍ التنفيذ', en: 'In progress');
      case 'arrived':
        return context.tr(ar: 'تم الوصول', en: 'Arrived');
      case 'completed':
        return context.tr(ar: 'مكتمل', en: 'Completed');
      case 'cancelled':
        return context.tr(ar: 'ملغي', en: 'Cancelled');
      default:
        return status;
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
        return AppColors.primary;
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

  String _paymentLabel(BuildContext context, String paymentStatus) {
    return paymentStatus == 'paid'
        ? context.tr(ar: 'مدفوع', en: 'Paid')
        : context.tr(ar: 'بانتظار الدفع', en: 'Payment pending');
  }

  Color _paymentForeground(String paymentStatus) {
    return paymentStatus == 'paid' ? AppColors.success : AppColors.accentDark;
  }

  Color _paymentBackground(String paymentStatus) {
    return paymentStatus == 'paid'
        ? AppColors.successSoft
        : AppColors.accentSoft;
  }

  bool _isLockedStatus(String status) {
    return status == 'completed' || status == 'cancelled';
  }
}

class _BookingTabs extends StatelessWidget {
  const _BookingTabs({
    required this.tabs,
    required this.currentIndex,
    required this.onChanged,
  });

  final List<String> tabs;
  final int currentIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return AppSectionCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: SizedBox(
        height: 46,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: tabs.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (context, index) {
            final selected = index == currentIndex;
            return GestureDetector(
              onTap: () => onChanged(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 18),
                decoration: BoxDecoration(
                  gradient: selected
                      ? const LinearGradient(
                          colors: [AppColors.primaryDark, AppColors.primary],
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
                alignment: Alignment.center,
                child: Text(
                  tabs[index],
                  style: TextStyle(
                    color: selected ? Colors.white : AppColors.textDark,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            );
          },
        ),
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
          child: Icon(icon, color: AppColors.primary, size: 20),
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
