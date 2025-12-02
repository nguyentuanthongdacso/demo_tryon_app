import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/tryon_request.dart';
import '../models/tryon_response.dart';
import '../constants/api_constants.dart';
import 'auth_service.dart';

class TryonService {
  // Production URL via Cloudflare
  static String get _baseHost => ApiConstants.tryOnBaseUrl;
  static const String tryonEndpoint = '/tryon';
  static const Duration timeout = Duration(seconds: 120);
  
  // AuthService để lấy JWT token
  final AuthService _authService = AuthService();
  
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

  Future<TryonResponse> sendTryonRequest(TryonRequest request) async {
    final url = Uri.parse('$_baseHost$tryonEndpoint');
    try {
      final response = await http.post(
      url,
      headers: _getAuthHeaders(),  // JWT token included
      body: jsonEncode(request.toJson()),
      ).timeout(timeout);
      
      // Check for auth errors
      if (response.statusCode == 401) {
        throw Exception('Phiên đăng nhập hết hạn. Vui lòng đăng nhập lại.');
      }

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        return TryonResponse.fromJson(jsonResponse);
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } on SocketException catch (e) {
      // Provide a clear error message when the client cannot connect
      throw Exception('Connection failed. Is the try-on server running and reachable at $_baseHost? (${e.message})');
    }
  }
}
