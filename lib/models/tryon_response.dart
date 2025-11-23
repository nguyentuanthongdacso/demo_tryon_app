class TryonResponse {
  final String status;
  final Map<String, dynamic> inputData;
  final List<String> outputImages;
  final String? error;

  TryonResponse({
    required this.status,
    required this.inputData,
    required this.outputImages,
    this.error,
  });

  factory TryonResponse.fromJson(Map<String, dynamic> json) {
    final results = json['results'] as Map<String, dynamic>?;
    final output = results?['output'] as List?;
    return TryonResponse(
      status: json['status'] as String? ?? '',
      inputData: json['input_data'] as Map<String, dynamic>? ?? {},
      outputImages: output?.map((e) => e.toString()).toList() ?? [],
      error: json['error'] as String?,
    );
  }
}
