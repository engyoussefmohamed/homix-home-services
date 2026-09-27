import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../constants/app_theme.dart';
import '../../core/app_localizations.dart';
import '../../core/app_router.dart';
import '../../models/service_booking.dart';
import '../../providers/auth_controller.dart';
import '../../services/api_service.dart';
import '../../widgets/app_widgets.dart';

class CustomerNotificationsScreen extends ConsumerStatefulWidget {
  const CustomerNotificationsScreen({super.key});

  @override
  ConsumerState<CustomerNotificationsScreen> createState() =>
      _CustomerNotificationsScreenState();
}

class _CustomerNotificationsScreenState
    extends ConsumerState<CustomerNotificationsScreen> {
  bool _isLoading = true;
  bool _showUnreadOnly = false;
  List<AppNotificationItem> _items = const [];

  String? get _token => ref.read(authControllerProvider).token;

  List<AppNotificationItem> get _visibleItems =>
      _showUnreadOnly ? _items.where((item) => !item.isRead).toList() : _items;

  int get _unreadCount => _items.where((item) => !item.isRead).length;

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
      final items = await ref
          .read(apiServiceProvider)
          .getMyNotifications(token);
      if (!mounted) return;
      setState(() => _items = items);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _openItem(AppNotificationItem item) async {
    final token = _token;
    if (token == null || token.isEmpty) return;

    if (!item.isRead) {
      await ref
          .read(apiServiceProvider)
          .markNotificationRead(token: token, notificationId: item.id);
      _markAsRead(item.id);
    }

    if (!mounted) return;
    if (item.bookingId.isNotEmpty) {
      await context.push(
        AppRoutes.customerBookingDetailsPath(
          item.bookingId,
          tab: _tabForCategory(item.category),
        ),
      );
      if (mounted) {
        await _load();
      }
    }
  }

  void _markAsRead(String notificationId) {
    setState(() {
      _items = _items
          .map(
            (item) => item.id == notificationId
                ? AppNotificationItem(
                    id: item.id,
                    bookingId: item.bookingId,
                    category: item.category,
                    title: item.title,
                    body: item.body,
                    isRead: true,
                    createdAt: item.createdAt,
                  )
                : item,
          )
          .toList();
    });
  }

  int _tabForCategory(String category) {
    return switch (category) {
      'chat' => 2,
      'review' => 3,
      _ => 1,
    };
  }

  @override
  Widget build(BuildContext context) {
    return HomixPage(
      title: context.tr(ar: 'الإشعارات', en: 'Notifications'),
      header: AppBanner(
        title: context.tr(
          ar: 'مركز إشعارات أوضح وأهدأ',
          en: 'A clearer, calmer notification center',
        ),
        message: context.tr(
          ar: 'رتبنا التحديثات الجديدة بحيث تصل للحجز أو المحادثة أو الدفع أسرع وبثقة أعلى.',
          en: 'Updates are reorganized so you can reach booking, chat, or payment faster.',
        ),
        icon: Icons.notifications_active_rounded,
        background: AppColors.primarySoft,
        foreground: AppColors.primaryDark,
      ),
      child: RefreshIndicator(
        onRefresh: _load,
        child: _isLoading
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 160),
                  Center(child: CircularProgressIndicator()),
                ],
              )
            : ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  DashboardHero(
                    title: context.tr(
                      ar: 'كل التحديثات المهمة في مكان واحد',
                      en: 'All important updates in one place',
                    ),
                    subtitle: context.tr(
                      ar: 'لوحة الإشعارات',
                      en: 'Notification center',
                    ),
                    chips: [
                      HeroTagChip(
                        label: context.tr(
                          ar: '${_items.length} إشعارات',
                          en: '${_items.length} notifications',
                        ),
                      ),
                      HeroTagChip(
                        label: context.tr(
                          ar: 'غير مقروءة $_unreadCount',
                          en: 'Unread $_unreadCount',
                        ),
                        highlight: true,
                      ),
                    ],
                    trailing: Container(
                      width: 104,
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
                            '$_unreadCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 30,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          Text(
                            context.tr(
                              ar: 'تحتاج انتباهك',
                              en: 'Need attention',
                            ),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.84),
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
                    child: Row(
                      children: [
                        Expanded(
                          child: _NotificationFilterChip(
                            label: context.tr(ar: 'الكل', en: 'All'),
                            selected: !_showUnreadOnly,
                            onTap: () =>
                                setState(() => _showUnreadOnly = false),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _NotificationFilterChip(
                            label: context.tr(ar: 'غير المقروءة', en: 'Unread'),
                            selected: _showUnreadOnly,
                            onTap: () => setState(() => _showUnreadOnly = true),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_visibleItems.isEmpty)
                    AsyncPlaceholder(
                      message: _showUnreadOnly
                          ? context.tr(
                              ar: 'لا توجد إشعارات غير مقروءة الآن.',
                              en: 'There are no unread notifications right now.',
                            )
                          : context.tr(
                              ar: 'لا توجد إشعارات حاليًا.',
                              en: 'There are no notifications right now.',
                            ),
                      icon: Icons.notifications_none_rounded,
                    )
                  else
                    ..._visibleItems.map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _NotificationCard(
                          item: item,
                          onTap: () => _openItem(item),
                          categoryLabel: _categoryLabel(context, item.category),
                          timestamp: _formatTimestamp(item.createdAt),
                          icon: _iconFor(item.category),
                          accent: _accentFor(item.category),
                        ),
                      ),
                    ),
                ],
              ),
      ),
    );
  }

  String _formatTimestamp(DateTime? value) {
    if (value == null) {
      return context.tr(ar: 'الآن', en: 'Now');
    }
    return DateFormat('yyyy/MM/dd • hh:mm a').format(value.toLocal());
  }

  String _categoryLabel(BuildContext context, String category) {
    return switch (category) {
      'payment' => context.tr(ar: 'دفع', en: 'Payment'),
      'chat' => context.tr(ar: 'محادثة', en: 'Chat'),
      'review' => context.tr(ar: 'تقييم', en: 'Review'),
      'tracking' => context.tr(ar: 'تتبع', en: 'Tracking'),
      _ => context.tr(ar: 'إشعار', en: 'Alert'),
    };
  }

  IconData _iconFor(String category) {
    return switch (category) {
      'payment' => Icons.payments_rounded,
      'chat' => Icons.chat_bubble_rounded,
      'review' => Icons.star_rounded,
      'tracking' => Icons.timeline_rounded,
      _ => Icons.notifications_rounded,
    };
  }

  Color _accentFor(String category) {
    return switch (category) {
      'payment' => AppColors.secondary,
      'chat' => AppColors.primary,
      'review' => AppColors.accentDark,
      'tracking' => AppColors.primaryDark,
      _ => AppColors.primary,
    };
  }
}

class _NotificationFilterChip extends StatelessWidget {
  const _NotificationFilterChip({
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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          gradient: selected
              ? const LinearGradient(
                  colors: [AppColors.primaryDark, AppColors.primary],
                )
              : const LinearGradient(
                  colors: [AppColors.cardWhite, AppColors.backgroundTertiary],
                ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? Colors.transparent : AppColors.border,
          ),
        ),
        alignment: Alignment.center,
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

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({
    required this.item,
    required this.onTap,
    required this.categoryLabel,
    required this.timestamp,
    required this.icon,
    required this.accent,
  });

  final AppNotificationItem item;
  final VoidCallback onTap;
  final String categoryLabel;
  final String timestamp;
  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return AppSectionCard(
      color: item.isRead ? null : AppColors.primarySoft,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(30),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(icon, color: accent),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      if (!item.isRead)
                        Container(
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(
                            color: AppColors.accent,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item.body,
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      height: 1.6,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      AppStatusBadge(
                        label: categoryLabel,
                        foreground: accent,
                        background: accent.withValues(alpha: 0.14),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          timestamp,
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
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
    );
  }
}
