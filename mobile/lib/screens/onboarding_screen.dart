import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../constants/app_theme.dart';
import '../core/app_localizations.dart';
import '../core/app_router.dart';
import '../widgets/app_widgets.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  late final PageController _pageController;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String t(String ar, String en) => context.tr(ar: ar, en: en);
    final pages = [
      _OnboardingPageData(
        eyebrow: t('رؤية أوضح قبل التنفيذ', 'See the work before it starts'),
        icon: Icons.camera_alt_rounded,
        accent: AppColors.primary,
        title: t(
          'صوّر المكان واحصل على تقدير يبدو احترافيًا من أول ثانية',
          'Capture the space and get a premium-feeling estimate instantly',
        ),
        subtitle: t(
          'ابدأ من الصورة، ثم اعرف تكلفة الدهانات والخامات بسرعة داخل تجربة أنيقة وواضحة.',
          'Start from a photo, then understand paint and materials costs in a polished, clear flow.',
        ),
        highlights: [
          _HighlightData(
            value: t('صورة', 'Photo'),
            label: t('بداية سريعة بدون تعقيد', 'Fast start without friction'),
          ),
          _HighlightData(
            value: t('تكلفة', 'Cost'),
            label: t(
              'مقارنة أوضح قبل القرار',
              'Clearer comparison before deciding',
            ),
          ),
        ],
        points: [
          t(
            'مناسب للتجديدات المنزلية والقرارات السريعة',
            'Built for quick home renovation decisions',
          ),
          t(
            'واجهة عربية واضحة مع إحساس حديث وفخم',
            'Arabic-first interface with a modern premium feel',
          ),
          t(
            'ينقل العميل من الفضول إلى القرار بثقة',
            'Moves the user from curiosity to confident action',
          ),
        ],
      ),
      _OnboardingPageData(
        eyebrow: t(
          'خدمة موثوقة يمكن متابعتها',
          'Trusted service you can follow',
        ),
        icon: Icons.engineering_rounded,
        accent: AppColors.secondary,
        title: t(
          'ابحث عن الفني المناسب وتابع الرحلة كأنها concierge service',
          'Find the right technician and follow the journey like a concierge service',
        ),
        subtitle: t(
          'كل خطوة مرتبة بصريًا من الترشيح وحتى التنفيذ، مع إحساس بالثقة والوضوح.',
          'Every step is visually organized from discovery to delivery, with trust and clarity built in.',
        ),
        highlights: [
          _HighlightData(
            value: t('موثوق', 'Trusted'),
            label: t(
              'واجهات تركّز على الاعتماد والسرعة',
              'Designed around trust and speed',
            ),
          ),
          _HighlightData(
            value: t('مباشر', 'Live'),
            label: t(
              'متابعة للحجز والتحديثات داخل التطبيق',
              'Track bookings and updates inside the app',
            ),
          ),
        ],
        points: [
          t(
            'فلترة أسرع حسب نوع الخدمة والموقع',
            'Faster filtering by service type and location',
          ),
          t(
            'عرض بيانات الفني بشكل يسهل المقارنة',
            'Technician details presented for quick comparison',
          ),
          t(
            'تجربة أقرب لمنتج premium من منصة خدمات عادية',
            'Feels more premium than a typical services app',
          ),
        ],
      ),
      _OnboardingPageData(
        eyebrow: t('من التقدير إلى الشراء', 'From estimate to purchase'),
        icon: Icons.storefront_rounded,
        accent: AppColors.accent,
        title: t(
          'المتجر، الطلبات، ولوحات المتابعة كلها داخل نظام واحد متناسق',
          'Shop, orders, and dashboards all live in one cohesive system',
        ),
        subtitle: t(
          'التطبيق يوحّد التجربة للعميل وصاحب المتجر والفني داخل هوية واحدة متقنة.',
          'The app unifies customer, shop owner, and technician journeys under one refined identity.',
        ),
        highlights: [
          _HighlightData(
            value: '3',
            label: t('رحلات استخدام أساسية', 'Core role journeys'),
          ),
          _HighlightData(
            value: '1',
            label: t('هوية بصرية متصلة', 'Connected visual identity'),
          ),
        ],
        points: [
          t(
            'سهولة انتقال بين الأدوار والمهام الأساسية',
            'Smooth movement between core flows and roles',
          ),
          t(
            'ألوان ومساحات تعطي انطباعًا أقوى للعميل',
            'Color and spacing tuned for stronger client impact',
          ),
          t(
            'رحلة تبان جاهزة للعرض أمام أي عميل أو مستثمر',
            'A journey ready to be shown to clients or investors',
          ),
        ],
      ),
    ];

    final page = pages[_index];

    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(
            child: AppAtmosphere(
              topColor: AppColors.background,
              bottomColor: AppColors.backgroundTertiary,
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 16, 22, 22),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 9,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.cardWhite.withValues(alpha: 0.84),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: AppColors.border.withValues(alpha: 0.65),
                          ),
                        ),
                        child: const Text(
                          'Homix',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            color: AppColors.primaryDark,
                          ),
                        ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () => context.go(AppRoutes.login),
                        child: Text(t('تخطي', 'Skip')),
                      ),
                      const SizedBox(width: 6),
                      const LanguageToggleButton(),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: PageView.builder(
                      controller: _pageController,
                      itemCount: pages.length,
                      onPageChanged: (value) => setState(() => _index = value),
                      itemBuilder: (context, index) {
                        final item = pages[index];
                        return SingleChildScrollView(
                          child: Column(
                            children: [
                              Container(
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      item.accent.withValues(alpha: 0.92),
                                      AppColors.primaryDark,
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(34),
                                  boxShadow: [
                                    BoxShadow(
                                      color: item.accent.withValues(
                                        alpha: 0.24,
                                      ),
                                      blurRadius: 28,
                                      offset: const Offset(0, 14),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  item.icon,
                                  color: Colors.white,
                                  size: 56,
                                ),
                              ),
                              const SizedBox(height: 22),
                              Text(
                                item.eyebrow,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: item.accent,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                item.title,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 30,
                                  fontWeight: FontWeight.w900,
                                  height: 1.25,
                                ),
                              ),
                              const SizedBox(height: 14),
                              Text(
                                item.subtitle,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 16,
                                  height: 1.8,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 22),
                              Row(
                                children: [
                                  Expanded(
                                    child: StatTile(
                                      label: item.highlights[0].label,
                                      value: item.highlights[0].value,
                                      color: item.accent,
                                      icon: item.icon,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: StatTile(
                                      label: item.highlights[1].label,
                                      value: item.highlights[1].value,
                                      color: AppColors.primary,
                                      icon: Icons.auto_awesome_rounded,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 18),
                              AppSectionCard(
                                child: Column(
                                  children: item.points
                                      .map(
                                        (point) => Padding(
                                          padding: const EdgeInsets.only(
                                            bottom: 12,
                                          ),
                                          child: Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Container(
                                                width: 28,
                                                height: 28,
                                                decoration: BoxDecoration(
                                                  color: item.accent.withValues(
                                                    alpha: 0.12,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                ),
                                                child: Icon(
                                                  Icons.check_rounded,
                                                  color: item.accent,
                                                  size: 18,
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Text(
                                                  point,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.w700,
                                                    height: 1.65,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      )
                                      .toList(),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      pages.length,
                      (i) => AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        width: _index == i ? 28 : 8,
                        height: 8,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          color: _index == i ? page.accent : AppColors.border,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      if (_index > 0)
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => _pageController.previousPage(
                              duration: const Duration(milliseconds: 280),
                              curve: Curves.easeOutCubic,
                            ),
                            child: Text(t('السابق', 'Back')),
                          ),
                        ),
                      if (_index > 0) const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            if (_index == pages.length - 1) {
                              context.go(AppRoutes.login);
                            } else {
                              _pageController.nextPage(
                                duration: const Duration(milliseconds: 280),
                                curve: Curves.easeOutCubic,
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: page.accent,
                          ),
                          icon: Icon(
                            _index == pages.length - 1
                                ? Icons.arrow_forward_rounded
                                : Icons.auto_awesome_rounded,
                          ),
                          label: Text(
                            _index == pages.length - 1
                                ? t('ابدأ الآن', 'Get started')
                                : t('التالي', 'Next'),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardingPageData {
  const _OnboardingPageData({
    required this.eyebrow,
    required this.icon,
    required this.accent,
    required this.title,
    required this.subtitle,
    required this.highlights,
    required this.points,
  });

  final String eyebrow;
  final IconData icon;
  final Color accent;
  final String title;
  final String subtitle;
  final List<_HighlightData> highlights;
  final List<String> points;
}

class _HighlightData {
  const _HighlightData({required this.value, required this.label});

  final String value;
  final String label;
}
