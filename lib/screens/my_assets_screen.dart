import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../models/tryon_image.dart';
import '../l10n/app_localizations.dart';
import '../utils/app_styles.dart';
import '../widgets/image_with_context_menu.dart';
import '../providers/theme_provider.dart';

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
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(loc.translate('my_assets')),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTryonImages,
          ),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              Provider.of<ThemeProvider>(context).mainBackground,
              fit: BoxFit.cover,
            ),
          ),
          SafeArea(
            child: _buildBody(loc),
          ),
        ],
      ),
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
            Icon(Icons.error_outline, size: AppStyles.iconSizeGiant, color: AppStyles.primaryRed),
            SizedBox(height: AppStyles.spacingLG),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(color: AppStyles.primaryRed),
            ),
            SizedBox(height: AppStyles.spacingLG),
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
              size: AppStyles.iconSizeMassive,
              color: AppStyles.backgroundWhiteTranslucent,
            ),
            SizedBox(height: AppStyles.spacingLG),
            Text(
              loc.translate('my_assets_empty'),
              style: AppStyles.titleLarge.copyWith(color: AppStyles.textWhite),
            ),
            SizedBox(height: AppStyles.spacingSM),
            Text(
              loc.translate('my_assets_description'),
              style: AppStyles.bodyMedium.copyWith(color: AppStyles.backgroundWhiteTranslucent),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadTryonImages,
      child: Padding(
        padding: AppStyles.paddingAll12,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header info
            Container(
              padding: AppStyles.paddingAll16,
              decoration: AppStyles.cardDecoration,
              child: Row(
                children: [
                  Icon(Icons.photo_library, color: AppStyles.primaryBlue),
                  SizedBox(width: AppStyles.spacingMD),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          loc.translate('my_assets'),
                          style: AppStyles.titleMedium,
                        ),
                        Text(
                          '${_tryonImages.length} ${loc.translate('photos')}',
                          style: AppStyles.bodyMediumWithColor(AppStyles.textGrey),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: AppStyles.spacingMD),
            
            // Grid of images
            Expanded(
              child: GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: AppStyles.spacingMD,
                  mainAxisSpacing: AppStyles.spacingMD,
                  childAspectRatio: AppStyles.aspectRatioCard,
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
      decoration: AppStyles.cardWithShadow,
      child: ClipRRect(
        borderRadius: AppStyles.borderRadiusLG,
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
                color: AppStyles.backgroundGreyLight,
                child: Icon(Icons.broken_image, size: AppStyles.iconSizeHuge),
              ),
            ),
            
            // Gradient overlay ở dưới
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: IgnorePointer(
                child: Container(
                  padding: AppStyles.paddingAll8,
                  decoration: AppStyles.gradientOverlayDecoration,
                  child: Text(
                    _formatDate(tryonImage.createdAt),
                    style: AppStyles.bodySmall.copyWith(color: AppStyles.textWhite),
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
              style: TextStyle(color: AppStyles.primaryRed),
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
      builder: (ctx) => AlertDialog(
        content: Row(
          children: [
            const CircularProgressIndicator(),
            SizedBox(width: AppStyles.spacingLG),
            const Text('Deleting...'),
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
              backgroundColor: AppStyles.primaryGreen,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.message.isNotEmpty ? response.message : loc.translate('delete_failed')),
              backgroundColor: AppStyles.primaryRed,
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
            backgroundColor: AppStyles.primaryRed,
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
        insetPadding: AppStyles.paddingAll16,
        child: Container(
          decoration: BoxDecoration(
            color: AppStyles.textWhite,
            borderRadius: AppStyles.borderRadiusXL,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: AppStyles.paddingAll16,
                decoration: BoxDecoration(
                  color: const Color(0xFF87CEEB),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(AppStyles.radiusXL)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.photo, color: AppStyles.textWhite),
                    SizedBox(width: AppStyles.spacingSM),
                    Expanded(
                      child: Text(
                        _formatDate(tryonImage.createdAt),
                        style: AppStyles.titleSmall.copyWith(color: AppStyles.textWhite),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: AppStyles.textWhite),
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
                      color: AppStyles.backgroundGreyLight,
                      child: Icon(Icons.broken_image, size: AppStyles.iconSizeGiant),
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
