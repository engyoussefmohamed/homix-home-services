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

class TechnicianNotificationsScreen extends ConsumerStatefulWidget {
  const TechnicianNotificationsScreen({super.key});

  @override
  ConsumerState<TechnicianNotificationsScreen> createState() =>
      _TechnicianNotificationsScreenState();
}

class _TechnicianNotificationsScreenState
    extends ConsumerState<TechnicianNotificationsScreen> {
  bool _isLoading = true;
  bool _showUnreadOnly = false;
  List<AppNotificationItem> _notifications = const [];
  String? _error;

  int get _unreadCount => _notifications.where((item) => !item.isRead).length;

  List<AppNotificationItem> get _visibleItems => _showUnreadOnly
      ? _notifications.where((item) => !item.isRead).toList()
      : _notifications;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadNotifications());
  }

  Future<void> _loadNotifications() async {
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
      final items = await ref
          .read(apiServiceProvider)
          .getMyNotifications(token);
      if (!mounted) return;
      setState(() => _notifications = items);
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error.toString());
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _openNotification(AppNotificationItem item) async {
    final token = ref.read(authControllerProvider).token;
    if (token == null || token.isEmpty) return;

    if (!item.isRead) {
      try {
        await ref
            .read(apiServiceProvider)
            .markNotificationRead(token: token, notificationId: item.id);
        if (mounted) {
          setState(() {
            _notifications = _notifications
                .map(
                  (entry) => entry.id == item.id
                      ? AppNotificationItem(
                          id: entry.id,
                          bookingId: entry.bookingId,
                          category: entry.category,
                          title: entry.title,
                          body: entry.body,
                          isRead: true,
                          createdAt: entry.createdAt,
                        )
                      : entry,
                )
                .toList();
          });
        }
      } catch (_) {
        // Keep navigation usable even if marking as read fails.
      }
    }

    if (!mounted || item.bookingId.isEmpty) return;
    context.push(
      AppRoutes.technicianBookingDetailsPath(
        item.bookingId,
        tab: _tabForCategory(item.category),
      ),
    );
  }

  int _tabForCategory(String category) {
    switch (category) {
      case 'chat':
        return 2;
      case 'tracking':
      case 'payment':
      case 'review':
        return 1;
      default:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return HomixPage(
      title: context.tr(ar: 'إشعارات الفني', en: 'Technician notifications'),
      header: AppBanner(
        title: context.tr(
          ar: 'مركز إشعارات عملي للفني',
          en: 'An operational notification center for technicians',
        ),
        message: context.tr(
          ar: 'التحديثات المهمة، الرسائل، والتنبيهات التشغيلية صارت أوضح وأسهل للوصول للحجز مباشرة.',
          en: 'Important updates, messages, and operational alerts are now easier to review and open.',
        ),
        icon: Icons.notifications_active_rounded,
        background: AppColors.secondarySoft,
        foreground: AppColors.secondary,
      ),
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? AsyncPlaceholder(message: _error!)
          : RefreshIndicator(
              onRefresh: _loadNotifications,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  DashboardHero(
                    title: context.tr(
                      ar: 'كل تنبيهاتك التشغيلية في شاشة واحدة',
                      en: 'All your operational alerts in one screen',
                    ),
                    subtitle: context.tr(
                      ar: 'إشعارات الفني',
                      en: 'Technician alerts',
                    ),
                    chips: [
                      HeroTagChip(
                        label: context.tr(
                          ar: '${_notifications.length} إشعارات',
                          en: '${_notifications.length} notifications',
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
                          child: _TechNotificationFilterChip(
                            label: context.tr(ar: 'الكل', en: 'All'),
                            selected: !_showUnreadOnly,
                            onTap: () =>
                                setState(() => _showUnreadOnly = false),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _TechNotificationFilterChip(
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
                              ar: 'لا توجد إشعارات للفني حتى الآن.',
                              en: 'There are no technician notifications yet.',
                            ),
                      icon: Icons.notifications_none_rounded,
                    )
                  else
                    ..._visibleItems.map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _TechNotificationCard(
                          item: item,
                          onTap: () => _openNotification(item),
                          timestamp: _formatTimestamp(item.createdAt),
                          label: _labelForCategory(context, item.category),
                          accent: _accentFor(item.category),
                          icon: _iconForCategory(item.category),
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  String _formatTimestamp(DateTime? value) {
    if (value == null) return context.tr(ar: 'الآن', en: 'Now');
    return DateFormat('yyyy/MM/dd • hh:mm a').format(value.toLocal());
  }

  String _labelForCategory(BuildContext context, String category) {
    switch (category) {
      case 'chat':
        return context.tr(ar: 'محادثة', en: 'Chat');
      case 'payment':
        return context.tr(ar: 'دفع', en: 'Payment');
      case 'review':
        return context.tr(ar: 'تقييم', en: 'Review');
      case 'tracking':
        return context.tr(ar: 'تتبع', en: 'Tracking');
      default:
        return context.tr(ar: 'تنبيه', en: 'Alert');
    }
  }

  IconData _iconForCategory(String category) {
    switch (category) {
      case 'chat':
        return Icons.chat_bubble_rounded;
      case 'payment':
        return Icons.payments_rounded;
      case 'review':
        return Icons.star_rounded;
      case 'tracking':
        return Icons.location_searching_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  Color _accentFor(String category) {
    switch (category) {
      case 'chat':
        return AppColors.primary;
      case 'payment':
        return AppColors.accentDark;
      case 'review':
        return AppColors.secondary;
      case 'tracking':
        return AppColors.primaryDark;
      default:
        return AppColors.primary;
    }
  }
}

class _TechNotificationFilterChip extends StatelessWidget {
  const _TechNotificationFilterChip({
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

class _TechNotificationCard extends StatelessWidget {
  const _TechNotificationCard({
    required this.item,
    required this.onTap,
    required this.timestamp,
    required this.label,
    required this.accent,
    required this.icon,
  });

  final AppNotificationItem item;
  final VoidCallback onTap;
  final String timestamp;
  final String label;
  final Color accent;
  final IconData icon;

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
                        const Icon(
                          Icons.brightness_1_rounded,
                          size: 10,
                          color: AppColors.accent,
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
                        label: label,
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
