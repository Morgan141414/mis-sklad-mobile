class AppConfig {
  static const String misBaseUrl = 'https://tetis1.kz';
  static const String skladBaseUrl = 'https://tetis1.kz/sklad';

  // MIS auth endpoints
  static const String misLoginPath = '/api/v1/auth/login';
  static const String misRefreshPath = '/api/v1/auth/refresh';

  // Sklad SSO exchange
  static const String skladTokenExchangePath = '/api/v1/sklad/token';

  // Sklad API
  static const String skladApiBase = '/sklad/api/v1';

  static const Duration accessTokenExpiry = Duration(hours: 8);
  static const Duration misTokenExpiry = Duration(days: 7);
}
