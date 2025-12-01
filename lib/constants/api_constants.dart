// Hướng dẫn:
// - Production: sử dụng các subdomain của tryonstylist.com
// - Development local: uncomment các dòng localhost bên dưới
//
// Domain structure (Cloudflare Tunnel):
// - gateway.tryonstylist.com -> Gateway (8003) - auth, user management  
// - scrape.tryonstylist.com  -> Scrape Server (8001) - search
// - tryon.tryonstylist.com   -> Try-On Server (8002) - AI try-on
// - tryonstylist.com         -> Reserved for website

// import 'dart:io'; // Chỉ cần khi dùng development mode

class ApiConstants {
  // ===== PRODUCTION MODE =====
  // Mỗi server có subdomain riêng
  static const String gatewayHost = 'https://gateway.tryonstylist.com';
  static const String scrapeHost = 'https://scrape.tryonstylist.com';
  static const String tryonHost = 'https://tryon.tryonstylist.com';
  static const String wsHost = 'wss://gateway.tryonstylist.com';
  
  // ===== DEVELOPMENT MODE (uncomment để test local) =====
  // static String get gatewayHost {
  //   if (Platform.isAndroid) return 'http://10.0.2.2:8003';
  //   return 'http://127.0.0.1:8003';
  // }
  // static String get scrapeHost {
  //   if (Platform.isAndroid) return 'http://10.0.2.2:8001';
  //   return 'http://127.0.0.1:8001';
  // }
  // static String get tryonHost {
  //   if (Platform.isAndroid) return 'http://10.0.2.2:8002';
  //   return 'http://127.0.0.1:8002';
  // }

  // ===== LEGACY PORTS (chỉ dùng cho development local) =====
  static const int gatewayPort = 8003;
  static const int searchPort = 8001;
  static const int tryonPort = 8002;

  // ===== BASE URLs =====
  static String get gatewayBaseUrl => gatewayHost;
  static String get baseUrl => gatewayHost;  // Legacy compatibility
  static String get wsBaseUrl => wsHost;
  static String get searchBaseUrl => scrapeHost;
  static String get tryOnBaseUrl => tryonHost;
  
  // ===== ENDPOINTS =====
  // Gateway endpoints (Auth)
  static const String checkLoginEndpoint = '/check-login';
  static const String checkTokenEndpoint = '/check-token';
  static const String subtractTokenEndpoint = '/subtract-token';
  
  // Search endpoints (on scrape server)
  static const String searchEndpoint = '/scrape';
  
  // Try-on endpoints (on tryon server)
  static const String tryOnEndpoint = '/tryon';
  
  // ===== TIMEOUTS =====
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration tryonTimeout = Duration(seconds: 120);
}
