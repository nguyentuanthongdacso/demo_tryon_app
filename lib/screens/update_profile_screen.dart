import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/session_upload_manager.dart';
import '../services/ad_service.dart';
import '../constants/ad_constants.dart';
import '../providers/search_provider.dart';
import '../providers/tryon_provider.dart';
import 'edit_model_image_screen.dart';
import 'language_screen.dart';
import 'my_assets_screen.dart';
import '../l10n/app_localizations.dart';

class UpdateProfileScreen extends StatefulWidget {
  final VoidCallback? onLogout;

  const UpdateProfileScreen({super.key, this.onLogout});

  @override
  State<UpdateProfileScreen> createState() => _UpdateProfileScreenState();
}

class _UpdateProfileScreenState extends State<UpdateProfileScreen> {
  final AuthService _authService = AuthService();
  bool _isSettingsExpanded = true;

  @override
  Widget build(BuildContext context) {
    final user = _authService.currentUser;
    // Lấy tên: ưu tiên name từ server, fallback về email prefix
    final userName = user?['name'] ?? 
                     user?['email']?.toString().split('@').first ?? 
                     'Người dùng';
    // Lấy ảnh: ưu tiên profile_image từ Google, sau đó là image từ server
    final userImage = user?['profile_image'] ?? user?['image'];

    final loc = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFF87CEEB), // Sky blue background
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Header với avatar và tên
              _buildHeader(userName, userImage),
              const SizedBox(height: 24),

