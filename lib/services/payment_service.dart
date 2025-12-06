import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import '../constants/api_constants.dart';
import 'auth_service.dart';

// ==================== MODELS ====================

/// Model cho gói token
class TokenPackage {
  final String id;
  final String productId; // Google Play product ID
  final String name;
  final String nameEn;
  final int tokens;
  final int price; // VND (for display)
  final double priceUSD;
  final int discount; // Percentage
  final String iconName;
  final int color;
  final bool isPopular;

  const TokenPackage({
    required this.id,
    required this.productId,
    required this.name,
    required this.nameEn,
    required this.tokens,
    required this.price,
    required this.priceUSD,
    this.discount = 0,
    required this.iconName,
    required this.color,
    this.isPopular = false,
  });

  /// Giá gốc (trước khi giảm)
  int get originalPrice {
    if (discount == 0) return price;
    return (price * 100 / (100 - discount)).round();
  }
}

/// Model cho phương thức thanh toán
class PaymentMethod {
  final String id;
  final String name;
  final String iconPath;
  final bool isEnabled;

  const PaymentMethod({
    required this.id,
    required this.name,
    required this.iconPath,
    this.isEnabled = true,
  });
}

/// Kết quả thanh toán
class PaymentResult {
  final bool success;
  final String message;
  final String? orderId;
  final int? tokensAdded;

  const PaymentResult({
    required this.success,
    required this.message,
    this.orderId,
    this.tokensAdded,
  });
}

/// Trạng thái thanh toán
enum PaymentStatus {
  pending,
  completed,
  failed,
  cancelled,
  unknown,
}

/// Kết quả kiểm tra trạng thái
class PaymentStatusResult {
  final PaymentStatus status;
  final String message;
  final int? tokensAdded;

  const PaymentStatusResult({
    required this.status,
    required this.message,
    this.tokensAdded,
  });
}

/// Lịch sử giao dịch
class TransactionHistory {
  final String orderId;
  final String packageName;
  final int tokens;
  final int amount;
  final String status;
  final DateTime createdAt;

  const TransactionHistory({
    required this.orderId,
    required this.packageName,
    required this.tokens,
    required this.amount,
    required this.status,
    required this.createdAt,
  });

  factory TransactionHistory.fromJson(Map<String, dynamic> json) {
    return TransactionHistory(
      orderId: json['order_id'] ?? '',
      packageName: json['package_name'] ?? '',
      tokens: json['tokens'] ?? 0,
      amount: json['amount'] ?? 0,
      status: json['status'] ?? '',
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
    );
  }
}

// ==================== SERVICE ====================

/// Service xử lý thanh toán In-App Purchase
/// Hỗ trợ Google Play và xác nhận server-side
class PaymentService {
  // Singleton pattern
  static final PaymentService _instance = PaymentService._internal();
  factory PaymentService() => _instance;
  PaymentService._internal();

  final AuthService _authService = AuthService();
  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  
  // Stream subscription để lắng nghe purchase updates
  StreamSubscription<List<PurchaseDetails>>? _subscription;
  
  // Callback khi thanh toán hoàn tất
  Function(PaymentResult)? onPurchaseComplete;
  
  // Trạng thái
  bool _isAvailable = false;
  bool _isInitialized = false;
  List<ProductDetails> _products = [];

  // API Gateway URL
  static String get _gatewayUrl => ApiConstants.gatewayBaseUrl;

  // Getters
  bool get isAvailable => _isAvailable;
  bool get isInitialized => _isInitialized;
  List<ProductDetails> get products => _products;

