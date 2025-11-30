import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import '../constants/cloudinary_constants.dart';

/// Quản lý các ảnh đã upload trong phiên đăng nhập
/// Tự động xóa tất cả ảnh khi user logout
class SessionUploadManager {
  // Singleton pattern
  static final SessionUploadManager _instance = SessionUploadManager._internal();
  factory SessionUploadManager() => _instance;
  SessionUploadManager._internal();

  // Danh sách public_id của các ảnh đã upload trong session này
  final Set<String> _uploadedPublicIds = {};

  /// Thêm public_id vào danh sách theo dõi
  void trackUpload(String publicId) {
    _uploadedPublicIds.add(publicId);
    print('📝 Tracking upload: $publicId (Total: ${_uploadedPublicIds.length})');
  }

  /// Lấy danh sách các public_id đã upload
  Set<String> get uploadedPublicIds => Set.unmodifiable(_uploadedPublicIds);

  /// Số lượng ảnh đã upload trong session
  int get uploadCount => _uploadedPublicIds.length;

  /// Tạo signature cho Cloudinary Admin API
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

  /// Xóa một ảnh trên Cloudinary bằng public_id
  Future<bool> _deleteImage(String publicId) async {
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

  /// Xóa tất cả ảnh đã upload trong session
  /// Gọi method này khi user logout
  Future<Map<String, dynamic>> clearSessionUploads() async {
    if (_uploadedPublicIds.isEmpty) {
      print('📭 No uploads to delete in this session');
      return {'deleted': 0, 'failed': 0, 'total': 0};
    }

    print('🧹 Clearing ${_uploadedPublicIds.length} session uploads...');
    
    int deletedCount = 0;
    int failedCount = 0;
    final List<String> toDelete = List.from(_uploadedPublicIds);

    // Xóa từng ảnh (có thể batch nhưng đơn giản hơn là xóa từng cái)
    for (final publicId in toDelete) {
      final success = await _deleteImage(publicId);
      if (success) {
        deletedCount++;
        _uploadedPublicIds.remove(publicId);
      } else {
        failedCount++;
      }
    }

    print('✅ Session cleanup complete: $deletedCount deleted, $failedCount failed');
    
    return {
      'deleted': deletedCount,
      'failed': failedCount,
      'total': toDelete.length,
    };
  }

  /// Reset tracking (không xóa ảnh trên cloud)
  void resetTracking() {
    _uploadedPublicIds.clear();
    print('🔄 Upload tracking reset');
  }
}
