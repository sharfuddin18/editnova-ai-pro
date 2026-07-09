import 'package:flutter_test/flutter_test.dart';

import 'package:editnova/network/mock_backend.dart';

// We only test the MockHttpBackend contract; do not call NovaAssistant
// (it instantiates FlutterTts which relies on platform channels).

void main() {
  test('MockHttpBackend returns configured JSON for create-poster', () async {
    final backend = MockHttpBackend(routes: {
      '/api/create-poster': {
        'status': 'success',
        'message': 'Poster created with theme: default',
      },
    });

    // Ensure the mocked endpoint returns the configured JSON.
    final res = await backend.postJson(
      Uri.parse('http://test.local/api/create-poster'),
      body: const {'theme': 'default'},
    );

    expect(res.statusCode, 200);
    expect(res.body, contains('Poster created with theme: default'));
  });
}
