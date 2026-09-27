enum AppEnvironment { dev, staging, prod }

class AppConfig {
  final AppEnvironment environment;
  final String baseUrl;
  final String stripePublishableKey;

  AppConfig({
    required this.environment,
    required this.baseUrl,
    required this.stripePublishableKey,
  });

  static AppConfig dev = AppConfig(
    environment: AppEnvironment.dev,
    // Local backend: http://localhost:3000/api/v1
    // Android emulator uses 10.0.2.2 instead of localhost
    baseUrl: 'http://localhost:3000/api/v1',
    stripePublishableKey: 'pk_test_placeholder',
  );

  static AppConfig staging = AppConfig(
    environment: AppEnvironment.staging,
    baseUrl: 'https://vesspay-api-staging.up.railway.app/api/v1',
    stripePublishableKey: 'pk_test_placeholder',
  );

  static AppConfig prod = AppConfig(
    environment: AppEnvironment.prod,
    baseUrl: 'https://api.vesspay.com/api/v1',
    stripePublishableKey: 'pk_live_placeholder',
  );

  static AppConfig current = dev;

  static void initialize(AppEnvironment env) {
    switch (env) {
      case AppEnvironment.dev:
        current = dev;
        break;
      case AppEnvironment.staging:
        current = staging;
        break;
      case AppEnvironment.prod:
        current = prod;
        break;
    }
  }
}
