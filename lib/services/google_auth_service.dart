import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

class GoogleAuthService {
  static final GoogleAuthService _instance = GoogleAuthService._internal();
  factory GoogleAuthService() => _instance;
  GoogleAuthService._internal();

  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  bool _initialized = false;

  bool get isInitialized => _initialized;

  /// Khởi tạo Google Sign-In
  Future<void> initialize({required String serverClientId}) async {
    if (_initialized) return;

    try {
      await _googleSignIn.initialize(serverClientId: serverClientId);
      _initialized = true;
      debugPrint('Google Sign-In initialized successfully');
    } catch (e) {
      debugPrint('Google Sign-In initialization error: $e');
      _initialized = true; // Vẫn đánh dấu đã init để không block UI
    }
  }

  /// Đăng nhập Google
  Future<GoogleSignInAccount?> signIn() async {
    if (!_initialized) {
      throw Exception('Google Sign-In chưa được khởi tạo');
    }

    try {
      if (_googleSignIn.supportsAuthenticate()) {
        debugPrint('Starting Google authenticate...');
        final account = await _googleSignIn.authenticate();
        debugPrint('Google authenticate completed: ${account.email}');
        return account;
      } else {
        throw Exception('Google Sign-In không được hỗ trợ trên nền tảng này');
      }
    } catch (e) {
      debugPrint('Google Sign-In exception: $e');
      final errorString = e.toString().toLowerCase();
      // Nếu người dùng huỷ thì trả về null thay vì throw
      if (errorString.contains('cancel') ||
          errorString.contains('dismissed') ||
          errorString.contains('user denied') ||
          errorString.contains('aborted')) {
        debugPrint('Google Sign-In cancelled by user');
        return null;
      }
      rethrow;
    }
  }

  /// Đăng xuất
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (e) {
      debugPrint('Google Sign-Out error: $e');
    }
  }

  /// Ngắt kết nối hoàn toàn
  Future<void> disconnect() async {
    try {
      await _googleSignIn.disconnect();
    } catch (e) {
      debugPrint('Google Disconnect error: $e');
    }
  }
}
