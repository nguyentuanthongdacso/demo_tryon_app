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
import 'services/session_upload_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Xoa anh tu phien truoc (neu app bi dong dot ngot)
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
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }
  
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    // Chi xoa khi app bi DONG HOAN TOAN (detached)
    // KHONG xoa khi chuyen qua app khac (paused/inactive)
    if (state == AppLifecycleState.detached) {
      debugPrint('🔴 App detached - cleaning up session uploads...');
      _cleanupSessionUploads();
    }
  }
  
  /// Xoa cac anh da upload trong session (khong xoa anh model cua user)
  Future<void> _cleanupSessionUploads() async {
    if (_isLoggedIn) {
      await SessionUploadManager().clearSessionUploads();
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
            home: _isLoggedIn
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

  List<Widget> get _screens => <Widget>[
    const SearchScreen(),
    const UploadImagesScreen(),
    const SuggestIdeaScreen(),
    UpdateProfileScreen(onLogout: widget.onLogout),
  ];

  // icons kept inline when building the items

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
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

