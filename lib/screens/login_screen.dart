import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/google_auth_service.dart';
import '../services/auth_service.dart';
import '../services/session_upload_manager.dart';
import '../widgets/social_login_button.dart';
import '../l10n/app_localizations.dart';
import '../providers/theme_provider.dart';

class LoginScreen extends StatefulWidget {
  final VoidCallback onLoginSuccess;

  const LoginScreen({
    super.key,
    required this.onLoginSuccess,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final GoogleAuthService _googleAuth = GoogleAuthService();
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    await _googleAuth.initialize(
      serverClientId:
          '504352327496-81r0qu02nmpa68s5u35l206kt81bavb8.apps.googleusercontent.com',
    );
  }

  // ========== Google Sign-In ==========
  Future<void> _handleGoogleSignIn() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      final account = await _googleAuth.signIn();

      debugPrint('Google account: $account');
      debugPrint('Account id: ${account?.id}');
      debugPrint('Account email: ${account?.email}');

      if (account != null && mounted) {
        // Gọi API check-login để lấy JWT token và user data
        debugPrint('🔐 Calling check-login API...');
        
        final loginResult = await _authService.checkLogin(
          email: account.email,
          name: account.displayName,
          photoUrl: account.photoUrl,
        );

        if (loginResult.success) {
          debugPrint('✅ Login success!');
          debugPrint('👤 User: ${_authService.currentUser}');
          debugPrint('🔑 JWT Token: ${_authService.jwtToken?.substring(0, 20)}...');
          
          // Lưu URL ảnh model của user để tránh xóa nhầm
          final userImageUrl = _authService.currentUser?['image'] as String?;
          await SessionUploadManager().setUserModelImageUrl(userImageUrl);
          
          if (mounted) {
            widget.onLoginSuccess();
          }
        } else {
          debugPrint('❌ Login failed: ${loginResult.message}');
          if (mounted) {
            _showError('${AppLocalizations.of(context).translate('login_failed')}: ${loginResult.message}');
          }
        }
      } else if (mounted) {
        debugPrint('Account is null - user may have cancelled');
      }
    } catch (e) {
      debugPrint('Google Sign-In error: $e');
      if (mounted) {
        _showError('${AppLocalizations.of(context).translate('google_signin_failed')}: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  // ========== Build UI ==========
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              Provider.of<ThemeProvider>(context).mainBackground,
              fit: BoxFit.cover,
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.3),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.checkroom_outlined,
                    size: 60,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 16),

                // Title
                Text(
                  AppLocalizations.of(context).translate('app_title'),
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 8),

                // Slogan
                Text(
                  AppLocalizations.of(context).translate('slogan'),
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black.withValues(alpha: 0.7),
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 50),

                // Google Login Button
                GoogleLoginButton(
                  onPressed: _handleGoogleSignIn,
                  isLoading: _isLoading,
                ),
                const SizedBox(height: 24),

                // Terms
                Text.rich(
                  TextSpan(
                    text: AppLocalizations.of(context).translate('terms_prefix'),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.black.withValues(alpha: 0.7),
                    ),
                    children: [
                      TextSpan(
                        text: AppLocalizations.of(context).translate('terms_of_service'),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                      TextSpan(text: '\nand '),
                      TextSpan(
                        text: AppLocalizations.of(context).translate('privacy_policy'),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
          ),
        ],
      ),
    );
  }
}
