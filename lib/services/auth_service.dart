import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

/// Service xử lý authentication với API Gateway
/// Gửi request đến 3_api_gateway và quản lý JWT token
class AuthService {
  // Singleton pattern
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  // API Gateway URL - Port 8003
  static String get _gatewayUrl {
    if (Platform.isAndroid) return 'http://10.0.2.2:8003';
    return 'http://127.0.0.1:8003';
  }

  // JWT token và user data
  String? _jwtToken;
  Map<String, dynamic>? _currentUser;

  // Getters
  String? get jwtToken => _jwtToken;
  Map<String, dynamic>? get currentUser => _currentUser;
  bool get isLoggedIn => _jwtToken != null && _currentUser != null;

  // User info getters
  String? get userKey => _currentUser?['user_key'];
  String? get userEmail => _currentUser?['email'];
  String? get userName => _currentUser?['name'];
  int? get tokenFree => _currentUser?['token_free'];
  int? get tokenVip => _currentUser?['token_vip'];

  /// Check login với API Gateway sau Google Sign-In
  /// 
  /// [email] - Email từ Google account
  /// [name] - Tên từ Google account (optional)
  /// [photoUrl] - URL ảnh đại diện (optional)
  Future<CheckLoginResponse> checkLogin({
    required String email,
    String? name,
    String? photoUrl,
  }) async {
    try {
      final url = Uri.parse('$_gatewayUrl/check-login');
      
      final requestBody = {
        'type': 'check_login',
        'email': email,
        if (name != null) 'name': name,
        if (photoUrl != null) 'photoUrl': photoUrl,
      };

      print('🔐 Check-login: $url');
      print('📧 Email: $email');

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      ).timeout(const Duration(seconds: 30));

      print('📊 Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        final result = CheckLoginResponse.fromJson(jsonResponse);

        if (result.success && result.jwtToken != null) {
          _jwtToken = result.jwtToken;
          _currentUser = result.user;
          print('✅ Login success! JWT saved.');
        }

        return result;
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } on SocketException {
      return CheckLoginResponse(
        success: false,
        message: 'Không thể kết nối server',
      );
    } catch (e) {
      print('❌ Check-login error: $e');
      return CheckLoginResponse(
        success: false,
        message: e.toString(),
      );
    }
  }

  /// Lấy headers với JWT token cho authenticated requests
  Map<String, String> getAuthHeaders() {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    if (_jwtToken != null) {
      headers['Authorization'] = 'Bearer $_jwtToken';
    }
    return headers;
  }

  /// Logout - xóa JWT và user data
  void logout() {
    _jwtToken = null;
    _currentUser = null;
    print('👋 Logged out');
  }

  /// Cập nhật user data (sau khi token thay đổi)
  void updateUser(Map<String, dynamic> userData) {
    _currentUser = userData;
  }

  /// Check token từ server
  Future<CheckTokenResponse> checkToken() async {
    if (_jwtToken == null || userKey == null) {
      return CheckTokenResponse(success: false, message: 'Not logged in');
    }

    try {
      final url = Uri.parse('$_gatewayUrl/check-token');
      final response = await http.post(
        url,
        headers: getAuthHeaders(),
        body: jsonEncode({
          'type': 'check_token',
          'user_key': userKey,
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return CheckTokenResponse.fromJson(jsonDecode(response.body));
      } else if (response.statusCode == 401) {
        // Token expired
        logout();
        return CheckTokenResponse(success: false, message: 'Token expired');
      }
      throw Exception('Server error: ${response.statusCode}');
    } catch (e) {
      return CheckTokenResponse(success: false, message: e.toString());
    }
  }

  /// Trừ token
  Future<SubtractTokenResponse> subtractToken(int amount) async {
    if (_jwtToken == null || userKey == null) {
      return SubtractTokenResponse(success: false, message: 'Not logged in');
    }

    try {
      final url = Uri.parse('$_gatewayUrl/subtract-token');
      final response = await http.post(
        url,
        headers: getAuthHeaders(),
        body: jsonEncode({
          'type': 'subtract_token',
          'user_key': userKey,
          'token_value': amount,
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final result = SubtractTokenResponse.fromJson(jsonDecode(response.body));
        // Cập nhật local user data
        if (result.success && _currentUser != null) {
          _currentUser!['token_free'] = result.tokenFreeRemaining;
          _currentUser!['token_vip'] = result.tokenVipRemaining;
        }
        return result;
      } else if (response.statusCode == 401) {
        logout();
        return SubtractTokenResponse(success: false, message: 'Token expired');
      }
      throw Exception('Server error: ${response.statusCode}');
    } catch (e) {
      return SubtractTokenResponse(success: false, message: e.toString());
    }
  }

  /// Thay doi anh mau cua user
  Future<ChangeImageResponse> changeImage(String newImageUrl) async {
    if (_jwtToken == null || userKey == null) {
      return ChangeImageResponse(success: false, message: 'Not logged in');
    }

    try {
      final url = Uri.parse('$_gatewayUrl/change-img');
      final response = await http.post(
        url,
        headers: getAuthHeaders(),
        body: jsonEncode({
          'type': 'change_img',
          'user_key': userKey,
          'image': newImageUrl,
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final result = ChangeImageResponse.fromJson(jsonDecode(response.body));
        // Cap nhat local user data
        if (result.success && _currentUser != null) {
          _currentUser!['image'] = result.image;
        }
        return result;
      } else if (response.statusCode == 401) {
        logout();
        return ChangeImageResponse(success: false, message: 'Token expired');
      }
      throw Exception('Server error: ${response.statusCode}');
    } catch (e) {
      return ChangeImageResponse(success: false, message: e.toString());
    }
  }
}


// ===== RESPONSE MODELS =====

class CheckLoginResponse {
  final bool success;
  final String message;
  final bool isNewUser;
  final Map<String, dynamic>? user;
  final String? jwtToken;

  CheckLoginResponse({
    required this.success,
    required this.message,
    this.isNewUser = false,
    this.user,
    this.jwtToken,
  });

  factory CheckLoginResponse.fromJson(Map<String, dynamic> json) {
    return CheckLoginResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      isNewUser: json['is_new_user'] ?? false,
      user: json['user'] as Map<String, dynamic>?,
      jwtToken: json['jwt_token'] as String?,
    );
  }
}


class CheckTokenResponse {
  final bool success;
  final String message;
  final int? tokenFree;
  final int? tokenVip;

  CheckTokenResponse({
    required this.success,
    required this.message,
    this.tokenFree,
    this.tokenVip,
  });

  factory CheckTokenResponse.fromJson(Map<String, dynamic> json) {
    return CheckTokenResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      tokenFree: json['token_free'],
      tokenVip: json['token_vip'],
    );
  }
}


class SubtractTokenResponse {
  final bool success;
  final String message;
  final int? tokenFreeRemaining;
  final int? tokenVipRemaining;

  SubtractTokenResponse({
    required this.success,
    required this.message,
    this.tokenFreeRemaining,
    this.tokenVipRemaining,
  });

  factory SubtractTokenResponse.fromJson(Map<String, dynamic> json) {
    return SubtractTokenResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      tokenFreeRemaining: json['token_free_remaining'],
      tokenVipRemaining: json['token_vip_remaining'],
    );
  }
}


class ChangeImageResponse {
  final bool success;
  final String message;
  final String? image;

  ChangeImageResponse({
    required this.success,
    required this.message,
    this.image,
  });

  factory ChangeImageResponse.fromJson(Map<String, dynamic> json) {
    return ChangeImageResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      image: json['image'],
    );
  }
}
