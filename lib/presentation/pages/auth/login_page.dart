import 'package:flutter/material.dart';
import 'package:carpinteria_movil_sw2/core/config/app_config.dart';
import 'package:carpinteria_movil_sw2/core/utils/validators.dart';
import 'package:carpinteria_movil_sw2/presentation/providers/app_provider.dart';
import 'package:carpinteria_movil_sw2/routes/app_router.dart';
import 'package:carpinteria_movil_sw2/theme/app_theme.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submitLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = AppScope.of(context);
    final success = await provider.login(
      _emailController.text.trim(),
      _passwordController.text,
    );

    if (!mounted) return;

    if (success) {
      Navigator.of(context).pushReplacementNamed(AppRouter.home);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage ?? 'Error al iniciar sesión'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  void _fillDemoCredentials() {
    setState(() {
      _emailController.text = 'maestro@carpinteria.bo';
      _passwordController.text = '123456';
    });
  }

  void _showBackendConfigDialog() {
    final urlCtrl = TextEditingController(text: AppConfig.baseUrl);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.dns_rounded, color: AppTheme.primaryWood),
            SizedBox(width: 8),
            Text('Conexión Backend'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'URL base de tu API REST. Si el servidor no responde, la app funcionará en modo híbrido (Demo local).',
              style: TextStyle(fontSize: 13, color: Colors.black54),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: urlCtrl,
              decoration: const InputDecoration(
                labelText: 'BASE_URL',
                hintText: 'http://192.168.1.10:8000/api',
                prefixIcon: Icon(Icons.link),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final provider = AppScope.of(context);
              await provider.updateBackendUrl(urlCtrl.text);
              if (ctx.mounted) Navigator.pop(ctx);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('URL actualizada: ${AppConfig.baseUrl}'),
                  ),
                );
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = AppScope.of(context);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF281100),
              Color(0xFF4A2508),
              AppTheme.warmCream,
            ],
            stops: [0.0, 0.36, 0.36],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                children: [
                  // Botón superior para configurar IP del Backend
                  Align(
                    alignment: Alignment.topRight,
                    child: TextButton.icon(
                      onPressed: _showBackendConfigDialog,
                      icon: const Icon(
                        Icons.settings_ethernet,
                        color: AppTheme.accentAmber,
                        size: 18,
                      ),
                      label: const Text(
                        'Configurar API',
                        style: TextStyle(color: AppTheme.accentAmber, fontSize: 12),
                      ),
                    ),
                  ),

                  // Logo e identidad de la Carpintería
                  Container(
                    width: 84,
                    height: 84,
                    decoration: BoxDecoration(
                      color: AppTheme.accentAmber.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppTheme.accentAmber.withValues(alpha: 0.6),
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.handyman_rounded,
                      size: 44,
                      color: AppTheme.accentAmber,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Carpintería El Roble',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Gestión de Muebles, Pedidos y Asistente IA',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Tarjeta de formulario
                  Card(
                    elevation: 6,
                    shadowColor: Colors.black26,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text(
                              'Iniciar Sesión',
                              style: TextStyle(
                                fontSize: 21,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryDarkWood,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Ingresa tus credenciales para acceder al taller',
                              style: TextStyle(fontSize: 13, color: Colors.black54),
                            ),
                            const SizedBox(height: 20),

                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              validator: Validators.email,
                              decoration: const InputDecoration(
                                labelText: 'Correo electrónico',
                                hintText: 'ejemplo@carpinteria.bo',
                                prefixIcon: Icon(Icons.email_outlined),
                              ),
                            ),
                            const SizedBox(height: 16),

                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              validator: Validators.password,
                              decoration: InputDecoration(
                                labelText: 'Contraseña',
                                prefixIcon: const Icon(Icons.lock_outline),
                                suffixIcon: IconButton(
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),

                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton.icon(
                                onPressed: _fillDemoCredentials,
                                icon: const Icon(Icons.bolt, size: 16),
                                label: const Text(
                                  'Usar cuenta de prueba',
                                  style: TextStyle(fontSize: 12.5),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),

                            SizedBox(
                              height: 50,
                              child: ElevatedButton(
                                onPressed: provider.isLoading ? null : _submitLogin,
                                child: provider.isLoading
                                    ? const SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Text('Ingresar al Sistema'),
                              ),
                            ),
                            const SizedBox(height: 16),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text(
                                  '¿No tienes una cuenta?',
                                  style: TextStyle(color: Colors.black54),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.of(context)
                                        .pushNamed(AppRouter.register);
                                  },
                                  child: const Text(
                                    'Regístrate aquí',
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
