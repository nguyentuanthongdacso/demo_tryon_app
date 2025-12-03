import 'dart:async';
import 'package:flutter/material.dart';

/// Button với rate limit và debounce
/// - Rate limit: Chỉ cho phép bấm 1 lần mỗi [rateLimitSeconds] giây
/// - Debounce: Nếu bấm liên tục, chỉ tính lần đầu tiên
class RateLimitedButton extends StatefulWidget {
  final VoidCallback onPressed;
  final Widget child;
  final int rateLimitSeconds;
  final ButtonStyle? style;
  final bool enabled;
  final IconData? icon;
  final bool isLoading;

  const RateLimitedButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.rateLimitSeconds = 15,
    this.style,
    this.enabled = true,
    this.icon,
    this.isLoading = false,
  });

  @override
  State<RateLimitedButton> createState() => _RateLimitedButtonState();
}

class _RateLimitedButtonState extends State<RateLimitedButton> {
  bool _isRateLimited = false;
  int _remainingSeconds = 0;
  Timer? _timer;
  bool _isProcessing = false; // Debounce flag

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _handlePress() {
    // Debounce: Nếu đang xử lý thì bỏ qua
    if (_isProcessing || _isRateLimited || !widget.enabled || widget.isLoading) {
      return;
    }

    // Đánh dấu đang xử lý (debounce)
    _isProcessing = true;

    // Gọi callback
    widget.onPressed();

    // Bắt đầu rate limit
    setState(() {
      _isRateLimited = true;
      _remainingSeconds = widget.rateLimitSeconds;
    });

    // Timer đếm ngược
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 1) {
        setState(() {
          _remainingSeconds--;
        });
      } else {
        timer.cancel();
        setState(() {
          _isRateLimited = false;
          _remainingSeconds = 0;
          _isProcessing = false; // Reset debounce
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDisabled = _isRateLimited || !widget.enabled || widget.isLoading;

    return ElevatedButton(
      onPressed: isDisabled ? null : _handlePress,
      style: widget.style,
      child: _isRateLimited
          ? Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (widget.icon != null) ...[
                  Icon(widget.icon, size: 20),
                  const SizedBox(width: 8),
                ],
                widget.child,
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_remainingSeconds}s',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            )
          : widget.isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (widget.icon != null) ...[
                      Icon(widget.icon, size: 20),
                      const SizedBox(width: 8),
                    ],
                    widget.child,
                  ],
                ),
    );
  }
}

/// IconButton với rate limit
class RateLimitedIconButton extends StatefulWidget {
  final VoidCallback onPressed;
  final IconData icon;
  final int rateLimitSeconds;
  final bool enabled;
  final Color? color;
  final double? size;

  const RateLimitedIconButton({
    super.key,
    required this.onPressed,
    required this.icon,
    this.rateLimitSeconds = 15,
    this.enabled = true,
    this.color,
    this.size,
  });

  @override
  State<RateLimitedIconButton> createState() => _RateLimitedIconButtonState();
}

class _RateLimitedIconButtonState extends State<RateLimitedIconButton> {
  bool _isRateLimited = false;
  int _remainingSeconds = 0;
  Timer? _timer;
  bool _isProcessing = false;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _handlePress() {
    if (_isProcessing || _isRateLimited || !widget.enabled) {
      return;
    }

    _isProcessing = true;
    widget.onPressed();

    setState(() {
      _isRateLimited = true;
      _remainingSeconds = widget.rateLimitSeconds;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 1) {
        setState(() {
          _remainingSeconds--;
        });
      } else {
        timer.cancel();
        setState(() {
          _isRateLimited = false;
          _remainingSeconds = 0;
          _isProcessing = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        IconButton(
          onPressed: (_isRateLimited || !widget.enabled) ? null : _handlePress,
          icon: Icon(widget.icon),
          color: _isRateLimited ? Colors.grey : widget.color,
          iconSize: widget.size,
        ),
        if (_isRateLimited)
          Positioned(
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${_remainingSeconds}s',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
