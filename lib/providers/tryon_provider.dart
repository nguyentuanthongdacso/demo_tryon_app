import 'package:flutter/material.dart';
import '../models/tryon_request.dart';
import '../models/tryon_response.dart';
import '../services/tryon_service.dart';

class TryonProvider extends ChangeNotifier {
  final TryonService _service = TryonService();

  bool _isLoading = false;
  String? _error;
  TryonResponse? _response;

  bool get isLoading => _isLoading;
  String? get error => _error;
  TryonResponse? get response => _response;

  Future<void> tryon(String initImage, String clothImage, String clothType) async {
    _isLoading = true;
    _error = null;
    _response = null;
    notifyListeners();
    try {
      final req = TryonRequest(
        initImage: initImage,
        clothImage: clothImage,
        clothType: clothType,
      );
      final res = await _service.sendTryonRequest(req);
      _response = res;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clear() {
    _isLoading = false;
    _error = null;
    _response = null;
    notifyListeners();
  }
}
