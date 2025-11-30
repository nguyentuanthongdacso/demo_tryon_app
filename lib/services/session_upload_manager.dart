import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/cloudinary_constants.dart';

/// Quan ly cac anh da upload trong phien dang nhap
/// Chi giu toi da 2 anh (init + cloth) tai moi thoi diem
/// Tu dong xoa tat ca anh khi user logout hoac app khoi dong lai
/// KHONG xoa anh trung voi anh model cua user
class SessionUploadManager {
  // Singleton pattern
  static final SessionUploadManager _instance = SessionUploadManager._internal();
  factory SessionUploadManager() => _instance;
  SessionUploadManager._internal();
  
  // Keys cho SharedPreferences
  static const String _keyInitPublicId = 'session_init_public_id';
  static const String _keyClothPublicId = 'session_cloth_public_id';
  static const String _keyInitUrl = 'session_init_url';
  static const String _keyClothUrl = 'session_cloth_url';
  static const String _keyUserModelUrl = 'session_user_model_url';

  // Luu public_id theo loai anh (init hoac cloth)
  String? _initImagePublicId;
  String? _clothImagePublicId;
  
  // Luu URL tuong ung
  String? _initImageUrl;
  String? _clothImageUrl;
  
  // Luu URL anh model cua user (de khong xoa nhom anh nay)
  String? _userModelImageUrl;

  // Getters
  String? get initImagePublicId => _initImagePublicId;
  String? get clothImagePublicId => _clothImagePublicId;
  String? get initImageUrl => _initImageUrl;
  String? get clothImageUrl => _clothImageUrl;
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
  
  // ========== PERSISTENCE (SharedPreferences) ==========
  
  /// Luu trang thai hien tai vao SharedPreferences
  Future<void> _saveToStorage() async {
    final prefs = await SharedPreferences.getInstance();
    
    if (_initImagePublicId != null) {
      await prefs.setString(_keyInitPublicId, _initImagePublicId!);
    } else {
      await prefs.remove(_keyInitPublicId);
    }
    
    if (_clothImagePublicId != null) {
      await prefs.setString(_keyClothPublicId, _clothImagePublicId!);
    } else {
      await prefs.remove(_keyClothPublicId);
    }
    
    if (_initImageUrl != null) {
      await prefs.setString(_keyInitUrl, _initImageUrl!);
    } else {
      await prefs.remove(_keyInitUrl);
    }
    
    if (_clothImageUrl != null) {
      await prefs.setString(_keyClothUrl, _clothImageUrl!);
    } else {
      await prefs.remove(_keyClothUrl);
    }
    
    if (_userModelImageUrl != null) {
      await prefs.setString(_keyUserModelUrl, _userModelImageUrl!);
    } else {
      await prefs.remove(_keyUserModelUrl);
    }
    
    print('💾 Session state saved to storage');
  }
  
  /// Load trang thai tu SharedPreferences
  Future<void> _loadFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    
    _initImagePublicId = prefs.getString(_keyInitPublicId);
    _clothImagePublicId = prefs.getString(_keyClothPublicId);
    _initImageUrl = prefs.getString(_keyInitUrl);
    _clothImageUrl = prefs.getString(_keyClothUrl);
    _userModelImageUrl = prefs.getString(_keyUserModelUrl);
    
    print('📂 Session state loaded from storage:');
    print('   Init: $_initImagePublicId');
    print('   Cloth: $_clothImagePublicId');
    print('   User model: $_userModelImageUrl');
  }
  
  /// Xoa du lieu trong SharedPreferences
  Future<void> _clearStorage() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyInitPublicId);
    await prefs.remove(_keyClothPublicId);
    await prefs.remove(_keyInitUrl);
    await prefs.remove(_keyClothUrl);
    await prefs.remove(_keyUserModelUrl);
    print('🗑️ Session storage cleared');
  }
  
  /// GOI KHI APP KHOI DONG: Load va xoa anh cu tu phien truoc
  Future<void> cleanupPreviousSession() async {
    try {
      print('🚀 Checking for previous session uploads to clean up...');
      
      // Load du lieu tu storage
      await _loadFromStorage();
      
      // Xoa anh cu (neu co) - KHONG xoa anh model cua user
      await clearSessionUploads();
      
      // Xoa storage
      await _clearStorage();
      
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
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        final result = jsonResponse['result'];
        print('🗑️ Delete $publicId: $result');
        return result == 'ok';
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
        }
      }
    }
    
    // Reset user model image URL
    _userModelImageUrl = null;

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

  /// Reset tracking (khong xoa anh tren cloud)
  void resetTracking() {
    _initImagePublicId = null;
    _clothImagePublicId = null;
    _initImageUrl = null;
    _clothImageUrl = null;
    print('🔄 Upload tracking reset');
  }
}
