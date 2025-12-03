import 'package:flutter/material.dart';
import '../models/tryon_request.dart';
import '../models/tryon_response.dart';
import '../services/tryon_service.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';

/// Provider riêng cho Search tab - tách biệt với Upload tab
class SearchTryonProvider extends ChangeNotifier {
  final TryonService _service = TryonService();
  final AuthService _authService = AuthService();
  final ApiService _apiService = ApiService();

  bool _isLoading = false;
  String? _error;
  TryonResponse? _response;

  bool get isLoading => _isLoading;
  String? get error => _error;
  TryonResponse? get response => _response;

  Future<void> tryon(String initImage, String clothImage, String clothType) async {
    _isLoading = true;
    _error = null;
    _response = null;
    notifyListeners();
    try {
      final userKey = _authService.currentUser?['user_key'] as String?;
      
      final req = TryonRequest(
        initImage: initImage,
        clothImage: clothImage,
        clothType: clothType,
        userKey: userKey,
      );
      final res = await _service.sendTryonRequest(req);
      _response = res;
      
      if (res.status == 'success') {
        await _authService.refreshTokenFromServer();
        
        // Lưu ảnh tryon ngay khi nhận được từ server (phòng crash)
        if (userKey != null && res.outputImages.isNotEmpty) {
          _saveTryonImages(userKey, res.outputImages);
        }
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Lưu các ảnh tryon vào database (chạy background, không block UI)
  Future<void> _saveTryonImages(String userKey, List<String> imageUrls) async {
    for (final imageUrl in imageUrls) {
      try {
        await _apiService.saveTryonImage(userKey: userKey, imageUrl: imageUrl);
        debugPrint('✅ Saved tryon image to My Assets: ${imageUrl.substring(0, 50)}...');
      } catch (e) {
        debugPrint('⚠️ Failed to save tryon image: $e');
        // Không throw error, tiếp tục lưu các ảnh khác
      }
    }
  }

  void clear() {
    _isLoading = false;
    _error = null;
    _response = null;
    notifyListeners();
  }
}
