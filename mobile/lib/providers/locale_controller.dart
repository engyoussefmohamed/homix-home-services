import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const arabicLocale = Locale('ar', 'EG');
const englishLocale = Locale('en', 'US');
const supportedAppLocales = [arabicLocale, englishLocale];
const _localeCodeKey = 'app_locale_code';

final localeControllerProvider = ChangeNotifierProvider<LocaleController>((
  ref,
) {
  return LocaleController()..bootstrap();
});

class LocaleController extends ChangeNotifier {
  Locale _locale = arabicLocale;

  Locale get locale => _locale;
  bool get isArabic => _locale.languageCode == arabicLocale.languageCode;

  Future<void> bootstrap() async {
    final prefs = await SharedPreferences.getInstance();
    final savedCode = prefs.getString(_localeCodeKey);
    if (savedCode == null || savedCode == _locale.languageCode) return;

    _locale = savedCode == englishLocale.languageCode
        ? englishLocale
        : arabicLocale;
    notifyListeners();
  }

  Future<void> toggleLanguage() async {
    _locale = isArabic ? englishLocale : arabicLocale;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localeCodeKey, _locale.languageCode);
  }

  Future<void> setLocale(Locale locale) async {
    if (_locale == locale) return;
    _locale = locale;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localeCodeKey, _locale.languageCode);
  }
}
