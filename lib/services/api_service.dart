import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/try_on_request.dart';
import '../models/api_response.dart';
import '../models/image_item.dart';
import '../constants/api_constants.dart';
import '../utils/logger.dart';

class ApiService {
  static const String baseUrl = ApiConstants.baseUrl;
  static const String searchEndpoint = ApiConstants.searchEndpoint;
  static const String tryOnEndpoint = ApiConstants.tryOnEndpoint;

  // Gọi API tìm kiếm
  Future<SearchResponse> searchImages(String imageUrl) async {
    try {
      AppLogger.apiRequest('POST', '$baseUrl$searchEndpoint', body: {'url': imageUrl});
      
      final response = await http.post(
        Uri.parse('$baseUrl$searchEndpoint'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'url': imageUrl}),
      ).timeout(
        ApiConstants.connectionTimeout,
        onTimeout: () {
          throw Exception('Yêu cầu tìm kiếm hết thời gian');
        },
      );

      AppLogger.apiResponse('$baseUrl$searchEndpoint', response.statusCode, body: response.body);

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        
        // Parse từ response format của server
        // Response: {"results": {"image_urls": [[0, "url1"], [1, "url2"], ...]}}
        final results = jsonResponse['results'] as Map<String, dynamic>?;
        
        if (results != null && results['image_urls'] != null) {
          final imageUrlsList = results['image_urls'] as List?;
          final images = <ImageItem>[];
          
          if (imageUrlsList != null) {
            for (var item in imageUrlsList) {
              if (item is List && item.length >= 2) {
                final id = item[0].toString();
                final url = item[1].toString();
                images.add(ImageItem(url: url, id: id));
              }
            }
          }
          
          AppLogger.info('✅ Tìm thấy ${images.length} ảnh');
          
          return SearchResponse(
            images: images,
            success: true,
            message: 'Tìm thấy ${images.length} ảnh',
          );
        }
        
        AppLogger.warning('⚠️ Không tìm thấy ảnh nào trong response');
        return SearchResponse(
          images: [],
          success: false,
          message: 'Không tìm thấy ảnh nào',
        );
      } else {
        throw Exception(
            'Lỗi tìm kiếm: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      AppLogger.apiError('$baseUrl$searchEndpoint', e);
      throw Exception('Lỗi kết nối API: $e');
    }
  }

  // Gọi API try-on
  Future<TryOnResponse> tryOn(String imageUrl) async {
    try {
      AppLogger.apiRequest('POST', '$baseUrl$tryOnEndpoint', body: {'imageUrl': imageUrl});
      
      final request = TryOnRequest(imageUrl: imageUrl);
      final response = await http.post(
        Uri.parse('$baseUrl$tryOnEndpoint'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(request.toJson()),
      ).timeout(
        ApiConstants.connectionTimeout,
        onTimeout: () {
          throw Exception('Yêu cầu try-on hết thời gian');
        },
      );

      AppLogger.apiResponse('$baseUrl$tryOnEndpoint', response.statusCode, body: response.body);

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        return TryOnResponse.fromJson(jsonResponse);
      } else {
        throw Exception('Lỗi try-on: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      AppLogger.apiError('$baseUrl$tryOnEndpoint', e);
      throw Exception('Lỗi kết nối API: $e');
    }
  }
}
