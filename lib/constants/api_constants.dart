// Hướng dẫn:
// - Nếu chạy trên Android Emulator: dùng 10.0.2.2
// - Nếu chạy trên Device thực: dùng IP của máy tính
// - Nếu chạy trên Simulator iOS: dùng 127.0.0.1

class ApiConstants {
  // Để Android Emulator kết nối được localhost
  // Android Emulator maps 10.0.2.2 → host machine's 127.0.0.1
  static const String baseUrl = 'http://10.0.2.2:8001';
  
  // Cho Device thực (thay <IP> bằng IP máy tính)
  // static const String baseUrl = 'http://<YOUR_COMPUTER_IP>:8001';
  
  // Cho iOS Simulator
  // static const String baseUrl = 'http://127.0.0.1:8001';
  
  static const String searchEndpoint = '/scrape';
  static const String tryOnEndpoint = '/try-on';
  
  static const Duration connectionTimeout = Duration(seconds: 30);
}
