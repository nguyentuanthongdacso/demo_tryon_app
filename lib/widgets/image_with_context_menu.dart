import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:gal/gal.dart';
import '../l10n/app_localizations.dart';

/// Widget hiển thị ảnh với menu context khi nhấn giữ
/// Hỗ trợ: Lưu ảnh, Sao chép, Chia sẻ, Xóa (tùy chọn)
class ImageWithContextMenu extends StatelessWidget {
  final String imageUrl;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;
  final BorderRadius? borderRadius;
  final VoidCallback? onTap;
  final VoidCallback? onDelete; // Callback khi nhấn xóa
  final bool showDeleteOption; // Hiển thị tùy chọn xóa

  const ImageWithContextMenu({
    super.key,
    required this.imageUrl,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
    this.borderRadius,
    this.onTap,
    this.onDelete,
    this.showDeleteOption = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: () => _showContextMenu(context),
      behavior: HitTestBehavior.opaque, // Đảm bảo nhận gesture trên toàn bộ vùng
      child: ClipRRect(
        borderRadius: borderRadius ?? BorderRadius.zero,
        child: Image.network(
          imageUrl,
          fit: fit,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return placeholder ?? Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                    : null,
              ),
            );
          },
          errorBuilder: (_, __, ___) => errorWidget ?? Container(
            color: Colors.grey[200],
            child: const Icon(Icons.broken_image, size: 48),
          ),
        ),
      ),
    );
  }

  void _showContextMenu(BuildContext context) {
    final loc = AppLocalizations.of(context);
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              
              // Save to gallery
              ListTile(
                leading: const Icon(Icons.save_alt, color: Colors.blue),
                title: Text(loc.translate('save_to_gallery')),
                onTap: () {
                  Navigator.pop(context);
                  _saveToGallery(context);
                },
              ),
              
              // Copy image URL
              ListTile(
                leading: const Icon(Icons.link, color: Colors.purple),
                title: Text(loc.translate('copy_image_url')),
                onTap: () {
                  Navigator.pop(context);
                  _copyImageUrl(context);
                },
              ),
              
              // Share image (gửi ảnh đến app khác)
              ListTile(
                leading: const Icon(Icons.share, color: Colors.orange),
                title: Text(loc.translate('share_image')),
                onTap: () {
                  Navigator.pop(context);
                  _shareImage(context);
                },
              ),
              
              // Delete option (nếu được bật)
              if (showDeleteOption && onDelete != null)
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: Colors.red),
                  title: Text(
                    loc.translate('delete_from_assets'),
                    style: const TextStyle(color: Colors.red),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    onDelete!();
                  },
                ),
              
              const SizedBox(height: 8),
              
              // Cancel
              ListTile(
                leading: const Icon(Icons.close, color: Colors.grey),
                title: Text(loc.translate('cancel')),
                onTap: () => Navigator.pop(context),
              ),
              
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Future<Uint8List?> _downloadImage() async {
    try {
      final response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode == 200) {
        return response.bodyBytes;
      }
    } catch (e) {
      debugPrint('Error downloading image: $e');
    }
    return null;
  }

  Future<void> _saveToGallery(BuildContext context) async {
    final loc = AppLocalizations.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    
    try {
      final bytes = await _downloadImage();
      if (bytes == null) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(loc.translate('download_failed')),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
        return;
      }
      
      // Save to temp file first
      final tempDir = await getTemporaryDirectory();
      final fileName = 'tryon_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsBytes(bytes);
      
      // Use Gal to save to gallery
      await Gal.putImage(file.path, album: 'TryOn');
      
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(loc.translate('saved_to_gallery')),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
      
      // Clean up temp file
      await file.delete();
    } catch (e) {
      debugPrint('Error saving to gallery: $e');
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(loc.translate('save_failed')),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _copyImageUrl(BuildContext context) async {
    final loc = AppLocalizations.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    
    await Clipboard.setData(ClipboardData(text: imageUrl));
    scaffoldMessenger.showSnackBar(
      SnackBar(
        content: Text(loc.translate('url_copied')),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _shareImage(BuildContext context) async {
    final loc = AppLocalizations.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    
    try {
      final bytes = await _downloadImage();
      if (bytes == null) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(loc.translate('download_failed')),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
        return;
      }
      
      // Save to temp file
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/tryon_share_${DateTime.now().millisecondsSinceEpoch}.jpg');
      await file.writeAsBytes(bytes);
      
      // Chia sẻ trực tiếp - không cần loading dialog
      // Khi user kéo bỏ share sheet thì tự động cancel
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Try-On Result',
      );
    } catch (e) {
      debugPrint('Error sharing image: $e');
      // Chỉ show error nếu thực sự có lỗi, không phải user cancel
    }
  }
}
