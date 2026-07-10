class AiResponse {
  final String status;

  AiResponse({required this.status});

  factory AiResponse.fromJson(Map<String, dynamic> json) {
    return AiResponse(
      status: json['status'] ?? 'unknown',
    );
  }
}
