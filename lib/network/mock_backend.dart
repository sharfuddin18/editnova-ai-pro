import 'dart:convert';

import 'package:http/http.dart' as http;

import 'http_backend.dart';

class MockHttpBackend implements HttpBackend {
  final Map<String, dynamic> _routes;

  /// Keys are full request paths (e.g. `/api/create-poster`).
  /// Values are decoded JSON objects or raw strings.
  MockHttpBackend({Map<String, dynamic>? routes}) : _routes = routes ?? {};

  @override
  Future<http.Response> postJson(
    Uri uri, {
    required Map<String, Object?> body,
    Map<String, String>? headers,
    Duration? timeout,
  }) async {
    final key = uri.path;

    if (!_routes.containsKey(key)) {
      return http.Response(
        jsonEncode({'status': 'error', 'message': 'Not found'}),
        404,
        headers: {'Content-Type': 'application/json'},
      );
    }

    final value = _routes[key];
    final payload = value is String ? value : jsonEncode(value);

    return http.Response(
      payload,
      200,
      headers: {'Content-Type': 'application/json'},
    );
  }
}
