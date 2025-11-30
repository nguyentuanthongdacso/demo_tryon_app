import 'package:flutter/material.dart';
import '../services/auth_service.dart';

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
                title: 'Cài đặt và quyền riêng tư',
                isExpanded: _isSettingsExpanded,
                onTap: () {
                  setState(() {
                    _isSettingsExpanded = !_isSettingsExpanded;
                  });
                },
                children: [
                  _buildMenuItem(
                    icon: Icons.person_outline,
                    title: 'Thông tin cá nhân',
                    onTap: () => _showComingSoon('Thông tin cá nhân'),
                  ),
                  _buildMenuItem(
                    icon: Icons.lock_outline,
                    title: 'Mật khẩu và bảo mật',
                    onTap: () => _showComingSoon('Mật khẩu và bảo mật'),
                  ),
                  _buildMenuItem(
                    icon: Icons.link,
                    title: 'Liên kết tài khoản',
                    onTap: () => _showComingSoon('Liên kết tài khoản'),
                  ),
                  _buildMenuItem(
                    icon: Icons.language,
                    title: 'Ngôn ngữ và khu vực',
                    onTap: () => _showComingSoon('Ngôn ngữ và khu vực'),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Chỉnh sửa hồ sơ
              _buildMenuItem(
                icon: Icons.edit,
                title: 'Chỉnh sửa hồ sơ',
                onTap: () => _showComingSoon('Chỉnh sửa hồ sơ'),
              ),
              const SizedBox(height: 12),

              // Trung tâm hỗ trợ
              _buildMenuItem(
                icon: Icons.help_outline,
                title: 'Trung tâm hỗ trợ',
                onTap: () => _showComingSoon('Trung tâm hỗ trợ'),
              ),
              const SizedBox(height: 12),

              // Yêu cầu trợ giúp
              _buildMenuItem(
                icon: Icons.chat_bubble_outline,
                title: 'Yêu cầu trợ giúp',
                onTap: () => _showComingSoon('Yêu cầu trợ giúp'),
              ),
              const SizedBox(height: 12),

              // Nâng cấp tài khoản
              _buildMenuItem(
                icon: Icons.attach_money,
                title: 'Nâng cấp tài khoản',
                onTap: () => _showComingSoon('Nâng cấp tài khoản'),
              ),
              const SizedBox(height: 12),

              // Log out
              _buildMenuItem(
                icon: Icons.logout,
                title: 'Log out',
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
          onPressed: () => _showComingSoon('Thông báo'),
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

  Widget _buildHighlightedButton({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E88E5), // Blue color
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        leading: Icon(icon, color: Colors.white),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature - Coming soon!'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _handleLogout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Đăng xuất'),
        content: const Text('Bạn có chắc chắn muốn đăng xuất?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _authService.logout();
              // Gọi callback để navigate về login screen
              if (widget.onLogout != null) {
                widget.onLogout!();
              }
            },
            child: const Text('Đăng xuất', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
