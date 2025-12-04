import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/cloudinary_constants.dart';

/// Quan ly cac anh da upload trong phien dang nhap
/// Chi giu toi da 2 anh (init + cloth) tai moi thoi diem
/// Tu dong xoa tat ca anh khi user logout hoac app khoi dong lai
/// KHONG xoa anh trung voi anh model cua user
/// Su dung flutter_secure_storage de ma hoa du lieu luu tru
class SessionUploadManager {
  // Singleton pattern
  static final SessionUploadManager _instance = SessionUploadManager._internal();
  factory SessionUploadManager() => _instance;
  SessionUploadManager._internal();
  
  // Secure Storage instance với cấu hình bảo mật cao
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );
  
  // Keys cho Secure Storage
  static const String _keyInitPublicId = 'session_init_public_id';
  static const String _keyClothPublicId = 'session_cloth_public_id';
  static const String _keyCroppedPublicId = 'session_cropped_public_id';
  static const String _keyInitUrl = 'session_init_url';
  static const String _keyClothUrl = 'session_cloth_url';
  static const String _keyCroppedUrl = 'session_cropped_url';
  static const String _keyUserModelUrl = 'session_user_model_url';
  static const String _keyPendingDeletes = 'session_pending_deletes';

  // Luu public_id theo loai anh (init, cloth, cropped)
  String? _initImagePublicId;
  String? _clothImagePublicId;
  String? _croppedImagePublicId;
  
  // Luu URL tuong ung
  String? _initImageUrl;
  String? _clothImageUrl;
  String? _croppedImageUrl;
  
  // Luu URL anh model cua user (de khong xoa nhom anh nay)
  String? _userModelImageUrl;
  // Pending deletes to retry later when network available
  final List<String> _pendingDeletes = [];

  // Getters
  String? get initImagePublicId => _initImagePublicId;
  String? get clothImagePublicId => _clothImagePublicId;
  String? get croppedImagePublicId => _croppedImagePublicId;
  String? get initImageUrl => _initImageUrl;
  String? get clothImageUrl => _clothImageUrl;
  String? get croppedImageUrl => _croppedImageUrl;
  String? get userModelImageUrl => _userModelImageUrl;
  
  /// Set URL anh model cua user (goi sau khi login)
  Future<void> setUserModelImageUrl(String? url) async {
    _userModelImageUrl = url;
    print('👤 User model image URL set: $url');
    await _saveToStorage();
  }
  
  /// Lay public_id tu URL Cloudinary
  /// URL format: https://res.cloudinary.com/cloud_name/image/upload/v123/public_id.ext
  String? _extractPublicIdFromUrl(String? url) {
    if (url == null) return null;
    try {
      final uri = Uri.parse(url);
      final pathSegments = uri.pathSegments;
      // Tim vi tri "upload" va lay phan sau no
      final uploadIndex = pathSegments.indexOf('upload');
      if (uploadIndex != -1 && uploadIndex < pathSegments.length - 1) {
        // Lay tat ca phan sau "upload" va bo version (vXXX)
        String publicIdWithExt = pathSegments.sublist(uploadIndex + 1).join('/');
        // Bo version neu co (v123456789/)
        if (publicIdWithExt.startsWith('v') && publicIdWithExt.contains('/')) {
          publicIdWithExt = publicIdWithExt.substring(publicIdWithExt.indexOf('/') + 1);
        }
        // Bo extension
        final lastDot = publicIdWithExt.lastIndexOf('.');
        if (lastDot != -1) {
          return publicIdWithExt.substring(0, lastDot);
        }
        return publicIdWithExt;
      }
    } catch (e) {
      print('❌ Error parsing URL for public_id: $e');
    }
    return null;
  }
  
  /// Kiem tra xem URL co phai la anh model cua user khong (so sanh bang public_id)
  bool _isUserModelImage(String? url) {
    if (_userModelImageUrl == null || url == null) return false;
    
    // So sanh bang public_id (hash) thay vi URL day du
    // Vi URL co the khac nhau do version (v123456...)
    final userModelPublicId = _extractPublicIdFromUrl(_userModelImageUrl);
    final imagePublicId = _extractPublicIdFromUrl(url);
    
    if (userModelPublicId == null || imagePublicId == null) {
      // Fallback: so sanh URL truc tiep
      return _userModelImageUrl == url;
    }
    
    final isMatch = userModelPublicId == imagePublicId;
    if (isMatch) {
      print('⚠️ Image matches user model image (public_id: $imagePublicId)');
    }
    return isMatch;
  }
  
  // ========== PERSISTENCE (Secure Storage - Mã hóa) ==========
  
  /// Luu trang thai hien tai vao Secure Storage (mã hóa)
  Future<void> _saveToStorage() async {
    print('💾 Saving to secure storage:');
    print('   Init: $_initImagePublicId');
    print('   Cloth: $_clothImagePublicId');
    print('   Cropped: $_croppedImagePublicId');
    print('   User model: $_userModelImageUrl');
    print('   Pending deletes: ${_pendingDeletes.length}');
    
    if (_initImagePublicId != null) {
      await _secureStorage.write(key: _keyInitPublicId, value: _initImagePublicId);
    } else {
      await _secureStorage.delete(key: _keyInitPublicId);
    }
    
    if (_clothImagePublicId != null) {
      await _secureStorage.write(key: _keyClothPublicId, value: _clothImagePublicId);
    } else {
      await _secureStorage.delete(key: _keyClothPublicId);
    }
    
    if (_croppedImagePublicId != null) {
      await _secureStorage.write(key: _keyCroppedPublicId, value: _croppedImagePublicId);
    } else {
      await _secureStorage.delete(key: _keyCroppedPublicId);
    }
    
    if (_initImageUrl != null) {
      await _secureStorage.write(key: _keyInitUrl, value: _initImageUrl);
    } else {
      await _secureStorage.delete(key: _keyInitUrl);
    }
    
    if (_clothImageUrl != null) {
      await _secureStorage.write(key: _keyClothUrl, value: _clothImageUrl);
    } else {
      await _secureStorage.delete(key: _keyClothUrl);
    }
    
    if (_croppedImageUrl != null) {
      await _secureStorage.write(key: _keyCroppedUrl, value: _croppedImageUrl);
    } else {
      await _secureStorage.delete(key: _keyCroppedUrl);
    }
    
    if (_userModelImageUrl != null) {
      await _secureStorage.write(key: _keyUserModelUrl, value: _userModelImageUrl);
    } else {
      await _secureStorage.delete(key: _keyUserModelUrl);
    }

    // Save pending deletes list
    if (_pendingDeletes.isNotEmpty) {
      await _secureStorage.write(key: _keyPendingDeletes, value: jsonEncode(_pendingDeletes));
    } else {
      await _secureStorage.delete(key: _keyPendingDeletes);
    }
    
    print('🔐 Session state saved to secure storage');
  }
  
  /// Load trang thai tu Secure Storage (mã hóa)
  Future<void> _loadFromStorage() async {
    _initImagePublicId = await _secureStorage.read(key: _keyInitPublicId);
    _clothImagePublicId = await _secureStorage.read(key: _keyClothPublicId);
    _croppedImagePublicId = await _secureStorage.read(key: _keyCroppedPublicId);
    _initImageUrl = await _secureStorage.read(key: _keyInitUrl);
    _clothImageUrl = await _secureStorage.read(key: _keyClothUrl);
    _croppedImageUrl = await _secureStorage.read(key: _keyCroppedUrl);
    _userModelImageUrl = await _secureStorage.read(key: _keyUserModelUrl);
    
    // Load pending deletes
    final pendingJson = await _secureStorage.read(key: _keyPendingDeletes);
    if (pendingJson != null) {
      try {
        final list = jsonDecode(pendingJson) as List<dynamic>;
        _pendingDeletes.clear();
        for (final item in list) {
          if (item is String) _pendingDeletes.add(item);
        }
      } catch (e) {
        print('⚠️ Failed to parse pending deletes: $e');
      }
    }
    
    print('🔐 Session state loaded from secure storage:');
    print('   Init: $_initImagePublicId');
    print('   Cloth: $_clothImagePublicId');
    print('   Cropped: $_croppedImagePublicId');
    print('   User model: $_userModelImageUrl');
  }
  
  /// Xoa du lieu trong Secure Storage
  Future<void> _clearStorage() async {
    await _secureStorage.delete(key: _keyInitPublicId);
    await _secureStorage.delete(key: _keyClothPublicId);
    await _secureStorage.delete(key: _keyCroppedPublicId);
    await _secureStorage.delete(key: _keyInitUrl);
    await _secureStorage.delete(key: _keyClothUrl);
    await _secureStorage.delete(key: _keyCroppedUrl);
    await _secureStorage.delete(key: _keyUserModelUrl);
    await _secureStorage.delete(key: _keyPendingDeletes);
    print('🔐 Session storage cleared');
  }
  
  /// GOI KHI APP KHOI DONG: Load va xoa anh cu tu phien truoc
  Future<void> cleanupPreviousSession() async {
    try {
      print('🚀 Checking for previous session uploads to clean up...');
      
      // Load du lieu tu storage
      await _loadFromStorage();
      
      // First, attempt pending deletes from previous failures
      if (_pendingDeletes.isNotEmpty) {
        print('🔁 Attempting pending deletes (${_pendingDeletes.length})...');
        final List<String> stillPending = [];
        for (final publicId in List<String>.from(_pendingDeletes)) {
          try {
            final ok = await deleteImage(publicId);
            if (!ok) {
              stillPending.add(publicId);
            }
          } catch (e) {
            // Network error or other - keep for next time
            stillPending.add(publicId);
          }
        }
        _pendingDeletes
          ..clear()
          ..addAll(stillPending);
        // Save pending state
        await _saveToStorage();
      }
      
      // Xoa anh cu (neu co) - KHONG xoa anh model cua user
      await clearSessionUploads();
      
      // If no pending deletes and no tracked session images, clear storage
      if (_pendingDeletes.isEmpty && _initImagePublicId == null && _clothImagePublicId == null && _croppedImagePublicId == null && _initImageUrl == null && _clothImageUrl == null && _croppedImageUrl == null && _userModelImageUrl == null) {
        await _clearStorage();
      } else {
        // Persist current state (remaining pending deletes or any tracking)
        await _saveToStorage();
      }
      
      print('✅ Previous session cleanup complete');
    } catch (e) {
      print('❌ Error during cleanup: $e');
      // Khong throw loi de app van chay duoc
    }
  }
  
  /// Tao signature cho Cloudinary Admin API
  String _generateSignature(Map<String, String> params) {
    final sortedKeys = params.keys.toList()..sort();
    final paramString = sortedKeys
        .map((key) => '$key=${params[key]}')
        .join('&');
    
    final stringToSign = '$paramString${CloudinaryConstants.apiSecret}';
    final bytes = utf8.encode(stringToSign);
    final digest = sha1.convert(bytes);
    
    return digest.toString();
  }

  /// Xoa mot anh tren Cloudinary bang public_id
  Future<bool> deleteImage(String publicId) async {
    try {
      final timestamp = (DateTime.now().millisecondsSinceEpoch ~/ 1000).toString();
      
      final paramsToSign = {
        'public_id': publicId,
        'timestamp': timestamp,
      };
      
      final signature = _generateSignature(paramsToSign);
      
      final url = Uri.parse(
        'https://api.cloudinary.com/v1_1/${CloudinaryConstants.cloudName}/image/destroy'
      );
      
      final response = await http.post(
        url,
        body: {
          'public_id': publicId,
          'timestamp': timestamp,
          'api_key': CloudinaryConstants.apiKey,
          'signature': signature,
        },
      ).timeout(const Duration(seconds: 10)); // Add timeout to prevent hanging

      print('📡 Cloudinary delete response: ${response.statusCode}');
      print('📡 Response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        final result = jsonResponse['result'];
        print('🗑️ Delete $publicId: $result');
        return result == 'ok' || result == 'not found';
      } else {
        print('❌ Delete failed for $publicId: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('❌ Delete error for $publicId: $e');
      return false;
    }
  }

  /// Luu thong tin anh init moi, xoa anh cu neu co
  /// Goi SAU khi upload thanh cong
  /// KHONG xoa neu anh cu la anh model cua user
  Future<void> setInitImage(String publicId, String url) async {
    // Xoa anh cu neu co va khac voi anh moi
    if (_initImagePublicId != null && _initImagePublicId != publicId) {
      // Kiem tra xem anh cu co phai la anh model cua user khong
      if (_isUserModelImage(_initImageUrl)) {
        print('⚠️ Old init image is user model image, skipping delete: $_initImagePublicId');
      } else {
        print('🗑️ Deleting old init image: $_initImagePublicId');
        await deleteImage(_initImagePublicId!);
      }
    }
    
    _initImagePublicId = publicId;
    _initImageUrl = url;
    await _saveToStorage();
    print('📝 Set init image: $publicId');
  }

  /// Luu thong tin anh cloth moi, xoa anh cu neu co
  /// Goi SAU khi upload thanh cong
  /// KHONG xoa neu anh cu la anh model cua user
  Future<void> setClothImage(String publicId, String url) async {
    // Xoa anh cu neu co va khac voi anh moi
    if (_clothImagePublicId != null && _clothImagePublicId != publicId) {
      // Kiem tra xem anh cu co phai la anh model cua user khong
      if (_isUserModelImage(_clothImageUrl)) {
        print('⚠️ Old cloth image is user model image, skipping delete: $_clothImagePublicId');
      } else {
        print('🗑️ Deleting old cloth image: $_clothImagePublicId');
        await deleteImage(_clothImagePublicId!);
      }
    }
    
    _clothImagePublicId = publicId;
    _clothImageUrl = url;
    await _saveToStorage();
    print('📝 Set cloth image: $publicId');
  }

  /// Luu thong tin anh cropped moi (tu Search tab), xoa anh cu neu co
  /// Goi SAU khi upload thanh cong
  Future<void> setCroppedImage(String publicId, String url) async {
    // Xoa anh cu neu co va khac voi anh moi
    if (_croppedImagePublicId != null && _croppedImagePublicId != publicId) {
      print('🗑️ Deleting old cropped image: $_croppedImagePublicId');
      await deleteImage(_croppedImagePublicId!);
    }
    
    _croppedImagePublicId = publicId;
    _croppedImageUrl = url;
    await _saveToStorage();
    print('📝 Set cropped image: $publicId');
  }

  /// Xoa tat ca anh da upload trong session
  /// Goi method nay khi user logout
  /// KHONG xoa anh trung voi anh model cua user
  Future<Map<String, dynamic>> clearSessionUploads() async {
    int deletedCount = 0;
    int failedCount = 0;
    int skippedCount = 0;
    int total = 0;

    // Xoa init image (neu khong phai anh model cua user)
        if (_initImagePublicId != null) {
      total++;
      if (_isUserModelImage(_initImageUrl)) {
        print('⚠️ Init image is user model image, skipping delete: $_initImagePublicId');
        skippedCount++;
        // Van reset tracking
          _initImagePublicId = null;
          _initImageUrl = null;
      } else {
          final success = await deleteImage(_initImagePublicId!);
          if (success) {
            deletedCount++;
            _initImagePublicId = null;
            _initImageUrl = null;
          } else {
            failedCount++;
            // Schedule for retry and still clear local tracking so user not stuck
            await _addPendingDelete(_initImagePublicId!);
            _initImagePublicId = null;
            _initImageUrl = null;
          }
      }
    }

    // Xoa cloth image (neu khong phai anh model cua user)
        if (_clothImagePublicId != null) {
      total++;
      if (_isUserModelImage(_clothImageUrl)) {
        print('⚠️ Cloth image is user model image, skipping delete: $_clothImagePublicId');
        skippedCount++;
        // Van reset tracking
          _clothImagePublicId = null;
          _clothImageUrl = null;
      } else {
          final success = await deleteImage(_clothImagePublicId!);
          if (success) {
            deletedCount++;
            _clothImagePublicId = null;
            _clothImageUrl = null;
          } else {
            failedCount++;
            // Schedule for retry and still clear local tracking so user not stuck
            await _addPendingDelete(_clothImagePublicId!);
            _clothImagePublicId = null;
            _clothImageUrl = null;
          }
      }
    }
    
    // Xoa cropped image (tu Search tab)
    if (_croppedImagePublicId != null) {
      total++;
      final success = await deleteImage(_croppedImagePublicId!);
      if (success) {
        deletedCount++;
        _croppedImagePublicId = null;
        _croppedImageUrl = null;
      } else {
        failedCount++;
        // Schedule for retry and still clear local tracking so user not stuck
        await _addPendingDelete(_croppedImagePublicId!);
        _croppedImagePublicId = null;
        _croppedImageUrl = null;
      }
    }
    
    // Reset user model image URL
    _userModelImageUrl = null;
    
    // Save updated state
    await _saveToStorage();

    if (total == 0) {
      print('📭 No uploads to delete in this session');
    } else {
      print('✅ Session cleanup complete: $deletedCount deleted, $skippedCount skipped (user model), $failedCount failed');
    }
    
    return {
      'deleted': deletedCount,
      'skipped': skippedCount,
      'failed': failedCount,
      'total': total,
    };
  }

  /// Add a publicId to pending deletes (persisted)
  Future<void> _addPendingDelete(String publicId) async {
    if (publicId.isEmpty) return;
    if (!_pendingDeletes.contains(publicId)) {
      _pendingDeletes.add(publicId);
      await _saveToStorage();
      print('🔖 Scheduled pending delete: $publicId');
    }
  }

  /// Reset tracking (khong xoa anh tren cloud)
  void resetTracking() {
    _initImagePublicId = null;
    _clothImagePublicId = null;
    _croppedImagePublicId = null;
    _initImageUrl = null;
    _clothImageUrl = null;
    _croppedImageUrl = null;
    print('🔄 Upload tracking reset');
  }
}