  /// Các gói token VIP có sẵn
  /// productId phải khớp với ID đã tạo trên Google Play Console
  static final List<TokenPackage> tokenPackages = [
    const TokenPackage(
      id: 'basic',
      productId: 'token_basic',
      name: 'Gói Khởi Đầu',
      nameEn: 'Starter Package',
      tokens: 2500,
      price: 12000,
      priceUSD: 0.49,
      discount: 0,
      iconName: 'star_border',
      color: 0xFF64B5F6,
    ),
    const TokenPackage(
      id: 'standard',
      productId: 'token_standard',
      name: 'Gói Tiêu Chuẩn',
      nameEn: 'Standard Package',
      tokens: 5250,
      price: 25000,
      priceUSD: 0.99,
      discount: 5,
      iconName: 'star_half',
      color: 0xFF42A5F5,
      isPopular: true,
    ),
    const TokenPackage(
      id: 'premium',
      productId: 'token_premium',
      name: 'Gói Cao Cấp',
      nameEn: 'Premium Package',
      tokens: 55000,
      price: 250000,
      priceUSD: 9.99,
      discount: 10,
      iconName: 'star',
      color: 0xFFFFD700,
    ),
    const TokenPackage(
      id: 'ultimate',
      productId: 'token_ultimate',
      name: 'Gói Đặc Biệt',
      nameEn: 'Ultimate Package',
      tokens: 312500,
      price: 1250000,
      priceUSD: 49.99,
      discount: 25,
      iconName: 'diamond',
      color: 0xFF9C27B0,
    ),
  ];

  /// Các phương thức thanh toán được hỗ trợ
  static final List<PaymentMethod> paymentMethods = [
    const PaymentMethod(
      id: 'google_play',
      name: 'Google Play',
      iconPath: 'assets/icons/google_play.png',
      isEnabled: true,
    ),
    const PaymentMethod(
      id: 'visa',
      name: 'Visa / Mastercard',
      iconPath: 'assets/icons/visa.png',
      isEnabled: true,
    ),
  ];

  /// Khởi tạo In-App Purchase
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Kiểm tra IAP có khả dụng không
    _isAvailable = await _inAppPurchase.isAvailable();
    if (!_isAvailable) {
      print('❌ In-App Purchase not available');
      return;
    }

    // Lắng nghe purchase updates
    _subscription = _inAppPurchase.purchaseStream.listen(
      _handlePurchaseUpdates,
      onDone: () => _subscription?.cancel(),
      onError: (error) => print('❌ Purchase stream error: $error'),
    );

    // Load products từ store
    await _loadProducts();

