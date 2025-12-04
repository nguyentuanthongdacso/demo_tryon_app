import 'dart:io';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import '../constants/cloudinary_constants.dart';
import 'session_upload_manager.dart';

/// Ket qua upload anh len Cloudinary
class CloudinaryUploadResult {
  final String url;
  final String publicId;
  final String hash;

  CloudinaryUploadResult({
    required this.url,
    required this.publicId,
    required this.hash,
  });
}

class CloudinaryService {
  // Cache de tranh upload trung lap trong cung session
  final Map<String, CloudinaryUploadResult> _uploadCache = {};
  
  // Session upload manager de track cac anh da upload
  final SessionUploadManager _sessionManager = SessionUploadManager();

  /// Tao hash MD5 tu noi dung file de lam unique ID
  /// Public method de co the dung tu ben ngoai
  Future<String> getFileHash(File file) async {
    final bytes = await file.readAsBytes();
    final digest = md5.convert(bytes);
    return digest.toString();
  }

  /// Tao signature cho signed upload
  String _generateSignature(Map<String, String> params) {
    // Sap xep params theo alphabet va tao string
    final sortedKeys = params.keys.toList()..sort();
    final paramString = sortedKeys
        .map((key) => '$key=${params[key]}')
        .join('&');
    
    // Them API Secret vao cuoi va hash SHA1
    final stringToSign = '$paramString${CloudinaryConstants.apiSecret}';
    final bytes = utf8.encode(stringToSign);
    final digest = sha1.convert(bytes);
    
    return digest.toString();
  }

  /// Upload file to Cloudinary using SIGNED upload
  /// [imageType] - 'init' hoac 'cloth' de xac dinh loai anh
  /// Su dung hash de tranh upload trung lap
  /// Tu dong xoa anh cu va luu anh moi vao SessionUploadManager
  Future<CloudinaryUploadResult> uploadImageWithTracking(File file, String imageType) async {
    try {
      // Tao hash tu file de kiem tra trung lap
      final fileHash = await getFileHash(file);
      
      // Kiem tra cache - neu da upload trong session nay thi tra ve URL cu
      if (_uploadCache.containsKey(fileHash)) {
        print('♻️ Image already uploaded in this session, using cached URL');
        return _uploadCache[fileHash]!;
      }

      final url = Uri.parse(CloudinaryConstants.uploadUrl);
      final request = http.MultipartRequest('POST', url);

      print('🔵 Uploading $imageType image to Cloudinary...');
      print('📁 File: ${file.path}');
      print('🔑 File Hash: $fileHash');

      // Timestamp cho signature
      final timestamp = (DateTime.now().millisecondsSinceEpoch ~/ 1000).toString();
      
      // Public ID dua tren hash
      final publicId = 'tryon_${imageType}_$fileHash';
      
      // Params can sign
      final paramsToSign = {
        'timestamp': timestamp,
        'public_id': publicId,
        'overwrite': 'true',
      };
      
      // Tao signature
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
      request.fields['signature'] = signature;
      
      // Send request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('📊 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        final secureUrl = jsonResponse['secure_url'] as String;
        
        final result = CloudinaryUploadResult(
          url: secureUrl,
          publicId: publicId,
          hash: fileHash,
        );
        
        // Luu vao cache
        _uploadCache[fileHash] = result;
        
        // Luu vao SessionUploadManager va xoa anh cu (neu co)
        if (imageType == 'init') {
          await _sessionManager.setInitImage(publicId, secureUrl);
        } else if (imageType == 'cloth') {
          await _sessionManager.setClothImage(publicId, secureUrl);
        } else if (imageType == 'cropped') {
          await _sessionManager.setCroppedImage(publicId, secureUrl);
        }
        
        print('✅ Upload successful!');
        print('🔗 URL: $secureUrl');
        return result;
      } else {
        print('❌ Response body: ${response.body}');
        throw Exception('Upload failed: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('❌ Upload error: $e');
      throw Exception('Cloudinary upload error: $e');
    }
  }

  /// Upload don gian (khong tracking) - dung cho model image
  Future<String> uploadImage(File file) async {
    try {
      final fileHash = await getFileHash(file);
      
      final url = Uri.parse(CloudinaryConstants.uploadUrl);
      final request = http.MultipartRequest('POST', url);

      print('🔵 Uploading to Cloudinary (no tracking)...');

      final timestamp = (DateTime.now().millisecondsSinceEpoch ~/ 1000).toString();
      final publicId = 'model_$fileHash';
      
      final paramsToSign = {
        'timestamp': timestamp,
        'public_id': publicId,
        'overwrite': 'true',
      };
      
      final signature = _generateSignature(paramsToSign);

      final multipartFile = await http.MultipartFile.fromPath(
        'file',
        file.path,
      );
      request.files.add(multipartFile);

      request.fields['api_key'] = CloudinaryConstants.apiKey;
      request.fields['timestamp'] = timestamp;
      request.fields['public_id'] = publicId;
      request.fields['overwrite'] = 'true';
      request.fields['signature'] = signature;
      
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        final secureUrl = jsonResponse['secure_url'] as String;
        print('✅ Upload successful: $secureUrl');
        return secureUrl;
      } else {
        throw Exception('Upload failed: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Upload error: $e');
      throw Exception('Cloudinary upload error: $e');
    }
  }

  /// Xoa cache (neu can reset)
  void clearCache() {
    _uploadCache.clear();
  }
}
