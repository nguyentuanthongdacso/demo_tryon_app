import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:provider/provider.dart';

import '../providers/upload_tryon_provider.dart';
import '../services/cloudinary_service.dart';
import '../services/auth_service.dart';
import 'tryon_result_screen.dart';
import '../l10n/app_localizations.dart';
import '../widgets/banner_ad_widget.dart';

class UploadImagesScreen extends StatefulWidget {
  const UploadImagesScreen({super.key});

  @override
  State<UploadImagesScreen> createState() => _UploadImagesScreenState();
}

class _UploadImagesScreenState extends State<UploadImagesScreen> 
    with AutomaticKeepAliveClientMixin {
  
  // Giữ state khi chuyển tab
  @override
  bool get wantKeepAlive => true;
  
  // Local file paths selected by user
  String? _initLocalPath;
  String? _clothLocalPath;

  // Public URLs returned by Cloudinary
  String? _initPublicUrl;
  String? _clothPublicUrl;
  
  // Store file hashes to detect duplicate images
  String? _initFileHash;
  String? _clothFileHash;
  
  // Uploading state
  bool _initUploading = false;
  bool _clothUploading = false;
  bool _isPicking = false; // Ngan double-click
  
  String _clothType = 'upper_body';
  final _clothTypes = ['upper_body', 'lower_body', 'dress'];
  final _cloudinaryService = CloudinaryService();

  Future<void> _pickImage(bool isInit) async {
    // Ngan double-click
    if (_isPicking) return;
    _isPicking = true;
    
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: ImageSource.gallery);
      if (picked != null) {
        if (!mounted) return;
        
        try {
          // Copy file từ cache sang app directory để tránh bị xóa
          final appDir = await getApplicationDocumentsDirectory();
          final fileName = '${isInit ? 'init' : 'cloth'}_${DateTime.now().millisecondsSinceEpoch}${path.extension(picked.path)}';
          final savedPath = path.join(appDir.path, fileName);
          
          final originalFile = File(picked.path);
          await originalFile.copy(savedPath);
          
          // Tính hash của file mới để kiểm tra có giống file cũ không
          final newFile = File(savedPath);
          final newHash = await _cloudinaryService.getFileHash(newFile);
          
          if (!mounted) return;
          
          // Kiểm tra xem ảnh mới có giống ảnh cũ không (cùng hash)
          final oldHash = isInit ? _initFileHash : _clothFileHash;
          final oldUrl = isInit ? _initPublicUrl : _clothPublicUrl;
          
          if (newHash == oldHash) {
            // Ảnh giống nhau - giữ URL cũ, chỉ update local path nếu cần
            if (oldUrl != null) {
              debugPrint('♻️ Ảnh giống hệt (hash: $newHash), giữ URL hiện tại');
            }
            setState(() {
              if (isInit) {
                _initLocalPath = savedPath;
                // Giữ _initPublicUrl và _initFileHash
              } else {
                _clothLocalPath = savedPath;
                // Giữ _clothPublicUrl và _clothFileHash
              }
            });
          } else {
            // Ảnh khác - reset URL để upload lại
            debugPrint('🆕 Ảnh mới được chọn (hash: $newHash)');
            setState(() {
              if (isInit) {
                _initLocalPath = savedPath;
                _initPublicUrl = null;
                _initFileHash = newHash;
              } else {
                _clothLocalPath = savedPath;
                _clothPublicUrl = null;
                _clothFileHash = newHash;
              }
            });
          }
        } catch (e) {
          debugPrint('Lỗi khi xử lý file: $e');
          // Fallback: dùng path gốc nếu copy/hash thất bại
          if (!mounted) return;
          setState(() {
            if (isInit) {
              _initLocalPath = picked.path;
              _initPublicUrl = null;
              _initFileHash = null;
            } else {
              _clothLocalPath = picked.path;
              _clothPublicUrl = null;
              _clothFileHash = null;
            }
          });
        }
        // Khong upload ngay - chi upload khi bam Try-on
      }
    } finally {
      _isPicking = false;
    }
  }

  Future<void> _uploadImage(bool isInit) async {
    final localPath = isInit ? _initLocalPath : _clothLocalPath;
    if (localPath == null) return;

    setState(() {
      if (isInit) {
        _initUploading = true;
      } else {
        _clothUploading = true;
      }
    });

    try {
      final file = File(localPath);
      // Upload to Cloudinary voi tracking (tu dong xoa anh cu)
      final imageType = isInit ? 'init' : 'cloth';
      final result = await _cloudinaryService.uploadImageWithTracking(file, imageType);
      
      if (!mounted) return;
      setState(() {
        if (isInit) {
          _initPublicUrl = result.url;
          _initUploading = false;
        } else {
          _clothPublicUrl = result.url;
          _clothUploading = false;
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        if (isInit) {
          _initUploading = false;
        } else {
          _clothUploading = false;
        }
      });
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${AppLocalizations.of(context).translate('upload_failed')}: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _sendTryon() async {
    final tryonProvider = Provider.of<UploadTryonProvider>(context, listen: false);
    final authService = AuthService();
    
    // Kiểm tra nếu đang loading thì không cho bấm nữa
    if (tryonProvider.isLoading) {
      debugPrint('⚠️ Đang tải, bỏ qua thao tác');
      return;
    }
    
    // Kiểm tra xem cả 2 ảnh đã được chọn chưa
    if (_initLocalPath == null || _clothLocalPath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).translate('must_select_two_images')),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Kiểm tra xem đang upload không
    if (_initUploading || _clothUploading) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).translate('wait_for_upload_complete')),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    debugPrint('🚀 Bắt đầu quá trình Try-on...');

    // ========== CHECK TOKEN TRƯỚC KHI UPLOAD ==========
    debugPrint('🔍 Kiểm tra token trước khi upload...');
    const int tokenCost = 50;
    
    try {
      final checkResult = await authService.checkToken();
      
      if (!checkResult.success) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).translate('token_check_failed')),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      
      final totalTokens = (checkResult.tokenFree ?? 0) + (checkResult.tokenVip ?? 0);
      debugPrint('💰 Token hiện có: $totalTokens (Free: ${checkResult.tokenFree}, VIP: ${checkResult.tokenVip})');
      
      if (totalTokens < tokenCost) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).translate('not_enough_tokens')),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
        return;
      }
      
      debugPrint('✅ Token đủ! Tiếp tục upload ảnh...');
    } catch (e) {
      debugPrint('❌ Lỗi kiểm tra token: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${AppLocalizations.of(context).translate('token_check_failed')}: $e'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    // ========== END CHECK TOKEN ==========

    // Upload cả 2 ảnh lên Cloudinary nếu chưa upload
    try {
      // Upload init image nếu chưa có URL
      if (_initPublicUrl == null) {
        debugPrint('📤 Đang tải ảnh người mẫu...');
        await _uploadImage(true);
      }
      
      // Upload cloth image nếu chưa có URL
      if (_clothPublicUrl == null) {
        debugPrint('📤 Đang tải ảnh quần áo...');
        await _uploadImage(false);
      }
      
      // Kiểm tra lại sau khi upload
      if (_initPublicUrl == null || _clothPublicUrl == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).translate('upload_failed_try_again')),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    } catch (e) {
      debugPrint('❌ Lỗi upload: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${AppLocalizations.of(context).translate('upload_failed')}: $e'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Gửi Cloudinary URLs tới API
    debugPrint('📤 Sending to try-on server...');
    debugPrint('   init_image: $_initPublicUrl');
    debugPrint('   cloth_image: $_clothPublicUrl');
    debugPrint('   cloth_type: $_clothType');
    
    await tryonProvider.tryon(_initPublicUrl!, _clothPublicUrl!, _clothType);
    
    // Kiểm tra kết quả và navigate đến màn hình mới
    if (!mounted) return;
    
    if (tryonProvider.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${AppLocalizations.of(context).translate('error_prefix')}: ${tryonProvider.error}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }
    
    if (tryonProvider.response != null && 
        tryonProvider.response!.outputImages.isNotEmpty) {
      // Navigate đến màn hình kết quả
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TryonResultScreen(
            futureLinks: tryonProvider.response!.outputImages,
            initImageUrl: _initPublicUrl!,
            clothImageUrl: _clothPublicUrl!,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Required for AutomaticKeepAliveClientMixin
    super.build(context);
    
    return Consumer<UploadTryonProvider>(
      builder: (context, provider, _) {
        return Column(
          children: [
            // Banner Ad ở đầu màn hình
            const BannerAdWidget(),
            // Main content - scrollable
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                      Text(AppLocalizations.of(context).translate('bottom_upload'), style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => _pickImage(true),
                child: _buildImagePreview(
                  localPath: _initLocalPath,
                  publicUrl: _initPublicUrl,
                  uploading: _initUploading,
                  placeholderText: AppLocalizations.of(context).translate('select_model_image'),
                ),
              ),
              const SizedBox(height: 16),
                Text(AppLocalizations.of(context).translate('bottom_upload'), style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => _pickImage(false),
                child: _buildImagePreview(
                  localPath: _clothLocalPath,
                  publicUrl: _clothPublicUrl,
                  uploading: _clothUploading,
                  placeholderText: AppLocalizations.of(context).translate('select_cloth_image'),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _clothType,
                items: _clothTypes
                    .map((type) => DropdownMenuItem(
                          value: type,
                          child: Text(type),
                        ))
                    .toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _clothType = val);
                },
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context).translate('type_of_cloth'),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: provider.isLoading ? null : _sendTryon,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.green,
                ),
                child: provider.isLoading
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
                          const SizedBox(width: 12),
                          Text(AppLocalizations.of(context).translate('processing_info'), style: const TextStyle(color: Colors.white)),
                        ],
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(AppLocalizations.of(context).translate('try_on'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.toll, size: 16, color: Colors.amber),
                                SizedBox(width: 4),
                                Text('50', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                              ],
                            ),
                          ),
                        ],
                      ),
              ),
              if (provider.isLoading)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Text(
                    AppLocalizations.of(context).translate('sending_to_ai'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildImagePreview({
    required String? localPath,
    required String? publicUrl,
    required bool uploading,
    required String placeholderText,
  }) {
    if (localPath == null && publicUrl == null) {
      return Container(
        height: 150,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_photo_alternate, size: 48, color: Colors.grey[400]),
              const SizedBox(height: 8),
              Text(placeholderText, style: TextStyle(color: Colors.grey[600])),
              const SizedBox(height: 6),
              // Removed 'Coming soon' text
            ],
          ),
        ),
      );
    }

    if (publicUrl != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(publicUrl, height: 150, fit: BoxFit.cover),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.check_circle, size: 16, color: Colors.green),
              const SizedBox(width: 4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(AppLocalizations.of(context).translate('uploaded'), style: const TextStyle(fontSize: 14, color: Colors.green)),
                    // Removed 'Coming soon' text from upload success notification
                  ],
                ),
              ),
            ],
          ),
        ],
      );
    }

    // localPath != null - chưa upload
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(File(localPath!), height: 150, fit: BoxFit.cover),
            ),
            if (uploading)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withAlpha(128),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(color: Colors.white),
                        const SizedBox(height: 8),
                        Text(
                          AppLocalizations.of(context).translate('uploading'),
                          style: const TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
