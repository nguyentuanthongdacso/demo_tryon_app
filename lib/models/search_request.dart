class SearchRequest {
  final String url;

  SearchRequest({required this.url});

  Map<String, dynamic> toJson() {
    return {
      'url': url,
    };
  }
}
