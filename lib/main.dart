import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/search_provider.dart';
import 'screens/search_screen.dart';
import 'screens/try_on_screen.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SearchProvider()),
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
        home: const SearchScreen(),
        routes: {
          '/search': (context) => const SearchScreen(),
          '/try-on': (context) => const TryOnScreen(),
        },
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

