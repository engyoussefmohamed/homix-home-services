import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../constants/app_theme.dart';
import '../../core/app_router.dart';
import '../../models/app_user.dart';
import '../../models/technician_profile.dart';
import '../../providers/auth_controller.dart';
import '../../services/api_service.dart';
import '../../widgets/app_widgets.dart';

final techniciansProvider = FutureProvider.autoDispose
    .family<List<TechnicianProfile>, TechnicianQuery>((ref, query) {
      return ref
          .watch(apiServiceProvider)
          .getTechnicians(query: query.searchQuery, category: query.category);
    });

class CustomerHomeScreen extends ConsumerStatefulWidget {
  const CustomerHomeScreen({super.key});

  @override
  ConsumerState<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends ConsumerState<CustomerHomeScreen> {
  final _searchController = TextEditingController();
  String _selectedCategory = 'الكل';
  String _query = '';

  static const List<String> _categories = [
    'الكل',
    'سباكة',
    'كهرباء',
    'دهانات',
    'تشطيب',
    'نجارة',
    'تكييف',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider).user;
    final firstName = user?.name.split(' ').first ?? 'عميل';
    final isAdmin = user?.role == UserRole.admin;
    final techniciansAsync = ref.watch(
      techniciansProvider(
        TechnicianQuery(searchQuery: _query, category: _selectedCategory),
      ),
    );
    final technicians =
        techniciansAsync.asData?.value ?? const <TechnicianProfile>[];
    final availableCount = technicians.where((item) => item.isAvailable).length;
    final avgResponse = technicians.isEmpty
        ? 0
        : (technicians
                      .map((item) => item.responseMinutes)
                      .reduce((a, b) => a + b) /
                  technicians.length)
              .round();

    return ListView(
      children: [
        DashboardHero(
          title: 'احجز فني، قارن الخيارات، وجهّز بيتك من واجهة واحدة',
          subtitle: 'أهلًا $firstName',
          chips: const [
            HeroTagChip(label: 'رحلة أسهل'),
            HeroTagChip(label: 'حجز أسرع'),
            HeroTagChip(label: 'واجهة مبهرة', highlight: true),
          ],
          trailing: Container(
            width: 104,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Column(
              children: [
                Text(
                  '${technicians.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  'فني متاح الآن',
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
              child: MetricPill(
                label: 'المتاح الآن',
                value: availableCount == 0 ? '--' : '$availableCount',
                background: AppColors.primarySoft,
                valueColor: AppColors.primaryDark,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: MetricPill(
                label: 'متوسط الرد',
                value: avgResponse == 0 ? '--' : '$avgResponse دقيقة',
                background: AppColors.secondarySoft,
                valueColor: AppColors.secondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        AppSectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'ابحث عن الفني أو الخدمة المناسبة',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 6),
              const Text(
                'اكتب التخصص أو المنطقة أو اسم الفني لتصل إلى النتائج بسرعة.',
                style: TextStyle(
                  color: AppColors.textMuted,
                  height: 1.6,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 14),
              AppTextField(
                controller: _searchController,
                onChanged: (value) => setState(() => _query = value.trim()),
                textDirection: TextDirection.rtl,
                decoration: InputDecoration(
                  hintText: 'ابحث عن فني أو تخصص أو منطقة...',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _query.isEmpty
                      ? null
                      : IconButton(
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _query = '');
                          },
                          icon: const Icon(Icons.close_rounded),
                        ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        const SectionHeading(
          title: 'ابدأ من أهم ما يهم العميل',
          subtitle: 'مسارات سريعة ومصممة لتختصر الوقت وتوضح القرار',
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _QuickActionCard(
                title: 'تقدير الدهانات',
                subtitle: 'ارفع صورة واحصل على تصور أسرع للتكلفة',
                icon: Icons.camera_alt_rounded,
                color: AppColors.primary,
                onTap: () => context.push(AppRoutes.cameraEstimation),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _QuickActionCard(
                title: 'المتجر',
                subtitle: 'خامات معتمدة وطلبات جاهزة للشراء',
                icon: Icons.storefront_rounded,
                color: AppColors.accent,
                onTap: () => context.go(AppRoutes.customerHome, extra: 2),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const AppBanner(
          title: 'اقتراحات Homix',
          message:
              'التصميم الجديد يبرز القيمة بسرعة: ابحث، قارن، ثم انتقل إلى التنفيذ داخل نفس التجربة.',
          icon: Icons.auto_awesome_rounded,
          background: AppColors.accentSoft,
          foreground: AppColors.accentDark,
        ),
        if (isAdmin) ...[
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => context.push(AppRoutes.adminDashboard),
            icon: const Icon(Icons.admin_panel_settings_rounded),
            label: const Text('الانتقال إلى لوحة الإدارة'),
          ),
        ],
        const SizedBox(height: 20),
        const SectionHeading(
          title: 'التخصصات',
          subtitle: 'فلترة سريعة حسب نوع الخدمة المطلوبة',
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 98,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _categories.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final category = _categories[index];
              return CategoryChip(
                label: category,
                icon: _categoryIcon(category),
                selected: _selectedCategory == category,
                onTap: () => setState(() => _selectedCategory = category),
                iconBackground: _categoryBackground(category),
              );
            },
          ),
        ),
        const SizedBox(height: 20),
        techniciansAsync.when(
          data: (items) => Column(
            children: [
              SectionHeading(
                title: 'فنيون مقترحون',
                subtitle: '${items.length} نتيجة مناسبة للبحث الحالي',
              ),
              const SizedBox(height: 12),
              if (items.isEmpty)
                const AsyncPlaceholder(
                  message:
                      'لا توجد نتائج مطابقة الآن. جرّب فلترًا مختلفًا أو ابحث باسم آخر.',
                )
              else
                ...items.map(
                  (employee) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _EmployeeCard(
                      employee: employee,
                      onTap: () => context.push(
                        AppRoutes.technicianJourney,
                        extra: employee,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (error, _) => AsyncPlaceholder(message: error.toString()),
        ),
      ],
    );
  }

  IconData _categoryIcon(String category) {
    switch (category) {
      case 'سباكة':
        return Icons.plumbing_rounded;
      case 'كهرباء':
        return Icons.electrical_services_rounded;
      case 'دهانات':
        return Icons.format_color_fill_rounded;
      case 'تشطيب':
        return Icons.construction_rounded;
      case 'نجارة':
        return Icons.handyman_rounded;
      case 'تكييف':
        return Icons.ac_unit_rounded;
      default:
        return Icons.dashboard_customize_rounded;
    }
  }

  Color _categoryBackground(String category) {
    switch (category) {
      case 'سباكة':
        return AppColors.iconGreenSoft;
      case 'كهرباء':
        return AppColors.iconGoldSoft;
      case 'دهانات':
        return AppColors.iconRedSoft;
      default:
        return AppColors.iconBlueSoft;
    }
  }
}

class TechnicianQuery {
  const TechnicianQuery({required this.searchQuery, required this.category});

  final String searchQuery;
  final String category;

  @override
  bool operator ==(Object other) {
    return other is TechnicianQuery &&
        other.searchQuery == searchQuery &&
        other.category == category;
  }

  @override
  int get hashCode => Object.hash(searchQuery, category);
}

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: AppSectionCard(
        color: color.withValues(alpha: 0.08),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color, AppColors.primaryDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(icon, color: Colors.white),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: const TextStyle(
                color: AppColors.textMuted,
                height: 1.6,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Text(
                  'ابدأ الآن',
                  style: TextStyle(color: color, fontWeight: FontWeight.w900),
                ),
                const Spacer(),
                Icon(Icons.arrow_forward_rounded, color: color),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EmployeeCard extends StatelessWidget {
  const _EmployeeCard({required this.employee, required this.onTap});

  final TechnicianProfile employee;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: AppSectionCard(
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: employee.accent,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Icon(employee.icon, color: AppColors.primaryDark),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        employee.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 17,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${employee.title} • ${employee.city}',
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                AppStatusBadge(
                  label: employee.isAvailable ? 'متاح' : 'مشغول',
                  foreground: employee.isAvailable
                      ? AppColors.success
                      : AppColors.accentDark,
                  background: employee.isAvailable
                      ? AppColors.successSoft
                      : AppColors.accentSoft,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: MetricPill(
                    label: 'التقييم',
                    value: '${employee.rating}',
                    background: AppColors.accentSoft,
                    valueColor: AppColors.accentDark,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: MetricPill(
                    label: 'سرعة الرد',
                    value: '${employee.responseMinutes} د',
                    background: AppColors.primarySoft,
                    valueColor: AppColors.primaryDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                if (employee.subscription.verifiedBadge)
                  const Padding(
                    padding: EdgeInsetsDirectional.only(end: 8),
                    child: AppStatusBadge(
                      label: 'موثق',
                      foreground: AppColors.success,
                      background: AppColors.successSoft,
                    ),
                  ),
                if (employee.subscription.isPro)
                  const Padding(
                    padding: EdgeInsetsDirectional.only(end: 8),
                    child: AppStatusBadge(
                      label: 'Pro',
                      foreground: AppColors.primary,
                      background: AppColors.primarySoft,
                    ),
                  ),
                Expanded(
                  child: Text(
                    '${employee.jobsDone} مهمة • ${employee.hourlyRate} ج.م/ساعة',
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_rounded,
                  color: AppColors.primary,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
