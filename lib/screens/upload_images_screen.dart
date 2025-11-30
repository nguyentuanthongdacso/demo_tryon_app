import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:provider/provider.dart';

import '../providers/tryon_provider.dart';
import '../services/cloudinary_service.dart';
import 'tryon_result_screen.dart';

class UploadImagesScreen extends StatefulWidget {
  const UploadImagesScreen({super.key});

  @override
  State<UploadImagesScreen> createState() => _UploadImagesScreenState();
}

class _UploadImagesScreenState extends State<UploadImagesScreen> {
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
  
  String _clothType = 'upper_body';
  final _clothTypes = ['upper_body', 'lower_body', 'dress'];
  final _cloudinaryService = CloudinaryService();

  Future<void> _pickImage(bool isInit) async {
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
        
        if (newHash == oldHash && oldUrl != null) {
          // Ảnh giống nhau - giữ URL cũ, chỉ update local path
          debugPrint('♻️ Same image detected (hash: $newHash), keeping existing URL');
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
          debugPrint('🆕 New image detected (hash: $newHash)');
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
        debugPrint('Error processing file: $e');
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
          content: Text('Upload that bai: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _sendTryon() async {
    final tryonProvider = Provider.of<TryonProvider>(context, listen: false);
    
    // Kiểm tra nếu đang loading thì không cho bấm nữa
    if (tryonProvider.isLoading) {
      debugPrint('⚠️ Already loading, ignoring tap');
      return;
    }
    
    // Kiểm tra xem cả 2 ảnh đã được chọn chưa
    if (_initLocalPath == null || _clothLocalPath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bạn phải chọn 2 ảnh trước'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Kiểm tra xem đang upload không
    if (_initUploading || _clothUploading) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chờ upload hoàn tất'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    debugPrint('🚀 Starting Try-on process...');

    // Upload cả 2 ảnh lên Cloudinary nếu chưa upload
    try {
      // Upload init image nếu chưa có URL
      if (_initPublicUrl == null) {
        debugPrint('📤 Uploading init image...');
        await _uploadImage(true);
      }
      
      // Upload cloth image nếu chưa có URL
      if (_clothPublicUrl == null) {
        debugPrint('📤 Uploading cloth image...');
        await _uploadImage(false);
      }
      
      // Kiểm tra lại sau khi upload
      if (_initPublicUrl == null || _clothPublicUrl == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Upload ảnh thất bại, vui lòng thử lại'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    } catch (e) {
      debugPrint('❌ Upload error: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi upload: $e'),
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
          content: Text('Lỗi: ${tryonProvider.error}'),
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
    return Consumer<TryonProvider>(
      builder: (context, provider, _) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Reference Image', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => _pickImage(true),
                child: _buildImagePreview(
                  localPath: _initLocalPath,
                  publicUrl: _initPublicUrl,
                  uploading: _initUploading,
                  placeholderText: 'Chọn ảnh người',
                ),
              ),
              const SizedBox(height: 16),
              const Text('Cloth Image', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => _pickImage(false),
                child: _buildImagePreview(
                  localPath: _clothLocalPath,
                  publicUrl: _clothPublicUrl,
                  uploading: _clothUploading,
                  placeholderText: 'Chọn ảnh quần áo',
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
                decoration: const InputDecoration(
                  labelText: 'Cloth Type',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: provider.isLoading ? null : _sendTryon,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: provider.isLoading
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                          SizedBox(width: 12),
                          Text('Đang xử lý... (có thể mất 30-60 giây)'),
                        ],
                      )
                    : const Text('Try-on'),
              ),
              if (provider.isLoading)
                const Padding(
                  padding: EdgeInsets.only(top: 16),
                  child: Text(
                    '⏳ Đang gửi ảnh đến server AI...\nVui lòng đợi, quá trình này có thể mất 30-60 giây.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ),
            ],
          ),
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
                child: Text(
                  'Đã upload',
                  style: const TextStyle(fontSize: 12, color: Colors.green),
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
                  child: const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(color: Colors.white),
                        SizedBox(height: 8),
                        Text(
                          'Đang upload...',
                          style: TextStyle(color: Colors.white),
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
