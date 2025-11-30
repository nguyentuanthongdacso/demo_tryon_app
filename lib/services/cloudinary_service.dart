import 'dart:io';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import '../constants/cloudinary_constants.dart';
import 'session_upload_manager.dart';

class CloudinaryService {
  // Cache để tránh upload trùng lặp trong cùng session
  final Map<String, String> _uploadCache = {};
  
  // Session upload manager để track các ảnh đã upload
  final SessionUploadManager _sessionManager = SessionUploadManager();

  /// Tạo hash MD5 từ nội dung file để làm unique ID
  /// Public method để có thể dùng từ bên ngoài
  Future<String> getFileHash(File file) async {
    final bytes = await file.readAsBytes();
    final digest = md5.convert(bytes);
    return digest.toString();
  }

  /// Tạo signature cho signed upload
  String _generateSignature(Map<String, String> params) {
    // Sắp xếp params theo alphabet và tạo string
    final sortedKeys = params.keys.toList()..sort();
    final paramString = sortedKeys
        .map((key) => '$key=${params[key]}')
        .join('&');
    
    // Thêm API Secret vào cuối và hash SHA1
    final stringToSign = '$paramString${CloudinaryConstants.apiSecret}';
    final bytes = utf8.encode(stringToSign);
    final digest = sha1.convert(bytes);
    
    return digest.toString();
  }

  /// Upload file to Cloudinary using SIGNED upload
  /// Upload ảnh GỐC không có bất kỳ transformation nào
  /// Sử dụng hash để tránh upload trùng lặp
  Future<String> uploadImage(File file) async {
    try {
      // Tạo hash từ file để kiểm tra trùng lặp
      final fileHash = await getFileHash(file);
      
      // Kiểm tra cache - nếu đã upload trong session này thì trả về URL cũ
      if (_uploadCache.containsKey(fileHash)) {
        print('♻️ Image already uploaded in this session, using cached URL');
        return _uploadCache[fileHash]!;
      }

      final url = Uri.parse(CloudinaryConstants.uploadUrl);
      final request = http.MultipartRequest('POST', url);

      print('🔵 Uploading to Cloudinary (signed, no transformation)...');
      print('📁 File: ${file.path}');
      print('🔑 File Hash: $fileHash');

      // Timestamp cho signature
      final timestamp = (DateTime.now().millisecondsSinceEpoch ~/ 1000).toString();
      
      // Public ID dựa trên hash
      final publicId = 'tryon_$fileHash';
      
      // Params cần sign - CHỈ có timestamp, public_id, overwrite (KHÔNG có transformation)
      final paramsToSign = {
        'timestamp': timestamp,
        'public_id': publicId,
        'overwrite': 'true',
      };
      
      // Tạo signature
      final signature = _generateSignature(paramsToSign);

      // Add the image file
      final multipartFile = await http.MultipartFile.fromPath(
        'file',
        file.path,
      );
      request.files.add(multipartFile);

      // Add all fields - KHÔNG có transformation
      request.fields['api_key'] = CloudinaryConstants.apiKey;
      request.fields['timestamp'] = timestamp;
      request.fields['public_id'] = publicId;
      request.fields['overwrite'] = 'true';
      request.fields['signature'] = signature;
      
      // Send request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('📊 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        // Lấy URL ảnh gốc (không có transformation trong URL)
        final secureUrl = jsonResponse['secure_url'] as String;
        
        // Lưu vào cache
        _uploadCache[fileHash] = secureUrl;
        
        // Track upload để xóa khi logout
        _sessionManager.trackUpload(publicId);
        
        print('✅ Upload successful!');
        print('🔗 URL: $secureUrl');
        return secureUrl;
      } else {
        print('❌ Response body: ${response.body}');
        throw Exception('Upload failed: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('❌ Upload error: $e');
      throw Exception('Cloudinary upload error: $e');
    }
  }

  /// Xóa cache (nếu cần reset)
  void clearCache() {
    _uploadCache.clear();
  }
}
