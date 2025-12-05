import 'package:flutter/material.dart';

/// ============================================================
/// APP STYLES - Tập trung tất cả styles cho toàn bộ ứng dụng
/// ============================================================
/// Sử dụng: import '../utils/app_styles.dart';
/// Ví dụ: AppStyles.titleLarge, AppStyles.cardDecoration, etc.
/// ============================================================

class AppStyles {
  AppStyles._(); // Private constructor - không cho phép tạo instance

  // ==================== COLORS ====================
  
  /// Primary colors
  static const Color primaryBlue = Colors.blue;
  static const Color primaryGreen = Colors.green;
  static const Color primaryOrange = Colors.orange;
  static const Color primaryRed = Colors.red;
  
  /// Text colors
  static const Color textPrimary = Colors.black87;
  static const Color textSecondary = Colors.black54;
  static const Color textWhite = Colors.white;
  static const Color textGrey = Colors.grey;
  static Color textGreyDark = Colors.grey.shade600;
  static Color textGreyLight = Colors.grey.shade400;
  
  /// Background colors
  static Color backgroundGrey = Colors.grey.shade100;
  static Color backgroundGreyLight = Colors.grey.shade200;
  static Color backgroundGreyMedium = Colors.grey.shade300;
  static Color backgroundWhiteTranslucent = Colors.white.withValues(alpha: 0.9);
  static Color backgroundWhiteTranslucent30 = Colors.white.withValues(alpha: 0.3);
  static Color backgroundBlackTranslucent = Colors.black.withValues(alpha: 0.5);
  static Color backgroundBlackTranslucent70 = Colors.black.withValues(alpha: 0.7);
  
  /// Status colors
  static Color errorBackground = Colors.red.shade100;
  static Color errorBorder = Colors.red.shade300;
  static Color errorText = Colors.red.shade700;
  static Color successBackground = Colors.green.shade50;
  static Color successBorder = Colors.green.shade300;
  static Color successText = Colors.green.shade700;
  static Color successDark = Colors.green.shade700;
  static Color warningBackground = Colors.orange.shade50;
  static Color warningBorder = Colors.orange.shade300;
  static Color warningText = Colors.orange.shade700;
  
  /// Icon colors
  static Color iconRed = Colors.red.shade400;
  static Color iconOrange = Colors.orange.shade600;
  static Color iconGreen = Colors.green;
  static Color iconBlue = Colors.blue;
  static Color iconGrey = Colors.grey;

  // ==================== SPACING ====================
  
  static const double spacingXS = 4.0;
  static const double spacingSM = 8.0;
  static const double spacingMD = 12.0;
  static const double spacingLG = 16.0;
  static const double spacingXL = 20.0;
  static const double spacingXXL = 24.0;
  static const double spacingXXXL = 32.0;

  // ==================== BORDER RADIUS ====================
  
  static const double radiusSM = 4.0;
  static const double radiusMD = 8.0;
  static const double radiusLG = 12.0;
  static const double radiusXL = 16.0;
  static const double radiusXXL = 20.0;
  static const double radiusCircle = 100.0;

  static BorderRadius borderRadiusXS = BorderRadius.circular(radiusSM);
  static BorderRadius borderRadiusSM = BorderRadius.circular(radiusSM);
  static BorderRadius borderRadiusMD = BorderRadius.circular(radiusMD);
  static BorderRadius borderRadiusLG = BorderRadius.circular(radiusLG);
  static BorderRadius borderRadiusXL = BorderRadius.circular(radiusXL);
  static BorderRadius borderRadiusXXL = BorderRadius.circular(radiusXXL);

  // ==================== TEXT STYLES ====================
  
  /// App Title - 36px bold
  static const TextStyle appTitle = TextStyle(
    fontSize: 36,
    fontWeight: FontWeight.bold,
    color: Colors.black,
    letterSpacing: 1.2,
  );
  
