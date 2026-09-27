import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' as intl;

import '../constants/app_theme.dart';
import '../core/app_localizations.dart';
import '../models/estimate_record.dart';
import '../providers/locale_controller.dart';

class AppAtmosphere extends StatelessWidget {
  const AppAtmosphere({
    super.key,
    this.topColor = AppColors.background,
    this.bottomColor = AppColors.backgroundTertiary,
  });

  final Color topColor;
  final Color bottomColor;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            topColor,
            Color.lerp(topColor, bottomColor, 0.55) ?? topColor,
            bottomColor,
          ],
        ),
      ),
      child: const Stack(
        children: [
          Positioned(
            top: -90,
            left: -55,
            child: _AtmosphereOrb(
              size: 220,
              color: AppColors.primarySoft,
              opacity: 0.72,
            ),
          ),
          Positioned(
            top: 84,
            right: -55,
            child: _AtmosphereOrb(
              size: 190,
              color: AppColors.accentSoft,
              opacity: 0.8,
            ),
          ),
          Positioned(
            bottom: -80,
            left: 12,
            child: _AtmosphereOrb(
              size: 170,
              color: AppColors.secondarySoft,
              opacity: 0.74,
            ),
          ),
          Positioned(
            top: 118,
            left: 34,
            child: _AtmosphereRing(size: 88, color: AppColors.primary),
          ),
          Positioned(
            bottom: 154,
            right: 20,
            child: _AtmosphereRing(size: 64, color: AppColors.accent),
          ),
        ],
      ),
    );
  }
}

class _AtmosphereOrb extends StatelessWidget {
  const _AtmosphereOrb({
    required this.size,
    required this.color,
    required this.opacity,
  });

  final double size;
  final Color color;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color.withValues(alpha: opacity),
            color.withValues(alpha: 0.08),
            Colors.transparent,
          ],
        ),
      ),
    );
  }
}

class _AtmosphereRing extends StatelessWidget {
  const _AtmosphereRing({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: color.withValues(alpha: 0.18), width: 1.4),
      ),
    );
  }
}

class HomixPage extends StatelessWidget {
  const HomixPage({
    super.key,
    required this.title,
    required this.child,
    this.actions = const [],
    this.bottomNavigationBar,
    this.header,
  });

  final String title;
  final Widget child;
  final List<Widget> actions;
  final Widget? bottomNavigationBar;
  final Widget? header;

