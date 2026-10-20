import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa;

/// Servicio de transcripción de voz 100% OFFLINE usando Whisper en formato
/// ONNX a través de sherpa_onnx (NO usa ggml, así que no choca con llamadart).
///
/// Flujo: graba PCM 16 kHz con `record` → al detener, decodifica todo el audio
/// con Whisper y devuelve el texto.
///
/// Mantiene la misma API pública que la versión anterior (Vosk):
/// [initialize], [startRecording], [stopAndTranscribe] y [dispose].
class WhisperService {
  // Carpeta de assets y archivos del modelo (sherpa-onnx-whisper-small).
  static const _assetDir = 'assets/models/whisper_onnx';
  static const _encoderFile = 'small-encoder.int8.onnx';
  static const _decoderFile = 'small-decoder.int8.onnx';
  static const _tokensFile = 'small-tokens.txt';

  static const _sampleRate = 16000;

  static bool _bindingsReady = false;

  final AudioRecorder _recorder = AudioRecorder();

  sherpa.OfflineRecognizer? _recognizer;
  StreamSubscription<Uint8List>? _audioSub;
  final List<Uint8List> _chunks = [];

  bool _isInitialized = false;
  bool _isRecording = false;

  /// Copia el modelo de assets al disco (solo la primera vez) y crea el
  /// reconocedor. El parámetro [modelPath] se ignora (compatibilidad).
  Future<void> initialize([String? modelPath]) async {
    if (_isInitialized) return;

    if (!_bindingsReady) {
      sherpa.initBindings();
      _bindingsReady = true;
    }

    final dir = await _ensureModelFiles();

    final whisper = sherpa.OfflineWhisperModelConfig(
      encoder: '$dir/$_encoderFile',
      decoder: '$dir/$_decoderFile',
      language: 'es',
      task: 'transcribe',
      tailPaddings: 1000,
    );

    final modelConfig = sherpa.OfflineModelConfig(
      whisper: whisper,
      tokens: '$dir/$_tokensFile',
      modelType: 'whisper',
      numThreads: 4,
      debug: false,
    );

    _recognizer = sherpa.OfflineRecognizer(
      sherpa.OfflineRecognizerConfig(model: modelConfig),
    );

    _isInitialized = true;
  }

  /// Copia los 3 archivos del modelo desde assets a almacenamiento interno.
  Future<String> _ensureModelFiles() async {
    final docs = await getApplicationDocumentsDirectory();
    final outDir = Directory('${docs.path}/whisper_onnx');
    await outDir.create(recursive: true);

    for (final name in [_encoderFile, _decoderFile, _tokensFile]) {
      final file = File('${outDir.path}/$name');
      if (file.existsSync() && file.lengthSync() > 0) continue;

      final data = await rootBundle.load('$_assetDir/$name');
      await file.writeAsBytes(
        data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
        flush: true,
      );
    }
    return outDir.path;
  }

  /// Inicia la captura del micrófono.
  Future<void> startRecording() async {
    if (!_isInitialized) await initialize();
    if (_isRecording) return;

    if (!await _recorder.hasPermission()) {
      throw Exception('Permiso de micrófono denegado');
    }

    _chunks.clear();

    final stream = await _recorder.startStream(const RecordConfig(
      encoder: AudioEncoder.pcm16bits,
      sampleRate: _sampleRate,
      numChannels: 1,
    ));
    _audioSub = stream.listen(_chunks.add);
    _isRecording = true;
  }

  /// Detiene la grabación y devuelve la transcripción completa.
  Future<String> stopAndTranscribe() async {
    if (!_isRecording) return '';

    await _recorder.stop();
    await _audioSub?.cancel();
    _audioSub = null;
    _isRecording = false;

    // Une los bloques PCM16 y convierte a Float32 [-1, 1].
    final total = _chunks.fold<int>(0, (s, c) => s + c.length);
    if (total < _sampleRate) return ''; // < 0.5 s de audio
    final bytes = BytesBuilder(copy: false);
    for (final c in _chunks) {
      bytes.add(c);
    }
    _chunks.clear();

    final pcm = bytes.takeBytes();
    final int16 = Int16List.view(pcm.buffer, 0, pcm.length ~/ 2);
    final samples = Float32List(int16.length);
    for (var i = 0; i < int16.length; i++) {
      samples[i] = int16[i] / 32768.0;
    }

    final stream = _recognizer!.createStream();
    try {
      stream.acceptWaveform(samples: samples, sampleRate: _sampleRate);
      _recognizer!.decode(stream);
      final text = _recognizer!.getResult(stream).text.trim();
      debugPrint('Whisper => "$text"');
      return text;
    } finally {
      stream.free();
    }
  }

  void dispose() {
    _audioSub?.cancel();
    _recorder.dispose();
    _recognizer?.free();
    _recognizer = null;
    _isInitialized = false;
  }
}
