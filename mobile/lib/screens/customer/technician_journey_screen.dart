import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../constants/app_theme.dart';
import '../../core/app_localizations.dart';
import '../../models/service_booking.dart';
import '../../models/technician_profile.dart';
import '../../providers/auth_controller.dart';
import '../../services/api_service.dart';
import '../../widgets/app_widgets.dart';

class TechnicianJourneyScreen extends ConsumerStatefulWidget {
  const TechnicianJourneyScreen({
    super.key,
    required this.profile,
    this.initialTab = 0,
  });

  final TechnicianProfile profile;
  final int initialTab;

  @override
  ConsumerState<TechnicianJourneyScreen> createState() =>
      _TechnicianJourneyScreenState();
}

class _TechnicianJourneyScreenState
    extends ConsumerState<TechnicianJourneyScreen> {
  late int _tabIndex;
  int _selectedDay = 1;
  int _selectedSlot = 1;
  int _selectedRating = 5;
  bool _isSubmittingBooking = false;
  bool _isSubmittingPayment = false;
  bool _isSendingMessage = false;
  bool _isSubmittingReview = false;
  ServiceBooking? _booking;

  final _problemController = TextEditingController();
  final _addressController = TextEditingController(
    text: 'القاهرة - عنوان العميل',
  );
  final _messageController = TextEditingController();
  final _reviewController = TextEditingController();

  static const _tabs = [
    'بروفايل الفني',
    'الحجز',
    'التتبع',
    'الشات',
    'الإشعارات',
  ];
  static const _days = [
    ('الأحد', 1),
    ('الاثنين', 2),
    ('الثلاثاء', 3),
    ('الأربعاء', 4),
    ('الخميس', 5),
  ];
  static const _slots = ['09:00', '10:00', '11:00', '14:00', '16:00', '18:00'];

  @override
  void initState() {
    super.initState();
    _tabIndex = widget.initialTab;
    _hydrateExistingBooking();
  }

  @override
  void dispose() {
    _problemController.dispose();
    _addressController.dispose();
    _messageController.dispose();
    _reviewController.dispose();
    super.dispose();
  }

  Future<void> _createBooking() async {
    final auth = ref.read(authControllerProvider);
    final token = auth.token;
    if (token == null || token.isEmpty) {
      _showSnack('يجب تسجيل الدخول أولًا.');
      return;
    }
    if (_problemController.text.trim().length < 10) {
      _showSnack('اكتب وصفًا أوضح للمشكلة قبل الحجز.');
      return;
    }
    if (_addressController.text.trim().length < 5) {
      _showSnack('أدخل عنوانًا صالحًا للزيارة.');
      return;
    }

    setState(() => _isSubmittingBooking = true);
    try {
      final dayOffset = _days[_selectedDay].$2;
      final slotParts = _slots[_selectedSlot].split(':');
      final now = DateTime.now();
      final scheduledFor = DateTime(
        now.year,
        now.month,
        now.day + dayOffset,
        int.parse(slotParts[0]),
        int.parse(slotParts[1]),
      );
      final created = await ref
          .read(apiServiceProvider)
          .createBooking(
            token: token,
            technicianId: widget.profile.id,
            scheduledFor: scheduledFor,
            address: _addressController.text.trim(),
            problemDescription: _problemController.text.trim(),
          );
      setState(() {
        _booking = created;
        _tabIndex = 2;
      });
      _showSnack('تم إنشاء الحجز بنجاح.');
    } catch (error) {
      _showSnack(error.toString());
    } finally {
      if (mounted) {
        setState(() => _isSubmittingBooking = false);
      }
    }
  }

  Future<void> _hydrateExistingBooking() async {
    final token = ref.read(authControllerProvider).token;
    if (token == null || token.isEmpty) return;
    try {
      final page = await ref
          .read(apiServiceProvider)
          .getMyBookings(token, pageSize: 20);
      final match = page.items.where(
        (item) => item.technician.id == widget.profile.id,
      );
      if (match.isEmpty || !mounted) return;
      setState(() => _booking = match.first);
    } catch (_) {
      // Ignore background hydration failures and keep the profile usable.
    }
  }

  Future<void> _refreshBooking() async {
    final token = ref.read(authControllerProvider).token;
    if (token == null || token.isEmpty || _booking == null) return;
    final booking = await ref
        .read(apiServiceProvider)
        .getBookingDetails(token: token, bookingId: _booking!.id);
    if (mounted) {
      setState(() => _booking = booking);
    }
  }

  Future<void> _payForBooking() async {
    final token = ref.read(authControllerProvider).token;
    if (token == null || token.isEmpty || _booking == null) return;
    setState(() => _isSubmittingPayment = true);
    try {
      await ref
          .read(apiServiceProvider)
          .payForBooking(token: token, bookingId: _booking!.id, method: 'card');
      await _refreshBooking();
      _showSnack('تم تسجيل الدفع بنجاح.');
    } catch (error) {
      _showSnack(error.toString());
    } finally {
      if (mounted) {
        setState(() => _isSubmittingPayment = false);
      }
    }
  }

  Future<void> _sendMessage() async {
    final token = ref.read(authControllerProvider).token;
    if (token == null || token.isEmpty || _booking == null) return;
    final message = _messageController.text.trim();
    if (message.isEmpty) return;
    setState(() => _isSendingMessage = true);
    try {
      await ref
          .read(apiServiceProvider)
          .sendBookingMessage(
            token: token,
            bookingId: _booking!.id,
            message: message,
          );
      _messageController.clear();
      await _refreshBooking();
    } catch (error) {
      _showSnack(error.toString());
    } finally {
      if (mounted) {
        setState(() => _isSendingMessage = false);
      }
    }
  }

  Future<void> _submitReview() async {
    final token = ref.read(authControllerProvider).token;
    if (token == null || token.isEmpty || _booking == null) return;
    setState(() => _isSubmittingReview = true);
    try {
      final updated = await ref
          .read(apiServiceProvider)
          .submitBookingReview(
            token: token,
            bookingId: _booking!.id,
            rating: _selectedRating,
            comment: _reviewController.text.trim(),
          );
      setState(() => _booking = updated);
      _showSnack('تم حفظ تقييمك.');
    } catch (error) {
      _showSnack(error.toString());
    } finally {
      if (mounted) {
        setState(() => _isSubmittingReview = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return HomixPage(
      title: _tabs[_tabIndex],
      header: AppBanner(
        title: context.tr(
          ar: 'رحلة الحجز مع الفني أصبحت أوضح',
          en: 'The technician journey is now clearer',
        ),
        message: context.tr(
          ar: 'راجع البروفايل، احجز، تابع، وراسل الفني من واجهة أقوى وأكثر ترتيبًا.',
          en: 'Review the profile, book, track, and chat from a stronger, more organized flow.',
        ),
        icon: Icons.handyman_rounded,
        background: AppColors.secondarySoft,
        foreground: AppColors.secondary,
      ),
      child: Column(
        children: [
          AppSectionCard(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: SizedBox(
              height: 46,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _tabs.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final selected = _tabIndex == index;
                  return GestureDetector(
                    onTap: () => setState(() => _tabIndex = index),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      decoration: BoxDecoration(
                        gradient: selected
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
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: selected
                              ? Colors.transparent
                              : AppColors.border,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        _tabs[index],
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
          ),
          const SizedBox(height: 14),
          Expanded(
            child: SingleChildScrollView(
              child: switch (_tabIndex) {
                0 => _buildProfileTab(),
                1 => _buildBookingTab(),
                2 => _buildTrackingTab(),
                3 => _buildChatTab(),
                _ => _buildNotificationsTab(),
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileTab() {
    final profile = widget.profile;
    return Column(
      children: [
        _JourneyHero(
          title: profile.name,
          subtitle: '${profile.title} - ${profile.city}',
        ),
        const SizedBox(height: 12),
        AppSectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: profile.accent,
                    child: Icon(profile.icon, color: AppColors.primaryDark),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          profile.name,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          profile.title,
                          style: const TextStyle(color: AppColors.textMuted),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(
                              Icons.star_rounded,
                              color: AppColors.accent,
                            ),
                            const SizedBox(width: 4),
                            Text('${profile.rating} (${profile.reviewsCount})'),
                            const SizedBox(width: 8),
                            AppStatusBadge(
                              label: profile.isAvailable
                                  ? 'متاح الآن'
                                  : 'مشغول',
                              foreground: profile.isAvailable
                                  ? AppColors.success
                                  : AppColors.accentDark,
                              background: profile.isAvailable
                                  ? AppColors.successSoft
                                  : AppColors.accentSoft,
                            ),
                            const SizedBox(width: 8),
                            AppStatusBadge(
                              label: profile.subscription.planName,
                              foreground: profile.subscription.isPro
                                  ? AppColors.success
                                  : AppColors.primary,
                              background: profile.subscription.isPro
                                  ? AppColors.successSoft
                                  : AppColors.primarySoft,
                            ),
                          ],
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
                      label: 'مهام',
                      value: '${profile.jobsDone}',
                      background: AppColors.primarySoft,
                      valueColor: AppColors.primaryDark,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: MetricPill(
                      label: 'استجابة',
                      value: '${profile.responseMinutes} د',
                      background: AppColors.accentSoft,
                      valueColor: const Color(0xFF8A5A00),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: MetricPill(
                      label: 'الساعة',
                      value: '${profile.hourlyRate} ج',
                      background: const Color(0xFFDDE7C9),
                      valueColor: const Color(0xFF446222),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                profile.bio,
                style: const TextStyle(color: AppColors.textMuted, height: 1.6),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: profile.skills
                    .map((skill) => _TagPill(label: skill))
                    .toList(),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: profile.serviceAreas
                    .map((area) => _TagPill(label: area, soft: true))
                    .toList(),
              ),
              const SizedBox(height: 14),
              AppSectionCard(
                color: profile.subscription.isPro
                    ? AppColors.successSoft
                    : AppColors.primarySoft,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'خطة الاشتراك: ${profile.subscription.planName}',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'العمولة ${profile.subscription.commissionRate.toStringAsFixed(0)}% • ${profile.subscription.verifiedBadge ? 'موثق' : 'بدون badge'}',
                      style: const TextStyle(color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => setState(() => _tabIndex = 1),
                  child: const Text('احجز الآن'),
                ),
              ),
            ],
          ),
        ),
        if (profile.recentReviews.isNotEmpty) ...[
          const SizedBox(height: 12),
          const Align(
            alignment: Alignment.centerRight,
            child: Text(
              'أحدث التقييمات',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(height: 10),
          ...profile.recentReviews.map(
            (review) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: AppSectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            review.customerName,
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                        Text('${review.rating}/5'),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      review.comment,
                      style: const TextStyle(color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildBookingTab() {
    final profile = widget.profile;
    return Column(
      children: [
        _JourneyHero(
          title: 'احجز موعدًا',
          subtitle: '${profile.name} - ${profile.hourlyRate} ج/ساعة',
        ),
        const SizedBox(height: 12),
        const Align(
          alignment: Alignment.centerRight,
          child: Text(
            'اختر اليوم',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 80,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _days.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final selected = _selectedDay == index;
              return GestureDetector(
                onTap: () => setState(() => _selectedDay = index),
                child: Container(
                  width: 88,
                  decoration: BoxDecoration(
                    color: selected ? AppColors.primary : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: selected ? AppColors.primary : AppColors.border,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      _days[index].$1,
                      style: TextStyle(
                        color: selected ? Colors.white : AppColors.textDark,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 14),
        const Align(
          alignment: Alignment.centerRight,
          child: Text(
            'اختر الوقت',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
        ),
        const SizedBox(height: 10),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _slots.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.2,
          ),
          itemBuilder: (context, index) {
            final selected = _selectedSlot == index;
            return GestureDetector(
              onTap: () => setState(() => _selectedSlot = index),
              child: Container(
                decoration: BoxDecoration(
                  color: selected ? AppColors.primary : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: selected ? AppColors.primary : AppColors.border,
                  ),
                ),
                child: Center(
                  child: Text(
                    _slots[index],
                    style: TextStyle(
                      color: selected ? Colors.white : AppColors.textDark,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 14),
        AppTextField(
          controller: _addressController,
          textDirection: TextDirection.rtl,
          decoration: const InputDecoration(labelText: 'العنوان'),
        ),
        const SizedBox(height: 12),
        AppTextField(
          controller: _problemController,
          maxLines: 4,
          textDirection: TextDirection.rtl,
          decoration: const InputDecoration(labelText: 'وصف المشكلة'),
        ),
        const SizedBox(height: 14),
        AppSectionCard(
          color: AppColors.primarySoft,
          child: Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'التكلفة التقديرية',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'يتم تحديثها بعد تأكيد الفني',
                      style: TextStyle(color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
              Text(
                '${profile.hourlyRate} ج',
                style: const TextStyle(
                  color: AppColors.primaryDark,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isSubmittingBooking ? null : _createBooking,
            child: Text(
              _isSubmittingBooking ? 'جارٍ إنشاء الحجز...' : 'تأكيد الحجز',
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTrackingTab() {
    final booking = _booking;
    if (booking == null) {
      return const AsyncPlaceholder(
        message: 'أنشئ حجزًا أولًا حتى يظهر التتبع المباشر للحالة.',
      );
    }
    return Column(
      children: [
        _JourneyHero(
          title: 'تتبع الحجز',
          subtitle: '${booking.technician.name} • ${booking.status}',
        ),
        const SizedBox(height: 12),
        AppSectionCard(
          color: AppColors.primarySoft,
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'الموعد',
                      style: TextStyle(color: AppColors.textMuted),
                    ),
                    Text(
                      booking.scheduledFor == null
                          ? 'غير محدد'
                          : booking.scheduledFor!
                                .toLocal()
                                .toString()
                                .substring(0, 16),
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 6),
                    Text('الدفع: ${booking.paymentStatus}'),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed:
                    _isSubmittingPayment || booking.paymentStatus == 'paid'
                    ? null
                    : _payForBooking,
                child: Text(
                  booking.paymentStatus == 'paid'
                      ? 'تم الدفع'
                      : (_isSubmittingPayment ? 'جارٍ الدفع...' : 'ادفع الآن'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        ...booking.tracking.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: AppSectionCard(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    margin: const EdgeInsets.only(top: 6),
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.label,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.details,
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            height: 1.5,
                          ),
                        ),
                        if (item.etaMinutes != null) ...[
                          const SizedBox(height: 4),
                          Text('ETA: ${item.etaMinutes} دقيقة'),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (booking.status == 'completed' && booking.review == null) ...[
          const SizedBox(height: 12),
          _buildReviewComposer(),
        ] else if (booking.review != null) ...[
          const SizedBox(height: 12),
          AppSectionCard(
            color: AppColors.successSoft,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'تقييمك المسجل',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                Text('${booking.review!.rating}/5'),
                const SizedBox(height: 6),
                Text(
                  booking.review!.comment,
                  style: const TextStyle(color: AppColors.textMuted),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildReviewComposer() {
    return AppSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'أضف تقييمك',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            children: List.generate(
              5,
              (index) => ChoiceChip(
                label: Text('${index + 1}'),
                selected: _selectedRating == index + 1,
                onSelected: (_) => setState(() => _selectedRating = index + 1),
              ),
            ),
          ),
          const SizedBox(height: 10),
          AppTextField(
            controller: _reviewController,
            maxLines: 3,
            textDirection: TextDirection.rtl,
            decoration: const InputDecoration(labelText: 'تعليقك'),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSubmittingReview ? null : _submitReview,
              child: Text(
                _isSubmittingReview ? 'جارٍ حفظ التقييم...' : 'إرسال التقييم',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatTab() {
    final booking = _booking;
    if (booking == null) {
      return const AsyncPlaceholder(
        message: 'بعد إنشاء الحجز ستظهر لك المحادثة مع الفني هنا.',
      );
    }
    return Column(
      children: [
        _JourneyHero(title: 'المحادثة', subtitle: booking.technician.name),
        const SizedBox(height: 12),
        ...booking.messages.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Align(
              alignment: item.isIncoming
                  ? Alignment.centerLeft
                  : Alignment.centerRight,
              child: Container(
                constraints: const BoxConstraints(maxWidth: 280),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: item.isIncoming ? Colors.white : AppColors.primary,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: item.isIncoming
                        ? AppColors.border
                        : AppColors.primary,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.senderName,
                      style: TextStyle(
                        color: item.isIncoming
                            ? AppColors.textDark
                            : Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.message,
                      style: TextStyle(
                        color: item.isIncoming
                            ? AppColors.textDark
                            : Colors.white,
                        height: 1.5,
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
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Expanded(
                child: AppTextField(
                  controller: _messageController,
                  textDirection: TextDirection.rtl,
                  decoration: const InputDecoration(
                    hintText: 'اكتب رسالة...',
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    filled: false,
                  ),
                ),
              ),
              CircleAvatar(
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

  Widget _buildNotificationsTab() {
    final token = ref.watch(authControllerProvider).token;
    if (token == null || token.isEmpty) {
      return const AsyncPlaceholder(message: 'سجل الدخول لعرض الإشعارات.');
    }

    return FutureBuilder<List<AppNotificationItem>>(
      future: ref.read(apiServiceProvider).getMyNotifications(token),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return AsyncPlaceholder(message: snapshot.error.toString());
        }
        final items = snapshot.data ?? const [];
        if (items.isEmpty) {
          return const AsyncPlaceholder(message: 'لا توجد إشعارات حتى الآن.');
        }
        return Column(
          children: [
            _JourneyHero(
              title: 'الإشعارات',
              subtitle: '${items.length} تحديثات حديثة',
            ),
            const SizedBox(height: 12),
            ...items.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: AppSectionCard(
                  color: item.isRead ? Colors.white : AppColors.primarySoft,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        item.body,
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        item.category,
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _JourneyHero extends StatelessWidget {
  const _JourneyHero({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return DashboardHero(
      title: title,
      subtitle: subtitle,
      chips: [
        HeroTagChip(
          label: context.tr(ar: 'رحلة منظمة', en: 'Organized journey'),
        ),
        HeroTagChip(
          label: context.tr(ar: 'ثقة أوضح', en: 'Clearer trust'),
          highlight: true,
        ),
      ],
    );
  }
}

class _TagPill extends StatelessWidget {
  const _TagPill({required this.label, this.soft = false});

  final String label;
  final bool soft;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: soft ? AppColors.accentSoft : AppColors.primarySoft,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: soft ? const Color(0xFF8A5A00) : AppColors.primaryDark,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
