import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../services/auth_service.dart';
import '../services/cloudinary_service.dart';
import '../constants/cloudinary_constants.dart';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';
import 'dart:convert';

class EditModelImageScreen extends StatefulWidget {
  const EditModelImageScreen({super.key});

  @override
  State<EditModelImageScreen> createState() => _EditModelImageScreenState();
}

class _EditModelImageScreenState extends State<EditModelImageScreen> {
  final AuthService _authService = AuthService();
  final CloudinaryService _cloudinaryService = CloudinaryService();
  
  String? _selectedImagePath;
  bool _isUploading = false;
  String? _errorMessage;

  // Lay anh hien tai cua user (image, khong phai profile_image)
  String? get _currentImage => _authService.currentUser?['image'];

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    
    if (picked != null) {
      try {
        // Copy file to app directory
        final appDir = await getApplicationDocumentsDirectory();
        final fileName = 'model_image_${DateTime.now().millisecondsSinceEpoch}${path.extension(picked.path)}';
        final savedPath = path.join(appDir.path, fileName);
        
        final originalFile = File(picked.path);
        await originalFile.copy(savedPath);
        
        setState(() {
          _selectedImagePath = savedPath;
          _errorMessage = null;
        });
      } catch (e) {
        setState(() {
          _errorMessage = 'Loi khi chon anh: $e';
        });
      }
    }
  }

  /// Xoa anh cu tren Cloudinary neu co
  Future<void> _deleteOldImage(String? oldImageUrl) async {
    if (oldImageUrl == null || oldImageUrl.isEmpty) return;
    
    try {
      // Extract public_id tu URL
      // URL format: https://res.cloudinary.com/cloud_name/image/upload/v123/public_id.ext
      final uri = Uri.parse(oldImageUrl);
      final pathSegments = uri.pathSegments;
      
      // Tim vi tri 'upload' va lay phan sau do
      final uploadIndex = pathSegments.indexOf('upload');
      if (uploadIndex == -1 || uploadIndex >= pathSegments.length - 1) return;
      
      // Public ID la phan cuoi, bo extension
      String publicId = pathSegments.last;
      final dotIndex = publicId.lastIndexOf('.');
      if (dotIndex != -1) {
        publicId = publicId.substring(0, dotIndex);
      }
      
      // Neu co version (v123456), bo qua no
      if (pathSegments.length > uploadIndex + 2) {
        final afterUpload = pathSegments[uploadIndex + 1];
        if (afterUpload.startsWith('v') && int.tryParse(afterUpload.substring(1)) != null) {
          // Co version, public_id la phan con lai
          publicId = pathSegments.sublist(uploadIndex + 2).join('/');
          final lastDot = publicId.lastIndexOf('.');
          if (lastDot != -1) {
            publicId = publicId.substring(0, lastDot);
          }
        }
      }
      
      debugPrint('Deleting old image with public_id: $publicId');
      
      // Goi Cloudinary destroy API
      final timestamp = (DateTime.now().millisecondsSinceEpoch ~/ 1000).toString();
      
      final paramsToSign = {
        'public_id': publicId,
        'timestamp': timestamp,
      };
      
      // Tao signature
      final sortedKeys = paramsToSign.keys.toList()..sort();
      final paramString = sortedKeys.map((key) => '$key=${paramsToSign[key]}').join('&');
      final stringToSign = '$paramString${CloudinaryConstants.apiSecret}';
      final signature = sha1.convert(utf8.encode(stringToSign)).toString();
      
      final url = Uri.parse(
        'https://api.cloudinary.com/v1_1/${CloudinaryConstants.cloudName}/image/destroy'
      );
      
      final response = await http.post(
        url,
        body: {
          'public_id': publicId,
          'timestamp': timestamp,
          'api_key': CloudinaryConstants.apiKey,
          'signature': signature,
        },
      );
      
      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        debugPrint('Delete old image result: ${jsonResponse['result']}');
      }
    } catch (e) {
      debugPrint('Error deleting old image: $e');
      // Khong throw exception, chi log loi
    }
  }

  Future<void> _updateImage() async {
    if (_selectedImagePath == null) {
      setState(() {
        _errorMessage = 'Vui long chon anh truoc';
      });
      return;
    }

    setState(() {
      _isUploading = true;
      _errorMessage = null;
    });

    try {
      // Luu lai anh cu de xoa sau
      final oldImageUrl = _currentImage;
      
      // Upload anh moi len Cloudinary
      debugPrint('Uploading new model image...');
      final file = File(_selectedImagePath!);
      final newImageUrl = await _cloudinaryService.uploadImage(file);
      
      debugPrint('New image URL: $newImageUrl');
      
      // Goi API de cap nhat image trong database
      debugPrint('Updating user image in database...');
      final result = await _authService.changeImage(newImageUrl);
      
      if (result.success) {
        // Xoa anh cu tren Cloudinary (neu co)
        await _deleteOldImage(oldImageUrl);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cap nhat anh thanh cong!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true); // Return true de bao hieu da cap nhat
        }
      } else {
        setState(() {
          _errorMessage = result.message;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Loi: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chinh sua anh mau'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hien thi anh hien tai
            const Text(
              'Anh mau hien tai:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildCurrentImage(),
            
            const SizedBox(height: 24),
            
            // Chon anh moi
            const Text(
              'Chon anh moi:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildNewImageSection(),
            
            const SizedBox(height: 24),
            
            // Error message
            if (_errorMessage != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red[300]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red[700]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(color: Colors.red[700]),
                      ),
                    ),
                  ],
                ),
              ),
            
            const SizedBox(height: 24),
            
            // Button cap nhat
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isUploading || _selectedImagePath == null
                    ? null
                    : _updateImage,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.blue,
                  disabledBackgroundColor: Colors.grey[300],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isUploading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Cap nhat anh',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentImage() {
    if (_currentImage != null && _currentImage!.isNotEmpty) {
      return Container(
        height: 250,
        width: double.infinity,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.blue[300]!),
          borderRadius: BorderRadius.circular(12),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(
            _currentImage!,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: Colors.grey[300],
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.broken_image, size: 48, color: Colors.grey),
                    SizedBox(height: 8),
                    Text('Khong the tai anh', style: TextStyle(color: Colors.grey)),
                  ],
                ),
              );
            },
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Center(
                child: CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                      : null,
                ),
              );
            },
          ),
        ),
      );
    }
    
    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.orange[50],
        border: Border.all(color: Colors.orange[300]!),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.image_not_supported, size: 48, color: Colors.orange[700]),
          const SizedBox(height: 12),
          Text(
            'Ban chua cap nhat anh mau',
            style: TextStyle(
              color: Colors.orange[700],
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Vui long chon anh de thu do',
            style: TextStyle(color: Colors.orange[600], fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildNewImageSection() {
    return Column(
      children: [
        // Hien thi anh da chon
        if (_selectedImagePath != null)
          Container(
            height: 250,
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.green[300]!),
              borderRadius: BorderRadius.circular(12),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(
                File(_selectedImagePath!),
                fit: BoxFit.contain,
              ),
            ),
          ),
        
        // Button chon anh
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _isUploading ? null : _pickImage,
            icon: const Icon(Icons.photo_library),
            label: Text(_selectedImagePath == null ? 'Chon anh tu thu vien' : 'Chon anh khac'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
