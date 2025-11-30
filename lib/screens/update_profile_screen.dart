import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/session_upload_manager.dart';
import '../providers/search_provider.dart';
import '../providers/tryon_provider.dart';
import 'edit_model_image_screen.dart';
import 'language_screen.dart';
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

  void _handleLogout() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
      title: Text(AppLocalizations.of(context).translate('logout_confirm_title')),
      content: Text(AppLocalizations.of(context).translate('logout_confirm_content')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(AppLocalizations.of(context).translate('cancel')),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              
              // Hiển thị loading trong khi xóa ảnh
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (ctx) => AlertDialog(
                  content: Row(
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(width: 16),
                      Flexible(child: Text(AppLocalizations.of(context).translate('clearing_session_data'))),
                    ],
                  ),
                ),
              );
              
              // Xóa tất cả ảnh đã upload trong session trên Cloudinary
              final sessionManager = SessionUploadManager();
              final result = await sessionManager.clearSessionUploads();
              
              // Đóng loading dialog
              if (context.mounted) {
                Navigator.pop(context);
              }
              
              // Log kết quả
              print('🧹 Session cleanup: ${result['deleted']}/${result['total']} ảnh đã xóa trên Cloudinary');
              
              // Clear all provider data khi logout
              if (context.mounted) {
                context.read<SearchProvider>().clearAll();
                context.read<TryonProvider>().clear();
              }
              
              _authService.logout();
              // Gọi callback để navigate về login screen
              if (widget.onLogout != null) {
                widget.onLogout!();
              }
            },
            child: Text(AppLocalizations.of(context).translate('logout'), style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
