# Project Structure - Clean Code Summary

## 📁 Project: demo_tryon_app

### ✅ Cleaned Up (Removed):
- ❌ Firebase (firebase_core, firebase_storage, firebase_app_check)
- ❌ firebase_options.dart
- ❌ firebase_upload_service.dart
- ❌ upload_service.dart (old HTTP upload)
- ❌ firebase.json
- ❌ google-services.json
- ❌ Google Services plugins from gradle
- ❌ crypto package (not needed for unsigned upload)

---

## 📂 Current Structure

### 🎯 Main Entry
- `lib/main.dart` - App entry point, clean from Firebase

### 📱 Screens
- `lib/screens/search_screen.dart` - Tìm kiếm ảnh từ API
- `lib/screens/try_on_screen.dart` - Hiển thị ảnh đã chọn và try-on
- `lib/screens/upload_images_screen.dart` - Upload ảnh lên Cloudinary & try-on
- `lib/screens/suggest_idea_screen.dart` - Placeholder
- `lib/screens/update_profile_screen.dart` - Placeholder

### 🔧 Services
- `lib/services/api_service.dart` - API search & try-on
- `lib/services/tryon_service.dart` - Try-on service (port 8005)
- `lib/services/cloudinary_service.dart` - **Cloudinary upload service** ✨

### 📊 Providers (State Management)
- `lib/providers/search_provider.dart` - Search state
- `lib/providers/tryon_provider.dart` - Try-on state

### 🎨 Models
- `lib/models/image_item.dart` - Image item model
- `lib/models/search_request.dart` - Search request
- `lib/models/try_on_request.dart` - Try-on request (cho API service)
- `lib/models/tryon_request.dart` - Tryon request (cho tryon service)
- `lib/models/tryon_response.dart` - Tryon response
- `lib/models/api_response.dart` - API response (SearchResponse, TryOnResponse)

### ⚙️ Constants
- `lib/constants/api_constants.dart` - API endpoints config
- `lib/constants/cloudinary_constants.dart` - **Cloudinary config** ✨

### 🛠️ Utils
- `lib/utils/logger.dart` - App logger

---

## 🚀 Key Features

### Cloudinary Integration ✨
```dart
// Upload preset: demo_tryon
// Folder: /demoTryon
// Unsigned upload (no signature needed)
```

### API Services
1. **Search API** (port 8001)
   - Endpoint: `/scrape`
   - Input: image URL
   - Output: List of similar images

2. **Try-on API** (port 8005)
   - Endpoint: `/tryon`
   - Input: init_image, cloth_image, cloth_type
   - Output: Try-on result images

### Upload Flow
```
User picks image → Local preview → 
Upload to Cloudinary → Get public URL → 
Send URLs to Try-on API → Display result
```

---

## 📦 Dependencies (pubspec.yaml)

```yaml
dependencies:
  flutter:
    sdk: flutter
  http: ^1.1.0              # HTTP requests
  mime: ^1.0.0              # MIME type detection
  http_parser: ^4.0.0       # HTTP parsing
  image_picker: ^1.2.1      # Image picker
  provider: ^6.0.0          # State management
```

---

## 🎯 No Firebase Dependencies

Project is **completely clean** from Firebase:
- ✅ No firebase_core
- ✅ No firebase_storage
- ✅ No firebase_app_check
- ✅ No Firebase config files
- ✅ No Firebase imports

---

## 🔐 Cloudinary Configuration

```dart
Cloud name: dcq6kbxpg
API key: 366287123542277
API secret: dTuz6cfhafLkA7hHQpLvbKpzwZs
Upload preset: demo_tryon (unsigned)
```

**Image URLs format:**
```
https://res.cloudinary.com/dcq6kbxpg/image/upload/demoTryon/...
```

---

## ✨ Code Quality

- ✅ No compilation errors
- ✅ No unused imports
- ✅ No duplicate code
- ✅ Clean architecture (separation of concerns)
- ✅ Proper state management with Provider
- ✅ Logging for debugging

---

## 🎨 Next Steps (Optional Improvements)

1. Implement `SuggestIdeaScreen` - form to send JSON to API
2. Implement `UpdateProfileScreen` - profile image upload
3. Add error handling UI (dialogs/snackbars)
4. Add loading states & animations
5. Add image caching
6. Add retry mechanism for failed uploads
7. Add image preview before upload
8. Add progress indicators for upload
