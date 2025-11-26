import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../models/try_on_request.dart';
import '../models/api_response.dart';
import '../models/image_item.dart';
import '../constants/api_constants.dart';
import '../utils/logger.dart';

class ApiService {
  static String get baseUrl => ApiConstants.baseUrl;
  static String get wsBaseUrl => ApiConstants.wsBaseUrl;
  static const String searchEndpoint = ApiConstants.searchEndpoint;
  static const String tryOnEndpoint = ApiConstants.tryOnEndpoint;

  // Gọi API tìm kiếm với WebSocket
  Future<SearchResponse> searchImages(String imageUrl) async {
    try {
      AppLogger.apiRequest('POST', '$baseUrl$searchEndpoint', body: {'url': imageUrl});
      
      // Bước 1: Gửi HTTP request để tạo task
      final response = await http.post(
        Uri.parse('$baseUrl$searchEndpoint'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'url': imageUrl}),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Yêu cầu tạo task hết thời gian');
        },
      );

      AppLogger.apiResponse('$baseUrl$searchEndpoint', response.statusCode, body: response.body);

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
      final wsUrl = '$wsBaseUrl/ws/$taskId';
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
