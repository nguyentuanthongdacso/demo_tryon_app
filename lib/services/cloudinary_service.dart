import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/cloudinary_constants.dart';

class CloudinaryService {
  /// Upload file to Cloudinary using unsigned upload preset
  /// This is simpler and doesn't require signature generation
  Future<String> uploadImage(File file) async {
    try {
      final url = Uri.parse(CloudinaryConstants.uploadUrl);
      final request = http.MultipartRequest('POST', url);

      print('🔵 Uploading to Cloudinary...');
      print('📍 URL: ${CloudinaryConstants.uploadUrl}');
      print('📁 File: ${file.path}');
      print('🔧 Upload Preset: ${CloudinaryConstants.uploadPreset}');

      // Add the image file
      final multipartFile = await http.MultipartFile.fromPath(
        'file',
        file.path,
      );
      request.files.add(multipartFile);

      // Use upload preset for unsigned uploads (no signature required)
      request.fields['upload_preset'] = CloudinaryConstants.uploadPreset;
      
      // Send request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('📊 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        final secureUrl = jsonResponse['secure_url'] as String;
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

}
