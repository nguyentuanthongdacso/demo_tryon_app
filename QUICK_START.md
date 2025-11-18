# Quick Start Guide

## Các bước chạy ứng dụng

### 1️⃣ Khởi động server FastAPI

```bash
# Terminal 1: Chạy server scrape
python -m uvicorn server:app --host 127.0.0.1 --port 8001 --reload
```

### 2️⃣ Chuẩn bị Android Emulator

```bash
# Terminal 2: Mở Android Emulator
emulator -avd <emulator_name>
```

Hoặc dùng Android Studio > Device Manager > tìm emulator cần chạy

### 3️⃣ Chạy Flutter App

```bash
# Terminal 3: Chạy Flutter
flutter run
```

**Nếu muốn chỉ định device:**
```bash
flutter devices                    # Liệt kê devices
flutter run -d <device_id>         # Chạy trên device cụ thể
```

## URLs Cần Chỉnh Sửa Theo Nền Tảng

| Nền Tảng | URL | Ghi Chú |
|----------|-----|--------|
| **Android Emulator** | `http://10.0.2.2:8001` | Mapping của emulator đến host machine |
| **iOS Simulator** | `http://127.0.0.1:8001` | iOS simulator truy cập trực tiếp |
| **Physical Device** | `http://<YOUR_IP>:8001` | Thay `<YOUR_IP>` bằng IP máy tính |

### Tìm IP máy tính:

**Windows:**
```powershell
ipconfig
# Tìm "IPv4 Address" dưới "Wireless LAN adapter WiFi"
```

**macOS/Linux:**
```bash
ifconfig
# Hoặc
hostname -I
```

## Thay Đổi Base URL

Chỉnh sửa file: `lib/constants/api_constants.dart`

```dart
class ApiConstants {
  // Đổi URL tại dòng này:
  static const String baseUrl = 'http://10.0.2.2:8001';  // Cho Android Emulator
  // static const String baseUrl = 'http://127.0.0.1:8001';  // Cho iOS Simulator
  // static const String baseUrl = 'http://192.168.1.100:8001';  // Cho Physical Device
}
```

Sau đó chạy lại:
```bash
flutter run
```

## Test URLs

### Test Search API

```bash
curl -X POST http://127.0.0.1:8001/scrape \
  -H "Content-Type: application/json" \
  -d '{"url":"https://www.amazon.com/..."}'
```

### Test Try-On API (nếu có)

```bash
curl -X POST http://127.0.0.1:8001/try-on \
  -H "Content-Type: application/json" \
  -d '{"imageUrl":"https://img.example.com/..."}'
```

## Xem Logs

```bash
# Real-time logs
flutter logs

# Chỉ logs của app
flutter logs --tag "TryOnApp"
```

## Khắc Phục Sự Cố

### ❌ "Connection refused"

✅ **Giải pháp:**
1. Kiểm tra server có chạy: `netstat -an | findstr 8001` (Windows)
2. Kiểm tra URL đúng trong `api_constants.dart`
3. Thử tắt firewall tạm thời

### ❌ "No images found"

✅ **Giải pháp:**
1. Test API trực tiếp bằng curl
2. Kiểm tra URL sản phẩm có hợp lệ không
3. Xem server logs để debug

### ❌ "Network timeout"

✅ **Giải pháp:**
1. Tăng timeout trong `api_constants.dart`:
```dart
static const Duration connectionTimeout = Duration(seconds: 60);
```
2. Kiểm tra kết nối mạng
3. Xem server có đang bị overload không

### ❌ "Android Emulator không kết nối được"

✅ **Giải pháp:**
1. Dùng `10.0.2.2` thay vì `127.0.0.1`
2. Kiểm tra file `android/app/src/main/res/xml/network_security_config.xml` đã được thêm chưa
3. Restart emulator

## Các File Quan Trọng

| File | Tác dụng |
|------|---------|
| `lib/constants/api_constants.dart` | Config URL và timeout |
| `lib/services/api_service.dart` | Gọi API |
| `lib/screens/search_screen.dart` | Màn hình tìm kiếm |
| `lib/screens/try_on_screen.dart` | Màn hình try-on |
| `android/app/src/main/res/xml/network_security_config.xml` | Config network cho Android |

## Useful Flutter Commands

```bash
# Xóa cache và build lại
flutter clean
flutter pub get
flutter run

# Build release (production)
flutter build apk          # APK
flutter build appbundle    # App Bundle (cho Google Play)

# Format code
flutter format lib/

# Analyze code
flutter analyze

# Run tests
flutter test
```
