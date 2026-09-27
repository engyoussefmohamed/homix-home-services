import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../constants/app_theme.dart';
import '../../core/app_localizations.dart';
import '../../providers/auth_controller.dart';
import '../../services/api_service.dart';
import '../../widgets/app_widgets.dart';

final auditLogDetailsProvider = FutureProvider.family
    .autoDispose<Map<String, dynamic>, String>((ref, logId) async {
      final token = ref.watch(authControllerProvider).token;
      if (token == null) {
        throw const ApiException('يجب تسجيل الدخول أولًا.');
      }
      return ref
          .watch(apiServiceProvider)
          .getAuditLogDetails(token: token, logId: logId);
    });

class AuditLogDetailScreen extends ConsumerWidget {
  const AuditLogDetailScreen({super.key, required this.logId});

  final String logId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailsAsync = ref.watch(auditLogDetailsProvider(logId));

    return HomixPage(
      title: context.tr(ar: 'تفاصيل السجل', en: 'Log details'),
      header: AppBanner(
        title: context.tr(
          ar: 'تفاصيل كاملة لحدث المراجعة',
          en: 'Full details for the audit event',
        ),
        message: context.tr(
          ar: 'كل الحقول المهمة والبيانات الوصفية أصبحت مرتبة داخل شاشة فحص واحدة.',
          en: 'Core fields and metadata are now organized into a single inspection view.',
        ),
        icon: Icons.manage_search_rounded,
        background: AppColors.secondarySoft,
        foreground: AppColors.secondary,
      ),
      child: detailsAsync.when(
        data: (entry) {
          final createdAt = DateTime.tryParse(
            (entry['created_at'] ?? '').toString(),
          );
          final formatted = createdAt == null
              ? context.tr(ar: 'غير متاح', en: 'Unavailable')
              : DateFormat('yyyy/MM/dd • hh:mm a').format(createdAt.toLocal());
          final action = (entry['action'] ?? '').toString();
          final entityType = (entry['entity_type'] ?? '').toString();
          final entityId = (entry['entity_id'] ?? '').toString();
          final userId = (entry['user_id'] ?? '').toString();
          final metadata = _prettyJson((entry['metadata'] ?? '').toString());

          return ListView(
            children: [
              DashboardHero(
                title: action.isEmpty ? logId : _labelize(action),
                subtitle: formatted,
                chips: [
                  HeroTagChip(label: entityType.isEmpty ? '--' : entityType),
                  HeroTagChip(
                    label: userId.isEmpty
                        ? context.tr(ar: 'بدون مستخدم', en: 'No user')
                        : 'User $userId',
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
                        entityId.isEmpty ? '--' : '#$entityId',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        context.tr(ar: 'مرجع الكيان', en: 'Entity ref'),
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
                      label: context.tr(ar: 'الإجراء', en: 'Action'),
                      value: action.isEmpty ? '--' : _labelize(action),
                      color: AppColors.primary,
                      icon: Icons.bolt_rounded,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: StatTile(
                      label: context.tr(ar: 'الكيان', en: 'Entity'),
                      value: entityType.isEmpty ? '--' : entityType,
                      color: AppColors.accent,
                      icon: Icons.account_tree_rounded,
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
                      title: context.tr(ar: 'ملخص الحدث', en: 'Event summary'),
                      subtitle: context.tr(
                        ar: 'المعلومات الأساسية المطلوبة لفهم الحدث بسرعة.',
                        en: 'Core data required to understand the event quickly.',
                      ),
                    ),
                    const SizedBox(height: 12),
                    _DetailRow(
                      label: context.tr(ar: 'المستخدم', en: 'User'),
                      value: userId.isEmpty ? '--' : userId,
                    ),
                    _DetailRow(
                      label: context.tr(ar: 'نوع الكيان', en: 'Entity type'),
                      value: entityType.isEmpty ? '--' : entityType,
                    ),
                    _DetailRow(
                      label: context.tr(ar: 'معرف الكيان', en: 'Entity ID'),
                      value: entityId.isEmpty ? '--' : entityId,
                    ),
                    _DetailRow(
                      label: context.tr(ar: 'وقت الحدث', en: 'Timestamp'),
                      value: formatted,
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
                      title: context.tr(ar: 'Metadata', en: 'Metadata'),
                      subtitle: context.tr(
                        ar: 'عرض منسق للبيانات الوصفية المرتبطة بهذا الحدث.',
                        en: 'A formatted view of the metadata attached to this event.',
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.backgroundTertiary,
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: SelectableText(
                        metadata,
                        style: const TextStyle(
                          color: AppColors.textDark,
                          height: 1.5,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => AsyncPlaceholder(message: error.toString()),
      ),
    );
  }

  String _prettyJson(String raw) {
    if (raw.isEmpty) return '{}';
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

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

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
            width: 96,
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
