import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'features/profile/data/settings_provider.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'core/config/app_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize AppConfig (defaulting to dev for now)
  AppConfig.initialize(AppEnvironment.dev);
  
  try {
    await dotenv.load(fileName: "assets/.env");
  } catch (e) {
    debugPrint('⚠️ Warning: .env file not found, using defaults: $e');
  }
  
  final prefs = await SharedPreferences.getInstance();
  
  runApp(
    ProviderScope(
      overrides: [
        sharedPrefsProvider.overrideWithValue(prefs),
      ],
      child: const VessPayApp(),
    ),
  );
}

class VessPayApp extends ConsumerWidget {
  const VessPayApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    
    return MaterialApp.router(
      title: 'VessPay',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      routerConfig: router,
      builder: (context, child) {
        // Restrict app to mobile-like dimensions on Web/Desktop
        return Container(
          color: const Color(0xFF0D0D0D), // Dark background for the empty space
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 450),
              child: ClipRect(child: child!),
            ),
          ),
        );
      },
    );
  }
}
