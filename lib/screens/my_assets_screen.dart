import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../models/tryon_image.dart';
import '../l10n/app_localizations.dart';
import '../widgets/image_with_context_menu.dart';

/// Màn hình hiển thị 10 ảnh tryon gần nhất của user
class MyAssetsScreen extends StatefulWidget {
  const MyAssetsScreen({super.key});

  @override
  State<MyAssetsScreen> createState() => _MyAssetsScreenState();
}

class _MyAssetsScreenState extends State<MyAssetsScreen> {
  final ApiService _apiService = ApiService();
  final AuthService _authService = AuthService();
  
  List<TryonImage> _tryonImages = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadTryonImages();
  }

  Future<void> _loadTryonImages() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final userKey = _authService.userKey;
    if (userKey == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'User not logged in';
      });
      return;
    }

    try {
      final response = await _apiService.getTryonImages(userKey: userKey);
      
      if (mounted) {
        setState(() {
          _isLoading = false;
          if (response.success) {
            _tryonImages = response.tryonImages;
          } else {
            _errorMessage = response.message;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    
    return Scaffold(
      backgroundColor: const Color(0xFF87CEEB),
      appBar: AppBar(
        title: Text(loc.translate('my_assets')),
        backgroundColor: const Color(0xFF87CEEB),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTryonImages,
          ),
        ],
      ),
      body: _buildBody(loc),
    );
  }

  Widget _buildBody(AppLocalizations loc) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadTryonImages,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_tryonImages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.photo_library_outlined,
              size: 80,
              color: Colors.white.withValues(alpha: 0.7),
            ),
            const SizedBox(height: 16),
            Text(
              loc.translate('my_assets_empty'),
              style: const TextStyle(
                fontSize: 18,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              loc.translate('my_assets_description'),
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadTryonImages,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.photo_library, color: Colors.blue),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          loc.translate('my_assets'),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${_tryonImages.length} ${loc.translate('photos')}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            
            // Grid of images
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.75,
                ),
                itemCount: _tryonImages.length,
                itemBuilder: (context, index) {
                  return _buildImageCard(_tryonImages[index]);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageCard(TryonImage tryonImage) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Ảnh chính với context menu (nhấn giữ)
            ImageWithContextMenu(
              imageUrl: tryonImage.imageUrl,
              fit: BoxFit.cover,
              onTap: () => _showImageDetail(tryonImage),
              showDeleteOption: true,
              onDelete: () => _confirmDeleteImage(tryonImage),
              placeholder: const Center(child: CircularProgressIndicator()),
              errorWidget: Container(
                color: Colors.grey[200],
                child: const Icon(Icons.broken_image, size: 48),
              ),
            ),
            
            // Gradient overlay ở dưới
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: IgnorePointer(
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.7),
                      ],
                    ),
                  ),
                  child: Text(
                    _formatDate(tryonImage.createdAt),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    // Chuyển từ UTC sang múi giờ local của người dùng
    final localDate = date.toLocal();
    
    // Hiển thị ngày giờ cụ thể: dd/MM/yyyy HH:mm
    final day = localDate.day.toString().padLeft(2, '0');
    final month = localDate.month.toString().padLeft(2, '0');
    final year = localDate.year;
    final hour = localDate.hour.toString().padLeft(2, '0');
    final minute = localDate.minute.toString().padLeft(2, '0');
    
    return '$day/$month/$year $hour:$minute';
  }

  /// Hiển thị dialog xác nhận xóa ảnh
  void _confirmDeleteImage(TryonImage tryonImage) {
    final loc = AppLocalizations.of(context);
    
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(loc.translate('delete_image_title')),
        content: Text(loc.translate('delete_image_confirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(loc.translate('cancel')),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              _deleteImage(tryonImage);
            },
            child: Text(
              loc.translate('delete'),
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  /// Xóa ảnh khỏi My Assets
  Future<void> _deleteImage(TryonImage tryonImage) async {
    final loc = AppLocalizations.of(context);
    final userKey = _authService.userKey;
    
    if (userKey == null) return;
    
    // Lưu navigator để đóng dialog sau này
    final navigator = Navigator.of(context, rootNavigator: true);
    
    // Hiển thị loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Deleting...'),
          ],
        ),
      ),
    );
    
    try {
      final response = await _apiService.deleteTryonImage(
        userKey: userKey,
        imageId: tryonImage.id,
      );
      
      // Đóng loading dialog bằng navigator đã lưu
      navigator.pop();
      
      if (response.success) {
        // Xóa khỏi danh sách local
        setState(() {
          _tryonImages.removeWhere((img) => img.id == tryonImage.id);
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(loc.translate('image_deleted')),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.message.isNotEmpty ? response.message : loc.translate('delete_failed')),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      // Đóng loading dialog
      navigator.pop();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showImageDetail(TryonImage tryonImage) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Color(0xFF87CEEB),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.photo, color: Colors.white),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _formatDate(tryonImage.createdAt),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              
              // Ảnh chính
              Flexible(
                child: ClipRRect(
                  child: Image.network(
                    tryonImage.imageUrl,
                    fit: BoxFit.contain,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return SizedBox(
                        height: 300,
                        child: Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                : null,
                          ),
                        ),
                      );
                    },
                    errorBuilder: (_, __, ___) => Container(
                      height: 300,
                      color: Colors.grey[200],
                      child: const Icon(Icons.broken_image, size: 64),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
