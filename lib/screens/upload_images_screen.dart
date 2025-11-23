import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../providers/tryon_provider.dart';
import '../services/cloudinary_service.dart';

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
      setState(() {
        if (isInit) {
          _initLocalPath = picked.path;
          _initPublicUrl = null;
        } else {
          _clothLocalPath = picked.path;
          _clothPublicUrl = null;
        }
      });
      
      // Tự động upload lên Cloudinary ngay sau khi chọn ảnh
      await _uploadImage(isInit);
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
      // Upload to Cloudinary
      final publicUrl = await _cloudinaryService.uploadImage(file);
      
      if (!mounted) return;
      setState(() {
        if (isInit) {
          _initPublicUrl = publicUrl;
          _initUploading = false;
        } else {
          _clothPublicUrl = publicUrl;
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
          content: Text('Upload thất bại: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _sendTryon() {
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

    // BẮT BUỘC phải upload lên Cloudinary trước
    if (_initPublicUrl == null || _clothPublicUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng upload cả 2 ảnh lên Cloudinary trước khi Try-on'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    // Gửi Cloudinary URLs tới API
    Provider.of<TryonProvider>(context, listen: false)
        .tryon(_initPublicUrl!, _clothPublicUrl!, _clothType);
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
                child: provider.isLoading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Try-on'),
              ),
              const SizedBox(height: 24),
              if (provider.response != null && provider.response!.outputImages.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Kết quả:', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Image.network(
                      provider.response!.outputImages.first,
                      height: 200,
                      fit: BoxFit.cover,
                    ),
                  ],
                ),
              if (provider.error != null)
                Text('Lỗi: ${provider.error}', style: const TextStyle(color: Colors.red)),
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