  @override
  Widget build(BuildContext context) {
    final bottomPadding = bottomNavigationBar == null ? 16.0 : 108.0;
    return Scaffold(
      extendBody: true,
      appBar: AppBar(
        title: Text(title),
        actions: [const LanguageToggleButton(), ...actions],
      ),
      bottomNavigationBar: bottomNavigationBar,
      body: Stack(
        children: [
          const Positioned.fill(child: AppAtmosphere()),
          SafeArea(
            child: Column(
              children: [
                if (header != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                    child: header!,
                  ),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(20, 10, 20, bottomPadding),
                    child: child,
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

class LanguageToggleButton extends ConsumerWidget {
  const LanguageToggleButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localeController = ref.watch(localeControllerProvider);
    return Padding(
      padding: const EdgeInsetsDirectional.only(end: 8),
      child: Tooltip(
        message: context.tr(
          ar: 'التحويل إلى الإنجليزية',
          en: 'Switch to Arabic',
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.backgroundTertiary.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: AppColors.border.withValues(alpha: 0.7)),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadow.withValues(alpha: 0.06),
                blurRadius: 14,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: TextButton.icon(
            key: const Key('language-toggle-button'),
            onPressed: () =>
                ref.read(localeControllerProvider).toggleLanguage(),
            icon: const Icon(Icons.translate_rounded, size: 18),
            label: Text(localeController.isArabic ? 'EN' : 'AR'),
          ),
        ),
      ),
    );
  }
}

class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    this.controller,
    this.decoration = const InputDecoration(),
    this.keyboardType,
    this.maxLines = 1,
    this.minLines,
    this.obscureText = false,
    this.enabled = true,
    this.onChanged,
    this.textDirection,
    this.hintLocales,
    this.textCapitalization = TextCapitalization.none,
  });

  final TextEditingController? controller;
  final InputDecoration decoration;
  final TextInputType? keyboardType;
  final int? maxLines;
  final int? minLines;
  final bool obscureText;
  final bool enabled;
  final ValueChanged<String>? onChanged;
  final TextDirection? textDirection;
  final List<Locale>? hintLocales;
  final TextCapitalization textCapitalization;

  @override
  Widget build(BuildContext context) {
    final resolvedDirection = textDirection ?? Directionality.of(context);
    final isRtl = resolvedDirection == TextDirection.rtl;
    return TextField(
      controller: controller,
      decoration: decoration,
      keyboardType: keyboardType,
      maxLines: maxLines,
      minLines: minLines,
      obscureText: obscureText,
      enabled: enabled,
      onChanged: onChanged,
      hintLocales: hintLocales,
      textDirection: resolvedDirection,
      textAlign: isRtl ? TextAlign.right : TextAlign.left,
      textCapitalization: textCapitalization,
      style: Theme.of(context).textTheme.bodyLarge,
    );
  }
}

class AppTextFormField extends StatelessWidget {
  const AppTextFormField({
    super.key,
    this.controller,
    this.decoration = const InputDecoration(),
    this.keyboardType,
    this.maxLines = 1,
    this.minLines,
    this.obscureText = false,
    this.enabled = true,
    this.validator,
    this.onChanged,
    this.textDirection,
    this.hintLocales,
    this.textCapitalization = TextCapitalization.none,
  });

  final TextEditingController? controller;
  final InputDecoration decoration;
  final TextInputType? keyboardType;
  final int? maxLines;
  final int? minLines;
  final bool obscureText;
  final bool enabled;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onChanged;
  final TextDirection? textDirection;
  final List<Locale>? hintLocales;
  final TextCapitalization textCapitalization;

  @override
  Widget build(BuildContext context) {
    final resolvedDirection = textDirection ?? Directionality.of(context);
    final isRtl = resolvedDirection == TextDirection.rtl;
    return TextFormField(
      controller: controller,
      decoration: decoration,
      keyboardType: keyboardType,
      maxLines: maxLines,
      minLines: minLines,
      obscureText: obscureText,
      enabled: enabled,
      validator: validator,
      onChanged: onChanged,
      hintLocales: hintLocales,
      textDirection: resolvedDirection,
      textAlign: isRtl ? TextAlign.right : TextAlign.left,
      textCapitalization: textCapitalization,
      style: Theme.of(context).textTheme.bodyLarge,
    );
  }
}

class AppSectionCard extends StatelessWidget {
  const AppSectionCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.color,
  });

  final Widget child;
  final EdgeInsets padding;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final baseColor = color ?? AppColors.cardWhite;
    final topColor = Color.lerp(baseColor, Colors.white, 0.24) ?? baseColor;
    final rimColor =
        Color.lerp(baseColor, AppColors.border, 0.35) ?? AppColors.border;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [topColor, baseColor],
        ),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: rimColor.withValues(alpha: 0.85)),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withValues(alpha: 0.08),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.55),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 58,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withValues(alpha: 0.22),
                    Colors.white.withValues(alpha: 0.02),
                  ],
                ),
              ),
            ),
          ),
          Padding(padding: padding, child: child),
        ],
      ),
    );
  }
}

class DashboardHero extends StatelessWidget {
  const DashboardHero({
    super.key,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.searchHint,
    this.chips = const [],
  });

  final String title;
  final String subtitle;
  final Widget? trailing;
  final String? searchHint;
  final List<Widget> chips;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      padding: const EdgeInsets.all(24),
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
        borderRadius: BorderRadius.circular(36),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withValues(alpha: 0.24),
            blurRadius: 30,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: -44,
            right: -26,
            child: Container(
              width: 146,
              height: 146,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.white.withValues(alpha: 0.18),
                    Colors.white.withValues(alpha: 0.02),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -70,
            left: -30,
            child: Container(
              width: 152,
              height: 152,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.accent.withValues(alpha: 0.24),
                    AppColors.accent.withValues(alpha: 0.04),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.accent,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 29,
                        fontWeight: FontWeight.w900,
                        height: 1.2,
                      ),
                    ),
                  ),
                  if (trailing != null) ...[
                    const SizedBox(width: 14),
                    trailing!,
                  ],
                ],
              ),
              if (chips.isNotEmpty) ...[
                const SizedBox(height: 18),
                Wrap(spacing: 10, runSpacing: 10, children: chips),
              ],
              if (searchHint != null) ...[
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 15,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.09),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.search_rounded,
                        color: Colors.white.withValues(alpha: 0.86),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          searchHint!,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.82),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class HeroTagChip extends StatelessWidget {
  const HeroTagChip({super.key, required this.label, this.highlight = false});

  final String label;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final foreground = highlight ? AppColors.primaryDark : Colors.white;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        gradient: highlight
            ? const LinearGradient(
                colors: [Colors.white, AppColors.accentSoft],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : LinearGradient(
                colors: [
                  Colors.white.withValues(alpha: 0.2),
                  Colors.white.withValues(alpha: 0.08),
                ],
              ),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Text(
        label,
        style: TextStyle(color: foreground, fontWeight: FontWeight.w800),
      ),
    );
  }
}

