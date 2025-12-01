class TryonRequest {
  final String initImage;
  final String clothImage;
  final String clothType;
  final String? userKey;  // User key for token verification

  TryonRequest({
    required this.initImage,
    required this.clothImage,
    required this.clothType,
    this.userKey,
  });

  Map<String, dynamic> toJson() {
    return {
      'init_image': initImage,
      'cloth_image': clothImage,
      'cloth_type': clothType,
      if (userKey != null) 'user_key': userKey,
    };
  }
}
