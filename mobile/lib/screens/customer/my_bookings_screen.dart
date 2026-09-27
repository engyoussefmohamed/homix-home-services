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

final myBookingsProvider = FutureProvider.autoDispose
    .family<PaginatedServiceBookings, String>((ref, status) {
      final token = ref.watch(authControllerProvider).token;
      if (token == null || token.isEmpty) {
        throw Exception('يجب تسجيل الدخول لعرض الحجوزات.');
      }
      return ref
          .watch(apiServiceProvider)
          .getMyBookings(token, status: status.isEmpty ? null : status);
    });

class MyBookingsScreen extends ConsumerStatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  ConsumerState<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends ConsumerState<MyBookingsScreen> {
  String _status = '';

  @override
  Widget build(BuildContext context) {
    final bookingsAsync = ref.watch(myBookingsProvider(_status));

    return HomixPage(
      title: context.tr(ar: 'حجوزاتي', en: 'My bookings'),
      header: AppBanner(
        title: context.tr(
          ar: 'مركز حجوزات أوضح وأسهل للمتابعة',
          en: 'A clearer, easier booking center',
        ),
        message: context.tr(
          ar: 'رتبنا الفلاتر، الحالات، وتفاصيل الحجز حتى تتابع التنفيذ والحالة والدفع بثقة أعلى.',
          en: 'Filters, statuses, and booking details are reorganized for better confidence and faster scanning.',
        ),
        icon: Icons.home_repair_service_rounded,
        background: AppColors.primarySoft,
        foreground: AppColors.primaryDark,
      ),
      child: Column(
        children: [
          DashboardHero(
            title: context.tr(
              ar: 'كل حجوزاتك في واجهة متابعة واحدة',
              en: 'All your bookings in one tracking view',
            ),
            subtitle: context.tr(ar: 'مركز الحجوزات', en: 'Booking center'),
            chips: [
              HeroTagChip(
                label: context.tr(ar: 'حالة أوضح', en: 'Clear status'),
              ),
              HeroTagChip(
                label: context.tr(
                  ar: 'الوصول للتفاصيل أسرع',
                  en: 'Faster details',
                ),
                highlight: true,
              ),
            ],
          ),
          const SizedBox(height: 16),
          AppSectionCard(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: SizedBox(
              height: 46,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _filters.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final item = _filters[index];
                  final selected = _status == item.$1;
                  return GestureDetector(
                    onTap: () => setState(() => _status = item.$1),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
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
                        item.$2,
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
          const SizedBox(height: 16),
          Expanded(
            child: bookingsAsync.when(
              data: (page) {
                if (page.items.isEmpty) {
                  return AsyncPlaceholder(
                    message: context.tr(
                      ar: 'لا توجد حجوزات خدمات حاليًا.',
                      en: 'There are no service bookings right now.',
                    ),
                    icon: Icons.event_busy_rounded,
                  );
                }

                final activeCount = page.items
                    .where(
                      (item) =>
                          item.status != 'completed' &&
                          item.status != 'cancelled',
                    )
                    .length;
                final completedCount = page.items
                    .where((item) => item.status == 'completed')
                    .length;

                return Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: StatTile(
                            label: context.tr(
                              ar: 'إجمالي الحجوزات',
                              en: 'Total bookings',
                            ),
                            value: '${page.total}',
                            color: AppColors.primary,
                            icon: Icons.event_note_rounded,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: StatTile(
                            label: context.tr(
                              ar: 'نشطة الآن',
                              en: 'Active now',
                            ),
                            value: '$activeCount',
                            color: AppColors.accent,
                            icon: Icons.handyman_rounded,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: MetricPill(
                            label: context.tr(ar: 'مكتملة', en: 'Completed'),
                            value: '$completedCount',
                            background: AppColors.successSoft,
                            valueColor: AppColors.success,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: MetricPill(
                            label: context.tr(
                              ar: 'الفلتر الحالي',
                              en: 'Current filter',
                            ),
                            value: _statusLabel(context, _status),
                            background: AppColors.primarySoft,
                            valueColor: AppColors.primaryDark,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: ListView.separated(
                        itemCount: page.items.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final booking = page.items[index];
                          return _BookingCard(booking: booking);
                        },
                      ),
                    ),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => AsyncPlaceholder(message: error.toString()),
            ),
          ),
        ],
      ),
    );
  }

  List<(String, String)> get _filters => [
    ('', context.tr(ar: 'الكل', en: 'All')),
    ('pending', context.tr(ar: 'قيد المراجعة', en: 'Pending')),
    ('confirmed', context.tr(ar: 'مؤكد', en: 'Confirmed')),
    ('in_progress', context.tr(ar: 'جارٍ التنفيذ', en: 'In progress')),
    ('completed', context.tr(ar: 'مكتمل', en: 'Completed')),
    ('cancelled', context.tr(ar: 'ملغي', en: 'Cancelled')),
  ];
}

class _BookingCard extends StatelessWidget {
  const _BookingCard({required this.booking});

  final ServiceBooking booking;

  @override
  Widget build(BuildContext context) {
    final scheduledFor = booking.scheduledFor == null
        ? context.tr(ar: 'غير محدد', en: 'Not scheduled')
        : DateFormat(
            'yyyy/MM/dd • hh:mm a',
          ).format(booking.scheduledFor!.toLocal());

    return AppSectionCard(
      child: InkWell(
        onTap: () =>
            context.push(AppRoutes.customerBookingDetailsPath(booking.id)),
        borderRadius: BorderRadius.circular(30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 28,
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
                          fontSize: 17,
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
                    ],
                  ),
                ),
                AppStatusBadge(
                  label: _statusLabel(context, booking.status),
                  foreground: _statusForeground(booking.status),
                  background: _statusBackground(booking.status),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              booking.problemDescription,
              style: const TextStyle(
                color: AppColors.textMuted,
                height: 1.6,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: MetricPill(
                    label: context.tr(ar: 'الموعد', en: 'Scheduled'),
                    value: scheduledFor,
                    background: AppColors.primarySoft,
                    valueColor: AppColors.primaryDark,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: MetricPill(
                    label: context.tr(ar: 'السعر', en: 'Price'),
                    value:
                        '${booking.estimatedPrice.toStringAsFixed(0)} ${booking.currency}',
                    background: AppColors.accentSoft,
                    valueColor: AppColors.accentDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              booking.address,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 14),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton.icon(
                onPressed: () => context.push(
                  AppRoutes.customerBookingDetailsPath(booking.id),
                ),
                icon: const Icon(Icons.arrow_outward_rounded),
                label: Text(context.tr(ar: 'عرض التفاصيل', en: 'View details')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _statusLabel(BuildContext context, String status) {
  switch (status) {
    case '':
      return context.tr(ar: 'الكل', en: 'All');
    case 'pending':
      return context.tr(ar: 'قيد المراجعة', en: 'Pending');
    case 'confirmed':
      return context.tr(ar: 'مؤكد', en: 'Confirmed');
    case 'in_progress':
      return context.tr(ar: 'جارٍ التنفيذ', en: 'In progress');
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
    case 'confirmed':
    case 'in_progress':
      return AppColors.primary;
    case 'completed':
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
    case 'in_progress':
      return AppColors.primarySoft;
    case 'completed':
      return AppColors.successSoft;
    case 'cancelled':
      return AppColors.errorSoft;
    default:
      return AppColors.accentSoft;
  }
}