    _isInitialized = true;
    print('✅ PaymentService initialized');
  }

  /// Load danh sách products từ Google Play
  Future<void> _loadProducts() async {
    final productIds = tokenPackages.map((p) => p.productId).toSet();
    
    try {
      final response = await _inAppPurchase.queryProductDetails(productIds);
      
      if (response.notFoundIDs.isNotEmpty) {
        print('⚠️ Products not found: ${response.notFoundIDs}');
      }
      
      _products = response.productDetails;
      print('✅ Loaded ${_products.length} products');
    } catch (e) {
      print('❌ Error loading products: $e');
    }
  }

  /// Xử lý purchase updates từ stream
  Future<void> _handlePurchaseUpdates(List<PurchaseDetails> purchaseDetailsList) async {
    for (final purchaseDetails in purchaseDetailsList) {
      print('📦 Purchase update: ${purchaseDetails.productID} - ${purchaseDetails.status}');
      
      switch (purchaseDetails.status) {
        case PurchaseStatus.pending:
          print('⏳ Purchase pending...');
          break;
          
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          // Thanh toán thành công - verify với server
          final result = await _verifyAndDeliverPurchase(purchaseDetails);
          onPurchaseComplete?.call(result);
          break;
          
        case PurchaseStatus.error:
          final result = PaymentResult(
            success: false,
            message: purchaseDetails.error?.message ?? 'Thanh toán thất bại',
          );
          onPurchaseComplete?.call(result);
          break;
          
        case PurchaseStatus.canceled:
          const result = PaymentResult(
            success: false,
            message: 'Thanh toán đã bị hủy',
          );
          onPurchaseComplete?.call(result);
          break;
      }
      
      // Complete purchase để không bị charge lại
      if (purchaseDetails.pendingCompletePurchase) {
        await _inAppPurchase.completePurchase(purchaseDetails);
      }
    }
  }

  /// Verify purchase với server và cộng token
  Future<PaymentResult> _verifyAndDeliverPurchase(PurchaseDetails purchaseDetails) async {
    try {
      final token = _authService.jwtToken;
      if (token == null) {
        return const PaymentResult(
          success: false,
          message: 'Vui lòng đăng nhập để nhận token',
        );
      }

      // Lấy user_key từ auth service
      final userKey = _authService.userKey;
      if (userKey == null) {
        return const PaymentResult(
          success: false,
          message: 'Không tìm thấy thông tin người dùng',
        );
      }

      // Lấy thông tin package
      final package = tokenPackages.firstWhere(
        (p) => p.productId == purchaseDetails.productID,
        orElse: () => tokenPackages.first,
      );

      // Lấy purchase token (Android specific)
      String? purchaseToken;
      if (Platform.isAndroid) {
        final androidDetails = purchaseDetails as GooglePlayPurchaseDetails;
        purchaseToken = androidDetails.billingClientPurchase.purchaseToken;
      }

      // Gọi API verify purchase
      final response = await http.post(
        Uri.parse('$_gatewayUrl/payment/verify-purchase'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'user_key': userKey,
          'product_id': purchaseDetails.productID,
          'purchase_token': purchaseToken ?? purchaseDetails.purchaseID,
          'order_id': purchaseDetails.purchaseID ?? 'unknown',
          'package_name': 'com.example.demo_tryon_app',
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // Refresh user data để cập nhật token mới
        await _authService.refreshTokenFromServer();
        
        return PaymentResult(
          success: true,
          message: data['message'] ?? 'Thanh toán thành công!',
          orderId: purchaseDetails.purchaseID,
          tokensAdded: data['tokens_added'] ?? package.tokens,
        );
      } else {
        final data = jsonDecode(response.body);
        return PaymentResult(
          success: false,
          message: data['detail'] ?? 'Xác thực thanh toán thất bại',
        );
      }
    } catch (e) {
      print('❌ Error verifying purchase: $e');
      return const PaymentResult(
        success: false,
        message: 'Lỗi kết nối. Vui lòng thử lại.',
      );
    }
  }

  /// Bắt đầu mua gói token
  Future<bool> purchasePackage(String packageId) async {
    if (!_isAvailable) {
      print('❌ IAP not available');
      return false;
    }

    // Tìm package
    final package = tokenPackages.firstWhere(
      (p) => p.id == packageId,
      orElse: () => tokenPackages.first,
    );

    // Tìm product details từ store
    ProductDetails? productDetails;
    try {
      productDetails = _products.firstWhere(
        (p) => p.id == package.productId,
      );
    } catch (e) {
      print('❌ Product not found in store: ${package.productId}');
      return false;
    }

    // Tạo purchase param
    final purchaseParam = PurchaseParam(productDetails: productDetails);

    try {
      // Bắt đầu purchase flow (consumable = true vì token có thể mua nhiều lần)
      final success = await _inAppPurchase.buyConsumable(
        purchaseParam: purchaseParam,
      );
      
      print('🛒 Purchase initiated: $success');
      return success;
    } catch (e) {
      print('❌ Error starting purchase: $e');
      return false;
    }
  }

  /// Khôi phục purchases
  Future<void> restorePurchases() async {
    if (!_isAvailable) return;
    await _inAppPurchase.restorePurchases();
  }

  /// Lấy giá hiển thị từ store (nếu có)
  String? getStorePrice(String packageId) {
    final package = tokenPackages.firstWhere(
      (p) => p.id == packageId,
      orElse: () => tokenPackages.first,
    );

    try {
      final product = _products.firstWhere(
        (p) => p.id == package.productId,
      );
      return product.price;
    } catch (e) {
      return null;
    }
  }

  /// Format giá tiền VND (fallback)
  static String formatVND(int amount) {
    final formatted = amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
    return '${formatted}đ';
  }

  /// Format giá tiền USD
  static String formatUSD(double amount) {
    return '\$${amount.toStringAsFixed(2)}';
  }

  /// Giải phóng resources
  void dispose() {
    _subscription?.cancel();
    _isInitialized = false;
  }
}
