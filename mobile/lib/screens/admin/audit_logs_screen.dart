import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../constants/app_theme.dart';
import '../../core/app_localizations.dart';
import '../../providers/auth_controller.dart';
import '../../services/api_service.dart';
import '../../widgets/app_widgets.dart';

final auditLogsPageProvider = StateProvider<int>((ref) => 1);

final auditLogsProvider = FutureProvider.autoDispose<Map<String, dynamic>>((
  ref,
) async {
  final token = ref.watch(authControllerProvider).token;
  if (token == null) {
    return const {
      'items': <dynamic>[],
      'total': 0,
      'page': 1,
      'page_size': 20,
      'has_more': false,
    };
  }
  return ref
      .watch(apiServiceProvider)
      .getAuditLogs(token, page: ref.watch(auditLogsPageProvider));
});

class AuditLogsScreen extends ConsumerWidget {
  const AuditLogsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logsAsync = ref.watch(auditLogsProvider);

    return HomixPage(
      title: context.tr(ar: 'سجل المراجعة', en: 'Audit logs'),
      header: AppBanner(
        title: context.tr(
          ar: 'مركز تتبع العمليات الحساسة',
          en: 'A control center for sensitive operations',
        ),
        message: context.tr(
          ar: 'سجلّات الجلسات والموافقات والإجراءات الإدارية صارت أوضح وأسهل للتمرير والتحقيق السريع.',
          en: 'Sessions, approvals, and administrative actions are now easier to scan and investigate quickly.',
        ),
        icon: Icons.shield_outlined,
        background: AppColors.primarySoft,
        foreground: AppColors.primaryDark,
      ),
      child: logsAsync.when(
        data: (payload) {
          final items = payload['items'] as List<dynamic>? ?? const [];
          final total = (payload['total'] as num?)?.toInt() ?? items.length;
          final page = (payload['page'] as num?)?.toInt() ?? 1;
          final hasMore = payload['has_more'] == true;

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(auditLogsProvider),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                DashboardHero(
                  title: context.tr(
                    ar: 'كل الأحداث الإدارية في عرض واحد',
                    en: 'All admin events in one operational view',
                  ),
                  subtitle: context.tr(
                    ar: 'صفحة $page من سجل المراجعة',
                    en: 'Page $page of the audit log',
                  ),
                  chips: [
                    HeroTagChip(
                      label: context.tr(ar: '$total سجل', en: '$total logs'),
                    ),
                    HeroTagChip(
                      label: context.tr(
                        ar: hasMore ? 'يوجد المزيد' : 'آخر صفحة',
                        en: hasMore ? 'More available' : 'Last page',
                      ),
                      highlight: true,
                    ),
                  ],
                  trailing: Container(
                    width: 110,
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
                          '$page',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          context.tr(ar: 'الصفحة الحالية', en: 'Current page'),
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
                        label: context.tr(ar: 'إجمالي السجل', en: 'Total logs'),
                        value: '$total',
                        color: AppColors.primary,
                        icon: Icons.list_alt_rounded,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: StatTile(
                        label: context.tr(
                          ar: 'الصفحة الحالية',
                          en: 'Current page',
                        ),
                        value: '$page',
                        color: AppColors.accent,
                        icon: Icons.layers_rounded,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                AppSectionCard(
                  child: Row(
                    children: [
                      Expanded(
                        child: MetricPill(
                          label: context.tr(ar: 'المراجعة', en: 'Review mode'),
                          value: context.tr(
                            ar: 'سريع ومنظم',
                            en: 'Fast and organized',
                          ),
                          background: AppColors.successSoft,
                          valueColor: AppColors.success,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: MetricPill(
                          label: context.tr(ar: 'أفضل استخدام', en: 'Best use'),
                          value: context.tr(
                            ar: 'التحقيق والتتبع',
                            en: 'Investigation',
                          ),
                          background: AppColors.secondarySoft,
                          valueColor: AppColors.secondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                if (items.isEmpty)
                  AsyncPlaceholder(
                    message: context.tr(
                      ar: 'لا توجد سجلات مراجعة حتى الآن.',
                      en: 'There are no audit logs yet.',
                    ),
                    icon: Icons.history_toggle_off_rounded,
                  )
                else
                  ...items.map(
                    (entry) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _AuditTile(
                        entry: Map<String, dynamic>.from(entry as Map),
                      ),
                    ),
                  ),
                if (items.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  AppSectionCard(
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: page > 1
                                ? () =>
                                      ref
                                              .read(
                                                auditLogsPageProvider.notifier,
                                              )
                                              .state =
                                          page - 1
                                : null,
                            child: Text(
                              context.tr(ar: 'السابق', en: 'Previous'),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: hasMore
                                ? () =>
                                      ref
                                              .read(
                                                auditLogsPageProvider.notifier,
                                              )
                                              .state =
                                          page + 1
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
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => AsyncPlaceholder(message: error.toString()),
      ),
    );
  }
}

class _AuditTile extends StatelessWidget {
  const _AuditTile({required this.entry});

  final Map<String, dynamic> entry;

  @override
  Widget build(BuildContext context) {
    final createdAt = DateTime.tryParse((entry['created_at'] ?? '').toString());
    final formatted = createdAt == null
        ? context.tr(ar: 'غير متاح', en: 'Unavailable')
        : DateFormat('yyyy/MM/dd • hh:mm a').format(createdAt.toLocal());
    final metadata = _formatMetadata((entry['metadata'] ?? '').toString());
    final metadataPreview = metadata.isEmpty
        ? context.tr(ar: 'لا توجد بيانات إضافية', en: 'No extra metadata')
        : metadata.split('\n').take(3).join('\n');
    final action = (entry['action'] ?? '').toString();
    final entityType = (entry['entity_type'] ?? '').toString();
    final entityId = (entry['entity_id'] ?? '').toString();
    final userId = (entry['user_id'] ?? '').toString();

    return AppSectionCard(
      child: InkWell(
        borderRadius: BorderRadius.circular(28),
        onTap: () => context.push('/admin/audit-logs/${entry['id']}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primaryDark, AppColors.primary],
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                    ),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Icon(
                    Icons.receipt_long_rounded,
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
                            label: _labelize(action),
                            foreground: AppColors.primaryDark,
                            background: AppColors.primarySoft,
                          ),
                          AppStatusBadge(
                            label: entityType.isEmpty ? '--' : entityType,
                            foreground: AppColors.accentDark,
                            background: AppColors.accentSoft,
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        action.isEmpty
                            ? context.tr(
                                ar: 'إجراء غير معروف',
                                en: 'Unknown action',
                              )
                            : _labelize(action),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        formatted,
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w700,
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
                    label: context.tr(ar: 'الكيان', en: 'Entity'),
                    value: entityId.isEmpty
                        ? (entityType.isEmpty ? '--' : entityType)
                        : '$entityType #$entityId',
                    background: AppColors.backgroundTertiary,
                    valueColor: AppColors.textDark,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: MetricPill(
                    label: context.tr(ar: 'المستخدم', en: 'User'),
                    value: userId.isEmpty ? '--' : userId,
                    background: AppColors.secondarySoft,
                    valueColor: AppColors.secondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.backgroundTertiary,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.tr(ar: 'معاينة البيانات', en: 'Metadata preview'),
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    metadataPreview,
                    style: const TextStyle(
                      color: AppColors.textDark,
                      height: 1.6,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatMetadata(String raw) {
    if (raw.isEmpty) return '';
    try {
      final decoded = jsonDecode(raw);
      return const JsonEncoder.withIndent('  ').convert(decoded);
    } catch (_) {
      return raw;
    }
  }

  String _labelize(String value) {
    return value
        .split('_')
        .where((part) => part.isNotEmpty)
        .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
        .join(' ');
  }
}
