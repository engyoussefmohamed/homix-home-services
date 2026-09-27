import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../constants/app_theme.dart';
import '../../core/app_localizations.dart';
import '../../providers/auth_controller.dart';
import '../../services/api_service.dart';
import '../../widgets/app_widgets.dart';

class AddProductScreen extends ConsumerStatefulWidget {
  const AddProductScreen({super.key});

  @override
  ConsumerState<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends ConsumerState<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _description = TextEditingController();
  final _volume = TextEditingController(text: '18');
  final _price = TextEditingController();
  bool _loading = false;

  int get _completedFields {
    var total = 0;
    if (_name.text.trim().isNotEmpty) total++;
    if (_description.text.trim().isNotEmpty) total++;
    if (double.tryParse(_volume.text.trim()) != null) total++;
    if (double.tryParse(_price.text.trim()) != null) total++;
    return total;
  }

  String get _previewName => _name.text.trim().isEmpty
      ? context.tr(ar: 'اسم المنتج سيظهر هنا', en: 'Product name appears here')
      : _name.text.trim();

  String get _previewDescription => _description.text.trim().isEmpty
      ? context.tr(
          ar: 'الوصف المختصر يساعد العميل على فهم المنتج بسرعة.',
          en: 'A short description helps customers understand the product quickly.',
        )
      : _description.text.trim();

  @override
  void initState() {
    super.initState();
    for (final controller in [_name, _description, _volume, _price]) {
      controller.addListener(_refreshPreview);
    }
  }

  @override
  void dispose() {
    for (final controller in [_name, _description, _volume, _price]) {
      controller.removeListener(_refreshPreview);
    }
    _name.dispose();
    _description.dispose();
    _volume.dispose();
    _price.dispose();
    super.dispose();
  }

  void _refreshPreview() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final volumeValue = double.tryParse(_volume.text.trim()) ?? 0;
    final priceValue = double.tryParse(_price.text.trim()) ?? 0;

