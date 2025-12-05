import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Enum đại diện cho các theme có sẵn
enum AppThemeType {
  pinkPastel,
  blueSky,
}

/// Lớp chứa thông tin về một theme
class AppThemeData {
  final String id;
  final String nameKey; // Key để dịch tên
  final String mainBackground;
  final String bottomNavBackground;

  const AppThemeData({
    required this.id,
    required this.nameKey,
    required this.mainBackground,
    required this.bottomNavBackground,
  });
}

/// Provider quản lý theme của app
class ThemeProvider extends ChangeNotifier {
  static const String _themeKey = 'app_theme';
  
  /// Danh sách các theme có sẵn
  static const Map<AppThemeType, AppThemeData> themes = {
    AppThemeType.pinkPastel: AppThemeData(
      id: 'pink_pastel',
      nameKey: 'theme_pink_pastel',
      mainBackground: 'assets/backgrounds/pink_pastel/bg_main.png',
      bottomNavBackground: 'assets/backgrounds/pink_pastel/bg_bottom_nav.jpg',
    ),
    AppThemeType.blueSky: AppThemeData(
      id: 'blue_sky',
      nameKey: 'theme_blue_sky',
      mainBackground: 'assets/backgrounds/blue_sky/bg_main.jpg',
      bottomNavBackground: 'assets/backgrounds/blue_sky/bg_bottom_nav.jpg',
    ),
  };

  AppThemeType _currentTheme = AppThemeType.blueSky;
  bool _isLoaded = false;

  /// Theme hiện tại
  AppThemeType get currentTheme => _currentTheme;
  
  /// Kiểm tra đã load từ storage chưa
  bool get isLoaded => _isLoaded;

  /// Lấy dữ liệu theme hiện tại
  AppThemeData get currentThemeData => themes[_currentTheme]!;

  /// Đường dẫn ảnh nền chính
  String get mainBackground => currentThemeData.mainBackground;

  /// Đường dẫn ảnh nền bottom navigation bar
  String get bottomNavBackground => currentThemeData.bottomNavBackground;

  /// Load theme từ SharedPreferences
  Future<void> loadTheme() async {
    if (_isLoaded) return;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final themeId = prefs.getString(_themeKey);
      
      if (themeId != null) {
        // Tìm theme theo id
        for (final entry in themes.entries) {
          if (entry.value.id == themeId) {
            _currentTheme = entry.key;
            break;
          }
        }
      }
    } catch (e) {
      debugPrint('❌ Error loading theme: $e');
    }
    
    _isLoaded = true;
    notifyListeners();
  }

  /// Đặt theme mới và lưu vào SharedPreferences
  Future<void> setTheme(AppThemeType theme) async {
    if (_currentTheme == theme) return;
    
    _currentTheme = theme;
    notifyListeners();
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_themeKey, themes[theme]!.id);
      debugPrint('✅ Theme saved: ${themes[theme]!.id}');
    } catch (e) {
      debugPrint('❌ Error saving theme: $e');
    }
  }

  /// Lấy danh sách tất cả theme để hiển thị trong dropdown
  static List<AppThemeType> get availableThemes => AppThemeType.values;
}
