// Hướng dẫn:
// - Nếu chạy trên Android Emulator: dùng 10.0.2.2
// - Nếu chạy trên Device thực: dùng IP của máy tính
// - Nếu chạy trên Simulator iOS: dùng 127.0.0.1

import 'dart:io';

class ApiConstants {
  // Platform-aware base for localhost services. Use emulator host mapping for Android.
  static String get baseHost {
    if (Platform.isAndroid) return 'http://10.0.2.2';
    return 'http://127.0.0.1';
  }

  // WebSocket base URL (ws:// instead of http://)
  static String get wsBaseHost {
    if (Platform.isAndroid) return 'ws://10.0.2.2';
    return 'ws://127.0.0.1';
  }

  // ===== SERVER PORTS =====
  static const int gatewayPort = 8003;  // 3_api_gateway - Auth & User management
  static const int searchPort = 8001;   // 1_scrape_url - Web scraping
  static const int tryonPort = 8002;    // 2_try_on - Try-on API
  // Port 8002 = 4_connect_db (internal only, not accessible from client)

  // ===== BASE URLs =====
  static String get gatewayBaseUrl => '$baseHost:$gatewayPort';  // API Gateway
  static String get baseUrl => '$baseHost:$searchPort';           // Search/Scrape
  static String get wsBaseUrl => '$wsBaseHost:$searchPort';       // WebSocket
  static String get tryOnBaseUrl => '$baseHost:$tryonPort';       // Try-on
  
  // ===== ENDPOINTS =====
  // Gateway endpoints (Auth)
  static const String checkLoginEndpoint = '/check-login';
  static const String checkTokenEndpoint = '/check-token';
  static const String subtractTokenEndpoint = '/subtract-token';
  
  // Search endpoints
  static const String searchEndpoint = '/scrape';
  
  // Try-on endpoints
  static const String tryOnEndpoint = '/tryon';
  
  // ===== TIMEOUTS =====
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration tryonTimeout = Duration(seconds: 120);
}
