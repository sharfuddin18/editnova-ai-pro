TODO - EditNova AI Pro Development Roadmap
🎯 High-Priority: Network & Architecture
[ ] Networking Abstraction: Create an HttpClient interface to decouple NovaAssistant from concrete network implementations.

[ ] Implement Adapters:

[ ] Real Client: Implement using package:http/http.dart.

[ ] Mock Client: Implement using http/testing.dart's MockClient for reliable testing.

[ ] Refactor NovaAssistant: Inject the HttpClient into the assistant and enable dynamic baseUrl configuration.

[ ] Unit Testing:

[ ] Add/expand unit tests for backend JSON parsing using MockHttpBackend.

[ ] Verify that no real network calls occur during widget testing.

[ ] Verification: Run flutter test to ensure all tests pass (Green Suite).

✅ Completed & Stable
[x] Project Structure: Fully defined and initialized.

[x] Typography: Montserrat font system integrated and mapped in pubspec.yaml.

[x] Build Pipeline:

[x] Resolved asset path conflict (assets/fonts/).

[x] Standardized flutter clean and build cache management.

[x] Established .gitignore policy for build/ and .dart_tool/ directories.

[x] Documentation: Updated README.md with environment setup and troubleshooting.

🚀 Future Roadmap
[ ] State Management: Implement Provider or Riverpod for cleaner UI updates.

[ ] Feature Implementation: Toggle existing API endpoints via the NovaAssistant service.

[ ] CI/CD: Automate dependency checks (flutter pub outdated) and testing.