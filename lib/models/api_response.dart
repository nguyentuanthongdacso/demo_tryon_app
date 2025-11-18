import 'image_item.dart';

class SearchResponse {
  final List<ImageItem> images;
  final bool success;
  final String? message;

  SearchResponse({
    required this.images,
    required this.success,
    this.message,
  });

  factory SearchResponse.fromJson(Map<String, dynamic> json) {
    return SearchResponse(
      images: (json['images'] as List?)
              ?.map((e) => ImageItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      success: json['success'] as bool? ?? false,
      message: json['message'] as String?,
    );
  }
}

class TryOnResponse {
  final String result;
  final bool success;
  final String? message;

  TryOnResponse({
    required this.result,
    required this.success,
    this.message,
  });

  factory TryOnResponse.fromJson(Map<String, dynamic> json) {
    return TryOnResponse(
      result: json['result'] as String? ?? '',
      success: json['success'] as bool? ?? false,
      message: json['message'] as String?,
    );
  }
}
