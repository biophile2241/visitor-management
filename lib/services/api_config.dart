class ApiConfig {
  ApiConfig._();

  static const apiKey = String.fromEnvironment(
    'API_KEY',
    defaultValue: '6ae0aa4dbe3bc8fead97b0c5',
  );

  static const baseUrl = String.fromEnvironment(
    'BASE_URL',
    defaultValue: 'https://$apiKey.mockapi.io/api/v1',
  );
}
