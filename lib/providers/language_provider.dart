import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider extends ChangeNotifier {
  static const String _keyLanguage = 'app_language';

  Locale _currentLocale = const Locale('vi', 'VN');
  bool _loaded = false;

  Locale get currentLocale => _currentLocale;
  bool get isLoaded => _loaded;

  // Supported languages (display order)
  static const List<LanguageOption> supportedLanguages = [
    LanguageOption(locale: Locale('vi', 'VN'), name: 'Tiếng Việt', nativeName: 'Tiếng Việt'),
    LanguageOption(locale: Locale('en', 'US'), name: 'English', nativeName: 'English'),
    LanguageOption(locale: Locale('zh', 'CN'), name: '中文 (简体)', nativeName: '中文 (简体)'),
    LanguageOption(locale: Locale('es', 'ES'), name: 'Español', nativeName: 'Español'),
    LanguageOption(locale: Locale('hi', 'IN'), name: 'हिन्दी', nativeName: 'हिन्दी'),
    LanguageOption(locale: Locale('ar', 'SA'), name: 'العربية', nativeName: 'العربية'),
    LanguageOption(locale: Locale('bn', 'BD'), name: 'বাংলা', nativeName: 'বাংলা'),
    LanguageOption(locale: Locale('fr', 'FR'), name: 'Français', nativeName: 'Français'),
    LanguageOption(locale: Locale('ru', 'RU'), name: 'Русский', nativeName: 'Русский'),
    LanguageOption(locale: Locale('pt', 'BR'), name: 'Português', nativeName: 'Português'),
  ];

  LanguageProvider();

  /// Load saved language (call after first frame to avoid blocking provider creation)
  Future<void> loadLanguage() async {
    if (_loaded) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final code = prefs.getString(_keyLanguage);
      if (code != null) {
        final match = supportedLanguages.firstWhere(
          (l) => l.locale.languageCode == code,
          orElse: () => supportedLanguages.first,
        );
        _currentLocale = match.locale;
      }
    } catch (_) {
      // ignore errors, keep default
    }
    _loaded = true;
    notifyListeners();
  }

  Future<void> setLanguage(Locale locale) async {
    if (_currentLocale == locale) return;
    _currentLocale = locale;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyLanguage, locale.languageCode);
    } catch (_) {}
    notifyListeners();
  }

  String getCurrentLanguageName() {
    final found = supportedLanguages.firstWhere(
      (l) => l.locale.languageCode == _currentLocale.languageCode,
      orElse: () => supportedLanguages.first,
    );
    return found.name;
  }
}

class LanguageOption {
  final Locale locale;
  final String name;
  final String nativeName;
  const LanguageOption({required this.locale, required this.name, required this.nativeName});
}
