import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/search_tryon_provider.dart';
import '../providers/theme_provider.dart';
import '../services/auth_service.dart';
import '../utils/app_styles.dart';
import 'tryon_result_screen.dart';
import '../l10n/app_localizations.dart';

class TryOnScreen extends StatefulWidget {
  final String? imageUrl;

  const TryOnScreen({super.key, this.imageUrl});

  @override
  State<TryOnScreen> createState() => _TryOnScreenState();
}

class _TryOnScreenState extends State<TryOnScreen> {
  final AuthService _authService = AuthService();
  String _clothType = 'upper_body';
  final _clothTypes = ['upper_body', 'lower_body', 'dress'];

  // Getter trực tiếp từ AuthService singleton - luôn có data mới nhất
  String? get _userInitImage => _authService.currentUser?['image'];

  Future<void> _handleTryOn(String clothImageUrl) async {
    final tryonProvider = Provider.of<SearchTryonProvider>(context, listen: false);
    final initImageUrl = _userInitImage;

    if (tryonProvider.isLoading) {
      debugPrint('Already loading, ignoring tap');
      return;
    }

    if (initImageUrl == null || initImageUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).translate('no_model_image_set')),
          backgroundColor: AppStyles.primaryOrange,
          duration: AppStyles.snackBarDurationMedium,
        ),
      );
      return;
    }

    // ========== CHECK TOKEN TRƯỚC KHI GỌI API ==========
    debugPrint('🔍 Kiểm tra token trước khi try-on...');
    const int tokenCost = 50;
    
    try {
      final checkResult = await _authService.checkToken();
      
      if (!checkResult.success) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).translate('token_check_failed')),
            backgroundColor: AppStyles.primaryRed,
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
            backgroundColor: AppStyles.primaryRed,
            duration: AppStyles.snackBarDurationLong,
          ),
        );
        return;
      }
      
      debugPrint('✅ Token đủ! Tiếp tục try-on...');
    } catch (e) {
      debugPrint('❌ Lỗi kiểm tra token: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${AppLocalizations.of(context).translate('token_check_failed')}: $e'),
          backgroundColor: AppStyles.primaryRed,
        ),
      );
      return;
    }
    // ========== END CHECK TOKEN ==========

    debugPrint('Starting Try-on from Search...');
    debugPrint('init_image (user): $initImageUrl');
    debugPrint('cloth_image (selected): $clothImageUrl');
    debugPrint('cloth_type: $_clothType');

    await tryonProvider.tryon(initImageUrl, clothImageUrl, _clothType);

    if (!mounted) return;

    if (tryonProvider.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${AppLocalizations.of(context).translate('error_prefix')}: ${tryonProvider.error}'),
          backgroundColor: AppStyles.primaryRed,
          duration: AppStyles.snackBarDurationMedium,
        ),
      );
      return;
    }

    if (tryonProvider.response != null &&
        tryonProvider.response!.outputImages.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TryonResultScreen(
            futureLinks: tryonProvider.response!.outputImages,
            initImageUrl: initImageUrl,
            clothImageUrl: clothImageUrl,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final clothImageUrl =
        widget.imageUrl ?? ModalRoute.of(context)?.settings.arguments as String?;
    final initImageUrl = _userInitImage;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).translate('app_title')),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
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
            child: Padding(
              padding: AppStyles.paddingAll12,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Row hiển thị 2 ảnh cạnh nhau
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Ảnh người mẫu (bên trái)
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppLocalizations.of(context).translate('current_model_image'),
                                style: AppStyles.titleSmall,
                              ),
                              SizedBox(height: AppStyles.spacingSM),
                              AspectRatio(
                                aspectRatio: AppStyles.aspectRatioModel,
                                child: _buildInitImageSection(initImageUrl),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: AppStyles.spacingMD),
                        // Ảnh quần áo (bên phải)
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppLocalizations.of(context).translate('selected_cloth_image'),
                                style: AppStyles.titleSmall,
                              ),
                              SizedBox(height: AppStyles.spacingSM),
                              AspectRatio(
                                aspectRatio: AppStyles.aspectRatioModel,
                                child: _buildClothImageSection(clothImageUrl),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: AppStyles.spacingMD),
                  // Cloth type selector
                  _buildClothTypeSelector(),
                  SizedBox(height: AppStyles.spacingMD),
                  // Try-on button
                  _buildTryOnButton(clothImageUrl, initImageUrl),
                  // Error section
                  _buildErrorSection(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInitImageSection(String? initImageUrl) {
    debugPrint('🖼️ Building init image section with URL: $initImageUrl');
    
    if (initImageUrl != null && initImageUrl.isNotEmpty) {
      return Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: AppStyles.borderRadiusLG,
        ),
        child: ClipRRect(
          borderRadius: AppStyles.borderRadiusLG,
          child: Image.network(
            initImageUrl,
            fit: BoxFit.contain,
            cacheWidth: 400,
            errorBuilder: (context, error, stackTrace) {
              debugPrint('❌ Image load error: $error');
              return GestureDetector(
                onTap: () {
                  setState(() {});
                },
                child: Container(
                  color: AppStyles.backgroundGreyMedium,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.broken_image, size: AppStyles.iconSizeXXXL, color: AppStyles.iconGrey),
                      SizedBox(height: AppStyles.spacingXS),
                      Text(AppLocalizations.of(context).translate('cannot_load_image'), style: AppStyles.bodySmallWithColor(AppStyles.textGrey)),
                    ],
                  ),
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
      width: double.infinity,
      decoration: AppStyles.warningContainerDecoration,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.warning_amber, size: AppStyles.iconSizeXXXL, color: AppStyles.warningText),
          SizedBox(height: AppStyles.spacingSM),
          Text(
            'Chưa có ảnh người mẫu',
            style: TextStyle(
              color: AppStyles.warningText,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: AppStyles.spacingXS),
          Text(
            'Cập nhật trong Profile',
            style: TextStyle(color: AppStyles.iconOrange, fontSize: 11),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildClothImageSection(String? clothImageUrl) {
    if (clothImageUrl != null) {
      return Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: AppStyles.borderRadiusLG,
        ),
        child: ClipRRect(
          borderRadius: AppStyles.borderRadiusLG,
          child: Image.network(
            clothImageUrl,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: AppStyles.backgroundGreyMedium,
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.broken_image, size: AppStyles.iconSizeXXXL, color: AppStyles.iconGrey),
                      SizedBox(height: AppStyles.spacingSM),
                      Text(AppLocalizations.of(context).translate('cannot_load_image'),
                          style: AppStyles.bodySmallWithColor(AppStyles.textGrey)),
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
      decoration: BoxDecoration(
        color: AppStyles.backgroundGrey,
        borderRadius: AppStyles.borderRadiusLG,
      ),
      child: Center(
        child: Text(
          AppLocalizations.of(context).translate('no_image_selected'),
          style: AppStyles.bodyMediumWithColor(AppStyles.textGrey),
        ),
      ),
    );
  }

  Widget _buildClothTypeSelector() {
    return DropdownButtonFormField<String>(
      initialValue: _clothType,
      items: _clothTypes
          .map((type) => DropdownMenuItem(
                value: type,
                child: Center(
                  child: Text(
                    type == 'upper_body'
                        ? AppLocalizations.of(context).translate('cloth_upper')
                        : type == 'lower_body'
                            ? AppLocalizations.of(context).translate('cloth_lower')
                            : AppLocalizations.of(context).translate('cloth_full'),
                  ),
                ),
              ))
          .toList(),
      onChanged: (val) {
        if (val != null) setState(() => _clothType = val);
      },
      decoration: InputDecoration(
        labelText: AppLocalizations.of(context).translate('type_of_cloth'),
        border: const OutlineInputBorder(),
      ),
    );
  }

  Widget _buildTryOnButton(String? clothImageUrl, String? initImageUrl) {
    return SizedBox(
      width: double.infinity,
      child: Consumer<SearchTryonProvider>(
        builder: (context, provider, _) {
          final canTryOn = clothImageUrl != null &&
              initImageUrl != null &&
              initImageUrl.isNotEmpty;

          return ElevatedButton(
            onPressed: (canTryOn && !provider.isLoading)
                ? () => _handleTryOn(clothImageUrl)
                : null,
            style: AppStyles.primaryButtonStyle,
            child: provider.isLoading
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: AppStyles.progressSizeMD,
                        height: AppStyles.progressSizeMD,
                        child: const CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                      SizedBox(width: AppStyles.spacingMD),
                      Text(
                        'Processing...',
                        style: AppStyles.buttonText,
                      ),
                    ],
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        AppLocalizations.of(context).translate('try_on'),
                        style: AppStyles.buttonTextLarge,
                      ),
                      SizedBox(width: AppStyles.spacingSM),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('50', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                          SizedBox(width: AppStyles.spacingXS),
                          Image.asset('assets/icons/coin_free.png', width: AppStyles.coinIconSize, height: AppStyles.coinIconSize),
                          const Text(' / ', style: TextStyle(color: Colors.white70, fontSize: 18)),
                          Image.asset('assets/icons/coin_vip.png', width: AppStyles.coinIconSize, height: AppStyles.coinIconSize),
                        ],
                      ),
                    ],
                  ),
          );
        },
      ),
    );
  }

  Widget _buildErrorSection() {
    return Consumer<SearchTryonProvider>(
      builder: (context, provider, _) {
        if (provider.error != null) {
          return Container(
            padding: AppStyles.paddingAll16,
            decoration: AppStyles.errorContainerDecoration,
            child: Row(
              children: [
                Icon(Icons.error_outline, color: AppStyles.errorText),
                SizedBox(width: AppStyles.spacingMD),
                Expanded(
                  child: Text(
                    provider.error!,
                    style: AppStyles.errorTextStyle,
                  ),
                ),
              ],
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}
