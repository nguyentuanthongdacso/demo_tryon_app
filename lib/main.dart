import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'providers/search_provider.dart';
import 'providers/tryon_provider.dart';
import 'screens/search_screen.dart';
import 'screens/try_on_screen.dart';
import 'screens/upload_images_screen.dart';
import 'screens/suggest_idea_screen.dart';
import 'screens/update_profile_screen.dart';
import 'screens/login_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
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

class _MainAppState extends State<MainApp> {
  bool _isLoggedIn = false;
  
  // Global key để access context cho providers
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

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
      ],
      child: MaterialApp(
        title: 'Try-On App',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
          appBarTheme: const AppBarTheme(
            elevation: 2,
          ),
        ),
        home: _isLoggedIn
            ? MainTabBar(onLogout: _handleLogout)
            : LoginScreen(onLoginSuccess: _handleLoginSuccess),
        routes: {
          '/search': (context) => const SearchScreen(),
          '/try-on': (context) => const TryOnScreen(),
        },
        debugShowCheckedModeBanner: false,
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

  static final List<BottomNavigationBarItem> _items = [
    const BottomNavigationBarItem(
      icon: Icon(Icons.search),
      label: 'Search',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.cloud_upload),
      label: 'Upload Images',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.lightbulb),
      label: 'Suggest Idea',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.person),
      label: 'Profile',
    ),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: _items,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
      ),
    );
  }
}

