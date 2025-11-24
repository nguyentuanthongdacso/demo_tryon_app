import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/try_on_request.dart';
import '../models/api_response.dart';
import '../models/image_item.dart';
import '../constants/api_constants.dart';
import '../utils/logger.dart';

class ApiService {
  static String get baseUrl => ApiConstants.baseUrl;
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
        
        // Parse từ response format mới của server
        // Response: {"status":"success","results":{"image_urls":["url1","url2",...]}}
        final results = jsonResponse['results'] as Map<String, dynamic>?;
        final images = <ImageItem>[];
        
        if (results != null && results['image_urls'] != null) {
          final imageUrlsList = results['image_urls'] as List?;
          
          if (imageUrlsList != null) {
            for (int i = 0; i < imageUrlsList.length; i++) {
              final url = imageUrlsList[i].toString();
              // Sử dụng index làm ID
              images.add(ImageItem(url: url, id: i.toString()));
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
      final tryOnUrl = Uri.parse('${ApiConstants.tryOnBaseUrl}$tryOnEndpoint');
      final response = await http.post(
        tryOnUrl,
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

      AppLogger.apiResponse('${ApiConstants.tryOnBaseUrl}$tryOnEndpoint', response.statusCode, body: response.body);

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
