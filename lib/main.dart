import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'providers/search_provider.dart';
import 'providers/search_tryon_provider.dart';
import 'providers/upload_tryon_provider.dart';
import 'providers/language_provider.dart';
import 'providers/theme_provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'screens/search_screen.dart';
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
  // Thêm timeout để tránh treo app khi khởi động
  try {
    await SessionUploadManager().cleanupPreviousSession()
        .timeout(const Duration(seconds: 5), onTimeout: () {
      debugPrint('⚠️ Cleanup previous session timed out, continuing...');
    });
  } catch (e) {
    debugPrint('⚠️ Error during cleanup: $e');
  }
  
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
    
    debugPrint('📱 App lifecycle state: $state');
    
    // Xóa ảnh session khi app bị ĐÓNG HOÀN TOÀN (detached)
    // KHÔNG xóa khi chuyển qua app khác (paused/inactive/hidden/resumed)
    if (state == AppLifecycleState.detached) {
      debugPrint('🔴 App detached - cleaning up session uploads...');
      _cleanupSessionUploads();
    }
    // Các state khác KHÔNG clear data:
    // - paused: user chuyển sang app khác
    // - inactive: app đang transition (ví dụ: incoming call)
    // - hidden: app bị ẩn nhưng vẫn chạy
    // - resumed: user quay lại app
  }
  
  /// Xóa các ảnh đã upload trong session (không xóa ảnh model của user)
  Future<void> _cleanupSessionUploads() async {
    if (_isLoggedIn) {
      // Add timeout to prevent hanging when app is detached
      await SessionUploadManager().clearSessionUploads()
          .timeout(const Duration(seconds: 10), onTimeout: () {
        debugPrint('⚠️ Session cleanup timed out');
        return {'deleted': 0, 'skipped': 0, 'failed': 0, 'total': 0};
      });
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
        ChangeNotifierProvider(create: (_) => SearchTryonProvider()),
        ChangeNotifierProvider(create: (_) => UploadTryonProvider()),
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: Consumer2<LanguageProvider, ThemeProvider>(
        builder: (context, languageProvider, themeProvider, child) {
          // Ensure language is loaded once we have a valid provider/context
          if (!languageProvider.isLoaded) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              languageProvider.loadLanguage();
            });
          }
          // Ensure theme is loaded
          if (!themeProvider.isLoaded) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              themeProvider.loadTheme();
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
  State<MainTabBar> createState() => MainTabBarState();
}

class MainTabBarState extends State<MainTabBar> {
  int _selectedIndex = 0;
  
  // Navigator keys cho mỗi tab để giữ stack riêng
  final List<GlobalKey<NavigatorState>> _navigatorKeys = [
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
  ];
  
  // Cache screens để giữ state khi chuyển tab
  late final List<Widget> _screens;
  
  @override
  void initState() {
    super.initState();
    debugPrint('🏠 MainTabBarState initState called');
    // Khởi tạo screens một lần duy nhất
    _screens = <Widget>[
      const SearchScreen(),
      const UploadImagesScreen(),
      const SuggestIdeaScreen(),
      UpdateProfileScreen(onLogout: widget.onLogout),
    ];
  }

  @override
  void dispose() {
    debugPrint('🏠 MainTabBarState dispose called');
    super.dispose();
  }

  void _onItemTapped(int index) {
    if (index == _selectedIndex) {
      // Nếu tap vào tab đang active, pop về root của tab đó
      _navigatorKeys[index].currentState?.popUntil((route) => route.isFirst);
    } else {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  // Cho phép navigate trong tab từ bên ngoài
  void navigateInCurrentTab(Widget screen) {
    _navigatorKeys[_selectedIndex].currentState?.push(
      MaterialPageRoute(builder: (context) => screen),
    );
  }

  // Xử lý nút back - pop trong tab trước, sau đó mới exit app
  Future<bool> _onWillPop() async {
    final navigator = _navigatorKeys[_selectedIndex].currentState;
    if (navigator != null && navigator.canPop()) {
      navigator.pop();
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        // Dùng IndexedStack với Navigator riêng cho mỗi tab
        body: IndexedStack(
          index: _selectedIndex,
          children: List.generate(_screens.length, (index) {
            return Navigator(
              key: _navigatorKeys[index],
              onGenerateRoute: (settings) {
                return MaterialPageRoute(
                  settings: settings,
                  builder: (context) => _screens[index],
                );
              },
            );
          }),
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

            return Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage(Provider.of<ThemeProvider>(context).bottomNavBackground),
                  fit: BoxFit.cover,
                ),
              ),
              child: BottomNavigationBar(
                items: items,
                currentIndex: _selectedIndex,
                onTap: _onItemTapped,
                type: BottomNavigationBarType.fixed,
                selectedItemColor: const Color.fromARGB(255, 10, 6, 236),
                unselectedItemColor: const Color.fromARGB(255, 164, 166, 167),
                showUnselectedLabels: true,
                backgroundColor: Colors.transparent,
                elevation: 0,
              ),
            );
          },
        ),
      ),
    );
  }
}

