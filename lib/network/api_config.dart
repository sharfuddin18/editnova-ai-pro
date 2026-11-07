import 'package:flutter/foundation.dart';

const _configuredApiBaseUrl = String.fromEnvironment('EDITNOVA_API_BASE_URL');

String get apiBaseUrl {
  final configured = _configuredApiBaseUrl.trim();
  if (configured.isNotEmpty) {
    return configured.replaceFirst(RegExp(r'/+$'), '');
  }

  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    return 'http://10.0.2.2:5001';
  }
  return 'http://localhost:5001';
}

Uri apiUri(String endpoint) {
  final normalizedEndpoint = endpoint.replaceFirst(RegExp(r'^/+'), '');
  return Uri.parse('$apiBaseUrl/api/$normalizedEndpoint');
}
