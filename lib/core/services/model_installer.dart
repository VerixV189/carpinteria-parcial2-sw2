import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

class ModelInstaller {
  static String? _whisperModelPath;
  static String? _llmModelPath;

  static String get whisperModelPath => _whisperModelPath!;
  static String get llmModelPath => _llmModelPath!;

  /// Llamado por [SplashPage] después de copiar los modelos al disco.
  /// Registra los paths finales para que el resto de la app los use.
  static void setResolvedPaths({
    required String whisperPath,
    required String llmPath,
  }) {
    _whisperModelPath = whisperPath;
    _llmModelPath = llmPath;
  }

  /// @deprecated Usa [SplashPage] en su lugar, que muestra progreso al usuario.
  /// Copia los modelos desde assets al almacenamiento local del dispositivo.
  /// Solo copia si no existen ya.
  static Future<void> ensureModelsReady() async {
    final dir = await getApplicationDocumentsDirectory();

    _whisperModelPath = '${dir.path}/ggml-base.bin';
    _llmModelPath = '${dir.path}/Qwen3-1.7B-Q4_K_M.gguf';

    await _copyIfMissing(
      assetPath: 'assets/models/whisper/ggml-base.bin',
      destPath: _whisperModelPath!,
      label: 'Whisper',
    );

    await _copyIfMissing(
      assetPath: 'assets/models/llm/Qwen3-1.7B-Q4_K_M.gguf',
      destPath: _llmModelPath!,
      label: 'LLM (Qwen3)',
    );
  }

  static Future<void> _copyIfMissing({
    required String assetPath,
    required String destPath,
    required String label,
  }) async {
    final file = File(destPath);

    if (file.existsSync()) {
      print('[$label] Modelo ya existe en disco: $destPath');
      return;
    }

    print('[$label] Copiando modelo desde assets...');
    final data = await rootBundle.load(assetPath);
    await file.writeAsBytes(data.buffer.asUint8List());
    print('[$label] Copia completada: $destPath');
  }
}