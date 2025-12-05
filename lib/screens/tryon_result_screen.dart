import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../providers/theme_provider.dart';
import '../utils/app_styles.dart';
import '../widgets/image_with_context_menu.dart';

class TryonResultScreen extends StatefulWidget {
  final List<String> futureLinks;
  final String initImageUrl;
  final String clothImageUrl;

  const TryonResultScreen({
    super.key,
    required this.futureLinks,
    required this.initImageUrl,
    required this.clothImageUrl,
  });

  @override
  State<TryonResultScreen> createState() => _TryonResultScreenState();
}

class _TryonResultScreenState extends State<TryonResultScreen> {
  Timer? _reloadTimer;
  final Map<String, bool> _imageStatus = {};
  int _attemptCount = 0;
  final int _maxAttempts = 360; // Thử trong 360 giây

  @override
  void initState() {
    super.initState();
    // Khởi tạo trạng thái cho tất cả ảnh
    for (var link in widget.futureLinks) {
      _imageStatus[link] = false;
    }
    // Bắt đầu kiểm tra ảnh
    _startChecking();
  }

  @override
  void dispose() {
    _reloadTimer?.cancel();
    super.dispose();
  }

  void _startChecking() {
    _reloadTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      _attemptCount++;
      
      // Kiểm tra timeout
      if (_attemptCount > _maxAttempts) {
        timer.cancel();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context).translate('timeout_try_again')),
              backgroundColor: AppStyles.primaryOrange,
              duration: AppStyles.snackBarDurationMedium,
            ),
          );
        }
        return;
      }

      // Kiểm tra từng ảnh
      bool allReady = true;
      for (var link in widget.futureLinks) {
        if (!_imageStatus[link]!) {
          final isReady = await _checkImageAvailable(link);
          if (mounted) {
            setState(() {
              _imageStatus[link] = isReady;
            });
          }
          if (!isReady) {
            allReady = false;
          }
        }
      }

      // Nếu tất cả ảnh đã sẵn sàng, dừng timer
        if (allReady) {
        timer.cancel();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context).translate('all_images_ready')),
              backgroundColor: AppStyles.primaryGreen,
              duration: AppStyles.snackBarDurationShort,
            ),
          );
        }
      }
    });
  }

  Future<bool> _checkImageAvailable(String url) async {
    try {
      final response = await http.head(Uri.parse(url)).timeout(
        const Duration(seconds: 2),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final allReady = _imageStatus.values.every((status) => status);
    final readyCount = _imageStatus.values.where((status) => status).length;
    final totalCount = _imageStatus.length;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).translate('tryon_results_title')),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (!allReady)
            Padding(
              padding: AppStyles.paddingAll8,
              child: Center(
                child: Row(
                  children: [
                    SizedBox(
                      width: AppStyles.progressSizeSM,
                      height: AppStyles.progressSizeSM,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Theme.of(context).colorScheme.onPrimary,
                        ),
                      ),
                    ),
                    SizedBox(width: AppStyles.spacingSM),
                    Text(
                      '${AppLocalizations.of(context).translate('processing_short')} ($readyCount/$totalCount)',
                      style: AppStyles.bodyMedium,
                    ),
                  ],
                ),
              ),
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
            child: SingleChildScrollView(
              padding: AppStyles.paddingAll16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Hiển thị thông tin
                  Card(
                    child: Padding(
                      padding: AppStyles.paddingAll16,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            allReady
                                ? AppLocalizations.of(context).translate('all_images_ready')
                                : '${AppLocalizations.of(context).translate('processing_short')} ($readyCount/$totalCount)',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: allReady ? AppStyles.primaryGreen : AppStyles.primaryOrange,
                            ),
                          ),
                          SizedBox(height: AppStyles.spacingSM),
                          Text(
                            'Thời gian chờ: $_attemptCount giây',
                            style: AppStyles.bodyMediumWithColor(AppStyles.textGrey),
                          ),
                          if (!allReady) ...[
                            SizedBox(height: AppStyles.spacingSM),
                            const LinearProgressIndicator(),
                          ],
                        ],
                      ),
                    ),
                  ),
            SizedBox(height: AppStyles.spacingLG),

            // Hiển thị ảnh gốc
            Text(
              AppLocalizations.of(context).translate('original_image'),
              style: AppStyles.titleMedium,
            ),
            SizedBox(height: AppStyles.spacingSM),
            Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Text(AppLocalizations.of(context).translate('model_label'), style: AppStyles.bodySmall),
                      SizedBox(height: AppStyles.spacingXS),
                      ClipRRect(
                        borderRadius: AppStyles.borderRadiusMD,
                        child: Image.network(
                          widget.initImageUrl,
                          height: 200,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => Container(
                            height: 200,
                            color: AppStyles.backgroundGreyMedium,
                            child: const Icon(Icons.error),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: AppStyles.spacingLG),
                Expanded(
                  child: Column(
                    children: [
                      Text(AppLocalizations.of(context).translate('cloth_label'), style: AppStyles.bodySmall),
                      SizedBox(height: AppStyles.spacingXS),
                      ClipRRect(
                        borderRadius: AppStyles.borderRadiusMD,
                        child: Image.network(
                          widget.clothImageUrl,
                          height: 200,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => Container(
                            height: 200,
                            color: AppStyles.backgroundGreyMedium,
                            child: const Icon(Icons.error),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: AppStyles.spacingXXL),

            // Hiển thị kết quả
            Text(
              AppLocalizations.of(context).translate('tryon_results_title'),
              style: AppStyles.titleMedium,
            ),
            SizedBox(height: AppStyles.spacingSM),

            ...widget.futureLinks.asMap().entries.map((entry) {
              final index = entry.key;
              final link = entry.value;
              final isReady = _imageStatus[link] ?? false;

              return Padding(
                padding: EdgeInsets.only(bottom: AppStyles.spacingLG),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${AppLocalizations.of(context).translate('results_label')} ${index + 1}',
                      style: AppStyles.bodyMedium.copyWith(fontWeight: FontWeight.w500),
                    ),
                    SizedBox(height: AppStyles.spacingSM),
                    isReady
                        ? ImageWithContextMenu(
                            imageUrl: link,
                            fit: BoxFit.cover,
                            borderRadius: AppStyles.borderRadiusMD,
                            placeholder: Container(
                              height: 300,
                              color: AppStyles.backgroundGreyLight,
                              child: const Center(
                                child: CircularProgressIndicator(),
                              ),
                            ),
                            errorWidget: Container(
                              height: 300,
                              color: AppStyles.backgroundGreyMedium,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.error, size: AppStyles.iconSizeHuge),
                                  SizedBox(height: AppStyles.spacingSM),
                                  const Text('Lỗi tải ảnh'),
                                ],
                              ),
                            ),
                          )
                        : ClipRRect(
                            borderRadius: AppStyles.borderRadiusMD,
                            child: Container(
                              height: 300,
                              decoration: BoxDecoration(
                                color: AppStyles.backgroundGreyLight,
                                borderRadius: AppStyles.borderRadiusMD,
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const CircularProgressIndicator(),
                                  SizedBox(height: AppStyles.spacingLG),
                                  Text(
                                    '⏳ Đang xử lý...',
                                    style: AppStyles.processingText,
                                  ),
                                ],
                              ),
                            ),
                          ),
                    ],
                  ),
                );
              }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}