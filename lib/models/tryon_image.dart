/// Model cho ảnh tryon lưu trong database
/// Mỗi user chỉ lưu tối đa 10 ảnh tryon gần nhất
class TryonImage {
  final int id;
  final String userKey;
  final String imageUrl;
  final DateTime createdAt;

  TryonImage({
    required this.id,
    required this.userKey,
    required this.imageUrl,
    required this.createdAt,
  });

  /// Parse từ JSON response
  factory TryonImage.fromJson(Map<String, dynamic> json) {
    // Server trả về thời gian UTC, cần parse và đánh dấu là UTC
    final createdAtString = json['created_at'] as String;
    // Thêm 'Z' để đánh dấu là UTC nếu chưa có
    final utcString = createdAtString.endsWith('Z') 
        ? createdAtString 
        : '${createdAtString}Z';
    
    return TryonImage(
      id: json['id'] as int,
      userKey: json['user_key'] as String,
      imageUrl: json['image_url'] as String,
      createdAt: DateTime.parse(utcString),
    );
  }

  /// Convert sang JSON để gửi request
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_key': userKey,
      'image_url': imageUrl,
      'created_at': createdAt.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'TryonImage(id: $id, userKey: $userKey, imageUrl: $imageUrl, createdAt: $createdAt)';
  }
}


/// Response khi lưu ảnh tryon
class SaveTryonImageResponse {
  final bool success;
  final String message;
  final TryonImage? tryonImage;

  SaveTryonImageResponse({
    required this.success,
    required this.message,
    this.tryonImage,
  });

  factory SaveTryonImageResponse.fromJson(Map<String, dynamic> json) {
    return SaveTryonImageResponse(
      success: json['success'] as bool,
      message: json['message'] as String,
      tryonImage: json['tryon_image'] != null
          ? TryonImage.fromJson(json['tryon_image'] as Map<String, dynamic>)
          : null,
    );
  }
}


/// Response khi lấy danh sách ảnh tryon
class GetTryonImagesResponse {
  final bool success;
  final String message;
  final List<TryonImage> tryonImages;
  final int total;

  GetTryonImagesResponse({
    required this.success,
    required this.message,
    required this.tryonImages,
    required this.total,
  });

  factory GetTryonImagesResponse.fromJson(Map<String, dynamic> json) {
    return GetTryonImagesResponse(
      success: json['success'] as bool,
      message: json['message'] as String,
      tryonImages: (json['tryon_images'] as List<dynamic>)
          .map((e) => TryonImage.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: json['total'] as int,
    );
  }
}
