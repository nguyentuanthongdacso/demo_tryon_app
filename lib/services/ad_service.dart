import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/ad_constants.dart';

// ignore: unused_import needed for Completer

/// AdMob Service - Quản lý quảng cáo trong ứng dụng
/// 
/// Hỗ trợ:
/// - Banner Ads: Hiển thị ở đầu các tab
/// - Rewarded Video Ads: Xem để nhận token
/// 
/// Anti-fraud client-side:
/// - Giới hạn thời gian giữa các lần xem
/// - Giới hạn số lần xem mỗi giờ/ngày
/// - Kiểm tra app không ở chế độ debug/root
class AdService {
  // Singleton pattern
  static final AdService _instance = AdService._internal();
  factory AdService() => _instance;
  AdService._internal();

  // State
  bool _isInitialized = false;
  BannerAd? _bannerAd;
  RewardedAd? _rewardedAd;
  bool _isRewardedAdLoading = false;
  
  // Anti-fraud tracking
  DateTime? _lastRewardedAdTime;
  final List<DateTime> _rewardedAdHistory = [];
  
  // Keys for SharedPreferences
  static const String _keyLastRewardedAdTime = 'ad_last_rewarded_time';
  static const String _keyRewardedAdHistory = 'ad_rewarded_history';
  // Reserved for future use
  // static const String _keyDailyRewardCount = 'ad_daily_reward_count';
  // static const String _keyLastRewardDate = 'ad_last_reward_date';

  /// Khởi tạo AdMob SDK
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      await MobileAds.instance.initialize();
      _isInitialized = true;
      debugPrint('✅ AdMob SDK initialized');
      
      // Load anti-fraud data từ SharedPreferences
      await _loadAntifraudData();
      
