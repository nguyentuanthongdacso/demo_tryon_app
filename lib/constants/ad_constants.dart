/// AdMob Configuration Constants
/// 
/// Ad Unit IDs từ Google AdMob Console
/// App ID: ca-app-pub-7370568836524098
/// 
/// Lưu ý: 
/// - Test trên emulator sẽ tự động dùng test ads
/// - Production chỉ hoạt động trên device thật với signed APK
library;

class AdConstants {
  // ===== TEST MODE =====
  /// Đặt true để dùng Test IDs và client-side reward (không cần SSV)
  /// Đặt false để dùng Production IDs và SSV callback
  static const bool isTestMode = true;
  
  // ===== APP ID =====
  /// Test App ID từ Google - dùng cho testing
  static const String testAppId = 'ca-app-pub-3940256099942544~3347511713';
  static const String prodAppId = 'ca-app-pub-7370568836524098~6292853283';
  static String get appId => isTestMode ? testAppId : prodAppId;
  
  // ===== AD UNIT IDs =====
  // Test IDs
  static const String testBannerAdUnitId = 'ca-app-pub-3940256099942544/6300978111';
  static const String testAppOpenAdUnitId = 'ca-app-pub-3940256099942544/3419835294';
  static const String testRewardedAdUnitId = 'ca-app-pub-3940256099942544/5224354917';
  static const String testInterstitialAdUnitId = 'ca-app-pub-3940256099942544/1033173712';
  static const String testNativeAdUnitId = 'ca-app-pub-3940256099942544/2247696110';
  
  // Production IDs
  static const String prodBannerAdUnitId = 'ca-app-pub-7370568836524098/7661775273';
  static const String prodAppOpenAdUnitId = 'ca-app-pub-7370568836524098/2078383906';
  static const String prodRewardedAdUnitId = 'ca-app-pub-7370568836524098/5753905031';
  
  // Getters - tự động chọn dựa theo mode
  static String get bannerAdUnitId => isTestMode ? testBannerAdUnitId : prodBannerAdUnitId;
  static String get appOpenAdUnitId => isTestMode ? testAppOpenAdUnitId : prodAppOpenAdUnitId;
  static String get rewardedAdUnitId => isTestMode ? testRewardedAdUnitId : prodRewardedAdUnitId;
  static String get interstitialAdUnitId => testInterstitialAdUnitId; // Chỉ có test
  static String get nativeAdUnitId => testNativeAdUnitId; // Chỉ có test
  
  // ===== REWARD CONFIG =====
  /// Số token thưởng khi xem video
  static const int rewardTokenAmount = 25;
  
  // ===== ANTI-FRAUD CLIENT-SIDE LIMITS =====
  /// Thời gian tối thiểu giữa 2 lần xem rewarded ad (giây)
  static const int minSecondsBetweenRewardedAds = 30;
  
  /// Số lần xem rewarded ad tối đa mỗi giờ
  static const int maxRewardedAdsPerHour = 10;
  
  /// Số lần xem rewarded ad tối đa mỗi ngày
  static const int maxRewardedAdsPerDay = 100;
  
  // ===== SSV (Server-Side Verification) =====
  /// URL endpoint để verify rewarded ad callback từ Google
  static const String ssvCallbackUrl = 'https://gateway.tryonstylist.com/admob-ssv';
}
