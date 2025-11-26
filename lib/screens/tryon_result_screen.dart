import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

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
            const SnackBar(
              content: Text('⏱️ Hết thời gian chờ. Vui lòng thử lại.'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 3),
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
            const SnackBar(
              content: Text('✅ Tất cả ảnh đã sẵn sàng!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
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
      appBar: AppBar(
        title: const Text('Try-On Results'),
        actions: [
          if (!allReady)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Center(
                child: Row(
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Theme.of(context).colorScheme.onPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Đang xử lý... ($readyCount/$totalCount)',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Hiển thị thông tin
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      allReady
                          ? '✅ Hoàn thành!'
                          : '⏳ Đang xử lý ảnh... ($readyCount/$totalCount)',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: allReady ? Colors.green : Colors.orange,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Thời gian chờ: $_attemptCount giây',
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    if (!allReady) ...[
                      const SizedBox(height: 8),
                      const LinearProgressIndicator(),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Hiển thị ảnh gốc
            const Text(
              'Ảnh gốc',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      const Text('Người mẫu', style: TextStyle(fontSize: 12)),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          widget.initImageUrl,
                          height: 200,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            height: 200,
                            color: Colors.grey[300],
                            child: const Icon(Icons.error),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    children: [
                      const Text('Quần áo', style: TextStyle(fontSize: 12)),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          widget.clothImageUrl,
                          height: 200,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            height: 200,
                            color: Colors.grey[300],
                            child: const Icon(Icons.error),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Hiển thị kết quả
            const Text(
              'Kết quả Try-On',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            ...widget.futureLinks.asMap().entries.map((entry) {
              final index = entry.key;
              final link = entry.value;
              final isReady = _imageStatus[link] ?? false;

              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Kết quả ${index + 1}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: isReady
                          ? Image.network(
                              link,
                              fit: BoxFit.cover,
                              loadingBuilder: (context, child, progress) {
                                if (progress == null) return child;
                                return Container(
                                  height: 300,
                                  color: Colors.grey[200],
                                  child: const Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                );
                              },
                              errorBuilder: (_, __, ___) => Container(
                                height: 300,
                                color: Colors.grey[300],
                                child: const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.error, size: 48),
                                    SizedBox(height: 8),
                                    Text('Lỗi tải ảnh'),
                                  ],
                                ),
                              ),
                            )
                          : Container(
                              height: 300,
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  CircularProgressIndicator(),
                                  SizedBox(height: 16),
                                  Text(
                                    '⏳ Đang xử lý...',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}
