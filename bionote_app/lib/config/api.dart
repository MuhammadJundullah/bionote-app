class ApiConfig {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:3000',
  );

  static const String registerPath = '/auth/register';
  static const String loginPath = '/auth/login';
}
