import 'package:flutter/material.dart';
import 'package:carpinteria_movil_sw2/core/config/app_config.dart';
import 'package:carpinteria_movil_sw2/presentation/pages/auth/login_page.dart';
import 'package:carpinteria_movil_sw2/presentation/pages/home_page.dart';
import 'package:carpinteria_movil_sw2/presentation/providers/app_provider.dart';
import 'package:carpinteria_movil_sw2/routes/app_router.dart';
import 'package:carpinteria_movil_sw2/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppConfig.init();

  final appProvider = AppProvider();
  await appProvider.initializeSession();

  runApp(MyApp(provider: appProvider));
}

class MyApp extends StatelessWidget {
  final AppProvider? provider;

  const MyApp({super.key, this.provider});

  @override
  Widget build(BuildContext context) {
    final effectiveProvider = provider ?? AppProvider();
    return AppScope(
      provider: effectiveProvider,
      child: MaterialApp(
        title: AppConfig.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        routes: AppRouter.routes,
        home: effectiveProvider.isAuthenticated
            ? const HomePage()
            : const LoginPage(),
      ),
    );
  }
}
