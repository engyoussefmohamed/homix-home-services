import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../constants/app_theme.dart';
import '../../core/app_localizations.dart';
import '../../core/app_router.dart';
import '../../providers/auth_controller.dart';
import '../../services/api_service.dart';
import '../../widgets/app_widgets.dart';

class CameraEstimationScreen extends ConsumerStatefulWidget {
  const CameraEstimationScreen({super.key});

  @override
  ConsumerState<CameraEstimationScreen> createState() =>
      _CameraEstimationScreenState();
}

class _CameraEstimationScreenState
    extends ConsumerState<CameraEstimationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _heightController = TextEditingController(text: '2.8');
  final _widthController = TextEditingController(text: '4.0');
  File? _selectedImage;
  bool _submitting = false;

  double get _previewArea {
    final height = double.tryParse(_heightController.text) ?? 0;
    final width = double.tryParse(_widthController.text) ?? 0;
    return height * width;
  }

  @override
  void dispose() {
    _heightController.dispose();
    _widthController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return HomixPage(
      title: context.tr(ar: 'تقدير التكلفة', en: 'Visual estimate'),
      header: AppBanner(
        title: context.tr(
          ar: 'قدّر المساحة قبل ما تشتري أو تحجز',
          en: 'Estimate before you buy or book',
        ),
        message: context.tr(
          ar: 'التجربة الجديدة تجعل رفع الصورة، إدخال المقاس، والانتقال للنتيجة أسرع وأكثر وضوحًا.',
          en: 'The refreshed flow makes upload, size entry, and result review faster and clearer.',
        ),
        icon: Icons.auto_awesome_rounded,
        background: AppColors.primarySoft,
        foreground: AppColors.primaryDark,
      ),
      child: ListView(
        children: [
          DashboardHero(
            title: context.tr(
              ar: 'صوّر الحائط وحدد المقاس وخذ تقديرًا سريعًا',
              en: 'Upload the wall, add size, and get a fast estimate',
            ),
            subtitle: context.tr(
              ar: 'رحلة التقدير البصري',
              en: 'Visual estimate flow',
            ),
            chips: [
              HeroTagChip(
                label: context.tr(ar: 'صورة أوضح', en: 'Clear photo'),
              ),
              HeroTagChip(
                label: context.tr(ar: 'مقاس صحيح', en: 'Correct size'),
              ),
              HeroTagChip(
                label: context.tr(ar: 'نتيجة فورية', en: 'Instant result'),
                highlight: true,
              ),
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
                    _selectedImage == null ? '0/3' : '1/3',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    context.tr(ar: 'خطوات مكتملة', en: 'Completed steps'),
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
          Row(
            children: [
              Expanded(
                child: _FlowStepTile(
                  icon: Icons.photo_camera_back_rounded,
                  color: AppColors.primary,
                  title: context.tr(
                    ar: '1. ارفع الصورة',
                    en: '1. Upload photo',
                  ),
                  subtitle: context.tr(
                    ar: 'صورة أمامية بإضاءة واضحة',
                    en: 'Front-facing photo with clear lighting',
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _FlowStepTile(
                  icon: Icons.straighten_rounded,
                  color: AppColors.accentDark,
                  title: context.tr(
                    ar: '2. أدخل المقاس',
                    en: '2. Add dimensions',
                  ),
                  subtitle: context.tr(
                    ar: 'الارتفاع والعرض بالمتر',
                    en: 'Height and width in meters',
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _FlowStepTile(
                  icon: Icons.insights_rounded,
                  color: AppColors.secondary,
                  title: context.tr(
                    ar: '3. راجع النتيجة',
                    en: '3. Review result',
                  ),
                  subtitle: context.tr(
                    ar: 'مقارنة أسرع قبل القرار',
                    en: 'Compare faster before deciding',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          AppSectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionHeading(
                  title: context.tr(ar: 'صورة الحائط', en: 'Wall photo'),
                  subtitle: context.tr(
                    ar: 'كلما كانت الصورة أنظف وأوضح، أصبحت النتيجة التقديرية أقرب للواقع.',
                    en: 'A cleaner and clearer image gives a more useful estimate.',
                  ),
                ),
                const SizedBox(height: 14),
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    height: 232,
                    width: double.infinity,
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          AppColors.background,
                          AppColors.backgroundTertiary,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: _selectedImage == null
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 72,
                                height: 72,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.85),
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                child: const Icon(
                                  Icons.camera_alt_rounded,
                                  size: 34,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(height: 14),
                              Text(
                                context.tr(
                                  ar: 'اضغط لاختيار صورة واضحة',
                                  en: 'Tap to choose a clear image',
                                ),
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                context.tr(
                                  ar: 'يُفضل تصوير الحائط كاملًا مع أقل قدر من الظلال',
                                  en: 'Try to capture the full wall with minimal shadows',
                                ),
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: AppColors.textMuted,
                                  fontWeight: FontWeight.w600,
                                  height: 1.6,
                                ),
                              ),
                            ],
                          )
                        : Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.file(_selectedImage!, fit: BoxFit.cover),
                              Positioned(
                                top: 14,
                                right: 14,
                                child: AppStatusBadge(
                                  label: context.tr(
                                    ar: 'جاهزة للتحليل',
                                    en: 'Ready to analyze',
                                  ),
                                  foreground: AppColors.success,
                                  background: AppColors.successSoft,
                                ),
                              ),
                              Positioned(
                                left: 14,
                                right: 14,
                                bottom: 14,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryDark.withValues(
                                      alpha: 0.72,
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.image_rounded,
                                        color: Colors.white,
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          _selectedImage!.path
                                              .split(Platform.pathSeparator)
                                              .last,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _pickImage,
                        icon: const Icon(Icons.file_upload_rounded),
                        label: Text(
                          _selectedImage == null
                              ? context.tr(
                                  ar: 'اختيار صورة',
                                  en: 'Choose image',
                                )
                              : context.tr(
                                  ar: 'تغيير الصورة',
                                  en: 'Change image',
                                ),
                        ),
                      ),
                    ),
                    if (_selectedImage != null) ...[
                      const SizedBox(width: 12),
                      TextButton.icon(
                        onPressed: () => setState(() => _selectedImage = null),
                        icon: const Icon(Icons.close_rounded),
                        label: Text(context.tr(ar: 'إزالة', en: 'Remove')),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          AppSectionCard(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SectionHeading(
                    title: context.tr(
                      ar: 'أدخل المقاس',
                      en: 'Enter dimensions',
                    ),
                    subtitle: context.tr(
                      ar: 'المقاس التقريبي يكفي للحصول على قراءة أسرع قبل المقارنة النهائية.',
                      en: 'Approximate dimensions are enough for a faster comparison.',
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: AppTextFormField(
                          controller: _heightController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          textDirection: TextDirection.ltr,
                          validator: _numberValidator,
                          decoration: InputDecoration(
                            labelText: context.tr(
                              ar: 'الارتفاع بالمتر',
                              en: 'Height in meters',
                            ),
                            prefixIcon: const Icon(Icons.height_rounded),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: AppTextFormField(
                          controller: _widthController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          textDirection: TextDirection.ltr,
                          validator: _numberValidator,
                          decoration: InputDecoration(
                            labelText: context.tr(
                              ar: 'العرض بالمتر',
                              en: 'Width in meters',
                            ),
                            prefixIcon: const Icon(Icons.straighten_rounded),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  AppSectionCard(
                    color: AppColors.primarySoft,
                    padding: const EdgeInsets.all(18),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                context.tr(
                                  ar: 'المساحة المبدئية',
                                  en: 'Estimated area',
                                ),
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                context.tr(
                                  ar: 'هذه القراءة تساعدنا نبني نتيجة أسرع وأكثر تنظيمًا.',
                                  en: 'This reading helps us generate a faster, more organized estimate.',
                                ),
                                style: const TextStyle(
                                  color: AppColors.textMuted,
                                  fontWeight: FontWeight.w600,
                                  height: 1.6,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '${_previewArea.toStringAsFixed(1)} ${context.tr(ar: 'م²', en: 'm²')}',
                          style: const TextStyle(
                            color: AppColors.primaryDark,
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  ElevatedButton.icon(
                    onPressed: _submitting ? null : _submit,
                    icon: const Icon(Icons.auto_awesome_rounded),
                    label: Text(
                      _submitting
                          ? context.tr(
                              ar: 'جارٍ إنشاء التقدير...',
                              en: 'Generating estimate...',
                            )
                          : context.tr(
                              ar: 'احسب التقدير الآن',
                              en: 'Generate estimate now',
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          AppBanner(
            title: context.tr(
              ar: 'نصائح لنتيجة أدق',
              en: 'Tips for a better result',
            ),
            message: context.tr(
              ar: 'صوّر الحائط كاملًا، تجنب الإضاءة الحادة جدًا، وحاول ألا تكون الصورة مائلة. بعد النتيجة يمكنك المتابعة للمتجر أو الرجوع لتقدير جديد.',
              en: 'Capture the full wall, avoid very harsh light, and keep the frame straight. After the result, you can continue to the shop or estimate again.',
            ),
            icon: Icons.tips_and_updates_rounded,
            background: AppColors.accentSoft,
            foreground: AppColors.accentDark,
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage() async {
    final result = await openFile(
      acceptedTypeGroups: const [
        XTypeGroup(label: 'images', extensions: ['jpg', 'jpeg', 'png']),
      ],
    );
    if (result == null) return;
    setState(() => _selectedImage = File(result.path));
  }

  String? _numberValidator(String? value) {
    final parsed = double.tryParse(value ?? '');
    if (parsed == null || parsed <= 0) {
      return context.tr(ar: 'أدخل رقمًا صحيحًا', en: 'Enter a valid number');
    }
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final token = ref.read(authControllerProvider).token;
    if (token == null) return;

    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.tr(
              ar: 'اختر صورة أولًا لإكمال التقدير',
              en: 'Choose an image first to continue',
            ),
          ),
        ),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      final estimate = await ref
          .read(apiServiceProvider)
          .submitEstimate(
            token: token,
            image: _selectedImage!,
            height: double.parse(_heightController.text),
            width: double.parse(_widthController.text),
          );
      if (!mounted) return;
      context.push(AppRoutes.estimationResult, extra: estimate);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }
}

class _FlowStepTile extends StatelessWidget {
  const _FlowStepTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return AppSectionCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
