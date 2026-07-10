import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart' as http_testing;

abstract class HttpClient {
  Future<Map<String, dynamic>> get(Uri url);
  Future<Map<String, dynamic>> post(Uri url, Map<String, dynamic> body);
}

class RealHttpClientAdapter implements HttpClient {
  final _client = http.Client();

  @override
  Future<Map<String, dynamic>> get(Uri url) async {
    final response = await _client.get(url);
    return jsonDecode(response.body);
  }

  @override
  Future<Map<String, dynamic>> post(Uri url, Map<String, dynamic> body) async {
    final response = await _client.post(url,
        headers: {'Content-Type': 'application/json'}, body: jsonEncode(body));
    return jsonDecode(response.body);
  }
}

class MockHttpClientAdapter implements HttpClient {
  final http_testing.MockClient _mockClient;

  MockHttpClientAdapter(this._mockClient);

  @override
  Future<Map<String, dynamic>> get(Uri url) async {
    final response = await _mockClient.get(url);
    return jsonDecode(response.body);
  }

  @override
  Future<Map<String, dynamic>> post(Uri url, Map<String, dynamic> body) async {
    final response = await _mockClient.post(url,
        headers: {'Content-Type': 'application/json'}, body: jsonEncode(body));
    return jsonDecode(response.body);
  }
}

class AiAssistant {
  final HttpClient client;
  final String baseUrl;

  AiAssistant({required this.client, required this.baseUrl});

  Future<Map<String, dynamic>> getData() async {
    return await client.get(Uri.parse(baseUrl));
  }

  Future<Map<String, dynamic>> postData(Map<String, dynamic> data) async {
    return await client.post(Uri.parse(baseUrl), data);
  }
}
