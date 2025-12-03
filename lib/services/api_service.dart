import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../models/try_on_request.dart';
import '../models/api_response.dart';
import '../models/image_item.dart';
import '../models/tryon_image.dart';
import '../constants/api_constants.dart';
import '../utils/logger.dart';
import 'auth_service.dart';

class ApiService {
  // AuthService để lấy JWT token
  final AuthService _authService = AuthService();
  
  // Search/Scrape uses scrape server
  static String get searchBaseUrl => ApiConstants.searchBaseUrl;
  static String get wsBaseUrl => ApiConstants.wsBaseUrl;
  static const String searchEndpoint = ApiConstants.searchEndpoint;
  
  // Try-on uses tryon server
  static String get tryOnBaseUrl => ApiConstants.tryOnBaseUrl;
  static const String tryOnEndpoint = ApiConstants.tryOnEndpoint;
  
  /// Get authorization headers with JWT token
  Map<String, String> _getAuthHeaders() {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    
    final token = _authService.jwtToken;
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    
    return headers;
  }

  // Gọi API tìm kiếm với WebSocket
  Future<SearchResponse> searchImages(String imageUrl) async {
    try {
      AppLogger.apiRequest('POST', '$searchBaseUrl$searchEndpoint', body: {'url': imageUrl});
      
      // Bước 1: Gửi HTTP request để tạo task (với JWT)
      final response = await http.post(
        Uri.parse('$searchBaseUrl$searchEndpoint'),
        headers: _getAuthHeaders(),
        body: jsonEncode({'url': imageUrl}),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Yêu cầu tạo task hết thời gian');
        },
      );

      AppLogger.apiResponse('$searchBaseUrl$searchEndpoint', response.statusCode, body: response.body);
      
      // Check for auth errors
      if (response.statusCode == 401) {
        throw Exception('Phiên đăng nhập hết hạn. Vui lòng đăng nhập lại.');
      }

      if (response.statusCode != 200) {
        throw Exception('Lỗi tạo task: ${response.statusCode} - ${response.body}');
      }

      final jsonResponse = jsonDecode(response.body);
      final taskId = jsonResponse['task_id'] as String?;
      
      if (taskId == null) {
        throw Exception('Không nhận được task_id từ server');
      }

      AppLogger.info('📝 Task ID: $taskId');
      
      // Bước 2: Kết nối WebSocket để nhận real-time updates
      // WebSocket vẫn trên scrape server
      final wsUrl = 'wss://scrape.tryonstylist.com/ws/$taskId';
      AppLogger.info('🔌 Connecting to WebSocket: $wsUrl');
      
      final channel = WebSocketChannel.connect(Uri.parse(wsUrl));
      final completer = Completer<SearchResponse>();
      
      // Bước 3: Lắng nghe kết quả từ WebSocket
      channel.stream.listen(
        (message) {
          try {
            final data = jsonDecode(message as String);
            final msgType = data['type'] as String?;
            
            AppLogger.info('📨 WebSocket message type: $msgType');
            
            // Xử lý message "connected" - chỉ log, không đóng kết nối
            if (msgType == 'connected') {
              final state = data['state'] as String?;
              AppLogger.info('🔌 Connected to task, state: $state');
              return; // Tiếp tục lắng nghe message tiếp theo
            }
            
            // Xử lý message "completed" - trả về kết quả
            if (msgType == 'completed') {
              final result = data['result'] as Map<String, dynamic>?;
              final imageUrlsList = result?['image_urls'] as List?;
              final images = <ImageItem>[];
              
              if (imageUrlsList != null) {
                for (int i = 0; i < imageUrlsList.length; i++) {
                  final url = imageUrlsList[i].toString();
                  images.add(ImageItem(url: url, id: i.toString()));
                }
              }
              
              AppLogger.info('✅ Tìm thấy ${images.length} ảnh');
              
              channel.sink.close();
              if (!completer.isCompleted) {
                completer.complete(SearchResponse(
                  images: images,
                  success: true,
                  message: 'Tìm thấy ${images.length} ảnh',
                ));
              }
              return;
            }
            
            // Xử lý message "failed" - trả về lỗi
            if (msgType == 'failed') {
              final error = data['error'] as String? ?? 'Unknown error';
              AppLogger.logError('❌ Task failed: $error');
              
              channel.sink.close();
              if (!completer.isCompleted) {
                completer.complete(SearchResponse(
                  images: [],
                  success: false,
                  message: 'Lỗi: $error',
                ));
              }
              return;
            }
            
            // Các message type khác - chỉ log
            AppLogger.info('ℹ️ Unknown message type: $msgType');
            
          } catch (e) {
            AppLogger.logError('❌ Error parsing WebSocket message', e);
          }
        },
        onError: (error) {
          AppLogger.logError('❌ WebSocket error', error);
          if (!completer.isCompleted) {
            completer.complete(SearchResponse(
              images: [],
              success: false,
              message: 'Lỗi WebSocket: $error',
            ));
          }
        },
        onDone: () {
          AppLogger.info('🔌 WebSocket closed');
          if (!completer.isCompleted) {
            completer.complete(SearchResponse(
              images: [],
              success: false,
              message: 'WebSocket đóng kết nối trước khi nhận được kết quả',
            ));
          }
        },
      );
      
      // Timeout cho WebSocket (60 giây)
      return completer.future.timeout(
        const Duration(seconds: 60),
        onTimeout: () {
          channel.sink.close();
          AppLogger.warning('⚠️ WebSocket timeout');
          return SearchResponse(
            images: [],
            success: false,
            message: 'Yêu cầu hết thời gian chờ',
          );
        },
      );
      
    } catch (e) {
      AppLogger.apiError('$searchBaseUrl$searchEndpoint', e);
      throw Exception('Lỗi kết nối API: $e');
    }
  }

  // Gọi API try-on
  Future<TryOnResponse> tryOn(String imageUrl) async {
    try {
      AppLogger.apiRequest('POST', '$tryOnBaseUrl$tryOnEndpoint', body: {'imageUrl': imageUrl});
      
      final request = TryOnRequest(imageUrl: imageUrl);
      final tryOnUrl = Uri.parse('$tryOnBaseUrl$tryOnEndpoint');
      final response = await http.post(
        tryOnUrl,
        headers: _getAuthHeaders(),  // JWT token included
        body: jsonEncode(request.toJson()),
      ).timeout(
        ApiConstants.connectionTimeout,
        onTimeout: () {
          throw Exception('Yêu cầu try-on hết thời gian');
        },
      );

      AppLogger.apiResponse('$tryOnBaseUrl$tryOnEndpoint', response.statusCode, body: response.body);
      
      // Check for auth errors
      if (response.statusCode == 401) {
        throw Exception('Phiên đăng nhập hết hạn. Vui lòng đăng nhập lại.');
      }

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        return TryOnResponse.fromJson(jsonResponse);
      } else {
        throw Exception('Lỗi try-on: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      AppLogger.apiError('$tryOnBaseUrl$tryOnEndpoint', e);
      throw Exception('Lỗi kết nối API: $e');
    }
  }

  // ==================== TRYON IMAGE APIs ====================

  /// Lưu ảnh tryon vào database
  /// Trả về SaveTryonImageResponse với thông tin ảnh đã lưu
  Future<SaveTryonImageResponse> saveTryonImage({
    required String userKey,
    required String imageUrl,
  }) async {
    try {
      final url = '${ApiConstants.gatewayBaseUrl}${ApiConstants.saveTryonImageEndpoint}';
      AppLogger.apiRequest('POST', url, body: {
        'type': 'save_tryon_image',
        'user_key': userKey,
        'image_url': imageUrl,
      });

      final response = await http.post(
        Uri.parse(url),
        headers: _getAuthHeaders(),
        body: jsonEncode({
          'type': 'save_tryon_image',
          'user_key': userKey,
          'image_url': imageUrl,
        }),
      ).timeout(ApiConstants.connectionTimeout);

      AppLogger.apiResponse(url, response.statusCode, body: response.body);

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        return SaveTryonImageResponse.fromJson(jsonResponse);
      } else {
        throw Exception('Lỗi lưu ảnh tryon: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      AppLogger.apiError('saveTryonImage', e);
      return SaveTryonImageResponse(
        success: false,
        message: 'Lỗi kết nối: $e',
        tryonImage: null,
      );
    }
  }

  /// Lấy danh sách ảnh tryon của user (tối đa 10 ảnh gần nhất)
  Future<GetTryonImagesResponse> getTryonImages({
    required String userKey,
    int limit = 10,
  }) async {
    try {
      final url = '${ApiConstants.gatewayBaseUrl}${ApiConstants.getTryonImagesEndpoint}';
      AppLogger.apiRequest('POST', url, body: {
        'type': 'get_tryon_images',
        'user_key': userKey,
        'limit': limit,
      });

      final response = await http.post(
        Uri.parse(url),
        headers: _getAuthHeaders(),
        body: jsonEncode({
          'type': 'get_tryon_images',
          'user_key': userKey,
          'limit': limit,
        }),
      ).timeout(ApiConstants.connectionTimeout);

      AppLogger.apiResponse(url, response.statusCode, body: response.body);

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        return GetTryonImagesResponse.fromJson(jsonResponse);
      } else {
        throw Exception('Lỗi lấy ảnh tryon: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      AppLogger.apiError('getTryonImages', e);
      return GetTryonImagesResponse(
        success: false,
        message: 'Lỗi kết nối: $e',
        tryonImages: [],
        total: 0,
      );
    }
  }
}
