import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/cloudinary_service.dart';
import '../services/session_upload_manager.dart';
import '../constants/cloudinary_constants.dart';
import '../providers/theme_provider.dart';
import '../utils/app_styles.dart';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';
import 'dart:convert';
import '../l10n/app_localizations.dart';

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
  bool _isPicking = false; // Ngan double-click
  String? _errorMessage;

  // Lấy ảnh hiện tại của user (image, không phải profile_image)
  String? get _currentImage => _authService.currentUser?['image'];

  Future<void> _pickImage() async {
    // Ngan double-click
    if (_isPicking) return;
    _isPicking = true;
    
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: ImageSource.gallery);
      
      if (picked != null && mounted) {
        // Mở màn hình crop ảnh
        await _cropImage(picked.path);
      }
    } finally {
      _isPicking = false;
    }
  }

  /// Crop ảnh với tỷ lệ tự do hoặc các preset
  Future<void> _cropImage(String imagePath) async {
    try {
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: imagePath,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: AppLocalizations.of(context).translate('crop_image'),
            toolbarColor: AppStyles.primaryBlue,
            toolbarWidgetColor: AppStyles.textWhite,
            statusBarColor: AppStyles.primaryBlue,
            backgroundColor: Colors.black,
            activeControlsWidgetColor: AppStyles.primaryBlue,
            initAspectRatio: CropAspectRatioPreset.original,
            lockAspectRatio: false,
            hideBottomControls: false,
            showCropGrid: true,
            cropStyle: CropStyle.rectangle,
            aspectRatioPresets: [
              CropAspectRatioPreset.original,
              CropAspectRatioPreset.square,
              CropAspectRatioPreset.ratio3x2,
              CropAspectRatioPreset.ratio4x3,
              CropAspectRatioPreset.ratio16x9,
            ],
          ),
          IOSUiSettings(
            title: AppLocalizations.of(context).translate('crop_image'),
            aspectRatioPresets: [
              CropAspectRatioPreset.original,
              CropAspectRatioPreset.square,
              CropAspectRatioPreset.ratio3x2,
              CropAspectRatioPreset.ratio4x3,
              CropAspectRatioPreset.ratio16x9,
            ],
          ),
        ],
      );

      if (croppedFile != null && mounted) {
        // Copy file đã crop vào app directory
        final appDir = await getApplicationDocumentsDirectory();
        final fileName = 'model_image_${DateTime.now().millisecondsSinceEpoch}${path.extension(croppedFile.path)}';
        final savedPath = path.join(appDir.path, fileName);
        
        final croppedFileObj = File(croppedFile.path);
        await croppedFileObj.copy(savedPath);
        
        setState(() {
          _selectedImagePath = savedPath;
          _errorMessage = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = '${AppLocalizations.of(context).translate('error_prefix')}: $e';
        });
      }
    }
  }

  /// Xóa ảnh cũ trên Cloudinary nếu có
  Future<void> _deleteOldImage(String? oldImageUrl) async {
    if (oldImageUrl == null || oldImageUrl.isEmpty) return;
    
    try {
      // Extract public_id từ URL
      // URL format: https://res.cloudinary.com/cloud_name/image/upload/v123/public_id.ext
      final uri = Uri.parse(oldImageUrl);
      final pathSegments = uri.pathSegments;
      
      // Tìm vị trí 'upload' và lấy phần sau đó
      final uploadIndex = pathSegments.indexOf('upload');
      if (uploadIndex == -1 || uploadIndex >= pathSegments.length - 1) return;
      
      // Public ID là phần cuối, bỏ extension
      String publicId = pathSegments.last;
      final dotIndex = publicId.lastIndexOf('.');
      if (dotIndex != -1) {
        publicId = publicId.substring(0, dotIndex);
      }
      
      // Nếu có version (v123456), bỏ qua nó
      if (pathSegments.length > uploadIndex + 2) {
        final afterUpload = pathSegments[uploadIndex + 1];
        if (afterUpload.startsWith('v') && int.tryParse(afterUpload.substring(1)) != null) {
          // Có version, public_id là phần còn lại
          publicId = pathSegments.sublist(uploadIndex + 2).join('/');
          final lastDot = publicId.lastIndexOf('.');
          if (lastDot != -1) {
            publicId = publicId.substring(0, lastDot);
          }
        }
      }
      
      debugPrint('Xóa ảnh cũ với public_id: $publicId');
      
      // Gọi Cloudinary destroy API
      final timestamp = (DateTime.now().millisecondsSinceEpoch ~/ 1000).toString();
      
      final paramsToSign = {
        'public_id': publicId,
        'timestamp': timestamp,
      };
      
      // Tạo signature
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
        debugPrint('Kết quả xóa ảnh cũ: ${jsonResponse['result']}');
      }
    } catch (e) {
      debugPrint('Lỗi khi xóa ảnh cũ: $e');
      // Không throw exception, chỉ log lỗi
    }
  }

  Future<void> _updateImage() async {
    if (_selectedImagePath == null) {
      setState(() {
        _errorMessage = AppLocalizations.of(context).translate('please_select_image');
      });
      return;
    }

    setState(() {
      _isUploading = true;
      _errorMessage = null;
    });

    try {
      // Lưu lại ảnh cũ để xóa sau
      final oldImageUrl = _currentImage;
      
      // Upload ảnh mới lên Cloudinary
      debugPrint('Đang tải ảnh mẫu mới lên...');
      final file = File(_selectedImagePath!);
      final newImageUrl = await _cloudinaryService.uploadImage(file);
      
      debugPrint('URL ảnh mới: $newImageUrl');
      
      // Gọi API để cập nhật ảnh trong cơ sở dữ liệu
      debugPrint('Đang cập nhật ảnh người dùng trong cơ sở dữ liệu...');
      final result = await _authService.changeImage(newImageUrl);
      
      if (result.success) {
        // Cập nhật URL ảnh model mới trong SessionUploadManager
        await SessionUploadManager().setUserModelImageUrl(newImageUrl);
        
        // Xóa ảnh cũ trên Cloudinary (nếu có)
        await _deleteOldImage(oldImageUrl);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context).translate('update_image_success')),
              backgroundColor: AppStyles.primaryGreen,
            ),
          );
          Navigator.pop(context, true); // Return true để báo hiệu đã cập nhật
        }
      } else {
        setState(() {
          _errorMessage = result.message;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Lỗi: $e';
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
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).translate('edit_model_image')),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
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
            child: SingleChildScrollView(
              padding: AppStyles.paddingAll16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Hiển thị ảnh hiện tại
                  Text(
                    AppLocalizations.of(context).translate('current_model_image'),
                    style: AppStyles.titleLarge,
                  ),
                  SizedBox(height: AppStyles.spacingMD),
                  _buildCurrentImage(),
                  
                  SizedBox(height: AppStyles.spacingXXL),
                  
                  // Chọn ảnh mới
                  Text(
                    AppLocalizations.of(context).translate('select_new_image'),
                    style: AppStyles.titleLarge,
                  ),
                  SizedBox(height: AppStyles.spacingMD),
                  _buildNewImageSection(),
                  
                  SizedBox(height: AppStyles.spacingXXL),
                  
                  // Error message
                  if (_errorMessage != null)
                    Container(
                      padding: AppStyles.paddingAll12,
                      decoration: AppStyles.errorContainerDecoration,
                      child: Row(
                        children: [
                    Icon(Icons.error_outline, color: AppStyles.errorText),
                    SizedBox(width: AppStyles.spacingSM),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(color: AppStyles.errorText),
                      ),
                    ),
                  ],
                ),
              ),
            
            SizedBox(height: AppStyles.spacingXXL),
            
            // Nút cập nhật
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isUploading || _selectedImagePath == null
                    ? null
                    : _updateImage,
                style: AppStyles.primaryButtonStyle,
                child: _isUploading
                    ? SizedBox(
                        height: AppStyles.progressSizeMD,
                        width: AppStyles.progressSizeMD,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(AppStyles.textWhite),
                        ),
                      )
                    : Text(
                        AppLocalizations.of(context).translate('update_image'),
                        style: AppStyles.buttonTextLarge,
                      ),
              ),
            ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentImage() {
    if (_currentImage != null && _currentImage!.isNotEmpty) {
      return Container(
        height: 250,
        width: double.infinity,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.blue.shade300),
          borderRadius: AppStyles.borderRadiusLG,
        ),
        child: ClipRRect(
          borderRadius: AppStyles.borderRadiusLG,
          child: Image.network(
            _currentImage!,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: AppStyles.backgroundGreyMedium,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.broken_image, size: AppStyles.iconSizeHuge, color: AppStyles.textGrey),
                    SizedBox(height: AppStyles.spacingSM),
                    Text(AppLocalizations.of(context).translate('cannot_load_image'), style: TextStyle(color: AppStyles.textGrey)),
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
      decoration: AppStyles.warningContainerDecoration.copyWith(
        border: Border.all(color: AppStyles.warningBorder),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.image_not_supported, size: AppStyles.iconSizeHuge, color: AppStyles.warningText),
          SizedBox(height: AppStyles.spacingMD),
          Text(
            AppLocalizations.of(context).translate('no_model_image_yet'),
            style: AppStyles.titleMedium.copyWith(color: AppStyles.warningText),
          ),
          SizedBox(height: AppStyles.spacingSM),
          Text(
            AppLocalizations.of(context).translate('please_set_model_image'),
            style: AppStyles.bodyMediumWithColor(Colors.orange.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildNewImageSection() {
    return Column(
      children: [
        // Hiển thị ảnh đã chọn
        if (_selectedImagePath != null)
          Container(
            height: 250,
            width: double.infinity,
            margin: EdgeInsets.only(bottom: AppStyles.spacingMD),
            decoration: BoxDecoration(
              border: Border.all(color: AppStyles.successBorder),
              borderRadius: AppStyles.borderRadiusLG,
            ),
            child: ClipRRect(
              borderRadius: AppStyles.borderRadiusLG,
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
            label: Text(_selectedImagePath == null 
                ? AppLocalizations.of(context).translate('pick_from_gallery') 
                : AppLocalizations.of(context).translate('pick_another_image')),
            style: OutlinedButton.styleFrom(
              padding: AppStyles.paddingVertical12.copyWith(top: 14, bottom: 14),
              shape: RoundedRectangleBorder(
                borderRadius: AppStyles.borderRadiusMD,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
