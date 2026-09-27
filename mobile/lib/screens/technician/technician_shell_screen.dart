import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../constants/app_theme.dart';
import '../../core/app_localizations.dart';
import '../../core/app_router.dart';
import '../../models/service_booking.dart';
import '../../models/technician_dashboard_models.dart';
import '../../models/technician_profile.dart';
import '../../providers/auth_controller.dart';
import '../../services/api_service.dart';
import '../../widgets/app_widgets.dart';

class TechnicianShellScreen extends ConsumerStatefulWidget {
  const TechnicianShellScreen({super.key, required this.profile});

  final TechnicianProfile profile;

  @override
  ConsumerState<TechnicianShellScreen> createState() =>
      _TechnicianShellScreenState();
}

class _TechnicianShellScreenState extends ConsumerState<TechnicianShellScreen> {
  int _tabIndex = 0;
  int _unreadNotifications = 0;
  bool _isLoadingBookings = false;
  bool _isLoadingEarnings = false;
  bool _isLoadingPayouts = false;
  bool _isSavingProfile = false;
  bool _isTogglingAvailability = false;
  bool _isSubmittingPayout = false;
  String _bookingsStatus = '';
  int _bookingsPage = 1;
  int _payoutsPage = 1;
  PaginatedServiceBookings? _bookings;
  TechnicianEarningsSummary? _earnings;
  PaginatedTechnicianPayouts? _payouts;
  late TechnicianProfile _profile;

  late final TextEditingController _nameController;
  late final TextEditingController _titleController;
  late final TextEditingController _cityController;
  late final TextEditingController _hourlyController;
  late final TextEditingController _bioController;
  late final TextEditingController _serviceAreasController;
  late final TextEditingController _skillsController;

  String? get _token => ref.read(authControllerProvider).token;
  ApiService get _api => ref.read(apiServiceProvider);

  List<String> _tabs(BuildContext context) => [
    context.tr(ar: 'الرئيسية', en: 'Home'),
    context.tr(ar: 'الحجوزات', en: 'Bookings'),
    context.tr(ar: 'الأرباح', en: 'Earnings'),
    context.tr(ar: 'التقييمات', en: 'Reviews'),
    context.tr(ar: 'الملف', en: 'Profile'),
  ];

  List<(String, String)> _statusFilters(BuildContext context) => [
    ('', context.tr(ar: 'الكل', en: 'All')),
    ('pending', context.tr(ar: 'قيد المراجعة', en: 'Pending')),
    ('confirmed', context.tr(ar: 'مؤكد', en: 'Confirmed')),
    ('in_progress', context.tr(ar: 'جارٍ التنفيذ', en: 'In progress')),
    ('completed', context.tr(ar: 'مكتمل', en: 'Completed')),
    ('cancelled', context.tr(ar: 'ملغي', en: 'Cancelled')),
  ];

