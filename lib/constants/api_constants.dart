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

  // Default ports for each service (can be changed if your servers use other ports)
  static const int searchPort = 8001;
  static const int tryonPort = 8005;
  static const int uploadPort = 8002; // default upload endpoint lives on same try-on server

  static String get baseUrl => '$baseHost:$searchPort';
  
  // Cho Device thực (thay <IP> bằng IP máy tính)
  // static const String baseUrl = 'http://<YOUR_COMPUTER_IP>:8001';
  
  // Cho iOS Simulator
  // static const String baseUrl = 'http://127.0.0.1:8001';
  
  static const String searchEndpoint = '/scrape';
  static const String tryOnEndpoint = '/try-on';
  static String get tryOnBaseUrl => '$baseHost:$tryonPort';
  static const String uploadEndpoint = '/upload';
  static String get uploadBaseUrl => '$baseHost:$uploadPort';
  
  static const Duration connectionTimeout = Duration(seconds: 30);
}