  /// Title Large - 18px bold
  static const TextStyle titleLarge = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
  );
  
  /// Title Medium - 16px semibold
  static const TextStyle titleMedium = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
  );
  
  /// Title Small - 14px bold
  static const TextStyle titleSmall = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.bold,
  );
  
  /// Body Large - 16px normal
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
  );
  
  /// Body Medium - 14px normal
  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
  );
  
  /// Body Small - 12px normal
  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
  );
  
  /// Caption - 10px
  static const TextStyle caption = TextStyle(
    fontSize: 10,
  );
  
  /// Button text - 16px bold white
  static const TextStyle buttonText = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: Colors.white,
  );
  
  /// Button text large - 18px bold white
  static const TextStyle buttonTextLarge = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: Colors.white,
  );
  
  /// Label text - 14px bold
  static const TextStyle labelText = TextStyle(
    fontWeight: FontWeight.bold,
    fontSize: 14,
  );
  
  /// Slogan text - 16px italic
  static TextStyle sloganText = TextStyle(
    fontSize: 16,
    color: Colors.black.withValues(alpha: 0.7),
    fontStyle: FontStyle.italic,
  );
  
  /// Header name - 20px bold
  static const TextStyle headerName = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: Colors.black87,
  );
  
  /// Menu item - 16px normal
  static const TextStyle menuItemText = TextStyle(
    fontSize: 16,
    color: Colors.black87,
  );
  
  /// Subtitle - 12px grey
  static TextStyle subtitleText = TextStyle(
    fontSize: 12,
    color: Colors.grey.shade600,
  );
  
  /// Token count text - 12px bold
  static const TextStyle tokenCountText = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.bold,
    color: Colors.black87,
  );
  
  /// Dialog title - 18px
  static const TextStyle dialogTitle = TextStyle(
    fontSize: 18,
  );
  
  /// Dialog content - 14px
  static const TextStyle dialogContent = TextStyle(
    fontSize: 14,
  );
  
  /// Terms text - 12px
  static TextStyle termsText = TextStyle(
    fontSize: 12,
    color: Colors.black.withValues(alpha: 0.7),
  );
  
  /// Error text - 14px red
  static TextStyle errorTextStyle = TextStyle(
    color: Colors.red.shade700,
    fontSize: 14,
  );
  
  /// Success text - 14px green
  static TextStyle successTextStyle = TextStyle(
    color: Colors.green.shade700,
    fontSize: 14,
  );
  
  /// Success title style - bold green
  static TextStyle successTitleStyle = TextStyle(
    fontWeight: FontWeight.bold,
    color: Colors.green.shade700,
  );
  
  /// Success subtitle style - 12px green
  static TextStyle successSubtitleStyle = TextStyle(
    fontSize: 12,
    color: Colors.green.shade600,
  );
  
  /// Button text white - plain white text
  static const TextStyle buttonTextStyleWhite = TextStyle(
    color: Colors.white,
  );
  
  /// Processing text - 12px grey
  static const TextStyle processingText = TextStyle(
    color: Colors.grey,
    fontSize: 12,
  );
  
  /// Uploaded badge text - 10px white
  static const TextStyle uploadedBadgeText = TextStyle(
    fontSize: 10,
    color: Colors.white,
  );

  // ==================== BOX DECORATIONS ====================
  
  /// Card decoration - white with rounded corners
  static BoxDecoration cardDecoration = BoxDecoration(
    color: Colors.white.withValues(alpha: 0.9),
    borderRadius: borderRadiusLG,
  );
  
  /// Card decoration solid - white without transparency
  static BoxDecoration cardDecorationSolid = BoxDecoration(
    color: Colors.white,
    borderRadius: borderRadiusXL,
  );
  
  /// Card with shadow
  static BoxDecoration cardWithShadow = BoxDecoration(
    color: Colors.white,
    borderRadius: borderRadiusLG,
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.1),
        blurRadius: 8,
        offset: const Offset(0, 2),
      ),
    ],
  );
  
  /// Container with border
  static BoxDecoration containerWithBorder = BoxDecoration(
    color: Colors.white.withValues(alpha: 0.9),
    borderRadius: borderRadiusLG,
    border: Border.all(color: Colors.grey.shade300),
  );
  
  /// Image container decoration
  static BoxDecoration imageContainerDecoration = BoxDecoration(
    borderRadius: borderRadiusMD,
  );
  
  /// Image container with shadow
  static BoxDecoration imageContainerWithShadow = BoxDecoration(
    borderRadius: borderRadiusLG,
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.1),
        blurRadius: 8,
        offset: const Offset(0, 2),
      ),
    ],
  );
  
  /// Placeholder container - grey background
  static BoxDecoration placeholderDecoration = BoxDecoration(
    color: Colors.grey.shade200,
    borderRadius: borderRadiusMD,
  );
  
  /// Selected item decoration
  static BoxDecoration selectedItemDecoration = BoxDecoration(
    border: Border.all(color: Colors.blue, width: 3),
    borderRadius: borderRadiusMD,
    color: Colors.blue.shade50,
  );
  
  /// Unselected item decoration
  static BoxDecoration unselectedItemDecoration = BoxDecoration(
    border: Border.all(color: Colors.grey.shade300, width: 1),
    borderRadius: borderRadiusMD,
    color: Colors.transparent,
  );
  
  /// Error container decoration
  static BoxDecoration errorContainerDecoration = BoxDecoration(
    color: Colors.red.shade100,
    borderRadius: borderRadiusMD,
    border: Border.all(color: Colors.red.shade300),
  );
  
  /// Success container decoration
  static BoxDecoration successContainerDecoration = BoxDecoration(
    color: Colors.green.shade50,
    borderRadius: borderRadiusMD,
    border: Border.all(color: Colors.green.shade300),
  );
  
  /// Warning container decoration
  static BoxDecoration warningContainerDecoration = BoxDecoration(
    color: Colors.orange.shade50,
    borderRadius: borderRadiusLG,
  );
  
  /// Uploaded badge decoration
  static BoxDecoration uploadedBadgeDecoration = BoxDecoration(
    color: Colors.green,
    borderRadius: borderRadiusSM,
  );
  
  /// Check badge decoration (circle)
  static const BoxDecoration checkBadgeDecoration = BoxDecoration(
    color: Colors.blue,
    shape: BoxShape.circle,
  );
  
  /// Bottom sheet decoration with top border and shadow
  static BoxDecoration bottomSheetDecoration = BoxDecoration(
    color: Colors.white,
    border: Border(
      top: BorderSide(color: Colors.grey.shade300),
    ),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.1),
        blurRadius: 8,
        offset: const Offset(0, -2),
      ),
    ],
  );
  
  /// Circle icon container decoration
  static BoxDecoration circleIconDecoration = BoxDecoration(
    color: Colors.white.withValues(alpha: 0.3),
    shape: BoxShape.circle,
  );
  
  /// Circle icon container solid
  static BoxDecoration circleIconDecorationSolid = BoxDecoration(
    color: Colors.white.withValues(alpha: 0.95),
    shape: BoxShape.circle,
  );
  
  /// Upload overlay decoration
  static BoxDecoration uploadOverlayDecoration = BoxDecoration(
    color: Colors.black.withAlpha(128),
    borderRadius: borderRadiusMD,
  );
  
  /// Bottom bar decoration with shadow
  static BoxDecoration bottomBarDecoration = BoxDecoration(
    color: Colors.white,
    border: Border(
      top: BorderSide(color: Colors.grey.shade300),
    ),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.1),
        blurRadius: 8,
        offset: const Offset(0, -2),
      ),
    ],
  );
  
  /// Gradient overlay for images
  static BoxDecoration gradientOverlayDecoration = BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Colors.transparent,
        Colors.black.withValues(alpha: 0.7),
      ],
    ),
  );
  
  /// Get token button gradient
  static BoxDecoration getTokenButtonDecoration = BoxDecoration(
    borderRadius: borderRadiusXL,
    image: const DecorationImage(
      image: AssetImage('assets/backgrounds/bg_get_token.jpg'),
      fit: BoxFit.cover,
    ),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.15),
        blurRadius: 10,
        offset: const Offset(0, 4),
      ),
    ],
  );

  // ==================== BUTTON STYLES ====================
  
  /// Primary button style - Blue
  static ButtonStyle primaryButtonStyle = ElevatedButton.styleFrom(
    padding: const EdgeInsets.symmetric(vertical: 16),
    backgroundColor: Colors.blue,
    disabledBackgroundColor: Colors.grey.shade300,
    shape: RoundedRectangleBorder(
      borderRadius: borderRadiusMD,
    ),
  );
  
  /// Primary button style with large radius
  static ButtonStyle primaryButtonStyleLarge = ElevatedButton.styleFrom(
    padding: const EdgeInsets.symmetric(vertical: 16),
    backgroundColor: Colors.blue,
    foregroundColor: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: borderRadiusLG,
    ),
  );
  
  /// Success button style - Green
  static ButtonStyle successButtonStyle = ElevatedButton.styleFrom(
    padding: const EdgeInsets.symmetric(vertical: 12),
    backgroundColor: Colors.green,
    shape: RoundedRectangleBorder(
      borderRadius: borderRadiusMD,
    ),
  );
  
  /// Warning button style - Orange
  static ButtonStyle warningButtonStyle = ElevatedButton.styleFrom(
    padding: const EdgeInsets.symmetric(vertical: 12),
    backgroundColor: Colors.orange,
    shape: RoundedRectangleBorder(
      borderRadius: borderRadiusMD,
    ),
  );
  
  /// Submit button style - Orange (alias for warningButtonStyle)
  static ButtonStyle submitButtonStyleOrange = ElevatedButton.styleFrom(
    padding: const EdgeInsets.symmetric(vertical: 12),
    backgroundColor: Colors.orange,
    shape: RoundedRectangleBorder(
      borderRadius: borderRadiusMD,
    ),
  );
  
  /// Submit button style - Green
  static ButtonStyle submitButtonStyleGreen = ElevatedButton.styleFrom(
    padding: const EdgeInsets.symmetric(vertical: 12),
    backgroundColor: Colors.green,
    shape: RoundedRectangleBorder(
      borderRadius: borderRadiusMD,
    ),
  );
  
  /// Danger button style - Red
  static ButtonStyle dangerButtonStyle = ElevatedButton.styleFrom(
    padding: const EdgeInsets.symmetric(vertical: 16),
    backgroundColor: Colors.red.shade400,
    shape: RoundedRectangleBorder(
      borderRadius: borderRadiusLG,
    ),
  );
  
  /// Search button style
  static ButtonStyle searchButtonStyle = ElevatedButton.styleFrom(
    padding: const EdgeInsets.symmetric(vertical: 12),
    shape: RoundedRectangleBorder(
      borderRadius: borderRadiusMD,
    ),
  );

  // ==================== INPUT DECORATIONS ====================
  
  /// Standard text field decoration
  static InputDecoration textFieldDecoration({
    required String hintText,
    required String labelText,
    IconData? prefixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      labelText: labelText,
      prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
      border: OutlineInputBorder(
        borderRadius: borderRadiusMD,
      ),
      filled: true,
      fillColor: Colors.grey.shade100,
    );
  }
  
  /// Dropdown decoration
  static InputDecoration dropdownDecoration({
    required String labelText,
  }) {
    return InputDecoration(
      labelText: labelText,
      border: const OutlineInputBorder(),
    );
  }
  
  /// Multiline text field decoration
  static InputDecoration multilineTextFieldDecoration({
    required String hintText,
  }) {
    return InputDecoration(
      hintText: hintText,
      border: OutlineInputBorder(
        borderRadius: borderRadiusMD,
      ),
      contentPadding: const EdgeInsets.all(12),
    );
  }
  
  /// Dropdown form field decoration
  static InputDecoration dropdownFormFieldDecoration = InputDecoration(
    border: OutlineInputBorder(
      borderRadius: borderRadiusMD,
    ),
    contentPadding: const EdgeInsets.symmetric(
      horizontal: 12,
      vertical: 12,
    ),
  );

  // ==================== PADDING ====================
  
  static const EdgeInsets paddingAll4 = EdgeInsets.all(4);
  static const EdgeInsets paddingAll8 = EdgeInsets.all(8);
  static const EdgeInsets paddingAll12 = EdgeInsets.all(12);
  static const EdgeInsets paddingAll16 = EdgeInsets.all(16);
  static const EdgeInsets paddingAll20 = EdgeInsets.all(20);
  static const EdgeInsets paddingAll24 = EdgeInsets.all(24);
  
  // Alias with SM, MD, LG names for consistency
  static const EdgeInsets paddingAllSM = paddingAll8;
  static const EdgeInsets paddingAllMD = paddingAll12;
  static const EdgeInsets paddingAllLG = paddingAll16;
  static const EdgeInsets paddingAllXL = paddingAll20;
  
  static const EdgeInsets paddingHorizontal12 = EdgeInsets.symmetric(horizontal: 12);
  static const EdgeInsets paddingHorizontal16 = EdgeInsets.symmetric(horizontal: 16);
  static const EdgeInsets paddingHorizontal32 = EdgeInsets.symmetric(horizontal: 32);
  
  static const EdgeInsets paddingVertical12 = EdgeInsets.symmetric(vertical: 12);
  static const EdgeInsets paddingVertical16 = EdgeInsets.symmetric(vertical: 16);
  
  static const EdgeInsets paddingSymmetric12x12 = EdgeInsets.symmetric(horizontal: 12, vertical: 12);
  static const EdgeInsets paddingSymmetric6x2 = EdgeInsets.symmetric(horizontal: 6, vertical: 2);
  static const EdgeInsets paddingSymmetric12x6 = EdgeInsets.symmetric(horizontal: 12, vertical: 6);
  static const EdgeInsets paddingSymmetric14 = EdgeInsets.symmetric(horizontal: 14);

  // ==================== SIZES ====================
  
  /// Icon sizes
  static const double iconSizeXS = 12.0;
  static const double iconSizeSM = 16.0;
  static const double iconSizeMD = 20.0;
  static const double iconSizeLG = 24.0;
  static const double iconSizeXL = 28.0;
  static const double iconSizeXXL = 32.0;
  static const double iconSizeXXXL = 40.0;
  static const double iconSizeHuge = 48.0;
  static const double iconSizeGiant = 60.0;
  static const double iconSizeMassive = 80.0;
  
  /// Avatar sizes
  static const double avatarSizeSM = 28.0;
  static const double avatarSizeMD = 40.0;
  static const double avatarSizeLG = 56.0;
  
  /// Coin icon size
  static const double coinIconSize = 20.0;
  static const double coinIconSizeLG = 24.0;
  
  /// Progress indicator sizes
  static const double progressSizeSM = 20.0;
  static const double progressSizeMD = 24.0;
  
  /// Button height
  static const double buttonHeight = 70.0;

  // ==================== ASPECT RATIOS ====================
  
  static const double aspectRatioModel = 9 / 21;
  static const double aspectRatioSquare = 1.0;
  static const double aspectRatioCard = 0.75;

  // ==================== SHADOWS ====================
  
  static List<BoxShadow> shadowLight = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.1),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];
  
  static List<BoxShadow> shadowMedium = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.15),
      blurRadius: 10,
      offset: const Offset(0, 4),
    ),
  ];
  
  static final List<Shadow> textShadow = const [
    Shadow(
      color: Colors.black45,
      blurRadius: 4.0,
      offset: Offset(2.0, 2.0), // Cần định nghĩa offset để thấy hiệu ứng bóng đổ
    ),
  ];

  // ==================== DURATIONS ====================
  
  static const Duration snackBarDurationShort = Duration(seconds: 2);
  static const Duration snackBarDurationMedium = Duration(seconds: 3);
  static const Duration snackBarDurationLong = Duration(seconds: 4);

  // ==================== HELPER METHODS ====================
  
  /// Get text style with custom color
  static TextStyle titleLargeWithColor(Color color) {
    return titleLarge.copyWith(color: color);
  }
  
  /// Get text style with custom color
  static TextStyle bodyMediumWithColor(Color color) {
    return bodyMedium.copyWith(color: color);
  }
  
  /// Get text style with custom color
  static TextStyle bodySmallWithColor(Color color) {
    return bodySmall.copyWith(color: color);
  }
  
  /// Get card decoration with custom color
  static BoxDecoration cardDecorationWithColor(Color color) {
    return BoxDecoration(
      color: color,
      borderRadius: borderRadiusLG,
    );
  }
  
  /// Get border with custom color and width
  static BoxDecoration borderDecoration({
    required Color color,
    double width = 1,
    double radius = radiusMD,
  }) {
    return BoxDecoration(
      border: Border.all(color: color, width: width),
      borderRadius: BorderRadius.circular(radius),
    );
  }
}
