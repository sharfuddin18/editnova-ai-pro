import 'dart:convert';

import 'package:http/http.dart' as http;

abstract class HttpBackend {
  Future<http.Response> postJson(
    Uri uri, {
    required Map<String, Object?> body,
    Map<String, String>? headers,
    Duration? timeout,
  });
}

class HttpBackendImpl implements HttpBackend {
  final http.Client _client;

  HttpBackendImpl({http.Client? client}) : _client = client ?? http.Client();

  @override
  Future<http.Response> postJson(
    Uri uri, {
    required Map<String, Object?> body,
    Map<String, String>? headers,
    Duration? timeout,
  }) {
    final mergedHeaders = <String, String>{
      'Content-Type': 'application/json',
      if (headers != null) ...headers,
    };

    return _client
        .post(
          uri,
          headers: mergedHeaders,
          body: jsonEncode(body),
        )
        .timeout(timeout ?? const Duration(seconds: 30));
  }
}
