import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import '../providers/search_provider.dart';
import '../providers/theme_provider.dart';
import '../l10n/app_localizations.dart';
import '../widgets/banner_ad_widget.dart';
import '../services/cloudinary_service.dart';
import '../utils/app_styles.dart';
import 'try_on_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> 
    with AutomaticKeepAliveClientMixin {
  final TextEditingController _urlController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final CloudinaryService _cloudinaryService = CloudinaryService();
  
  bool _isCropping = false;
  String? _croppedImageUrl; // URL của ảnh đã crop và upload lên Cloudinary

  // Giữ state khi chuyển tab
  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _urlController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _handleSearch() {
    FocusScope.of(context).unfocus(); // Đóng bàn phím
    final url = _urlController.text.trim();
    if (url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).translate('please_enter_url'))),
      );
      return;
    }
    // Reset cropped image khi search mới
    setState(() {
      _croppedImageUrl = null;
    });
    context.read<SearchProvider>().searchImages(url);
  }

  /// Download ảnh từ URL về local
  Future<File?> _downloadImage(String imageUrl) async {
    try {
      final response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode == 200) {
        final tempDir = await getTemporaryDirectory();
        final fileName = 'temp_crop_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final file = File(path.join(tempDir.path, fileName));
        await file.writeAsBytes(response.bodyBytes);
        return file;
      }
    } catch (e) {
      debugPrint('Error downloading image: $e');
    }
    return null;
  }

  /// Crop ảnh đã chọn và upload lên Cloudinary
  Future<void> _cropSelectedImage() async {
    final provider = context.read<SearchProvider>();
    final selectedImage = provider.selectedImage;
    
    if (selectedImage == null) return;
    
    setState(() {
      _isCropping = true;
    });
    
    try {
      // Download ảnh về local
      final localFile = await _downloadImage(selectedImage.url);
      if (localFile == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context).translate('error_downloading_image')),
              backgroundColor: AppStyles.primaryRed,
            ),
          );
        }
        return;
      }
      
      // Mở màn hình crop
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: localFile.path,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: AppLocalizations.of(context).translate('crop_image'),
            toolbarColor: Colors.blue,
            toolbarWidgetColor: Colors.white,
            statusBarColor: Colors.blue,
            backgroundColor: Colors.black,
            activeControlsWidgetColor: Colors.blue,
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
        // Upload ảnh đã crop lên Cloudinary với tracking
        final croppedFileObj = File(croppedFile.path);
        final uploadResult = await _cloudinaryService.uploadImageWithTracking(croppedFileObj, 'cropped');
        
        setState(() {
          _croppedImageUrl = uploadResult.url;
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context).translate('crop_success')),
              backgroundColor: AppStyles.primaryGreen,
            ),
          );
        }
      }
      
      // Xóa file tạm
      try {
        await localFile.delete();
      } catch (_) {}
      
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppLocalizations.of(context).translate('error_prefix')}: $e'),
            backgroundColor: AppStyles.primaryRed,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCropping = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Required for AutomaticKeepAliveClientMixin
    super.build(context);
    
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).translate('search_appbar_title')),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
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
            child: Column(
              children: [
                // Banner Ad ở đầu màn hình
                const BannerAdWidget(),
                // Main content - scrollable
                Expanded(
                  child: Stack(
                    children: [
                      SingleChildScrollView(
                        child: Padding(
                          padding: const EdgeInsets.only(
                            left: 16.0,
                            top: 16.0,
                            right: 16.0,
                            bottom: 100, // Space for fixed button at bottom
                          ),
                          child: Column(
                            children: [
                              TextField(
                                controller: _urlController,
                                focusNode: _focusNode,
                                decoration: AppStyles.textFieldDecoration(
                      hintText: AppLocalizations.of(context).translate('enter_image_url_hint'),
                      labelText: AppLocalizations.of(context).translate('url_label'),
                      prefixIcon: Icons.link,
                    ),
                    keyboardType: TextInputType.url,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _handleSearch(),
                  ),
                  SizedBox(height: AppStyles.spacingLG),
                  SizedBox(
                    width: double.infinity,
                    child: Consumer<SearchProvider>(
                      builder: (context, provider, _) {
                        return ElevatedButton.icon(
                          onPressed: provider.isLoading ? null : _handleSearch,
                          icon: provider.isLoading 
                              ? SizedBox(
                                  width: AppStyles.progressSizeSM,
                                  height: AppStyles.progressSizeSM,
                                  child: const CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Icon(Icons.search),
                          label: Text(AppLocalizations.of(context).translate('search_button')),
                          style: AppStyles.searchButtonStyle,
                        );
                      },
                    ),
                  ),
                  SizedBox(height: AppStyles.spacingXXL),
                  Consumer<SearchProvider>(
                    builder: (context, provider, _) {
                      if (provider.isLoading) {
                        return const Padding(
                          padding: EdgeInsets.all(32.0),
                          child: CircularProgressIndicator(),
                        );
                      }

                      if (provider.error != null) {
                        return Container(
                          padding: AppStyles.paddingAll16,
                          decoration: AppStyles.errorContainerDecoration,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.error_outline,
                                  color: AppStyles.errorText, size: AppStyles.iconSizeXXL),
                              SizedBox(height: AppStyles.spacingSM),
                              Text(
                                provider.error ?? 'Có lỗi xảy ra',
                                textAlign: TextAlign.center,
                                style: AppStyles.errorTextStyle,
                              ),
                            ],
                          ),
                        );
                      }

                      if (provider.images.isEmpty) {
                        return const SizedBox.shrink();
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${AppLocalizations.of(context).translate('results_label')} (${provider.images.length} ${AppLocalizations.of(context).translate('photos')})',
                            style: AppStyles.titleMedium,
                          ),
                          SizedBox(height: AppStyles.spacingMD),
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: AppStyles.spacingMD,
                              mainAxisSpacing: AppStyles.spacingMD,
                              childAspectRatio: 1,
                            ),
                            itemCount: provider.images.length,
                            itemBuilder: (context, index) {
                              final image = provider.images[index];
                              final isSelected =
                                  provider.selectedImage?.id == image.id;

                              return GestureDetector(
                                onTap: () {
                                  provider.selectImage(image);
                                },
                                child: Container(
                                  decoration: isSelected
                                      ? AppStyles.selectedItemDecoration
                                      : AppStyles.unselectedItemDecoration,
                                  child: Stack(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(6),
                                        child: Image.network(
                                          image.url,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) {
                                            return Container(
                                              color: AppStyles.backgroundGreyMedium,
                                              child: Icon(
                                                Icons.broken_image,
                                                size: AppStyles.iconSizeHuge,
                                                color: AppStyles.iconGrey,
                                              ),
                                            );
                                          },
                                          loadingBuilder: (context, child,
                                              loadingProgress) {
                                            if (loadingProgress == null) {
                                              return child;
                                            }
                                            return Center(
                                              child: CircularProgressIndicator(
                                                value: loadingProgress
                                                            .expectedTotalBytes !=
                                                        null
                                                    ? loadingProgress
                                                            .cumulativeBytesLoaded /
                                                        loadingProgress
                                                            .expectedTotalBytes!
                                                    : null,
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                      if (isSelected)
                                        Positioned(
                                          top: AppStyles.spacingXS,
                                          right: AppStyles.spacingXS,
                                          child: Container(
                                            decoration: AppStyles.checkBadgeDecoration,
                                            padding: AppStyles.paddingAll4,
                                            child: Icon(
                                              Icons.check,
                                              color: AppStyles.textWhite,
                                              size: AppStyles.iconSizeSM,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          // Fixed Try-On button at bottom
          Consumer<SearchProvider>(
            builder: (context, provider, _) {
              if (provider.selectedImage == null) {
                return const SizedBox.shrink();
              }

              return Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  decoration: AppStyles.bottomSheetDecoration,
                  padding: AppStyles.paddingAllLG,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Hiển thị ảnh đã crop (nếu có)
                      if (_croppedImageUrl != null) ...[
                        Container(
                          padding: AppStyles.paddingAllSM,
                          decoration: AppStyles.successContainerDecoration,
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(AppStyles.radiusSM),
                                child: Image.network(
                                  _croppedImageUrl!,
                                  width: 60,
                                  height: 60,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              SizedBox(width: AppStyles.spacingMD),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      AppLocalizations.of(context).translate('cropped_image'),
                                      style: AppStyles.successTitleStyle,
                                    ),
                                    SizedBox(height: AppStyles.spacingXS),
                                    Text(
                                      AppLocalizations.of(context).translate('will_use_cropped'),
                                      style: AppStyles.successSubtitleStyle,
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                onPressed: () {
                                  setState(() {
                                    _croppedImageUrl = null;
                                  });
                                },
                                icon: Icon(Icons.close, color: AppStyles.successDark),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: AppStyles.spacingMD),
                      ],
                      // Các nút action
                      Row(
                        children: [
                          // Nút Crop
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _isCropping ? null : _cropSelectedImage,
                              icon: _isCropping
                                  ? SizedBox(
                                      width: AppStyles.iconSizeMD,
                                      height: AppStyles.iconSizeMD,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: AppStyles.textWhite,
                                      ),
                                    )
                                  : Icon(Icons.crop, color: AppStyles.textWhite),
                              label: Text(
                                AppLocalizations.of(context).translate('crop_image'),
                                style: AppStyles.buttonTextStyleWhite,
                              ),
                              style: AppStyles.submitButtonStyleOrange,
                            ),
                          ),
                          SizedBox(width: AppStyles.spacingMD),
                          // Nút Try-On
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                // Sử dụng ảnh đã crop nếu có, không thì dùng ảnh gốc
                                final imageUrl = _croppedImageUrl ?? provider.selectedImage?.url;
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => TryOnScreen(
                                      imageUrl: imageUrl,
                                    ),
                                  ),
                                );
                              },
                              icon: Icon(Icons.checkroom, color: AppStyles.textWhite),
                              label: Text(
                                AppLocalizations.of(context).translate('try_on'),
                                style: AppStyles.buttonTextStyleWhite,
                              ),
                              style: AppStyles.submitButtonStyleGreen,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}