class StatTile extends StatelessWidget {
  const StatTile({
    super.key,
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  final String label;
  final String value;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.16),
            color.withValues(alpha: 0.08),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: color.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textDark,
                  ),
                ),
                Text(
                  label,
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
    );
  }
}

class MetricPill extends StatelessWidget {
  const MetricPill({
    super.key,
    required this.label,
    required this.value,
    required this.background,
    this.valueColor = AppColors.textDark,
  });

  final String label;
  final String value;
  final Color background;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color.lerp(background, Colors.white, 0.18) ?? background,
            background,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: valueColor,
              fontWeight: FontWeight.w900,
              fontSize: 22,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}

class CategoryChip extends StatelessWidget {
  const CategoryChip({
    super.key,
    required this.label,
    required this.icon,
    required this.selected,
    this.onTap,
    this.iconBackground,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback? onTap;
  final Color? iconBackground;

  @override
  Widget build(BuildContext context) {
    final foreground = selected ? Colors.white : AppColors.textDark;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        width: 90,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          gradient: selected
              ? const LinearGradient(
                  colors: [AppColors.primaryDark, AppColors.primary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : const LinearGradient(
                  colors: [AppColors.cardWhite, AppColors.backgroundTertiary],
                ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: selected
                ? Colors.white.withValues(alpha: 0.08)
                : AppColors.border,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow.withValues(alpha: selected ? 0.14 : 0.05),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: selected
                    ? Colors.white.withValues(alpha: 0.14)
                    : iconBackground ?? AppColors.iconBlueSoft,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                icon,
                color: selected ? Colors.white : AppColors.primary,
                size: 22,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: foreground,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SectionHeading extends StatelessWidget {
  const SectionHeading({
    super.key,
    required this.title,
    required this.subtitle,
    this.action,
  });

  final String title;
  final String subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 4,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  gradient: const LinearGradient(
                    colors: [AppColors.accent, AppColors.primary],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  height: 1.55,
                ),
              ),
            ],
          ),
        ),
        if (action != null) ...[const SizedBox(width: 12), action!],
      ],
    );
  }
}

class AppBanner extends StatelessWidget {
  const AppBanner({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.info_outline_rounded,
    this.background = AppColors.accentSoft,
    this.foreground = AppColors.accentDark,
  });

  final String title;
  final String message;
  final IconData icon;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color.lerp(background, Colors.white, 0.18) ?? background,
            background,
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: foreground.withValues(alpha: 0.08)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: foreground.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: foreground),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: foreground,
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  message,
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

class AppStatusBadge extends StatelessWidget {
  const AppStatusBadge({
    super.key,
    required this.label,
    required this.foreground,
    required this.background,
  });

  final String label;
  final Color foreground;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color.lerp(background, Colors.white, 0.15) ?? background,
            background,
          ],
        ),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: foreground,
          fontWeight: FontWeight.w900,
          fontSize: 12,
        ),
      ),
    );
  }
}

class EstimateTile extends StatelessWidget {
  const EstimateTile({super.key, required this.estimate});

  final EstimateRecord estimate;