    return HomixPage(
      title: context.tr(ar: 'إضافة منتج', en: 'Add product'),
      header: AppBanner(
        title: context.tr(
          ar: 'أضف منتجك بشكل يليق بصورة المتجر',
          en: 'Add your product in a way that reflects your shop quality',
        ),
        message: context.tr(
          ar: 'رتبنا الإدخال والمعاينة في شاشة واحدة حتى ترى المنتج كما سيظهر تقريبًا قبل إرساله للمراجعة.',
          en: 'Input and preview are now organized in one place so you can see how the product may appear before submission.',
        ),
        icon: Icons.inventory_2_rounded,
        background: AppColors.accentSoft,
        foreground: AppColors.accentDark,
      ),
      child: ListView(
        children: [
          DashboardHero(
            title: context.tr(
              ar: 'أدخل بيانات المنتج بثقة',
              en: 'Enter product details with confidence',
            ),
            subtitle: context.tr(
              ar: 'كلما كانت المعلومات أوضح، صار اعتماد المنتج أسرع داخل المتجر.',
              en: 'The clearer the information, the faster the product approval.',
            ),
            chips: [
              HeroTagChip(
                label: context.tr(ar: 'اسم واضح', en: 'Clear name'),
              ),
              HeroTagChip(
                label: context.tr(ar: 'سعر دقيق', en: 'Precise price'),
              ),
              HeroTagChip(
                label: context.tr(ar: 'وصف مقنع', en: 'Strong description'),
                highlight: true,
              ),
            ],
            trailing: Container(
              width: 110,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: Column(
                children: [
                  Text(
                    '$_completedFields/4',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    context.tr(ar: 'اكتمال البيانات', en: 'Field completion'),
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
                  label: context.tr(
                    ar: 'حالة الإرسال',
                    en: 'Submission status',
                  ),
                  value: context.tr(ar: 'جاهز للمراجعة', en: 'Review-ready'),
                  color: AppColors.accent,
                  icon: Icons.rate_review_rounded,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatTile(
                  label: context.tr(ar: 'حقول مكتملة', en: 'Completed fields'),
                  value: '$_completedFields/4',
                  color: AppColors.primary,
                  icon: Icons.checklist_rounded,
                ),
              ),
            ],
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
                      ar: 'بيانات المنتج',
                      en: 'Product details',
                    ),
                    subtitle: context.tr(
                      ar: 'اكتب المعلومات التي ستظهر للعميل وللمراجع بنفس الوقت.',
                      en: 'Enter the details that both customers and reviewers will see.',
                    ),
                  ),
                  const SizedBox(height: 12),
                  AppTextFormField(
                    controller: _name,
                    decoration: InputDecoration(
                      labelText: context.tr(
                        ar: 'اسم المنتج',
                        en: 'Product name',
                      ),
                      prefixIcon: const Icon(Icons.inventory_2_rounded),
                    ),
                    textDirection: TextDirection.rtl,
                    validator: _required,
                  ),
                  const SizedBox(height: 14),
                  AppTextFormField(
                    controller: _description,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: context.tr(
                        ar: 'وصف المنتج',
                        en: 'Product description',
                      ),
                      prefixIcon: const Icon(Icons.notes_rounded),
                    ),
                    textDirection: TextDirection.rtl,
                    validator: _required,
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: AppTextFormField(
                          controller: _volume,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: InputDecoration(
                            labelText: context.tr(
                              ar: 'الحجم باللتر',
                              en: 'Volume in liters',
                            ),
                            prefixIcon: const Icon(Icons.scale_rounded),
                          ),
                          textDirection: TextDirection.ltr,
                          validator: _numberValidator,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: AppTextFormField(
                          controller: _price,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: InputDecoration(
                            labelText: context.tr(
                              ar: 'السعر بالجنيه',
                              en: 'Price in EGP',
                            ),
                            prefixIcon: const Icon(Icons.payments_rounded),
                          ),
                          textDirection: TextDirection.ltr,
                          validator: _numberValidator,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: MetricPill(
                          label: context.tr(
                            ar: 'الحجم الحالي',
                            en: 'Current volume',
                          ),
                          value: volumeValue > 0
                              ? '${volumeValue.toStringAsFixed(volumeValue.truncateToDouble() == volumeValue ? 0 : 1)} ${context.tr(ar: 'لتر', en: 'L')}'
                              : '--',
                          background: AppColors.primarySoft,
                          valueColor: AppColors.primaryDark,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: MetricPill(
                          label: context.tr(
                            ar: 'السعر الحالي',
                            en: 'Current price',
                          ),
                          value: priceValue > 0
                              ? '${priceValue.toStringAsFixed(priceValue.truncateToDouble() == priceValue ? 0 : 1)} ${context.tr(ar: 'ج.م', en: 'EGP')}'
                              : '--',
                          background: AppColors.accentSoft,
                          valueColor: AppColors.accentDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                    ),
                    onPressed: _loading ? null : _submit,
                    child: Text(
                      _loading
                          ? context.tr(
                              ar: 'جارٍ الإرسال...',
                              en: 'Submitting...',
                            )
                          : context.tr(
                              ar: 'إرسال للمراجعة',
                              en: 'Submit for review',
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          AppSectionCard(
            color: AppColors.secondarySoft,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionHeading(
                  title: context.tr(ar: 'معاينة سريعة', en: 'Quick preview'),
                  subtitle: context.tr(
                    ar: 'هذا ملخص بصري يساعدك على رؤية المنتج قبل إرساله.',
                    en: 'A visual summary that helps you preview the product before submission.',
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.76),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  AppColors.accentDark,
                                  AppColors.accent,
                                ],
                                begin: Alignment.topRight,
                                end: Alignment.bottomLeft,
                              ),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: const Icon(
                              Icons.inventory_2_rounded,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _previewName,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _previewDescription,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: AppColors.textMuted,
                                    height: 1.5,
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
                            child: _PreviewInfo(
                              label: context.tr(ar: 'الحجم', en: 'Volume'),
                              value: volumeValue > 0
                                  ? '${volumeValue.toStringAsFixed(volumeValue.truncateToDouble() == volumeValue ? 0 : 1)} ${context.tr(ar: 'لتر', en: 'L')}'
                                  : '--',
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _PreviewInfo(
                              label: context.tr(ar: 'السعر', en: 'Price'),
                              value: priceValue > 0
                                  ? '${priceValue.toStringAsFixed(priceValue.truncateToDouble() == priceValue ? 0 : 1)} ${context.tr(ar: 'ج.م', en: 'EGP')}'
                                  : '--',
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
          const SizedBox(height: 16),
          AppBanner(
            title: context.tr(ar: 'مهم قبل الإرسال', en: 'Before you submit'),
            message: context.tr(
              ar: 'اكتب اسم المنتج كما سيظهر للعميل، واستخدم وصفًا مختصرًا يوضح الفائدة بسرعة داخل المتجر.',
              en: 'Write the name exactly as customers should see it, and use a short description that communicates value quickly.',
            ),
            icon: Icons.info_outline_rounded,
          ),
        ],
      ),
    );
  }

  String? _required(String? value) => (value == null || value.trim().isEmpty)
      ? context.tr(ar: 'هذا الحقل مطلوب', en: 'This field is required')
      : null;

  String? _numberValidator(String? value) =>
      double.tryParse(value ?? '') == null
      ? context.tr(ar: 'أدخل رقمًا صحيحًا', en: 'Enter a valid number')
      : null;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final token = ref.read(authControllerProvider).token;
    if (token == null) return;

    setState(() => _loading = true);
    try {
      await ref
          .read(apiServiceProvider)
          .addProduct(
            token: token,
            name: _name.text.trim(),
            description: _description.text.trim(),
            volumeLiters: double.parse(_volume.text.trim()),
            price: double.parse(_price.text.trim()),
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.tr(
              ar: 'تم إرسال المنتج للمراجعة',
              en: 'Product submitted for review',
            ),
          ),
        ),
      );
      Navigator.pop(context);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}

class _PreviewInfo extends StatelessWidget {
  const _PreviewInfo({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.backgroundTertiary,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}
