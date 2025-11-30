import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/tryon_provider.dart';
import '../services/auth_service.dart';
import 'tryon_result_screen.dart';

class TryOnScreen extends StatefulWidget {
  final String? imageUrl;

  const TryOnScreen({super.key, this.imageUrl});

  @override
  State<TryOnScreen> createState() => _TryOnScreenState();
}

class _TryOnScreenState extends State<TryOnScreen> {
  final AuthService _authService = AuthService();
  String _clothType = 'upper';

  String? get _userInitImage => _authService.currentUser?['image'];

  Future<void> _handleTryOn(String clothImageUrl) async {
    final tryonProvider = Provider.of<TryonProvider>(context, listen: false);
    final initImageUrl = _userInitImage;

    if (tryonProvider.isLoading) {
      debugPrint('Already loading, ignoring tap');
      return;
    }

    if (initImageUrl == null || initImageUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bạn chưa cài đặt ảnh người dùng. Vui lòng cập nhật trong Profile.'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    debugPrint('Starting Try-on from Search...');
    debugPrint('init_image (user): $initImageUrl');
    debugPrint('cloth_image (selected): $clothImageUrl');
    debugPrint('cloth_type: $_clothType');

    await tryonProvider.tryon(initImageUrl, clothImageUrl, _clothType);

    if (!mounted) return;

    if (tryonProvider.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Loi: ${tryonProvider.error}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
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
      appBar: AppBar(
        title: const Text('Try-On'),
        centerTitle: true,
        elevation: 2,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Ảnh của bạn:',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              _buildInitImageSection(initImageUrl),
              const SizedBox(height: 24),
              const Text(
                'Quần áo được chọn:',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              _buildClothImageSection(clothImageUrl),
              const SizedBox(height: 24),
              const Text(
                'Loại quần áo:',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              _buildClothTypeSelector(),
              const SizedBox(height: 32),
              _buildTryOnButton(clothImageUrl, initImageUrl),
              const SizedBox(height: 24),
              _buildErrorSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInitImageSection(String? initImageUrl) {
    if (initImageUrl != null && initImageUrl.isNotEmpty) {
      return Container(
        height: 200,
        width: double.infinity,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.blue[300]!),
          borderRadius: BorderRadius.circular(12),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(
            initImageUrl,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: Colors.grey[300],
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.broken_image, size: 48, color: Colors.grey),
                    SizedBox(height: 8),
                    Text('Không thể tải ảnh', style: TextStyle(color: Colors.grey)),
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
      decoration: BoxDecoration(
        color: Colors.orange[50],
        border: Border.all(color: Colors.orange[300]!),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.warning_amber, size: 48, color: Colors.orange[700]),
          const SizedBox(height: 12),
          Text(
            'Chưa có ảnh người mẫu',
            style: TextStyle(
              color: Colors.orange[700],
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Vui lòng cập nhật ảnh người mẫu trong Profile',
            style: TextStyle(color: Colors.orange[600], fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildClothImageSection(String? clothImageUrl) {
    if (clothImageUrl != null) {
      return Container(
        height: 250,
        width: double.infinity,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.green[300]!),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(26),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(
            clothImageUrl,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: Colors.grey[300],
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.broken_image, size: 64, color: Colors.grey),
                    SizedBox(height: 12),
                    Text('Không thể tải ảnh',
                        style: TextStyle(color: Colors.grey, fontSize: 16)),
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
      height: 250,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(
        child: Text(
          'Không có ảnh được chọn',
          style: TextStyle(color: Colors.grey, fontSize: 16),
        ),
      ),
    );
  }

  Widget _buildClothTypeSelector() {
    return Row(
      children: [
        Expanded(
          child: _buildClothTypeButton('upper', 'Áo', Icons.checkroom),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildClothTypeButton('lower', 'Quần', Icons.straighten),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildClothTypeButton('full', 'Cả bộ', Icons.accessibility),
        ),
      ],
    );
  }

  Widget _buildClothTypeButton(String type, String label, IconData icon) {
    final isSelected = _clothType == type;
    return GestureDetector(
      onTap: () {
        setState(() {
          _clothType = type;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue : Colors.grey[100],
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : Colors.grey[600],
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey[600],
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTryOnButton(String? clothImageUrl, String? initImageUrl) {
    return SizedBox(
      width: double.infinity,
      child: Consumer<TryonProvider>(
        builder: (context, provider, _) {
          final canTryOn = clothImageUrl != null &&
              initImageUrl != null &&
              initImageUrl.isNotEmpty;

          return ElevatedButton(
            onPressed: canTryOn && !provider.isLoading
                ? () => _handleTryOn(clothImageUrl)
                : null,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: Colors.blue,
              disabledBackgroundColor: Colors.grey[300],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: provider.isLoading
                ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text(
                    'Bat dau Try-On',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
          );
        },
      ),
    );
  }

  Widget _buildErrorSection() {
    return Consumer<TryonProvider>(
      builder: (context, provider, _) {
        if (provider.error != null) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red[100],
              border: Border.all(color: Colors.red[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.red[700]),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    provider.error!,
                    style: TextStyle(color: Colors.red[700]),
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
