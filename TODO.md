# TODO - Dependency Injection + Mock Network for editnova-ai-pro

## Plan (Option 1)
1. Create a small networking abstraction (HttpClient interface) used by NovaAssistant for backend calls.
2. Implement a real client adapter using `package:http/http.dart`.
3. Implement a Mock client using `http/testing.dart`'s `MockClient`.
4. Refactor `lib/ai_assistant.dart` to receive an injected client (and allow passing custom baseUrl).
5. Add/expand widget tests (or unit tests) to verify JSON parsing and that no real network calls happen.
6. Run `flutter test` to ensure the suite is green.
7. Add unit tests covering backend JSON parsing using `MockHttpBackend`.


