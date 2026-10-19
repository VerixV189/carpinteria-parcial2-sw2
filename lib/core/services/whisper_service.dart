import 'dart:convert';
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:vosk_flutter/vosk_flutter.dart';

/// Servicio de transcripción de voz 100% OFFLINE usando Vosk.
/// Modelo: vosk-model-small-es-0.42 (español, ~39 MB).
/// Extrae el ZIP manualmente con archive ^4.x para evitar conflicto
/// entre vosk_flutter (necesita archive ^3.x) y llamadart (^4.x).
class WhisperService {
  static const _modelAssetZip = 'assets/models/vosk/vosk-model-small-es-0.42.zip';
  static const _modelDirName  = 'vosk-model-small-es-0.42';

  final VoskFlutterPlugin _vosk = VoskFlutterPlugin.instance();

  Model?         _model;
  Recognizer?    _recognizer;
  SpeechService? _speechService;

  bool _isInitialized = false;
  bool _isRecording   = false;

  final StringBuffer _finalBuffer = StringBuffer();
  String _partialText = '';

  /// Inicializa Vosk: extrae el modelo ZIP al disco (solo la primera vez)
  /// y crea el reconocedor.
  /// El parámetro [modelPath] se ignora (compatibilidad con API anterior).
  Future<void> initialize([String? modelPath]) async {
    if (_isInitialized) return;

    final modelDir = await _ensureModelExtracted();

    _model = await _vosk.createModel(modelDir);
    _recognizer = await _vosk.createRecognizer(
      model:      _model!,
      sampleRate: 16000,
    );

    _isInitialized = true;
  }

  /// Extrae el modelo ZIP desde assets al almacenamiento interno.
  /// Devuelve el path del directorio del modelo.
  /// Si ya existe, lo reutiliza sin extraer de nuevo.
  Future<String> _ensureModelExtracted() async {
    final docsDir  = await getApplicationDocumentsDirectory();
    final modelDir = Directory('${docsDir.path}/$_modelDirName');

    if (modelDir.existsSync()) {
      return modelDir.path;   // Ya extraído en una ejecución anterior
    }

    // Cargar el ZIP desde assets (39 MB — dentro del límite de Dart)
    final data  = await rootBundle.load(_modelAssetZip);
    final bytes = data.buffer.asUint8List();

    // Decodificar y extraer con archive ^4.x
    final archive = ZipDecoder().decodeBytes(bytes);
    for (final file in archive.files) {
      final outPath = '${docsDir.path}/${file.name}';
      if (file.isFile) {
        final outFile = File(outPath);
        await outFile.create(recursive: true);
        await outFile.writeAsBytes(file.content as List<int>);
      } else {
        await Directory(outPath).create(recursive: true);
      }
    }

    return modelDir.path;
  }

  /// Inicia la captura del micrófono y el reconocimiento en tiempo real.
  Future<void> startRecording() async {
    if (!_isInitialized) await initialize();
    if (_isRecording) return;

    _finalBuffer.clear();
    _partialText = '';

    _speechService = await _vosk.initSpeechService(_recognizer!);

    // Resultados parciales (mientras habla)
    _speechService!.onPartial().listen((json) {
      try {
        final map = jsonDecode(json) as Map<String, dynamic>;
        _partialText = (map['partial'] as String? ?? '').trim();
      } catch (_) {}
    });

    // Resultados finales (al detectar pausa)
    _speechService!.onResult().listen((json) {
      try {
        final map  = jsonDecode(json) as Map<String, dynamic>;
        final text = (map['text'] as String? ?? '').trim();
        if (text.isNotEmpty) {
          if (_finalBuffer.isNotEmpty) _finalBuffer.write(' ');
          _finalBuffer.write(text);
        }
        _partialText = '';
      } catch (_) {}
    });

    await _speechService!.start();
    _isRecording = true;
  }

  /// Detiene la grabación y devuelve la transcripción completa.
  Future<String> stopAndTranscribe() async {
    if (!_isRecording || _speechService == null) return '';

    await _speechService!.stop();
    _isRecording = false;

    final pending = _partialText.trim();
    if (pending.isNotEmpty) {
      if (_finalBuffer.isNotEmpty) _finalBuffer.write(' ');
      _finalBuffer.write(pending);
    }

    final result = _finalBuffer.toString().trim();
    _finalBuffer.clear();
    _partialText = '';
    return result;
  }

  void dispose() {
    _speechService?.stop();
    _recognizer?.dispose();
    _model?.dispose();
    _isInitialized = false;
  }
}