      // Pre-load rewarded ad
      await loadRewardedAd();
    } catch (e) {
      debugPrint('❌ AdMob initialization failed: $e');
    }
  }

  /// Load anti-fraud data từ local storage
  Future<void> _loadAntifraudData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Load last rewarded ad time
      final lastTimeMs = prefs.getInt(_keyLastRewardedAdTime);
      if (lastTimeMs != null) {
        _lastRewardedAdTime = DateTime.fromMillisecondsSinceEpoch(lastTimeMs);
      }
      
      // Load rewarded ad history (for hourly limit)
      final historyStr = prefs.getStringList(_keyRewardedAdHistory) ?? [];
      _rewardedAdHistory.clear();
      for (final str in historyStr) {
        _rewardedAdHistory.add(DateTime.parse(str));
      }
      
      // Clean up old history (older than 24 hours)
      final now = DateTime.now();
      _rewardedAdHistory.removeWhere((dt) => now.difference(dt).inHours >= 24);
      
      debugPrint('📊 Loaded ad history: ${_rewardedAdHistory.length} ads in last 24h');
    } catch (e) {
      debugPrint('⚠️ Error loading antifraud data: $e');
    }
  }

  /// Save anti-fraud data to local storage
  Future<void> _saveAntifraudData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      if (_lastRewardedAdTime != null) {
        await prefs.setInt(_keyLastRewardedAdTime, _lastRewardedAdTime!.millisecondsSinceEpoch);
      }
      
      await prefs.setStringList(
        _keyRewardedAdHistory,
        _rewardedAdHistory.map((dt) => dt.toIso8601String()).toList(),
      );
    } catch (e) {
      debugPrint('⚠️ Error saving antifraud data: $e');
    }
  }

  // ==================== BANNER AD ====================

  /// Tạo Banner Ad mới
  BannerAd createBannerAd({
    required void Function(Ad) onAdLoaded,
    required void Function(Ad, LoadAdError) onAdFailedToLoad,
  }) {
    return BannerAd(
      adUnitId: AdConstants.bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: onAdLoaded,
        onAdFailedToLoad: onAdFailedToLoad,
        onAdOpened: (ad) => debugPrint('Banner ad opened'),
        onAdClosed: (ad) => debugPrint('Banner ad closed'),
      ),
    );
  }

  // ==================== REWARDED AD ====================

  /// Kiểm tra xem có thể xem rewarded ad không (anti-fraud)
  Future<Map<String, dynamic>> canShowRewardedAd() async {
    final now = DateTime.now();
    
    // Check 1: Thời gian tối thiểu giữa 2 lần xem
    if (_lastRewardedAdTime != null) {
      final diff = now.difference(_lastRewardedAdTime!).inSeconds;
      if (diff < AdConstants.minSecondsBetweenRewardedAds) {
        final waitTime = AdConstants.minSecondsBetweenRewardedAds - diff;
        return {
          'allowed': false,
          'reason': 'cooldown',
          'waitSeconds': waitTime,
          'message': 'Vui lòng đợi $waitTime giây',
        };
      }
    }
    
    // Check 2: Giới hạn số lần mỗi giờ
    final adsInLastHour = _rewardedAdHistory.where(
      (dt) => now.difference(dt).inHours < 1
    ).length;
    
    if (adsInLastHour >= AdConstants.maxRewardedAdsPerHour) {
      return {
        'allowed': false,
        'reason': 'hourly_limit',
        'message': 'Bạn đã đạt giới hạn ${AdConstants.maxRewardedAdsPerHour} lượt/giờ',
      };
    }
    
    // Check 3: Giới hạn số lần mỗi ngày
    final today = DateTime(now.year, now.month, now.day);
    final adsToday = _rewardedAdHistory.where((dt) {
      final dtDate = DateTime(dt.year, dt.month, dt.day);
      return dtDate == today;
    }).length;
    
    if (adsToday >= AdConstants.maxRewardedAdsPerDay) {
      return {
        'allowed': false,
        'reason': 'daily_limit',
        'message': 'Bạn đã đạt giới hạn ${AdConstants.maxRewardedAdsPerDay} lượt/ngày',
      };
    }
    
    // Check 4: Kiểm tra debug mode (chỉ warning, không block)
    if (kDebugMode) {
      debugPrint('⚠️ App đang chạy ở debug mode - reward sẽ không được verify trên server');
    }
    
    return {
      'allowed': true,
      'adsToday': adsToday,
      'adsThisHour': adsInLastHour,
    };
  }

  // User key để gửi trong SSV callback
  String? _pendingUserKey;

  /// Load rewarded ad với user_key cho SSV
  Future<void> loadRewardedAd({String? userKey}) async {
    if (_isRewardedAdLoading || _rewardedAd != null) return;
    
    _isRewardedAdLoading = true;
    _pendingUserKey = userKey;
    debugPrint('📺 Loading rewarded ad for user: $userKey');
    
    await RewardedAd.load(
      adUnitId: AdConstants.rewardedAdUnitId,
      request: AdRequest(
        httpTimeoutMillis: 30000,
      ),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          debugPrint('✅ Rewarded ad loaded');
          _rewardedAd = ad;
          _isRewardedAdLoading = false;
          
          // Set SSV options sau khi ad load
          if (_pendingUserKey != null) {
            _rewardedAd!.setServerSideOptions(
              ServerSideVerificationOptions(
                customData: _pendingUserKey,
              ),
            );
          }
        },
        onAdFailedToLoad: (error) {
          debugPrint('❌ Rewarded ad failed to load: ${error.message}');
          _isRewardedAdLoading = false;
        },
      ),
    );
  }

  /// Hiển thị rewarded ad
  /// Returns: Map với kết quả {success: bool, reward: int?, error: String?}
  Future<Map<String, dynamic>> showRewardedAd({
    required String userKey,
  }) async {
    // Kiểm tra anti-fraud trước
    final canShow = await canShowRewardedAd();
    if (canShow['allowed'] != true) {
      return {
        'success': false,
        'error': canShow['message'] ?? 'Không thể xem quảng cáo lúc này',
      };
    }
    
    if (_rewardedAd == null) {
      await loadRewardedAd(userKey: userKey);
      // Wait a bit for ad to load
      await Future.delayed(const Duration(seconds: 2));
      
      if (_rewardedAd == null) {
        return {
          'success': false,
          'error': 'Quảng cáo chưa sẵn sàng. Vui lòng thử lại.',
        };
      }
    }
    
    final completer = Completer<Map<String, dynamic>>();
    
    // SSV options đã được set trong loadRewardedAd
    debugPrint('📺 Showing rewarded ad with SSV for user: $userKey');
    
    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        debugPrint('📺 Rewarded ad showed');
      },
      onAdDismissedFullScreenContent: (ad) {
        debugPrint('📺 Rewarded ad dismissed');
        ad.dispose();
        _rewardedAd = null;
        // Pre-load next ad (không có userKey, sẽ set lại khi show)
        loadRewardedAd();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('❌ Rewarded ad failed to show: ${error.message}');
        ad.dispose();
        _rewardedAd = null;
        loadRewardedAd();
        
        if (!completer.isCompleted) {
          completer.complete({
            'success': false,
            'error': 'Không thể hiển thị quảng cáo: ${error.message}',
          });
        }
      },
    );
    
    await _rewardedAd!.show(
      onUserEarnedReward: (ad, reward) async {
        debugPrint('🎁 User earned reward: ${reward.amount} ${reward.type}');
        
        // Cập nhật anti-fraud tracking
        final now = DateTime.now();
        _lastRewardedAdTime = now;
        _rewardedAdHistory.add(now);
        await _saveAntifraudData();
        
        // Server sẽ verify qua SSV callback
        // Ở đây chỉ trả về success, server sẽ tự động cộng token
        if (!completer.isCompleted) {
          completer.complete({
            'success': true,
            'reward': AdConstants.rewardTokenAmount,
            'message': 'Đang xác thực phần thưởng...',
          });
        }
      },
    );
    
    return completer.future;
  }

  /// Kiểm tra xem rewarded ad đã sẵn sàng chưa
  bool get isRewardedAdReady => _rewardedAd != null;

  /// Dispose tất cả ads
  void dispose() {
    _bannerAd?.dispose();
    _rewardedAd?.dispose();
  }
}
