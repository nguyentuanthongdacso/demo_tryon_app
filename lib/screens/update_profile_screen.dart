import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/ad_service.dart';
import '../constants/ad_constants.dart';
import '../providers/search_provider.dart';
import '../providers/search_tryon_provider.dart';
import '../providers/upload_tryon_provider.dart';
import '../providers/theme_provider.dart';
import '../utils/app_styles.dart';
import 'edit_model_image_screen.dart';
import 'language_screen.dart';
import 'theme_screen.dart';
import 'my_assets_screen.dart';
import 'report_bug_screen.dart';
import 'payment_screen.dart';
import '../l10n/app_localizations.dart';

class UpdateProfileScreen extends StatefulWidget {
  final VoidCallback? onLogout;

  const UpdateProfileScreen({super.key, this.onLogout});

  @override
  State<UpdateProfileScreen> createState() => _UpdateProfileScreenState();
}

class _UpdateProfileScreenState extends State<UpdateProfileScreen> {
  final AuthService _authService = AuthService();
  bool _isSettingsExpanded = false;

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
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              themeProvider.mainBackground,
              fit: BoxFit.cover,
            ),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: AppStyles.paddingAll16,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight - 32, // Trừ padding
                    ),
                    child: Column(
                      children: [
                        // Header với avatar và tên
                        _buildHeader(userName, userImage),
                        SizedBox(height: AppStyles.spacingXXL),

                        // Get Token button (Rewarded Video Ad)
                        _buildRewardedAdButton(loc),
                        SizedBox(height: AppStyles.spacingMD),

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
                            // Password & Security - Tạm ẩn, sẽ dùng lại trong tương lai
                            // _buildMenuItem(
                            //   icon: Icons.lock_outline,
                            //   title: loc.translate('password_security'),
                            //   onTap: () => _showComingSoon(loc.translate('password_security')),
                            // ),
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
                            _buildMenuItem(
                              icon: Icons.palette,
                              title: loc.translate('theme_button'),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const ThemeScreen(),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                        SizedBox(height: AppStyles.spacingMD),

                        // Chinh sua anh mau
                        _buildMenuItem(
                          icon: Icons.photo_camera,
                          title: loc.translate('edit_model_image'),
                          onTap: () => _navigateToEditModelImage(),
                        ),
                        SizedBox(height: AppStyles.spacingMD),

                        // My Assets - Ảnh của tôi
                        _buildMenuItem(
                          icon: Icons.photo_library,
                          title: loc.translate('my_assets'),
                          onTap: () => _navigateToMyAssets(),
                        ),
                        SizedBox(height: AppStyles.spacingMD),

                        // Trung tâm hỗ trợ
                        _buildMenuItem(
                          icon: Icons.help_outline,
                          title: loc.translate('support_center'),
                          onTap: () => _showComingSoon(loc.translate('support_center')),
                        ),
                        SizedBox(height: AppStyles.spacingMD),

                        // Báo cáo lỗi
                        _buildMenuItem(
                          icon: Icons.bug_report,
                          title: loc.translate('report_bug'),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const ReportBugScreen(),
                              ),
                            );
                          },
                        ),
                        SizedBox(height: AppStyles.spacingMD),

                        // Nâng cấp tài khoản
                        _buildMenuItem(
                          icon: Icons.attach_money,
                          title: loc.translate('upgrade_account'),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const PaymentScreen(),
                              ),
                            );
                          },
                        ),
                        SizedBox(height: AppStyles.spacingMD),

                        // // Click để nhận token - Rewarded Video Ad
                        // _buildRewardedAdButton(loc),
                        // SizedBox(height: AppStyles.spacingMD),

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
                );
              },
            ),
          ),
        ],
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
            style: AppStyles.headerName,
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
                  style: AppStyles.tokenCountText,
                ),
                Image.asset(
                  'assets/icons/coin_free.png',
                  width: AppStyles.coinIconSizeLG,
                  height: AppStyles.coinIconSizeLG,
                ),
              ],
            ),
            SizedBox(width: AppStyles.spacingSM),
            // Token VIP
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$tokenVip',
                  style: AppStyles.tokenCountText,
                ),
                Image.asset(
                  'assets/icons/coin_vip.png',
                  width: AppStyles.coinIconSizeLG,
                  height: AppStyles.coinIconSizeLG,
                ),
              ],
            ),
          ],
        ),
        SizedBox(width: AppStyles.spacingSM),
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
      decoration: AppStyles.cardDecorationSolid,
      child: Column(
        children: [
          // Header
          InkWell(
            onTap: onTap,
            borderRadius: AppStyles.borderRadiusXL,
            child: Padding(
              padding: AppStyles.paddingAll16,
              child: Row(
                children: [
                  Icon(icon, color: AppStyles.textSecondary),
                  SizedBox(width: AppStyles.spacingMD),
                  Expanded(
                    child: Text(
                      title,
                      style: AppStyles.titleMedium,
                    ),
                  ),
                  Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: AppStyles.textSecondary,
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
                        padding: EdgeInsets.only(left: AppStyles.spacingLG),
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
      margin: EdgeInsets.only(bottom: AppStyles.spacingXS - 2),
      decoration: AppStyles.cardDecorationSolid,
      child: ListTile(
        leading: Icon(icon, color: AppStyles.textSecondary),
        title: Text(
          title,
          style: AppStyles.menuItemText.copyWith(color: titleColor),
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: AppStyles.borderRadiusXL,
        ),
      ),
    );
  }

  // removed unused helper

  /// Nút xem quảng cáo để nhận token
  Widget _buildRewardedAdButton(AppLocalizations loc) {
    return GestureDetector(
      onTap: _handleWatchRewardedAd,
      child: Container(
        height: AppStyles.buttonHeight,
        decoration: AppStyles.getTokenButtonDecoration,
        child: ClipRRect(
          borderRadius: AppStyles.borderRadiusXL,
          child: Stack(
            children: [
              // Overlay gradient nhẹ để text dễ đọc
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      Colors.black.withOpacity(0.4),
                      Colors.transparent,
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
              ),
              // Nội dung
              Padding(
                padding: AppStyles.paddingSymmetric14,
                child: Row(
                  children: [
                    // Icon play
                    Container(
                      width: 42,
                      height: 42,
                      decoration: AppStyles.circleIconDecorationSolid,
                      child: Icon(
                        Icons.play_arrow_rounded,
                        color: AppStyles.iconOrange,
                        size: AppStyles.iconSizeXL,
                      ),
                    ),
                    SizedBox(width: AppStyles.spacingMD),
                    // Text
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            loc.translate('click_to_get_token'),
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              shadows: AppStyles.textShadow,
                            ),
                          ),
                          SizedBox(height: AppStyles.spacingSM),
                          Text(
                            loc.translate('watch_ad_reward'),
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.black.withValues(alpha: 0.85),
                              shadows: AppStyles.textShadow,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    // Badge +25
                    Container(
                      padding: AppStyles.paddingSymmetric12x6,
                      decoration: BoxDecoration(
                        color: AppStyles.textWhite,
                        borderRadius: AppStyles.borderRadiusXXL,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '+25',
                            style: TextStyle(
                              color: AppStyles.warningText,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          SizedBox(width: AppStyles.spacingXS),
                          Image.asset('assets/icons/coin_free.png', width: AppStyles.coinIconSize, height: AppStyles.coinIconSize),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
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
                    loc.translate('ad_reward_success').replaceAll('{amount}', '${AdConstants.rewardTokenAmount}'),
                  ),
                  backgroundColor: Colors.green,
                ),
              );
            }
          } else {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error: ${addResult.message}'),
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
                content: Text('Error: $e'),
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
    
    // Lưu navigator context để đóng dialog sau
    final rootNavigator = Navigator.of(context, rootNavigator: true);
    
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
              
              // Show loading dialog với rootNavigator
              showDialog(
                context: context,
                barrierDismissible: false,
                useRootNavigator: true,
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
              
              // Clear all provider data khi logout
              if (mounted) {
                context.read<SearchProvider>().clearAll();
                context.read<SearchTryonProvider>().clear();
                context.read<UploadTryonProvider>().clear();
              }
              
              // Logout - this will handle session cleanup with timeout
              await _authService.logout();
              
              // Đóng loading dialog TRƯỚC khi gọi callback
              // Sử dụng rootNavigator để đảm bảo đóng được dialog
              try {
                rootNavigator.pop();
              } catch (e) {
                debugPrint('⚠️ Error closing loading dialog: $e');
              }
              
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
