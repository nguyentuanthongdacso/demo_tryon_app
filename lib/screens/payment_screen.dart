import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/payment_service.dart';
import '../services/auth_service.dart';
import '../providers/theme_provider.dart';
import '../utils/app_styles.dart';
import '../l10n/app_localizations.dart';

/// Màn hình thanh toán để mua token VIP
class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final PaymentService _paymentService = PaymentService();
  final AuthService _authService = AuthService();
  
  String? _selectedPackageId;
  String? _selectedPaymentMethodId;
  bool _isProcessing = false;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializePayment();
    // Chọn gói popular mặc định
    _selectedPackageId = PaymentService.tokenPackages
        .firstWhere((p) => p.isPopular, orElse: () => PaymentService.tokenPackages.first)
        .id;
  }

  Future<void> _initializePayment() async {
    await _paymentService.initialize();
    
    // Lắng nghe kết quả thanh toán
    _paymentService.onPurchaseComplete = (result) {
      if (!mounted) return;
      
      setState(() {
        _isProcessing = false;
      });
      
      if (result.success) {
        _showSuccessDialog(result);
      } else {
        _showErrorSnackBar(result.message);
      }
    };
    
    if (mounted) {
      setState(() {
        _isInitialized = true;
      });
    }
  }

  @override
  void dispose() {
    _paymentService.onPurchaseComplete = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final user = _authService.currentUser;
    final tokenFree = user?['token_free'] ?? 0;
    final tokenVip = user?['token_vip'] ?? 0;
    final isVietnamese = loc.locale.languageCode == 'vi';

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppStyles.backgroundWhiteTranslucent,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.arrow_back, color: Colors.black),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          loc.translate('upgrade_account'),
          style: AppStyles.titleLarge.copyWith(color: Colors.black),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // Background
          Positioned.fill(
            child: Image.asset(
              themeProvider.mainBackground,
              fit: BoxFit.cover,
            ),
          ),
          // Content
          SafeArea(
            child: SingleChildScrollView(
              padding: AppStyles.paddingAll16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Current token balance
                  _buildTokenBalance(loc, tokenFree, tokenVip),
                  SizedBox(height: AppStyles.spacingXXL),

                  // Token packages
                  Text(
                    loc.translate('select_package'),
                    style: AppStyles.titleLarge.copyWith(
                      color: Colors.black87,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          color: Colors.white.withValues(alpha: 0.8),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: AppStyles.spacingMD),
                  _buildPackageList(isVietnamese),
                  SizedBox(height: AppStyles.spacingXXL),

                  // Payment methods
                  Text(
                    loc.translate('payment_method'),
                    style: AppStyles.titleLarge.copyWith(
                      color: Colors.black87,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          color: Colors.white.withValues(alpha: 0.8),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: AppStyles.spacingMD),
                  _buildPaymentMethods(loc),
                  SizedBox(height: AppStyles.spacingXXL),

                  // Pay button
                  _buildPayButton(loc),
                  SizedBox(height: AppStyles.spacingMD),

                  // Note
                  _buildNote(loc),
                ],
              ),
            ),
          ),
          // Loading overlay
          if (_isProcessing)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTokenBalance(AppLocalizations loc, int tokenFree, int tokenVip) {
    return Container(
      padding: AppStyles.paddingAll16,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.blue.shade400,
            Colors.purple.shade400,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: AppStyles.borderRadiusLG,
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            loc.translate('your_balance'),
            style: AppStyles.bodyMedium.copyWith(
              color: Colors.white70,
            ),
          ),
          SizedBox(height: AppStyles.spacingSM),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Token Free
              Column(
                children: [
                  Row(
                    children: [
                      Image.asset(
                        'assets/icons/coin_free.png',
                        width: 24,
                        height: 24,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$tokenFree',
                        style: AppStyles.displaySmall.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    'Token Free',
                    style: AppStyles.bodySmall.copyWith(color: Colors.white70),
                  ),
                ],
              ),
              Container(
                height: 40,
                width: 1,
                color: Colors.white30,
                margin: const EdgeInsets.symmetric(horizontal: 24),
              ),
              // Token VIP
              Column(
                children: [
                  Row(
                    children: [
                      Image.asset(
                        'assets/icons/coin_vip.png',
                        width: 24,
                        height: 24,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$tokenVip',
                        style: AppStyles.displaySmall.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    'Token VIP',
                    style: AppStyles.bodySmall.copyWith(color: Colors.white70),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPackageList(bool isVietnamese) {
    return Column(
      children: PaymentService.tokenPackages.map((package) {
        final isSelected = _selectedPackageId == package.id;
        final packageColor = Color(package.color);
        
        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedPackageId = package.id;
            });
          },
          child: Container(
            margin: EdgeInsets.only(bottom: AppStyles.spacingMD),
            padding: AppStyles.paddingAll16,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.95),
              borderRadius: AppStyles.borderRadiusLG,
              border: Border.all(
                color: isSelected ? packageColor : Colors.grey.shade300,
                width: isSelected ? 3 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: isSelected 
                      ? packageColor.withValues(alpha: 0.4)
                      : Colors.black.withValues(alpha: 0.08),
                  blurRadius: isSelected ? 12 : 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                // Icon
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: packageColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getPackageIcon(package.iconName),
                    color: packageColor,
                    size: 28,
                  ),
                ),
                SizedBox(width: AppStyles.spacingMD),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isVietnamese ? package.name : package.nameEn,
                        style: AppStyles.titleMedium.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Row(
                        children: [
                          if (package.isPopular) ...[
                            Container(
                              margin: const EdgeInsets.only(top: 4, right: 8),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Text(
                                'HOT',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                          if (package.id == 'ultimate') ...[
                            Container(
                              margin: const EdgeInsets.only(top: 4),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Colors.purple, Colors.deepPurple],
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Text(
                                'BEST VALUE',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${package.tokens} Token VIP',
                        style: AppStyles.bodyMedium.copyWith(
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                // Price
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (package.discount > 0)
                      Text(
                        PaymentService.formatVND(package.originalPrice),
                        style: AppStyles.bodySmall.copyWith(
                          decoration: TextDecoration.lineThrough,
                          color: AppStyles.textGrey,
                        ),
                      ),
                    Text(
                      PaymentService.formatVND(package.price),
                      style: AppStyles.titleMedium.copyWith(
                        color: packageColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (package.discount > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '-${package.discount}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                // Radio
                SizedBox(width: AppStyles.spacingSM),
                Icon(
                  isSelected 
                      ? Icons.radio_button_checked 
                      : Icons.radio_button_unchecked,
                  color: isSelected ? packageColor : AppStyles.textGrey,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPaymentMethods(AppLocalizations loc) {
    final enabledMethods = PaymentService.paymentMethods
        .where((m) => m.isEnabled)
        .toList();

    return Wrap(
      spacing: AppStyles.spacingMD,
      runSpacing: AppStyles.spacingMD,
      children: enabledMethods.map((method) {
        final isSelected = _selectedPaymentMethodId == method.id;
        
        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedPaymentMethodId = method.id;
            });
          },
          child: Container(
            width: (MediaQuery.of(context).size.width - 48) / 2,
            padding: AppStyles.paddingAll12,
            decoration: BoxDecoration(
              color: isSelected 
                  ? Colors.blue.withValues(alpha: 0.1)
                  : AppStyles.backgroundWhiteTranslucent,
              borderRadius: AppStyles.borderRadiusMD,
              border: Border.all(
                color: isSelected ? Colors.blue : Colors.grey.shade300,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                // Icon placeholder (có thể thay bằng image nếu có)
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _getPaymentMethodColor(method.id),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getPaymentMethodIcon(method.id),
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                SizedBox(width: AppStyles.spacingSM),
                Expanded(
                  child: Text(
                    method.name,
                    style: AppStyles.bodyMedium.copyWith(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
                if (isSelected)
                  const Icon(Icons.check_circle, color: Colors.blue, size: 20),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPayButton(AppLocalizations loc) {
    final selectedPackage = PaymentService.tokenPackages
        .firstWhere((p) => p.id == _selectedPackageId, 
                   orElse: () => PaymentService.tokenPackages.first);

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _selectedPaymentMethodId == null ? null : _processPayment,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          disabledBackgroundColor: Colors.grey.shade300,
          shape: RoundedRectangleBorder(
            borderRadius: AppStyles.borderRadiusLG,
          ),
          elevation: 4,
        ),
        child: Text(
          _selectedPaymentMethodId == null
              ? loc.translate('select_payment_method')
              : '${loc.translate('pay_now')} - ${PaymentService.formatVND(selectedPackage.price)}',
          style: AppStyles.buttonText.copyWith(
            color: _selectedPaymentMethodId == null 
                ? Colors.grey 
                : Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildNote(AppLocalizations loc) {
    return Container(
      padding: AppStyles.paddingAll12,
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: AppStyles.borderRadiusMD,
        border: Border.all(color: Colors.amber.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.amber.shade700, size: 20),
          SizedBox(width: AppStyles.spacingSM),
          Expanded(
            child: Text(
              loc.translate('payment_note'),
              style: AppStyles.bodySmall.copyWith(
                color: Colors.amber.shade900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getPackageIcon(String iconName) {
    switch (iconName) {
      case 'star_border':
        return Icons.star_border;
      case 'star_half':
        return Icons.star_half;
      case 'star':
        return Icons.star;
      case 'diamond':
        return Icons.diamond;
      default:
        return Icons.star;
    }
  }

  IconData _getPaymentMethodIcon(String methodId) {
    switch (methodId) {
      case 'google_play':
        return Icons.play_arrow;
      case 'visa':
        return Icons.credit_card;
      default:
        return Icons.payment;
    }
  }

  Color _getPaymentMethodColor(String methodId) {
    switch (methodId) {
      case 'google_play':
        return const Color(0xFF34A853); // Google green
      case 'visa':
        return const Color(0xFF1A1F71); // Visa blue
      default:
        return Colors.grey;
    }
  }

  Future<void> _processPayment() async {
    if (_selectedPackageId == null || _selectedPaymentMethodId == null) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      // Kiểm tra IAP có sẵn không
      if (!_paymentService.isAvailable) {
        _showErrorSnackBar('Dịch vụ thanh toán không khả dụng');
        setState(() => _isProcessing = false);
        return;
      }

      // Bắt đầu purchase flow
      final success = await _paymentService.purchasePackage(_selectedPackageId!);
      
      if (!success) {
        if (!mounted) return;
        _showErrorSnackBar('Không thể bắt đầu thanh toán. Vui lòng thử lại.');
        setState(() => _isProcessing = false);
      }
      // Nếu success, đợi callback từ onPurchaseComplete
    } catch (e) {
      if (!mounted) return;
      _showErrorSnackBar('Đã xảy ra lỗi. Vui lòng thử lại.');
      setState(() => _isProcessing = false);
    }
  }

  void _showSuccessDialog(PaymentResult result) {
    final loc = AppLocalizations.of(context);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 28),
            const SizedBox(width: 8),
            Text(loc.translate('payment_success')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.diamond, color: Colors.purple, size: 60),
            const SizedBox(height: 16),
            Text(
              '+${result.tokensAdded ?? 0} Token VIP',
              style: AppStyles.titleLarge.copyWith(
                color: Colors.purple,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              result.message,
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Refresh để cập nhật token mới
              setState(() {});
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
            ),
            child: Text(loc.translate('ok')),
          ),
        ],
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
}
