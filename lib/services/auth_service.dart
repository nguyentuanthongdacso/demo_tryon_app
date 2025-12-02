import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'session_upload_manager.dart';
import '../constants/api_constants.dart';

/// Service xử lý authentication với API Gateway
/// Gửi request đến 3_api_gateway và quản lý JWT token
/// Session được lưu trữ MÃ HÓA và tự động khôi phục khi mở app
/// Token hết hạn sau 7 ngày
/// Sử dụng flutter_secure_storage (Keystore trên Android, Keychain trên iOS)
class AuthService {
  // Singleton pattern
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  // API Gateway URL - Production domain
  static String get _gatewayUrl => ApiConstants.gatewayBaseUrl;

  // Secure Storage instance với cấu hình bảo mật cao
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true, // Sử dụng EncryptedSharedPreferences
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  // Storage keys
  static const String _keyJwtToken = 'auth_jwt_token';
  static const String _keyCurrentUser = 'auth_current_user';
  static const String _keyLoginTime = 'auth_login_time';
  
  // Token expiration: 7 days
  static const int _tokenExpirationDays = 7;

  // JWT token và user data
  String? _jwtToken;
  Map<String, dynamic>? _currentUser;
  DateTime? _loginTime;

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
  
  /// Kiểm tra xem token có hết hạn chưa (7 ngày)
  bool get isTokenExpired {
    if (_loginTime == null) return true;
    final now = DateTime.now();
    final diff = now.difference(_loginTime!);
    return diff.inDays >= _tokenExpirationDays;
  }
  
  /// Lưu session vào Secure Storage (mã hóa)
  Future<void> _saveSession() async {
    if (_jwtToken != null) {
      await _secureStorage.write(key: _keyJwtToken, value: _jwtToken);
    } else {
      await _secureStorage.delete(key: _keyJwtToken);
    }
    
    if (_currentUser != null) {
      await _secureStorage.write(key: _keyCurrentUser, value: jsonEncode(_currentUser));
    } else {
      await _secureStorage.delete(key: _keyCurrentUser);
    }
    
    if (_loginTime != null) {
      await _secureStorage.write(key: _keyLoginTime, value: _loginTime!.toIso8601String());
    } else {
      await _secureStorage.delete(key: _keyLoginTime);
    }
    
    print('🔐 Session saved to secure storage');
  }
  
  /// Load session từ Secure Storage (mã hóa)
  /// Trả về true nếu có session hợp lệ
  Future<bool> loadSession() async {
    try {
      _jwtToken = await _secureStorage.read(key: _keyJwtToken);
      
      final userJson = await _secureStorage.read(key: _keyCurrentUser);
      if (userJson != null) {
        _currentUser = jsonDecode(userJson) as Map<String, dynamic>;
      }
      
      final loginTimeStr = await _secureStorage.read(key: _keyLoginTime);
      if (loginTimeStr != null) {
        _loginTime = DateTime.parse(loginTimeStr);
      }
      
      print('🔐 Session loaded from secure storage');
      print('   Token: ${_jwtToken != null ? "exists" : "null"}');
      print('   User: ${_currentUser?['email'] ?? "null"}');
      print('   Login time: $_loginTime');
      
      // Kiểm tra token có hết hạn không
      if (isTokenExpired) {
        print('⏰ Token expired (>$_tokenExpirationDays days). Clearing session...');
        await clearSession();
        return false;
      }
      
      return isLoggedIn;
    } catch (e) {
      print('❌ Error loading session: $e');
      return false;
    }
  }
  
  /// Xóa session khỏi Secure Storage (gọi khi logout)
  Future<void> clearSession() async {
    try {
      // Ensure any session uploads on Cloudinary are removed first
      await SessionUploadManager().clearSessionUploads();
    } catch (e) {
      // Log error but continue to clear session data locally
      print('⚠️ Failed to clear session uploads: $e');
    }

    await _secureStorage.delete(key: _keyJwtToken);
    await _secureStorage.delete(key: _keyCurrentUser);
    await _secureStorage.delete(key: _keyLoginTime);

    _jwtToken = null;
    _currentUser = null;
    _loginTime = null;

    print('🔐 Session cleared from secure storage');
  }

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
          _loginTime = DateTime.now();
          await _saveSession(); // Lưu session vào storage
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

  /// Logout - xóa JWT, user data và session từ storage
  Future<void> logout() async {
    await clearSession();
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
        await logout();
        return CheckTokenResponse(success: false, message: 'Token expired');
      }
      throw Exception('Server error: ${response.statusCode}');
    } catch (e) {
      return CheckTokenResponse(success: false, message: e.toString());
    }
  }

  /// Refresh token data từ server (dùng sau khi nhận reward từ ad)
  Future<void> refreshTokenFromServer() async {
    if (_jwtToken == null || userKey == null) {
      throw Exception('Not logged in');
    }

    try {
      final response = await checkToken();
      if (response.success && _currentUser != null) {
        // Cập nhật local user data với token mới từ server
        _currentUser!['token_free'] = response.tokenFree;
        _currentUser!['token_vip'] = response.tokenVip;
        await _saveSession();
        print('🔄 Token refreshed: free=${response.tokenFree}, vip=${response.tokenVip}');
      }
    } catch (e) {
      print('❌ Error refreshing token: $e');
      rethrow;
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
        await logout();
        return SubtractTokenResponse(success: false, message: 'Token expired');
      }
      throw Exception('Server error: ${response.statusCode}');
    } catch (e) {
      return SubtractTokenResponse(success: false, message: e.toString());
    }
  }

  /// Cộng token miễn phí (dùng sau khi xem quảng cáo)
  Future<AddTokenFreeResponse> addTokenFree(int amount) async {
    if (_jwtToken == null || userKey == null) {
      return AddTokenFreeResponse(success: false, message: 'Not logged in');
    }

    try {
      final url = Uri.parse('$_gatewayUrl/add-token-free');
      final response = await http.post(
        url,
        headers: getAuthHeaders(),
        body: jsonEncode({
          'type': 'add_token_free',
          'user_key': userKey,
          'token_value': amount,
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final result = AddTokenFreeResponse.fromJson(jsonDecode(response.body));
        // Cập nhật local user data
        if (result.success && _currentUser != null) {
          _currentUser!['token_free'] = result.tokenFreeNew;
          await _saveSession();
          print('✅ Token added: +$amount, new balance: ${result.tokenFreeNew}');
        }
        return result;
      } else if (response.statusCode == 401) {
        await logout();
        return AddTokenFreeResponse(success: false, message: 'Token expired');
      }
      throw Exception('Server error: ${response.statusCode}');
    } catch (e) {
      return AddTokenFreeResponse(success: false, message: e.toString());
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
        await logout();
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


class AddTokenFreeResponse {
  final bool success;
  final String? message;
  final int? tokenFreeNew;

  AddTokenFreeResponse({
    required this.success,
    this.message,
    this.tokenFreeNew,
  });

  factory AddTokenFreeResponse.fromJson(Map<String, dynamic> json) {
    return AddTokenFreeResponse(
      success: json['success'] ?? false,
      message: json['message'],
      tokenFreeNew: json['token_free'],  // Server trả về token_free
    );
  }
}
