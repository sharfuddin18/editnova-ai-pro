import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart' as http_testing;
// This import relies on 'name: editnova' defined in your pubspec.yaml
import 'package:editnova/ai_assistant.dart';

void main() {
  group('AiAssistant Networking Tests', () {
    test('Verify JSON parsing', () async {
      final mockClient = http_testing.MockClient((request) async {
        return http.Response(jsonEncode({'status': 'ok'}), 200);
      });

      final assistant = AiAssistant(
        client: MockHttpClientAdapter(mockClient),
        baseUrl: 'https://example.com',
      );

      final data = await assistant.getData();
      expect(data['status'], equals('ok'));
    });

    test('Verify that mock client intercepts calls correctly', () async {
      final mockClient = http_testing.MockClient((request) async {
        return http.Response(jsonEncode({'test': 'success'}), 200);
      });

      final assistant = AiAssistant(
        client: MockHttpClientAdapter(mockClient),
        baseUrl: 'https://example.com',
      );

      final data = await assistant.getData();
      expect(data['test'], equals('success'));
    });
  });
}