  @override
  Widget build(BuildContext context) {
    final localeCode = Localizations.localeOf(context).languageCode;
    final date = intl.DateFormat(
      'dd MMM yyyy - hh:mm a',
      localeCode,
    ).format(estimate.createdAt);
    final shortId = estimate.id.length > 8
        ? estimate.id.substring(0, 8)
        : estimate.id;

    return AppSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.iconBlueSoft, AppColors.primarySoft],
                  ),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr(
                        ar: 'تقدير #$shortId',
                        en: 'Estimate #$shortId',
                      ),
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                      ),
                    ),
                    Text(
                      date,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                context.tr(
                  ar: '${estimate.totalCost.toStringAsFixed(0)} ج.م',
                  en: 'EGP ${estimate.totalCost.toStringAsFixed(0)}',
                ),
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  color: AppColors.primary,
                  fontSize: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: MetricPill(
                  label: context.tr(ar: 'المساحة', en: 'Area'),
                  value: context.tr(
                    ar: '${estimate.area.toStringAsFixed(1)} م²',
                    en: '${estimate.area.toStringAsFixed(1)} m²',
                  ),
                  background: AppColors.primarySoft,
                  valueColor: AppColors.primaryDark,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: MetricPill(
                  label: context.tr(
                    ar: 'العناصر المكتشفة',
                    en: 'Detected items',
                  ),
                  value: '${estimate.crackCount}',
                  background: AppColors.successSoft,
                  valueColor: AppColors.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: AppColors.backgroundTertiary,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: AppColors.border.withValues(alpha: 0.7),
              ),
            ),
            child: Text(
              estimate.bestOffer.isEmpty
                  ? context.tr(
                      ar: 'لا يوجد عرض متاح حالياً',
                      en: 'No available offer right now',
                    )
                  : context.tr(
                      ar: 'أفضل عرض: ${estimate.bestOffer}',
                      en: 'Best offer: ${estimate.bestOffer}',
                    ),
              style: const TextStyle(fontWeight: FontWeight.w800, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}

class AppLoadingCard extends StatelessWidget {
  const AppLoadingCard({
    super.key,
    this.title,
    this.message,
    this.compact = false,
  });

  final String? title;
  final String? message;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final resolvedTitle =
        title ?? context.tr(ar: 'جارٍ التحميل', en: 'Loading');
    final resolvedMessage =
        message ??
        context.tr(
          ar: 'نجهز أحدث البيانات لك الآن. سيظهر المحتوى بعد لحظات.',
          en: 'We are preparing the latest data for you now.',
        );
    final spinnerSize = compact ? 52.0 : 64.0;
    final iconSize = compact ? 18.0 : 22.0;

    return Center(
      child: AppSectionCard(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 20 : 24,
          vertical: compact ? 22 : 26,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: spinnerSize,
              height: spinnerSize,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          AppColors.primarySoft.withValues(alpha: 0.95),
                          AppColors.primarySoft.withValues(alpha: 0.2),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                  SizedBox(
                    width: spinnerSize,
                    height: spinnerSize,
                    child: const CircularProgressIndicator(
                      strokeWidth: 3.2,
                      valueColor: AlwaysStoppedAnimation(AppColors.primary),
                      backgroundColor: AppColors.backgroundSecondary,
                    ),
                  ),
                  Icon(
                    Icons.auto_awesome_rounded,
                    size: iconSize,
                    color: AppColors.accentDark,
                  ),
                ],
              ),
            ),
            SizedBox(height: compact ? 14 : 16),
            Text(
              resolvedTitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: compact ? 17 : 18,
                fontWeight: FontWeight.w900,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              resolvedMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textMuted,
                height: 1.65,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AsyncPlaceholder extends StatelessWidget {
  const AsyncPlaceholder({
    super.key,
    required this.message,
    this.icon = Icons.inbox_rounded,
    this.title,
    this.action,
  });

  final String message;
  final IconData icon;
  final String? title;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final accent = _resolvePlaceholderAccent(icon);
    final shellColor = Color.lerp(accent, Colors.white, 0.8) ?? accent;
    final haloColor = Color.lerp(accent, Colors.white, 0.9) ?? accent;

    return Center(
      child: AppSectionCard(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 112,
                  height: 112,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        haloColor.withValues(alpha: 0.92),
                        haloColor.withValues(alpha: 0.16),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
                Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: accent.withValues(alpha: 0.14),
                      width: 1.4,
                    ),
                  ),
                ),
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color.lerp(shellColor, Colors.white, 0.28) ??
                            shellColor,
                        shellColor,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: accent.withValues(alpha: 0.14),
                        blurRadius: 18,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Icon(icon, size: 30, color: accent),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _PlaceholderAccentPill(color: accent, width: 20),
                const SizedBox(width: 6),
                _PlaceholderAccentPill(color: accent, width: 42, strong: true),
                const SizedBox(width: 6),
                _PlaceholderAccentPill(color: accent, width: 28),
              ],
            ),
            if (title != null) ...[
              const SizedBox(height: 16),
              Text(
                title!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textDark,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textMuted,
                height: 1.7,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (action != null) ...[const SizedBox(height: 18), action!],
          ],
        ),
      ),
    );
  }
}

class _PlaceholderAccentPill extends StatelessWidget {
  const _PlaceholderAccentPill({
    required this.color,
    required this.width,
    this.strong = false,
  });

  final Color color;
  final double width;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: 8,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: strong ? 0.32 : 0.18),
            color.withValues(alpha: strong ? 0.18 : 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(999),
      ),
    );
  }
}

Color _resolvePlaceholderAccent(IconData icon) {
  if (icon == Icons.error_outline_rounded ||
      icon == Icons.warning_amber_rounded ||
      icon == Icons.highlight_off_rounded) {
    return AppColors.error;
  }
  if (icon == Icons.account_balance_wallet_outlined ||
      icon == Icons.payments_outlined ||
      icon == Icons.query_stats_rounded) {
    return AppColors.accentDark;
  }
  if (icon == Icons.event_busy_rounded || icon == Icons.rate_review_outlined) {
    return AppColors.secondary;
  }
  return AppColors.primary;
}
