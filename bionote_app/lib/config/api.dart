class ApiConfig {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://bionote-app.vercel.app',
  );

  static const String registerPath = '/auth/register';
  static const String loginPath = '/auth/login';
}
