class AppConfig {
  const AppConfig._();

  static const String apiBaseUrl = String.fromEnvironment(
    'VITI_API_URL',
    defaultValue: 'https://viti-core-api-alexby2g.onrender.com/api/v1',
  );
}
