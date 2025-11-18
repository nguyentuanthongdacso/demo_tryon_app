class TryOnRequest {
  final String imageUrl;

  TryOnRequest({required this.imageUrl});

  Map<String, dynamic> toJson() {
    return {
      'imageUrl': imageUrl,
    };
  }
}
