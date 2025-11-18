# Try-On App - Flutter

Ứng dụng Flutter để tìm kiếm và thử đồ bằng AI.

## Tính năng

✅ Tìm kiếm ảnh từ URL  
✅ Hiển thị danh sách ảnh kết quả  
✅ Chọn ảnh để thử đồ (Try-On)  
✅ Gọi API server FastAPI chạy trên port 8001  

## Yêu cầu

- Flutter SDK 3.10+
- Dart SDK 3.10+
- Android Studio (cho Android emulator)
- Server FastAPI chạy trên `http://127.0.0.1:8001`

## Setup

### 1. Cài đặt dependencies

```bash
cd test1
flutter pub get
```

### 2. Cấu hình Server API

Đảm bảo server FastAPI của bạn chạy tại:
- **URL**: `http://127.0.0.1:8001/scrape`
- **Port**: 8001

#### Nếu chạy trên Android Emulator

Thay `http://127.0.0.1:8001` bằng `http://10.0.2.2:8001` trong file `lib/services/api_service.dart`:

```dart
static const String baseUrl = 'http://10.0.2.2:8001';
```

#### Nếu chạy trên Device thực

Dùng IP của máy tính thay vì localhost:

```dart
static const String baseUrl = 'http://<YOUR_COMPUTER_IP>:8001';
```

### 3. Chạy ứng dụng

#### Chạy trên Android Emulator

```bash
flutter run
```

#### Chạy trên Device USB

```bash
flutter run -d <device-id>
```

#### Chạy trên Web (nếu muốn)

```bash
flutter run -d chrome
```

## Cấu trúc Dự án

```
lib/
├── main.dart                 # Entry point
├── models/
│   ├── image_item.dart       # Model ảnh
│   ├── search_request.dart   # Request tìm kiếm
│   ├── try_on_request.dart   # Request try-on
│   └── api_response.dart     # Response từ API
├── services/
│   └── api_service.dart      # Service gọi API
├── screens/
│   ├── search_screen.dart    # Màn hình tìm kiếm
│   └── try_on_screen.dart    # Màn hình try-on
└── providers/
    └── search_provider.dart  # State management
```

## API Endpoints

### Tìm kiếm ảnh

**Endpoint**: `POST /scrape`

**Request**:
```json
{
  "url": "https://example.com/product"
}
```

**Response**:
```json
{
  "results": {
    "image_urls": [
      [0, "https://image-url-1.jpg"],
      [1, "https://image-url-2.jpg"],
      ...
    ]
  }
}
```

### Try-On

**Endpoint**: `POST /try-on`

**Request**:
```json
{
  "imageUrl": "https://image-url.jpg"
}
```

**Response**:
```json
{
  "result": "try-on-result-data",
  "success": true,
  "message": "Success"
}
```

## Ghi Chú Quan Trọng

1. **Kết nối từ Emulator**: Android Emulator không thể truy cập `127.0.0.1`. Sử dụng `10.0.2.2` thay vì.

2. **CORS**: Nếu gặp lỗi CORS, đảm bảo server FastAPI cho phép CORS:

```python
from fastapi.middleware.cors import CORSMiddleware

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)
```

3. **Network Security**: Trên Android 9+, HTTP mặc định bị từ chối. Thêm file `network_security_config.xml` để cho phép HTTP localhost:

```xml
<?xml version="1.0" encoding="utf-8"?>
<network-security-config>
    <domain-config cleartextTrafficPermitted="true">
        <domain includeSubdomains="true">10.0.2.2</domain>
        <domain includeSubdomains="true">127.0.0.1</domain>
    </domain-config>
</network-security-config>
```

## Khắc Phục Sự Cố

### Lỗi: "Failed to connect to server"

- Kiểm tra server có chạy không: `curl http://127.0.0.1:8001/scrape`
- Kiểm tra URL trong code có đúng không
- Nếu dùng emulator, thay `127.0.0.1` bằng `10.0.2.2`

### Lỗi: "No images found"

- Kiểm tra URL sản phẩm có hợp lệ không
- Xem server logs để debug

### Lỗi: "Connection refused"

- Đảm bảo server FastAPI đang chạy
- Kiểm tra port 8001 có đang lắng nghe không

## Liên Hệ & Hỗ Trợ

Nếu gặp vấn đề, kiểm tra:
1. Server logs
2. App logs (flutter logs)
3. Network connectivity
