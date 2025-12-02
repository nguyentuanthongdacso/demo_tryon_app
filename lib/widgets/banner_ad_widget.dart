import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../services/ad_service.dart';

/// Widget hiển thị Banner Ad ở đầu màn hình
/// Sử dụng trong các tab: Search, Upload, Suggest (không có Profile)
class BannerAdWidget extends StatefulWidget {
  const BannerAdWidget({super.key});

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  BannerAd? _bannerAd;
  bool _isAdLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadBannerAd();
  }

  void _loadBannerAd() {
    _bannerAd = AdService().createBannerAd(
      onAdLoaded: (ad) {
        debugPrint('✅ Banner ad loaded');
        if (mounted) {
          setState(() {
            _isAdLoaded = true;
          });
        }
      },
      onAdFailedToLoad: (ad, error) {
        debugPrint('❌ Banner ad failed to load: ${error.message}');
        ad.dispose();
        _bannerAd = null;
      },
    );
    
    _bannerAd?.load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isAdLoaded || _bannerAd == null) {
      // Placeholder khi chưa load xong - giữ chiều cao để tránh layout jump
      return const SizedBox(
        height: 50, // AdSize.banner.height
        child: Center(
          child: SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    return Container(
      alignment: Alignment.center,
      width: _bannerAd!.size.width.toDouble(),
      height: _bannerAd!.size.height.toDouble(),
      child: AdWidget(ad: _bannerAd!),
    );
  }
}
