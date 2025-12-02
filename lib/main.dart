import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'providers/search_provider.dart';
import 'providers/tryon_provider.dart';
import 'providers/language_provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'screens/search_screen.dart';
import 'screens/try_on_screen.dart';
import 'screens/upload_images_screen.dart';
import 'screens/suggest_idea_screen.dart';
import 'screens/update_profile_screen.dart';
import 'screens/login_screen.dart';
import 'l10n/app_localizations.dart';
import 'services/auth_service.dart';
import 'services/session_upload_manager.dart';
import 'services/ad_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Khởi tạo AdMob SDK
  await AdService().initialize();
  
  // Xóa ảnh từ phiên trước (nếu app bị đóng đột ngột)
  // Giữ lại để tối ưu storage trên Cloudinary
  await SessionUploadManager().cleanupPreviousSession();
  
  // Khóa orientation - chỉ cho phép chế độ dọc
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(const MainApp());
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> with WidgetsBindingObserver {
  bool _isLoggedIn = false;
  bool _isCheckingSession = true; // Loading state khi check session
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkExistingSession();
  }
  
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    // Xóa ảnh session khi app bị ĐÓNG HOÀN TOÀN (detached)
    // KHÔNG xóa khi chuyển qua app khác (paused/inactive)
    if (state == AppLifecycleState.detached) {
      debugPrint('🔴 App detached - cleaning up session uploads...');
      _cleanupSessionUploads();
    }
  }
  
  /// Xóa các ảnh đã upload trong session (không xóa ảnh model của user)
  Future<void> _cleanupSessionUploads() async {
    if (_isLoggedIn) {
      await SessionUploadManager().clearSessionUploads();
    }
  }
  
  /// Kiểm tra session đã lưu khi app khởi động
  Future<void> _checkExistingSession() async {
    try {
      final authService = AuthService();
      final hasValidSession = await authService.loadSession();
      
      if (hasValidSession) {
        debugPrint('✅ Found valid session, auto-login...');
        // Khôi phục URL ảnh model của user
        final userImageUrl = authService.currentUser?['image'] as String?;
        await SessionUploadManager().setUserModelImageUrl(userImageUrl);
        
        if (mounted) {
          setState(() {
            _isLoggedIn = true;
            _isCheckingSession = false;
          });
        }
      } else {
        debugPrint('❌ No valid session found');
        if (mounted) {
          setState(() {
            _isCheckingSession = false;
          });
        }
      }
    } catch (e) {
      debugPrint('❌ Error checking session: $e');
      if (mounted) {
        setState(() {
          _isCheckingSession = false;
        });
      }
    }
  }

  void _handleLoginSuccess() {
    setState(() {
      _isLoggedIn = true;
    });
  }

  void _handleLogout() {
    setState(() {
      _isLoggedIn = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SearchProvider()),
        ChangeNotifierProvider(create: (_) => TryonProvider()),
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
      ],
      child: Consumer<LanguageProvider>(
        builder: (context, languageProvider, child) {
          // Ensure language is loaded once we have a valid provider/context
          if (!languageProvider.isLoaded) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              languageProvider.loadLanguage();
            });
          }

          return MaterialApp(
            // Avoid calling AppLocalizations.of(context) here because
            // Localizations are not yet available above MaterialApp.
            title: 'Try-On App',
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
              useMaterial3: true,
              appBarTheme: const AppBarTheme(
                elevation: 2,
              ),
            ),
            // Localization
            localizationsDelegates: [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
              const AppLocalizationsDelegate(),
            ],
            supportedLocales: LanguageProvider.supportedLanguages.map((l) => l.locale).toList(),
            locale: languageProvider.currentLocale,
            home: _isCheckingSession
                ? const Scaffold(
                    body: Center(
                      child: CircularProgressIndicator(),
                    ),
                  )
                : _isLoggedIn
                    ? MainTabBar(onLogout: _handleLogout)
                    : LoginScreen(onLoginSuccess: _handleLoginSuccess),
            routes: {
              '/search': (context) => const SearchScreen(),
              '/try-on': (context) => const TryOnScreen(),
            },
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}

class MainTabBar extends StatefulWidget {
  final VoidCallback? onLogout;

  const MainTabBar({super.key, this.onLogout});

  @override
  State<MainTabBar> createState() => _MainTabBarState();
}

class _MainTabBarState extends State<MainTabBar> {
  int _selectedIndex = 0;
  
  // Cache screens để giữ state khi chuyển tab
  late final List<Widget> _screens;
  
  @override
  void initState() {
    super.initState();
    // Khởi tạo screens một lần duy nhất
    _screens = <Widget>[
      const SearchScreen(),
      const UploadImagesScreen(),
      const SuggestIdeaScreen(),
      UpdateProfileScreen(onLogout: widget.onLogout),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Dùng IndexedStack để giữ state của tất cả các tab
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: Builder(
        builder: (context) {
          final loc = AppLocalizations.of(context);
          final items = <BottomNavigationBarItem>[
            BottomNavigationBarItem(icon: const Icon(Icons.search), label: loc.translate('bottom_search')),
            BottomNavigationBarItem(icon: const Icon(Icons.cloud_upload), label: loc.translate('bottom_upload')),
            BottomNavigationBarItem(icon: const Icon(Icons.lightbulb), label: loc.translate('bottom_idea')),
            BottomNavigationBarItem(icon: const Icon(Icons.person), label: loc.translate('bottom_profile')),
          ];

          return BottomNavigationBar(
            items: items,
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
            type: BottomNavigationBarType.fixed,
            selectedItemColor: Colors.blue,
            unselectedItemColor: Colors.grey,
            showUnselectedLabels: true,
          );
        },
      ),
    );
  }
}

