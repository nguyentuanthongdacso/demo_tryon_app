import 'dart:developer' as developer;

class AppLogger {
  static const String _tag = 'TryOnApp';

  static void info(String message) {
    developer.log('ℹ️ $message', name: _tag);
    print('[$_tag] INFO: $message');
  }

  static void debug(String message) {
    developer.log('🐛 $message', name: _tag, level: 500);
    print('[$_tag] DEBUG: $message');
  }

  static void warning(String message) {
    developer.log('⚠️ $message', name: _tag, level: 800);
    print('[$_tag] WARNING: $message');
  }

  static void logError(String message, [Object? error, StackTrace? stackTrace]) {
    developer.log('❌ $message', name: _tag, error: error, stackTrace: stackTrace, level: 1000);
    print('[$_tag] ERROR: $message');
    if (error != null) {
      print('  Error: $error');
    }
    if (stackTrace != null) {
      print('  StackTrace: $stackTrace');
    }
  }

  static void apiRequest(String method, String url, {Map<String, dynamic>? body}) {
    info('🔵 API REQUEST: $method $url');
    if (body != null) {
      debug('Request Body: $body');
    }
  }

  static void apiResponse(String url, int statusCode, {dynamic body}) {
    info('🟢 API RESPONSE: $statusCode from $url');
    if (body != null) {
      debug('Response Body: $body');
    }
  }

  static void apiError(String url, Object error) {
    logError('🔴 API ERROR: $url - $error');
  }
}

