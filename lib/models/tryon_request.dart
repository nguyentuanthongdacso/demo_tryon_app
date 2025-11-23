class TryonRequest {
  final String initImage;
  final String clothImage;
  final String clothType;

  TryonRequest({
    required this.initImage,
    required this.clothImage,
    required this.clothType,
  });

  Map<String, dynamic> toJson() {
    return {
      'init_image': initImage,
      'cloth_image': clothImage,
      'cloth_type': clothType,
    };
  }
}
