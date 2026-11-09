import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import 'package:carpinteria_movil_sw2/core/services/model_installer.dart';
import 'package:carpinteria_movil_sw2/core/services/whisper_service.dart';
import 'package:carpinteria_movil_sw2/presentation/pages/voice_test/voice_test_page.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  // ── Channels ──────────────────────────────────────────────────────────────
  static const _methodCh = MethodChannel('carpinteria/model_copy');
  static const _eventCh  = EventChannel('carpinteria/model_copy_progress');

  // ── Animation ─────────────────────────────────────────────────────────────
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  // ── State ─────────────────────────────────────────────────────────────────
  String _statusMessage = 'Iniciando...';
  double _progress = 0.0;
  bool _hasError = false;
  String _errorDetail = '';

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _pulseAnim = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) => _initModels());
  }

  // ── Model initialisation ──────────────────────────────────────────────────

  Future<void> _initModels() async {
    setState(() {
      _hasError = false;
      _errorDetail = '';
      _progress = 0.0;
    });

    try {
      final dir = await getApplicationDocumentsDirectory();

      // ── Vosk: extrae el modelo zip al disco (solo la primera vez) ─────────
      await _extractVoskModel();

      final llmDest = '${dir.path}/Qwen3-1.7B-Q4_K_M.gguf';

      // ── LLM (> 1 GB – canal nativo) ───────────────────────────────────────
      await _copyModel(
        assetPath:     'assets/models/llm/Qwen3-1.7B-Q4_K_M.gguf',
        destPath:      llmDest,
        label:         'Modelo de IA (Qwen3)',
        progressStart: 0.25,
        progressEnd:   1.0,
        usePlatform:   true,
      );

      ModelInstaller.setResolvedPaths(
        whisperPath: '',
        llmPath:     llmDest,
      );

      if (!mounted) return;
      setState(() {
        _statusMessage = '¡Todo listo!';
        _progress = 1.0;
      });

      await Future.delayed(const Duration(milliseconds: 700));
      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder:      (_, __, ___) => const VoiceTestPage(),
          transitionsBuilder: (_, anim, __, child) =>
              FadeTransition(opacity: anim, child: child),
          transitionDuration: const Duration(milliseconds: 500),
        ),
      );
    } catch (e, st) {
      debugPrint('SplashPage error: $e\n$st');
      if (!mounted) return;
      setState(() {
        _hasError     = true;
        _statusMessage = 'Error al cargar modelos';
        _errorDetail  = e.toString();
      });
    }
  }

  // ── Vosk model extraction ─────────────────────────────────────────────────

  /// Extrae el modelo Vosk ZIP y crea el reconocedor (solo la 1ª vez).
  /// La extracción la realiza WhisperService internamente con archive ^4.x.
  Future<void> _extractVoskModel() async {
    setState(() {
      _statusMessage = 'Preparando reconocimiento de voz offline (Vosk)...';
      _progress = 0.0;
    });

    // Instancia temporal sólo para extraer; VoiceTestPage tendrá la suya propia.
    final svc = WhisperService();
    final extractFuture = svc.initialize();

    // Anima la barra de 0 → 0.25 mientras dura la extracción
    bool done = false;
    double fakeProgress = 0.0;
    extractFuture.then((_) => done = true).catchError((_) => done = true);
    while (!done) {
      await Future.delayed(const Duration(milliseconds: 150));
      fakeProgress = (fakeProgress + 0.01).clamp(0.0, 0.24);
      if (mounted) setState(() => _progress = fakeProgress);
    }
    await extractFuture; // lanza excepción si falla
    svc.dispose();

    if (mounted) {
      setState(() {
        _statusMessage = 'Voz offline lista ✓';
        _progress = 0.25;
      });
    }
  }

  // ── Copy helpers ──────────────────────────────────────────────────────────

  /// Copia un modelo. Si [usePlatform] es true usa el canal nativo (para
  /// archivos > 1 GB que superan el límite de rootBundle).
  Future<void> _copyModel({
    required String assetPath,
    required String destPath,
    required String label,
    required double progressStart,
    required double progressEnd,
    required bool   usePlatform,
  }) async {
    // Verifica existencia vía canal nativo (evita race en disco)
    final exists = await _methodCh.invokeMethod<bool>(
          'fileExists', {'path': destPath}) ??
        false;

    if (exists) {
      setState(() {
        _statusMessage = '$label ya instalado ✓';
        _progress      = progressEnd;
      });
      return;
    }

    setState(() => _statusMessage = 'Copiando $label...');

    if (usePlatform) {
      await _copyViaChannel(
        assetPath:     assetPath,
        destPath:      destPath,
        label:         label,
        progressStart: progressStart,
        progressEnd:   progressEnd,
      );
    } else {
      await _copyViaDart(
        assetPath:     assetPath,
        destPath:      destPath,
        label:         label,
        progressStart: progressStart,
        progressEnd:   progressEnd,
      );
    }
  }

  /// Copia vía Kotlin (streaming nativo, sin límite de tamaño).
  Future<void> _copyViaChannel({
    required String assetPath,
    required String destPath,
    required String label,
    required double progressStart,
    required double progressEnd,
  }) async {
    // Escucha progreso desde EventChannel
    final sub = _eventCh.receiveBroadcastStream().listen((dynamic raw) {
      if (raw is double && mounted) {
        setState(() {
          _progress = progressStart + raw * (progressEnd - progressStart);
        });
      }
    });

    try {
      await _methodCh.invokeMethod<bool>('copyAsset', {
        'assetPath': assetPath,
        'destPath':  destPath,
      });
    } finally {
      await sub.cancel();
    }

    if (mounted) {
      setState(() {
        _statusMessage = '$label instalado ✓';
        _progress      = progressEnd;
      });
    }
  }

  /// Copia vía Dart rootBundle (sólo para archivos < ~900 MB).
  Future<void> _copyViaDart({
    required String assetPath,
    required String destPath,
    required String label,
    required double progressStart,
    required double progressEnd,
  }) async {
    final data  = await rootBundle.load(assetPath);
    final bytes = data.buffer.asUint8List();
    final total = bytes.length;
    const chunkSize = 1024 * 1024; // 1 MB
    final sink  = File(destPath).openWrite();
    int written = 0;

    while (written < total) {
      final end = (written + chunkSize).clamp(0, total);
      sink.add(bytes.sublist(written, end));
      written = end;

      setState(() {
        _progress = progressStart +
            (written / total) * (progressEnd - progressStart);
      });
      await Future.delayed(Duration.zero);
    }

    await sink.flush();
    await sink.close();

    setState(() {
      _statusMessage = '$label instalado ✓';
      _progress      = progressEnd;
    });
  }

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  // ── UI ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end:   Alignment.bottomRight,
            colors: [
              Color(0xFF1A0A00),
              Color(0xFF3E1C00),
              Color(0xFF5C2E00),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(flex: 2),

                  // ── Logo ──────────────────────────────────────
                  ScaleTransition(
                    scale: _pulseAnim,
                    child: Container(
                      width: 136,
                      height: 136,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFFFFB74D).withValues(alpha: 0.6),
                          width: 2.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFF8C00).withValues(alpha: 0.3),
                            blurRadius: 30,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/images/logo_el_roble.png',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  const Text(
                    'Carpintería El Roble',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFFFB74D),
                      letterSpacing: 1.2,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    'Asistente inteligente y gestión de carpintería',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.65),
                      letterSpacing: 0.5,
                    ),
                  ),

                  const Spacer(flex: 2),

                  // ── Progreso / Error ──────────────────────────
                  if (!_hasError) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: _progress,
                        minHeight: 6,
                        backgroundColor: Colors.white.withOpacity(0.1),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFFFFB74D),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _statusMessage,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${(_progress * 100).toStringAsFixed(0)}%',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFFFFB74D),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ] else ...[
                    const Icon(Icons.error_outline,
                        color: Colors.redAccent, size: 40),
                    const SizedBox(height: 12),
                    Text(
                      _statusMessage,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 15,
                          fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _errorDetail,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: Colors.redAccent, fontSize: 11),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: _initModels,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Reintentar'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFB74D),
                        foregroundColor: Colors.black,
                      ),
                    ),
                  ],

                  const SizedBox(height: 48),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
