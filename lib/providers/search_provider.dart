import 'package:flutter/material.dart';
import '../models/image_item.dart';
import '../services/api_service.dart';

class SearchProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<ImageItem> _images = [];
  bool _isLoading = false;
  String? _error;
  ImageItem? _selectedImage;
  String? _tryOnResult;

  List<ImageItem> get images => _images;
  bool get isLoading => _isLoading;
  String? get error => _error;
  ImageItem? get selectedImage => _selectedImage;
  String? get tryOnResult => _tryOnResult;

  Future<void> searchImages(String imageUrl) async {
    _isLoading = true;
    _error = null;
    _images = [];
    _selectedImage = null;
    notifyListeners();

    try {
      final response = await _apiService.searchImages(imageUrl);
      if (response.success) {
        _images = response.images;
      } else {
        _error = response.message ?? 'Không tìm thấy ảnh nào';
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> tryOnRequest(String imageUrl) async {
    _isLoading = true;
    _error = null;
    _tryOnResult = null;
    notifyListeners();

    try {
      final response = await _apiService.tryOn(imageUrl);
      if (response.success) {
        _tryOnResult = response.result;
      } else {
        _error = response.message ?? 'Try-on thất bại';
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void selectImage(ImageItem image) {
    _selectedImage = image;
    notifyListeners();
  }

  void clearSelection() {
    _selectedImage = null;
    notifyListeners();
  }

  void clearAll() {
    _images = [];
    _error = null;
    _selectedImage = null;
    _tryOnResult = null;
    notifyListeners();
  }
}