  @override
  void initState() {
    super.initState();
    _profile = widget.profile;
    _nameController = TextEditingController(text: _profile.name);
    _titleController = TextEditingController(text: _profile.title);
    _cityController = TextEditingController(text: _profile.city);
    _hourlyController = TextEditingController(
      text: _profile.hourlyRate.toString(),
    );
    _bioController = TextEditingController(text: _profile.bio);
    _serviceAreasController = TextEditingController(
      text: _profile.serviceAreas.join(', '),
    );
    _skillsController = TextEditingController(text: _profile.skills.join(', '));
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadDashboard());
  }

  @override
  void dispose() {
    _nameController.dispose();
    _titleController.dispose();
    _cityController.dispose();
    _hourlyController.dispose();
    _bioController.dispose();
    _serviceAreasController.dispose();
    _skillsController.dispose();
    super.dispose();
  }

  Future<void> _loadDashboard() async {
    await Future.wait([
      _refreshProfile(),
      _loadBookings(reset: true),
      _loadEarnings(),
      _loadPayouts(reset: true),
      _loadUnreadNotifications(),
    ]);
  }

  Future<void> _loadUnreadNotifications() async {
    final token = _token;
    if (token == null || token.isEmpty) return;
    final unreadCount = await _api.getUnreadNotificationsCount(token);
    if (!mounted) return;
    setState(() {
      _unreadNotifications = unreadCount;
    });
  }

  Future<void> _refreshProfile() async {
    final token = _token;
    if (token == null || token.isEmpty) return;
    final profile = await _api.getMyTechnicianProfile(token);
    if (!mounted) return;
    setState(() {
      _profile = profile;
      _nameController.text = profile.name;
      _titleController.text = profile.title;
      _cityController.text = profile.city;
      _hourlyController.text = profile.hourlyRate.toString();
      _bioController.text = profile.bio;
      _serviceAreasController.text = profile.serviceAreas.join(', ');
      _skillsController.text = profile.skills.join(', ');
    });
  }

  Future<void> _loadBookings({required bool reset}) async {
    final token = _token;
    if (token == null || token.isEmpty) return;
    setState(() {
      _isLoadingBookings = true;
      if (reset) {
        _bookingsPage = 1;
      }
    });
    try {
      final response = await _api.getMyTechnicianBookings(
        token,
        status: _bookingsStatus,
        page: _bookingsPage,
        pageSize: 6,
      );
      if (!mounted) return;
      setState(() {
        if (reset || _bookings == null) {
          _bookings = response;
        } else {
          _bookings = PaginatedServiceBookings(
            items: [..._bookings!.items, ...response.items],
            total: response.total,
            page: response.page,
            pageSize: response.pageSize,
            hasMore: response.hasMore,
          );
        }
      });
    } finally {
      if (mounted) {
        setState(() => _isLoadingBookings = false);
      }
    }
  }

  Future<void> _loadEarnings() async {
    final token = _token;
    if (token == null || token.isEmpty) return;
    setState(() => _isLoadingEarnings = true);
    try {
      final response = await _api.getMyTechnicianEarnings(token);
      if (!mounted) return;
      setState(() => _earnings = response);
    } finally {
      if (mounted) {
        setState(() => _isLoadingEarnings = false);
      }
    }
  }

  Future<void> _loadPayouts({required bool reset}) async {
    final token = _token;
    if (token == null || token.isEmpty) return;
    setState(() {
      _isLoadingPayouts = true;
      if (reset) {
        _payoutsPage = 1;
      }
    });
    try {
      final response = await _api.getMyTechnicianPayouts(
        token,
        page: _payoutsPage,
        pageSize: 5,
      );
      if (!mounted) return;
      setState(() {
        if (reset || _payouts == null) {
          _payouts = response;
        } else {
          _payouts = PaginatedTechnicianPayouts(
            items: [..._payouts!.items, ...response.items],
            total: response.total,
            page: response.page,
            pageSize: response.pageSize,
            hasMore: response.hasMore,
          );
        }
      });
    } finally {
      if (mounted) {
        setState(() => _isLoadingPayouts = false);
      }
    }
  }

  Future<void> _changeAvailability(bool value) async {
    final token = _token;
    if (token == null || token.isEmpty) return;
    final previous = _profile.isAvailable;
    setState(() {
      _isTogglingAvailability = true;
      _profile = _copyProfile(_profile, isAvailable: value);
    });
    try {
      await _api.updateMyTechnicianAvailability(
        token: token,
        isAvailable: value,
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _profile = _copyProfile(_profile, isAvailable: previous));
      _showSnack(error.toString());
    } finally {
      if (mounted) {
        setState(() => _isTogglingAvailability = false);
      }
    }
  }

  Future<void> _updateBookingStatus(
    ServiceBooking booking,
    String action,
  ) async {
    final token = _token;
    if (token == null || token.isEmpty) return;
    try {
      await _api.updateTechnicianBookingStatus(
        token: token,
        bookingId: booking.id,
        action: action,
      );
      await Future.wait([
        _loadBookings(reset: true),
        _loadEarnings(),
        _refreshProfile(),
      ]);
      if (!mounted) return;
      _showSnack('تم تحديث حالة الحجز.');
    } catch (error) {
      _showSnack(error.toString());
    }
  }

  Future<void> _requestPayout() async {
    final token = _token;
    final earnings = _earnings;
    if (token == null || token.isEmpty || earnings == null) return;

    final draft = await showDialog<_PayoutDraft>(
      context: context,
      builder: (context) {
        final amountController = TextEditingController(
          text: earnings.availableBalance > 0
              ? earnings.availableBalance.toStringAsFixed(0)
              : '',
        );
        final destinationController = TextEditingController();
        final notesController = TextEditingController();
        return AlertDialog(
          title: const Text('طلب سحب'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'الرصيد المتاح ${earnings.availableBalance.toStringAsFixed(0)} ${earnings.currency}',
              ),
              const SizedBox(height: 12),
              AppTextField(
                key: const Key('technician-payout-amount-field'),
                controller: amountController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                textDirection: TextDirection.ltr,
                decoration: const InputDecoration(labelText: 'المبلغ'),
              ),
              const SizedBox(height: 12),
              AppTextField(
                key: const Key('technician-payout-destination-field'),
                controller: destinationController,
                textDirection: TextDirection.rtl,
                decoration: const InputDecoration(
                  labelText: 'وسيلة الاستلام',
                  hintText: 'فودافون كاش أو رقم الحساب',
                ),
              ),
              const SizedBox(height: 12),
              AppTextField(
                controller: notesController,
                maxLines: 2,
                textDirection: TextDirection.rtl,
                decoration: const InputDecoration(labelText: 'ملاحظات'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(
                  _PayoutDraft(
                    amountText: amountController.text.trim(),
                    destinationLabel: destinationController.text.trim(),
                    notes: notesController.text.trim(),
                  ),
                );
              },
              child: const Text('إرسال الطلب'),
            ),
          ],
        );
      },
    );
    if (draft == null) return;

    final amount = double.tryParse(draft.amountText);
    if (amount == null || amount <= 0) {
      _showSnack('اكتب مبلغ سحب صحيح.');
      return;
    }
    if (amount > earnings.availableBalance) {
      _showSnack('المبلغ المطلوب أكبر من الرصيد المتاح.');
      return;
    }

    setState(() => _isSubmittingPayout = true);
    try {
      await _api.requestTechnicianPayout(
        token: token,
        amount: amount,
        destinationLabel: draft.destinationLabel,
        notes: draft.notes,
      );
      await Future.wait([_loadEarnings(), _loadPayouts(reset: true)]);
      if (!mounted) return;
      _showSnack('تم إرسال طلب السحب.');
    } catch (error) {
      _showSnack(error.toString());
    } finally {
      if (mounted) {
        setState(() => _isSubmittingPayout = false);
      }
    }
  }

  Future<void> _saveProfile() async {
    final token = _token;
    if (token == null || token.isEmpty) return;
    final hourlyRate = double.tryParse(_hourlyController.text.trim());
    if (hourlyRate == null) {
      _showSnack('أدخل سعر ساعة صحيح.');
      return;
    }
    setState(() => _isSavingProfile = true);
    try {
      final updated = await _api.updateMyTechnicianProfile(
        token: token,
        name: _nameController.text.trim(),
        title: _titleController.text.trim(),
        city: _cityController.text.trim(),
        hourlyRate: hourlyRate,
        bio: _bioController.text.trim(),
        serviceAreas: _splitInput(_serviceAreasController.text),
        skills: _splitInput(_skillsController.text),
      );
      if (!mounted) return;
      setState(() => _profile = updated);
      _showSnack('تم حفظ التعديلات.');
    } catch (error) {
      _showSnack(error.toString());
    } finally {
      if (mounted) {
        setState(() => _isSavingProfile = false);
      }
    }
  }

  Future<void> _logout() async {
    await ref.read(authControllerProvider).logout();
    if (!mounted) return;
    context.go(AppRoutes.login);
  }

  List<String> _splitInput(String value) {
    return value
        .split(',')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }

  TechnicianProfile _copyProfile(
    TechnicianProfile profile, {
    bool? isAvailable,
  }) {
    return TechnicianProfile(
      id: profile.id,
      name: profile.name,
      title: profile.title,
      category: profile.category,
      city: profile.city,
      rating: profile.rating,
      reviewsCount: profile.reviewsCount,
      jobsDone: profile.jobsDone,
      yearsExperience: profile.yearsExperience,
      responseMinutes: profile.responseMinutes,
      hourlyRate: profile.hourlyRate,
      bio: profile.bio,
      serviceAreas: profile.serviceAreas,
      skills: profile.skills,
      accent: profile.accent,
      icon: profile.icon,
      isAvailable: isAvailable ?? profile.isAvailable,
      recentReviews: profile.recentReviews,
      subscription: profile.subscription,
    );
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final tabs = _tabs(context);
    return HomixPage(
      title: context.tr(ar: 'لوحة الفني', en: 'Technician dashboard'),
      header: AppBanner(
        title: context.tr(
          ar: 'واجهة فني أوضح وأكثر احترافية',
          en: 'A cleaner, more premium technician dashboard',
        ),
        message: context.tr(
          ar: 'الحجوزات، الأرباح، والتقييمات صارت مرتبة داخل shell بصري أقوى وأسهل في العرض على العميل.',
          en: 'Bookings, earnings, and reviews are now presented inside a stronger visual shell.',
        ),
        icon: Icons.engineering_rounded,
        background: AppColors.secondarySoft,
        foreground: AppColors.secondary,
      ),
      actions: [
        IconButton(
          onPressed: () async {
            await context.push(AppRoutes.technicianNotifications);
            if (mounted) {
              await _loadUnreadNotifications();
            }
          },
          icon: Stack(
            clipBehavior: Clip.none,
            children: [
              const Icon(Icons.notifications_rounded),
              if (_unreadNotifications > 0)
                Positioned(
                  top: -4,
                  right: -6,
                  child: Container(
                    key: const Key('technician-notifications-badge'),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: const BoxDecoration(
                      color: AppColors.error,
                      shape: BoxShape.rectangle,
                      borderRadius: BorderRadius.all(Radius.circular(999)),
                    ),
                    child: Text(
                      '$_unreadNotifications',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
      bottomNavigationBar: _TechnicianBottomBar(
        currentIndex: _tabIndex > 3 ? 3 : _tabIndex,
        onChanged: (value) {
          setState(() {
            _tabIndex = switch (value) {
              0 => 0,
              1 => 1,
              2 => 2,
              _ => 4,
            };
          });
        },
      ),
      child: Column(
        children: [
          AppSectionCard(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: SizedBox(
              height: 46,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: tabs.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final selected = index == _tabIndex;
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
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
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
                              ? Colors.white.withValues(alpha: 0.08)
                              : AppColors.border,
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
          ),
          const SizedBox(height: 14),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadDashboard,
              child: ListView(
                children: [
                  switch (_tabIndex) {
                    0 => _buildProfileTab(),
                    1 => _buildOrdersTab(),
                    2 => _buildEarningsTab(),
                    3 => _buildReviewsTab(),
                    _ => _buildEditTab(),
                  },
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileTab() {
    final p = _profile;
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primary, AppColors.primaryDark],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(28),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 34,
                    backgroundColor: Colors.white.withValues(alpha: 0.85),
                    child: Icon(p.icon, color: AppColors.primary, size: 28),
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      Text(
                        context.tr(
                          ar: p.isAvailable ? 'متاح' : 'مشغول',
                          en: p.isAvailable ? 'Available' : 'Busy',
                        ),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Switch(
                        value: p.isAvailable,
                        activeThumbColor: AppColors.success,
                        onChanged: _isTogglingAvailability
                            ? null
                            : _changeAvailability,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      '${p.title} - ${p.city}',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.82),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          color: AppColors.accent,
                          size: 20,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          context.tr(
                            ar: '${p.rating.toStringAsFixed(1)} (${p.reviewsCount} تقييم)',
                            en: '${p.rating.toStringAsFixed(1)} (${p.reviewsCount} reviews)',
                          ),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: p.skills
              .map(
                (skill) => Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    skill,
                    style: const TextStyle(
                      color: AppColors.primaryDark,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 14),
        AppSectionCard(
          color: p.subscription.isPro
              ? AppColors.successSoft
              : AppColors.primarySoft,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.tr(
                  ar: 'الباقة الحالية: ${p.subscription.planName}',
                  en: 'Current plan: ${p.subscription.planName}',
                ),
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'العمولة ${p.subscription.commissionRate.toStringAsFixed(0)}% • ${p.subscription.verifiedBadge ? 'badge موثق' : 'بدون badge'}',
                style: const TextStyle(color: AppColors.textMuted),
              ),
              if (p.subscription.expiresAt != null) ...[
                const SizedBox(height: 6),
                Text(
                  'ينتهي في ${_formatDateTime(p.subscription.expiresAt)}',
                  style: const TextStyle(color: AppColors.textMuted),
                ),
              ],
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton(
                  onPressed: () =>
                      context.push(AppRoutes.technicianSubscription),
                  child: Text(
                    context.tr(ar: 'إدارة الباقة', en: 'Manage plan'),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1.3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            MetricPill(
              label: context.tr(ar: 'مهام مكتملة', en: 'Completed jobs'),
              value: '${p.jobsDone}',
              background: AppColors.primarySoft,
              valueColor: AppColors.primaryDark,
            ),
            MetricPill(
              label: context.tr(ar: 'سنوات خبرة', en: 'Years of experience'),
              value: '${p.yearsExperience}',
              background: const Color(0xFFDCE5CF),
              valueColor: const Color(0xFF35511B),
            ),
            MetricPill(
              label: context.tr(ar: 'الحالة', en: 'Status'),
              value: context.tr(
                ar: p.isAvailable ? 'متاح' : 'مشغول',
                en: p.isAvailable ? 'Available' : 'Busy',
              ),
              background: AppColors.accentSoft,
              valueColor: const Color(0xFF8A5A00),
            ),
            MetricPill(
              label: context.tr(ar: 'زمن الاستجابة', en: 'Response time'),
              value: context.tr(
                ar: '${p.responseMinutes} د',
                en: '${p.responseMinutes} min',
              ),
              background: AppColors.errorSoft,
              valueColor: AppColors.error,
            ),
          ],
        ),
        const SizedBox(height: 14),
        AppSectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.tr(ar: 'نبذة عني', en: 'About me'),
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                p.bio,
                style: const TextStyle(color: AppColors.textMuted, height: 1.7),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        AppSectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'مناطق الخدمة',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: p.serviceAreas
                    .map(
                      (area) => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primarySoft,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          area,
                          style: const TextStyle(
                            color: AppColors.primaryDark,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOrdersTab() {
    final bookings = _bookings;
    final statusFilters = _statusFilters(context);
    return Column(
      children: [
        _TabHeaderCard(
          title: context.tr(ar: 'طلبات الخدمة', en: 'Service bookings'),
          subtitle: context.tr(
            ar: 'تابع الحالات، افتح التتبع، وتحرك بسرعة بين تفاصيل كل حجز.',
            en: 'Track statuses, open tracking, and move quickly across booking details.',
          ),
          icon: Icons.assignment_rounded,
        ),
        const SizedBox(height: 14),
        AppSectionCard(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionHeading(
                title: context.tr(ar: 'فلترة الحالات', en: 'Status filters'),
                subtitle: context.tr(
                  ar: 'بدّل بين حالات الحجز بسرعة للحصول على رؤية تشغيلية أوضح.',
                  en: 'Switch between booking states quickly for a clearer operating view.',
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: statusFilters
                    .map(
                      (filter) => _TechnicianStatusChip(
                        label: filter.$2,
                        selected: filter.$1 == _bookingsStatus,
                        onTap: () async {
                          setState(() {
                            _bookingsStatus = filter.$1;
                            _bookingsPage = 1;
                          });
                          await _loadBookings(reset: true);
                        },
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        if (_isLoadingBookings && bookings == null)
          const Padding(
            padding: EdgeInsets.all(12),
            child: AppLoadingCard(
              compact: true,
              message: 'نجهز الحجوزات الحالية ونرتبها لك الآن.',
            ),
          )
        else if (bookings == null || bookings.items.isEmpty)
          const AsyncPlaceholder(
            title: 'لا توجد حجوزات حالياً',
            message:
                'عند وصول أي طلب خدمة جديد أو تحديث على الحجوزات سيظهر هنا مباشرة.',
            icon: Icons.event_busy_rounded,
          )
        else ...[
          ...bookings.items.map(
            (booking) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _TechnicianBookingCard(
                booking: booking,
                onAction: (action) => _updateBookingStatus(booking, action),
                onViewDetails: () => context.push(
                  AppRoutes.technicianBookingDetailsPath(booking.id),
                ),
                onOpenTracking: () => context.push(
                  AppRoutes.technicianBookingDetailsPath(booking.id, tab: 1),
                ),
                onOpenChat: () => context.push(
                  AppRoutes.technicianBookingDetailsPath(booking.id, tab: 2),
                ),
              ),
            ),
          ),
          if (bookings.hasMore)
            OutlinedButton(
              onPressed: _isLoadingBookings
                  ? null
                  : () async {
                      setState(() => _bookingsPage += 1);
                      await _loadBookings(reset: false);
                    },
              child: Text(
                _isLoadingBookings ? 'جارٍ التحميل...' : 'عرض المزيد',
              ),
            ),
        ],
      ],
    );
  }

  Widget _buildEarningsTab() {
    final earnings = _earnings;
    final payouts = _payouts;
    if (_isLoadingEarnings && earnings == null) {
      return const Padding(
        padding: EdgeInsets.all(12),
        child: AppLoadingCard(
          message: 'نجهز ملخص الأرباح وأحدث المعاملات المالية.',
        ),
      );
    }
    if (earnings == null) {
      return const AsyncPlaceholder(
        title: 'تعذر تحميل الأرباح',
        message:
            'لم نتمكن من جلب البيانات المالية الآن. يمكنك المحاولة مرة أخرى بعد لحظات.',
        icon: Icons.query_stats_rounded,
      );
    }
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(28),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'الأرباح',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                earnings.currentMonthLabel,
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 16),
              Text(
                '${earnings.netEarnings.toStringAsFixed(0)} ${earnings.currency}',
                style: const TextStyle(
                  color: AppColors.accent,
                  fontSize: 42,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                'الإجمالي ${earnings.grossEarnings.toStringAsFixed(0)} - العمولة ${earnings.commissionAmount.toStringAsFixed(0)}',
                style: const TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: MetricPill(
                label: 'حجوزات مكتملة',
                value: '${earnings.completedBookings}',
                background: const Color(0xFFDCE5CF),
                valueColor: const Color(0xFF35511B),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: MetricPill(
                label: 'متوسط الطلب',
                value: '${earnings.averageTicket.toStringAsFixed(0)} ج',
                background: AppColors.accentSoft,
                valueColor: const Color(0xFF8A5A00),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: MetricPill(
                label: 'الرصيد المتاح',
                value:
                    '${earnings.availableBalance.toStringAsFixed(0)} ${earnings.currency}',
                background: const Color(0xFFDDEBFF),
                valueColor: const Color(0xFF20467A),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: MetricPill(
                label: 'سحب معلق',
                value:
                    '${earnings.pendingPayout.toStringAsFixed(0)} ${earnings.currency}',
                background: const Color(0xFFFFE7D0),
                valueColor: const Color(0xFF8A4C00),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        AppSectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'السحب والتحويلات',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
              ),
              const SizedBox(height: 8),
              Text(
                'إجمالي المسحوب ${earnings.paidOut.toStringAsFixed(0)} ${earnings.currency}',
                style: const TextStyle(color: AppColors.textMuted),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  key: const Key('technician-request-payout-button'),
                  onPressed:
                      _isSubmittingPayout || earnings.availableBalance <= 0
                      ? null
                      : _requestPayout,
                  icon: const Icon(Icons.account_balance_wallet_rounded),
                  label: Text(
                    _isSubmittingPayout ? 'جارٍ الإرسال...' : 'طلب سحب جديد',
                  ),
                ),
              ),
              if (earnings.availableBalance <= 0) ...[
                const SizedBox(height: 8),
                const Text(
                  'لا يوجد رصيد متاح للسحب الآن.',
                  style: TextStyle(color: AppColors.textMuted),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 14),
        AppSectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'آخر المعاملات',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
              ),
              const SizedBox(height: 12),
              if (earnings.recentTransactions.isEmpty)
                const AsyncPlaceholder(
                  title: 'لا توجد معاملات بعد',
                  message:
                      'بمجرد اكتمال أول خدمة أو تحويل مالي ستظهر حركة الأرباح هنا بشكل منظم.',
                  icon: Icons.payments_outlined,
                )
              else
                ...earnings.recentTransactions.map(
                  (item) => _FinanceRow(
                    title: item.customerName.isEmpty
                        ? item.title
                        : '${item.customerName} - ${item.title}',
                    time: _formatDateTime(item.completedAt),
                    amount:
                        '+${item.netAmount.toStringAsFixed(0)} ${item.currency}',
                    positive: true,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        AppSectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'طلبات السحب',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
              ),
              const SizedBox(height: 12),
              if (_isLoadingPayouts && payouts == null)
                const AppLoadingCard(
                  compact: true,
                  message: 'نجهز طلبات السحب وحالتها الحالية.',
                )
              else if (payouts == null || payouts.items.isEmpty)
                const AsyncPlaceholder(
                  title: 'لا توجد طلبات سحب',
                  message:
                      'عندما ترسل أول طلب سحب أو مراجعة مالية سيظهر سجل الطلبات هنا.',
                  icon: Icons.account_balance_wallet_outlined,
                )
              else ...[
                ...payouts.items.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _PayoutRow(
                      title: item.destinationLabel.isEmpty
                          ? 'طلب سحب'
                          : item.destinationLabel,
                      subtitle: _formatDateTime(item.createdAt),
                      amount:
                          '${item.amount.toStringAsFixed(0)} ${item.currency}',
                      statusLabel: _payoutStatusLabel(item.status),
                      statusColor: _payoutStatusColor(item.status),
                    ),
                  ),
                ),
                if (payouts.hasMore)
                  OutlinedButton(
                    onPressed: _isLoadingPayouts
                        ? null
                        : () async {
                            setState(() => _payoutsPage += 1);
                            await _loadPayouts(reset: false);
                          },
                    child: Text(
                      _isLoadingPayouts ? 'جارٍ التحميل...' : 'عرض المزيد',
                    ),
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReviewsTab() {
    final reviews = _profile.recentReviews;
    final ratingBuckets = <int, int>{5: 0, 4: 0, 3: 0, 2: 0, 1: 0};
    for (final review in reviews) {
      ratingBuckets[review.rating] = (ratingBuckets[review.rating] ?? 0) + 1;
    }
    final total = reviews.isEmpty ? 1 : reviews.length;
    return Column(
      children: [
        _TabHeaderCard(
          title: context.tr(ar: 'التقييمات', en: 'Reviews'),
          subtitle: context.tr(
            ar: 'صورة أوضح عن رضا العملاء وجودة الخدمة التي تقدمها.',
            en: 'A clearer picture of customer satisfaction and service quality.',
          ),
          icon: Icons.star_rate_rounded,
        ),
        const SizedBox(height: 14),
        AppSectionCard(
          child: Column(
            children: [
              Text(
                _profile.rating.toStringAsFixed(1),
                style: const TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  5,
                  (index) =>
                      const Icon(Icons.star_rounded, color: AppColors.accent),
                ),
              ),
              const SizedBox(height: 6),
              Text('بناءً على ${_profile.reviewsCount} تقييم'),
              const SizedBox(height: 16),
              ...[5, 4, 3, 2, 1].map(
                (score) => _RateBarRow(
                  label: '$score',
                  count: '${ratingBuckets[score] ?? 0}',
                  widthFactor: (ratingBuckets[score] ?? 0) / total,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        if (reviews.isEmpty)
          const AsyncPlaceholder(
            title: 'لا توجد تقييمات بعد',
            message:
                'بعد انتهاء أولى الحجوزات سيبدأ العملاء بإضافة تقييماتهم وملاحظاتهم هنا.',
            icon: Icons.rate_review_outlined,
          )
        else
          ...reviews.map(
            (review) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _ReviewCard(review: review),
            ),
          ),
      ],
    );
  }

  Widget _buildEditTab() {
    return Column(
      children: [
        _TabHeaderCard(
          title: context.tr(ar: 'تعديل البيانات', en: 'Edit profile'),
          subtitle: context.tr(
            ar: 'حدّث هويتك المهنية ومجالات خدمتك وطريقة ظهورك أمام العميل.',
            en: 'Update your professional identity, service areas, and how customers see you.',
          ),
          icon: Icons.edit_note_rounded,
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: MetricPill(
                label: context.tr(ar: 'المهارات', en: 'Skills'),
                value: '${_profile.skills.length}',
                background: AppColors.primarySoft,
                valueColor: AppColors.primaryDark,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: MetricPill(
                label: context.tr(ar: 'حالة التوفر', en: 'Availability'),
                value: _profile.isAvailable
                    ? context.tr(ar: 'متاح', en: 'Available')
                    : context.tr(ar: 'غير متاح', en: 'Unavailable'),
                background: _profile.isAvailable
                    ? AppColors.successSoft
                    : AppColors.errorSoft,
                valueColor: _profile.isAvailable
                    ? AppColors.success
                    : AppColors.error,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        AppSectionCard(
          child: Column(
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: const BoxDecoration(
                  color: AppColors.primarySoft,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(
                    _profile.icon,
                    size: 34,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              AppTextField(
                controller: _nameController,
                textDirection: TextDirection.rtl,
                decoration: const InputDecoration(labelText: 'الاسم الكامل'),
              ),
              const SizedBox(height: 12),
              AppTextField(
                controller: _titleController,
                textDirection: TextDirection.rtl,
                decoration: const InputDecoration(labelText: 'المسمى المهني'),
              ),
              const SizedBox(height: 12),
              AppTextField(
                controller: _cityController,
                textDirection: TextDirection.rtl,
                decoration: const InputDecoration(labelText: 'المدينة'),
              ),
              const SizedBox(height: 12),
              AppTextField(
                controller: _hourlyController,
                textDirection: TextDirection.ltr,
                decoration: const InputDecoration(labelText: 'سعر الساعة (ج)'),
              ),
              const SizedBox(height: 12),
              AppTextField(
                controller: _serviceAreasController,
                textDirection: TextDirection.rtl,
                decoration: const InputDecoration(
                  labelText: 'مناطق الخدمة (بفواصل)',
                ),
              ),
              const SizedBox(height: 12),
              AppTextField(
                controller: _skillsController,
                textDirection: TextDirection.rtl,
                decoration: const InputDecoration(
                  labelText: 'المهارات (بفواصل)',
                ),
              ),
              const SizedBox(height: 12),
              AppTextField(
                controller: _bioController,
                maxLines: 4,
                textDirection: TextDirection.rtl,
                decoration: const InputDecoration(labelText: 'نبذة عنك'),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        context.tr(
                          ar: 'متاح لاستقبال الطلبات',
                          en: 'Available for incoming requests',
                        ),
                      ),
                    ),
                    Switch(
                      value: _profile.isAvailable,
                      activeThumbColor: AppColors.success,
                      onChanged: _isTogglingAvailability
                          ? null
                          : _changeAvailability,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              ElevatedButton(
                onPressed: _isSavingProfile ? null : _saveProfile,
                child: Text(
                  _isSavingProfile
                      ? context.tr(ar: 'جارٍ الحفظ...', en: 'Saving...')
                      : context.tr(ar: 'حفظ التعديلات', en: 'Save changes'),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _isSavingProfile ? null : _logout,
                  icon: const Icon(Icons.logout_rounded),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.error),
                  ),
                  label: Text(context.tr(ar: 'تسجيل الخروج', en: 'Log out')),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDateTime(DateTime? value) {
    if (value == null) return 'غير محدد';
    final local = value.toLocal();
    return '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')} ${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }

  String _payoutStatusLabel(String status) {
    return switch (status) {
      'approved' => 'معتمد',
      'rejected' => 'مرفوض',
      'paid' => 'تم التحويل',
      _ => 'قيد المراجعة',
    };
  }

  Color _payoutStatusColor(String status) {
    return switch (status) {
      'approved' => AppColors.info,
      'rejected' => AppColors.error,
      'paid' => AppColors.success,
      _ => AppColors.accent,
    };
  }
}

class _PayoutDraft {
  const _PayoutDraft({
    required this.amountText,
    required this.destinationLabel,
    required this.notes,
  });

  final String amountText;
  final String destinationLabel;
  final String notes;
}

class _TechnicianStatusChip extends StatelessWidget {
  const _TechnicianStatusChip({
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

class _TabHeaderCard extends StatelessWidget {
  const _TabHeaderCard({
    required this.title,
    this.subtitle,
    this.icon = Icons.dashboard_customize_rounded,
  });

  final String title;
  final String? subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            AppColors.primaryDark,
            AppColors.primary,
            AppColors.secondary,
          ],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withValues(alpha: 0.2),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(icon, color: Colors.white),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 24,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle!,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.82),
                      height: 1.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TechnicianBookingCard extends StatelessWidget {
  const _TechnicianBookingCard({
    required this.booking,
    required this.onAction,
    required this.onViewDetails,
    required this.onOpenTracking,
    required this.onOpenChat,
  });

  final ServiceBooking booking;
  final ValueChanged<String> onAction;
  final VoidCallback onViewDetails;
  final VoidCallback onOpenTracking;
  final VoidCallback onOpenChat;

  @override
  Widget build(BuildContext context) {
    final actions = _actionsForStatus(booking.status);
    return AppSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _statusColor(booking.status).withValues(alpha: 0.85),
                      _statusColor(booking.status),
                    ],
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                  ),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(Icons.handyman_rounded, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  booking.problemDescription,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _statusColor(booking.status).withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  _statusLabel(booking.status),
                  style: TextStyle(
                    color: _statusColor(booking.status),
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${booking.customerName} • ${booking.address}',
            style: const TextStyle(color: AppColors.textMuted),
          ),
          const SizedBox(height: 4),
          Text(
            '${booking.estimatedPrice.toStringAsFixed(0)} ${booking.currency} • ${booking.paymentStatus}',
            style: const TextStyle(color: AppColors.textMuted),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onViewDetails,
                  child: const Text('عرض التفاصيل'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: onOpenTracking,
                  child: const Text('التتبع'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: onOpenChat,
                  child: const Text('المحادثة'),
                ),
              ),
            ],
          ),
          if (actions.isNotEmpty) const SizedBox(height: 10),
          if (actions.isNotEmpty)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: actions
                  .map(
                    (action) => action.$1 == 'cancel'
                        ? OutlinedButton(
                            onPressed: () => onAction(action.$1),
                            child: Text(action.$2),
                          )
                        : ElevatedButton(
                            onPressed: () => onAction(action.$1),
                            child: Text(action.$2),
                          ),
                  )
                  .toList(),
            ),
        ],
      ),
    );
  }

  static List<(String, String)> _actionsForStatus(String status) {
    switch (status) {
      case 'pending':
        return const [('confirm', 'قبول'), ('cancel', 'رفض')];
      case 'confirmed':
        return const [('start', 'بدء التحرك'), ('cancel', 'إلغاء')];
      case 'in_progress':
        return const [('arrive', 'تم الوصول')];
      case 'arrived':
        return const [('complete', 'تم الإنجاز')];
      default:
        return const [];
    }
  }

  static String _statusLabel(String status) {
    switch (status) {
      case 'pending':
        return 'جديد';
      case 'confirmed':
        return 'مؤكد';
      case 'in_progress':
        return 'جاري';
      case 'arrived':
        return 'وصل';
      case 'completed':
        return 'مكتمل';
      case 'cancelled':
        return 'ملغي';
      default:
        return status;
    }
  }

  static Color _statusColor(String status) {
    switch (status) {
      case 'pending':
        return AppColors.accent;
      case 'confirmed':
      case 'in_progress':
      case 'arrived':
        return AppColors.primary;
      case 'completed':
        return AppColors.success;
      case 'cancelled':
        return AppColors.error;
      default:
        return AppColors.border;
    }
  }
}

class _PayoutRow extends StatelessWidget {
  const _PayoutRow({
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.statusLabel,
    required this.statusColor,
  });

  final String title;
  final String subtitle;
  final String amount;
  final String statusLabel;
  final Color statusColor;

  @override
  Widget build(BuildContext context) {
    return AppSectionCard(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(amount, style: const TextStyle(fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FinanceRow extends StatelessWidget {
  const _FinanceRow({
    required this.title,
    required this.time,
    required this.amount,
    required this.positive,
  });

  final String title;
  final String time;
  final String amount;
  final bool positive;

  @override
  Widget build(BuildContext context) {
    return AppSectionCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  time,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            amount,
            style: TextStyle(
              color: positive ? AppColors.success : AppColors.error,
              fontWeight: FontWeight.w800,
              fontSize: 22,
            ),
          ),
        ],
      ),
    );
  }
}

class _RateBarRow extends StatelessWidget {
  const _RateBarRow({
    required this.label,
    required this.count,
    required this.widthFactor,
  });

  final String label;
  final String count;
  final double widthFactor;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.backgroundTertiary,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 18,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: widthFactor.clamp(0, 1),
                minHeight: 9,
                backgroundColor: AppColors.border.withValues(alpha: 0.5),
                valueColor: const AlwaysStoppedAnimation(AppColors.accent),
              ),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 32,
            child: Text(
              count,
              textAlign: TextAlign.end,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.review});

  final TechnicianReview review;

  @override
  Widget build(BuildContext context) {
    final initial = review.customerName.isEmpty
        ? '?'
        : review.customerName.characters.first;
    return AppSectionCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.accentDark, AppColors.accent],
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
                fontWeight: FontWeight.w900,
                fontSize: 18,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        review.customerName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    if (review.createdAt != null)
                      AppStatusBadge(
                        label:
                            '${review.createdAt!.year}/${review.createdAt!.month}/${review.createdAt!.day}',
                        foreground: AppColors.primaryDark,
                        background: AppColors.primarySoft,
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: List.generate(
                    5,
                    (index) => Icon(
                      Icons.star_rounded,
                      color: index < review.rating
                          ? AppColors.accent
                          : AppColors.border,
                      size: 18,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  review.comment,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    height: 1.6,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TechnicianBottomBar extends StatelessWidget {
  const _TechnicianBottomBar({
    required this.currentIndex,
    required this.onChanged,
  });

  final int currentIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final items = [
      (Icons.home_rounded, context.tr(ar: 'الرئيسية', en: 'Home')),
      (Icons.assignment_rounded, context.tr(ar: 'الحجوزات', en: 'Bookings')),
      (Icons.attach_money_rounded, context.tr(ar: 'الأرباح', en: 'Earnings')),
      (Icons.person_rounded, context.tr(ar: 'الملف', en: 'Profile')),
    ];

    return Container(
      margin: const EdgeInsets.fromLTRB(18, 0, 18, 18),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.bottomBar, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withValues(alpha: 0.24),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Row(
        children: List.generate(items.length, (index) {
          final item = items[index];
          final active = currentIndex == index;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                padding: const EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 6,
                ),
                decoration: BoxDecoration(
                  gradient: active
                      ? const LinearGradient(
                          colors: [Colors.white, AppColors.accentSoft],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: active
                            ? AppColors.primaryDark
                            : Colors.white.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(item.$1, color: Colors.white, size: 18),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.$2,
                      style: TextStyle(
                        color: active ? AppColors.primaryDark : Colors.white70,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
