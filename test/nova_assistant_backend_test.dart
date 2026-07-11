import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart' as http_testing;
import 'package:editnova/ai_assistant.dart';
import 'package:editnova/models/ai_response.dart';

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

      // We now receive an AiResponse object
      final AiResponse response = await assistant.getData();

      // Access property directly using the dot operator
      expect(response.status, equals('ok'));
    });

    test('Verify that mock client intercepts calls correctly', () async {
      final mockClient = http_testing.MockClient((request) async {
        // Return a response that matches the AiResponse model
        return http.Response(jsonEncode({'status': 'success'}), 200);
      });

      final assistant = AiAssistant(
        client: MockHttpClientAdapter(mockClient),
        baseUrl: 'https://example.com',
      );

      final AiResponse response = await assistant.getData();

      // Access property directly using the dot operator
      expect(response.status, equals('success'));
    });
  });
}
