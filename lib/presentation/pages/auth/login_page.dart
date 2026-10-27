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

  void _fillDemoClient() {
    setState(() {
      _emailController.text = 'cliente@carpinteria.com';
      _passwordController.text = 'cliente123';
    });
  }

  void _fillDemoCarpenter() {
    setState(() {
      _emailController.text = 'carpintero@carpinteria.com';
      _passwordController.text = 'carp123';
    });
  }

  void _fillDemoAdmin() {
    setState(() {
      _emailController.text = 'admin@carpinteria.com';
      _passwordController.text = 'admin123';
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
            Text('Conexión Gateway API'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'URL del API Gateway (Backend2 NestJS en puerto 3000). En emulador Android usa http://10.0.2.2:3000.',
              style: TextStyle(fontSize: 13, color: Colors.black54),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: urlCtrl,
              decoration: const InputDecoration(
                labelText: 'BASE_URL (Gateway :3000)',
                hintText: 'http://10.0.2.2:3000',
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
                  Align(
                    alignment: Alignment.topRight,
                    child: TextButton.icon(
                      onPressed: _showBackendConfigDialog,
                      icon: const Icon(
                        Icons.settings_ethernet,
                        color: AppTheme.accentAmber,
                        size: 18,
                      ),
                      label: Text(
                        'Gateway: ${AppConfig.baseUrl}',
                        style: const TextStyle(
                          color: AppTheme.accentAmber,
                          fontSize: 11.5,
                        ),
                      ),
                    ),
                  ),
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
                    'Portal Cliente • Taller Carpintero • Admin • IA Online/Offline',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
                  const SizedBox(height: 22),
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
                              'Conecta en modo Online con el Gateway (:3000) o híbrido local',
                              style: TextStyle(fontSize: 12.5, color: Colors.black54),
                            ),
                            const SizedBox(height: 18),
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              validator: Validators.email,
                              decoration: const InputDecoration(
                                labelText: 'Correo electrónico',
                                hintText: 'cliente@carpinteria.com',
                                prefixIcon: Icon(Icons.email_outlined),
                              ),
                            ),
                            const SizedBox(height: 14),
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
                            const SizedBox(height: 12),
                            const Text(
                              'Accesos rápidos (Usuarios Seed del Backend):',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: Colors.black54,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: [
                                ActionChip(
                                  avatar: const Icon(
                                    Icons.storefront_rounded,
                                    size: 16,
                                    color: AppTheme.primaryWood,
                                  ),
                                  label: const Text(
                                    'Cliente (Portal)',
                                    style: TextStyle(fontSize: 11.5),
                                  ),
                                  onPressed: _fillDemoClient,
                                ),
                                ActionChip(
                                  avatar: const Icon(
                                    Icons.construction_rounded,
                                    size: 16,
                                    color: AppTheme.primaryWood,
                                  ),
                                  label: const Text(
                                    'Carpintero (Taller)',
                                    style: TextStyle(fontSize: 11.5),
                                  ),
                                  onPressed: _fillDemoCarpenter,
                                ),
                                ActionChip(
                                  avatar: const Icon(
                                    Icons.admin_panel_settings_outlined,
                                    size: 16,
                                    color: AppTheme.primaryWood,
                                  ),
                                  label: const Text(
                                    'Admin General',
                                    style: TextStyle(fontSize: 11.5),
                                  ),
                                  onPressed: _fillDemoAdmin,
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
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
                            const SizedBox(height: 14),
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
