import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/locale_controller.dart';

extension HomixLocalizationX on BuildContext {
  bool get isArabic {
    final locale = Localizations.maybeLocaleOf(this);
    if (locale != null) {
      return locale.languageCode.toLowerCase() == 'ar';
    }

    try {
      final fallbackLocale = ProviderScope.containerOf(
        this,
        listen: false,
      ).read(localeControllerProvider).locale;
      return fallbackLocale.languageCode.toLowerCase() == 'ar';
    } catch (_) {
      return true;
    }
  }

  String tr({required String ar, required String en}) {
    return isArabic ? ar : en;
  }

  TextDirection get appTextDirection =>
      isArabic ? TextDirection.rtl : TextDirection.ltr;
}
