import 'dart:io';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import '../constants/cloudinary_constants.dart';

class CloudinaryService {
  // Cache để tránh upload trùng lặp trong cùng session
  final Map<String, String> _uploadCache = {};

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
  /// Ảnh sẽ được resize về 512x512 với padding (không cắt, không mất ảnh gốc)
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

      print('🔵 Uploading to Cloudinary (signed)...');
      print('📁 File: ${file.path}');
      print('🔑 File Hash: $fileHash');

      // Timestamp cho signature
      final timestamp = (DateTime.now().millisecondsSinceEpoch ~/ 1000).toString();
      
      // Public ID dựa trên hash
      final publicId = 'tryon_$fileHash';
      
      // Transformation: resize về 512x512 với padding
      const transformation = 'c_pad,w_512,h_512,b_white';
      
      // Params cần sign (KHÔNG bao gồm file, api_key, signature)
      final paramsToSign = {
        'timestamp': timestamp,
        'public_id': publicId,
        'overwrite': 'true',
        'transformation': transformation,
      };
      
      // Tạo signature
      final signature = _generateSignature(paramsToSign);

      // Add the image file
      final multipartFile = await http.MultipartFile.fromPath(
        'file',
        file.path,
      );
      request.files.add(multipartFile);

      // Add all fields
      request.fields['api_key'] = CloudinaryConstants.apiKey;
      request.fields['timestamp'] = timestamp;
      request.fields['public_id'] = publicId;
      request.fields['overwrite'] = 'true';
      request.fields['transformation'] = transformation;
      request.fields['signature'] = signature;
      
      // Send request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('📊 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        final secureUrl = jsonResponse['secure_url'] as String;
        
        // Lưu vào cache
        _uploadCache[fileHash] = secureUrl;
        
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
