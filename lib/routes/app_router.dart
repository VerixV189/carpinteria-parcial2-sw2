import 'package:flutter/material.dart';
import 'package:carpinteria_movil_sw2/presentation/pages/auth/login_page.dart';
import 'package:carpinteria_movil_sw2/presentation/pages/auth/register_page.dart';
import 'package:carpinteria_movil_sw2/presentation/pages/home_page.dart';
import 'package:carpinteria_movil_sw2/presentation/pages/splash/splash_page.dart';
import 'package:carpinteria_movil_sw2/presentation/pages/voice_test/voice_test_page.dart';

class AppRouter {
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/home';
  static const String splashModels = '/splash-models';
  static const String voiceTest = '/voice-test';

  static Map<String, WidgetBuilder> get routes => {
        login: (_) => const LoginPage(),
        register: (_) => const RegisterPage(),
        home: (_) => const HomePage(),
        splashModels: (_) => const SplashPage(),
        voiceTest: (_) => const VoiceTestPage(),
      };
}
