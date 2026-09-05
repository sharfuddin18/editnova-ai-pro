class ApiConfig {
  const ApiConfig._();

  static const String baseUrl = String.fromEnvironment(
    'EDITNOVA_API_URL',
    defaultValue: 'http://localhost:5001',
  );

  static Uri endpoint(String path) {
    final normalizedBase = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$normalizedBase$normalizedPath');
  }
}