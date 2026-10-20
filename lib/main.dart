import 'package:flutter/material.dart';
import 'package:carpinteria_movil_sw2/presentation/pages/splash/splash_page.dart';

/// Inicializa los modelos de IA antes de arrancar la app.
/// La copia solo ocurre la primera vez; las siguientes aperturas usan el disco.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Carpintería Móvil',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.brown),
        useMaterial3: true,
      ),
      home: const SplashPage(),
    );
  }
}