              // Settings & Privacy Section (expandable)
              _buildExpandableSection(
                icon: Icons.settings,
                title: loc.translate('settings_privacy'),
                isExpanded: _isSettingsExpanded,
                onTap: () {
                  setState(() {
                    _isSettingsExpanded = !_isSettingsExpanded;
                  });
                },
                children: [
                  _buildMenuItem(
                    icon: Icons.person_outline,
                    title: loc.translate('personal_info'),
                    onTap: () => _showComingSoon(loc.translate('personal_info')),
                  ),
                  _buildMenuItem(
                    icon: Icons.lock_outline,
                    title: loc.translate('password_security'),
                    onTap: () => _showComingSoon(loc.translate('password_security')),
                  ),
                  _buildMenuItem(
                    icon: Icons.link,
                    title: loc.translate('link_accounts'),
                    onTap: () => _showComingSoon(loc.translate('link_accounts')),
                  ),
                  _buildMenuItem(
                    icon: Icons.language,
                    title: loc.translate('language'),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LanguageScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Chinh sua anh mau
              _buildMenuItem(
                icon: Icons.photo_camera,
                title: loc.translate('edit_model_image'),
                onTap: () => _navigateToEditModelImage(),
              ),
              const SizedBox(height: 12),

              // My Assets - Ảnh của tôi
              _buildMenuItem(
                icon: Icons.photo_library,
                title: loc.translate('my_assets'),
                onTap: () => _navigateToMyAssets(),
              ),
              const SizedBox(height: 12),

              // Trung tâm hỗ trợ
              _buildMenuItem(
                icon: Icons.help_outline,
                title: loc.translate('support_center'),
                onTap: () => _showComingSoon(loc.translate('support_center')),
              ),
              const SizedBox(height: 12),

              // Yêu cầu trợ giúp
              _buildMenuItem(
                icon: Icons.chat_bubble_outline,
                title: loc.translate('request_help'),
                onTap: () => _showComingSoon(loc.translate('request_help')),
              ),
              const SizedBox(height: 12),

              // Nâng cấp tài khoản
              _buildMenuItem(
                icon: Icons.attach_money,
                title: loc.translate('upgrade_account'),
                onTap: () => _showComingSoon(loc.translate('upgrade_account')),
              ),
              const SizedBox(height: 12),

              // Click để nhận token - Rewarded Video Ad
              _buildRewardedAdButton(loc),
              const SizedBox(height: 12),

              // Log out
              _buildMenuItem(
                icon: Icons.logout,
                title: loc.translate('logout'),
                titleColor: Colors.red,
                onTap: _handleLogout,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(String userName, String? userImage) {
    final user = _authService.currentUser;
    final tokenFree = user?['token_free'] ?? 0;
    final tokenVip = user?['token_vip'] ?? 0;

    return Row(
      children: [
        // Avatar
        CircleAvatar(
          radius: 28,
          backgroundColor: Colors.white,
          backgroundImage: userImage != null ? NetworkImage(userImage) : null,
          child: userImage == null
              ? const Icon(Icons.person, size: 32, color: Colors.grey)
              : null,
        ),
        const SizedBox(width: 12),
        // Name
        Expanded(
          child: Text(
            userName,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),
        // Token display
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Token Free
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$tokenFree',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                Image.asset(
                  'assets/icons/coin_free.png',
                  width: 24,
                  height: 24,
                ),
              ],
            ),
            const SizedBox(width: 8),
            // Token VIP
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$tokenVip',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                Image.asset(
                  'assets/icons/coin_vip.png',
                  width: 24,
                  height: 24,
                ),
              ],
            ),
          ],
        ),
        const SizedBox(width: 8),
        // Notification bell
        IconButton(
          icon: const Icon(Icons.notifications_outlined, color: Colors.black87),
          onPressed: () => _showComingSoon(AppLocalizations.of(context).translate('notifications')),
        ),
      ],
    );
  }

  Widget _buildExpandableSection({
    required IconData icon,
    required String title,
    required bool isExpanded,
    required VoidCallback onTap,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          // Header
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(icon, color: Colors.black54),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: Colors.black54,
                  ),
                ],
              ),
            ),
          ),
          // Children (expandable)
          if (isExpanded)
            Column(
              children: children
                  .map((child) => Padding(
                        padding: const EdgeInsets.only(left: 16),
                        child: child,
                      ))
                  .toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    Color? titleColor,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        leading: Icon(icon, color: Colors.black54),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 16,
            color: titleColor ?? Colors.black87,
          ),
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  // removed unused helper

  /// Nút xem quảng cáo để nhận token
  Widget _buildRewardedAdButton(AppLocalizations loc) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        leading: const Icon(Icons.play_circle_fill, color: Colors.white, size: 32),
        title: Text(
          loc.translate('click_to_get_token'),
          style: const TextStyle(
            fontSize: 16,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          loc.translate('watch_ad_reward'),
          style: const TextStyle(
            fontSize: 12,
            color: Colors.white70,
          ),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.toll, size: 18, color: Colors.white),
              SizedBox(width: 4),
              Text(
                '+25',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        onTap: _handleWatchRewardedAd,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  /// Xử lý khi nhấn nút xem quảng cáo
  Future<void> _handleWatchRewardedAd() async {
    final loc = AppLocalizations.of(context);
    final adService = AdService();
    
    // Kiểm tra có thể xem không
    final canShow = await adService.canShowRewardedAd();
    if (canShow['allowed'] != true) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(canShow['message'] ?? loc.translate('ad_not_ready')),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }
    
    // Hiển thị quảng cáo
    final result = await adService.showRewardedAd(
      userKey: _authService.userKey ?? '',
    );
    
    if (!mounted) return;
    
    if (result['success'] == true) {
      // Test Mode: Client gọi trực tiếp API vì test ads không gọi SSV callback
      // Production Mode: Đợi SSV callback từ Google
      
      if (AdConstants.isTestMode) {
        // TEST MODE: Gọi trực tiếp API add-token-free
        try {
          final addResult = await _authService.addTokenFree(AdConstants.rewardTokenAmount);
          if (addResult.success) {
            await _authService.refreshTokenFromServer();
            if (mounted) {
              setState(() {}); // Rebuild UI với token mới
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    '[TEST] ${loc.translate('ad_reward_success').replaceAll('{amount}', '${AdConstants.rewardTokenAmount}')}',
                  ),
                  backgroundColor: Colors.green,
                ),
              );
            }
          } else {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('[TEST] Error: ${addResult.message}'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        } catch (e) {
          debugPrint('Test mode add token error: $e');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('[TEST] Error: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } else {
        // PRODUCTION MODE: SSV Flow
        // Google sẽ gửi callback đến server để cộng token
        // Client chỉ cần đợi và refresh token từ server
        
        // Hiển thị thông báo đang xác thực
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(loc.translate('ad_verifying')),
            backgroundColor: Colors.blue,
            duration: const Duration(seconds: 3),
          ),
        );
        
        // Đợi 3-5 giây để Google gửi SSV callback và server xử lý
        await Future.delayed(const Duration(seconds: 4));
        
        // Refresh token từ server (server đã cộng token qua SSV)
        try {
          await _authService.refreshTokenFromServer();
          if (mounted) {
            setState(() {}); // Rebuild UI với token mới
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  loc.translate('ad_reward_success')
                      .replaceAll('{amount}', '${AdConstants.rewardTokenAmount}'),
                ),
                backgroundColor: Colors.green,
              ),
            );
          }
        } catch (e) {
          debugPrint('Error refreshing token: $e');
          // Nếu refresh thất bại, vẫn thông báo cho user biết reward đang được xử lý
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(loc.translate('ad_reward_processing')),
                backgroundColor: Colors.orange,
              ),
            );
          }
        }
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['error'] ?? loc.translate('ad_not_ready')),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature - ${AppLocalizations.of(context).translate('coming_soon')}'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _navigateToEditModelImage() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const EditModelImageScreen(),
      ),
    );
    
    // Neu cap nhat thanh cong, rebuild UI
    if (result == true && mounted) {
      setState(() {});
    }
  }

  void _navigateToMyAssets() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const MyAssetsScreen(),
      ),
    );
  }

  void _handleLogout() {
    // Lưu tất cả localized strings TRƯỚC khi show dialog
    final localizations = AppLocalizations.of(context);
    final logoutConfirmTitle = localizations.translate('logout_confirm_title');
    final logoutConfirmContent = localizations.translate('logout_confirm_content');
    final cancelText = localizations.translate('cancel');
    final logoutText = localizations.translate('logout');
    final clearingSessionText = localizations.translate('clearing_session_data');
    
    // Lưu callback trước
    final onLogoutCallback = widget.onLogout;
    
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(logoutConfirmTitle),
        content: Text(logoutConfirmContent),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(cancelText),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              
              // Hiển thị loading trong khi xóa ảnh
              if (!mounted) return;
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (ctx) => AlertDialog(
                  content: Row(
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(width: 16),
                      Flexible(child: Text(clearingSessionText)),
                    ],
                  ),
                ),
              );
              
              // Xóa tất cả ảnh đã upload trong session trên Cloudinary
              final sessionManager = SessionUploadManager();
              final result = await sessionManager.clearSessionUploads();
              
              // Đóng loading dialog
              if (mounted) {
                Navigator.pop(context);
              }
              
              // Log kết quả
              print('🧹 Session cleanup: ${result['deleted']}/${result['total']} ảnh đã xóa trên Cloudinary');
              
              // Clear all provider data khi logout
              if (mounted) {
                context.read<SearchProvider>().clearAll();
                context.read<TryonProvider>().clear();
              }
              
              await _authService.logout();
              // Gọi callback để navigate về login screen
              if (onLogoutCallback != null) {
                onLogoutCallback();
              }
            },
            child: Text(logoutText, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
