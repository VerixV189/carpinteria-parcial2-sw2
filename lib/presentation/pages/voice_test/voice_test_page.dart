import 'package:flutter/material.dart';
import 'package:carpinteria_movil_sw2/core/services/whisper_service.dart';
import 'package:carpinteria_movil_sw2/core/services/llm_service.dart';
import 'package:carpinteria_movil_sw2/core/services/model_installer.dart';

class VoiceTestPage extends StatefulWidget {
  const VoiceTestPage({super.key});

  @override
  State<VoiceTestPage> createState() => _VoiceTestPageState();
}

class _VoiceTestPageState extends State<VoiceTestPage> {
  final _controller = TextEditingController();
  final _whisperService = WhisperService();
  final _llmService = LlmService();

  bool _isInitialized = false;
  bool _isRecording = false;
  bool _isTranscribing = false;
  bool _isThinking = false;
  String _llmResponse = '';
  String _statusMessage = 'Inicializando modelos...';

  @override
  void initState() {
    super.initState();
    _initServices();
  }

  Future<void> _initServices() async {
    try {
      // Inicializar reconocimiento de voz nativo (no necesita modelo en disco)
      await _whisperService.initialize();
      // Cargar el LLM
      await _llmService.loadModel(ModelInstaller.llmModelPath);

      setState(() {
        _isInitialized = true;
        _statusMessage = 'Listo. Presiona el micrófono para hablar.';
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Error al inicializar: $e';
      });
    }
  }

  Future<void> _toggleRecording() async {
    if (!_isInitialized) return;

    if (_isRecording) {
      // --- Detener grabación y transcribir ---
      setState(() {
        _isRecording = false;
        _isTranscribing = true;
        _statusMessage = 'Transcribiendo...';
      });

      try {
        final transcript = await _whisperService.stopAndTranscribe();
        setState(() {
          _controller.text = transcript;
          _isTranscribing = false;
          _statusMessage = 'Transcripción lista. Puedes editarla o enviarla.';
        });
      } catch (e) {
        setState(() {
          _isTranscribing = false;
          _statusMessage = 'Error al transcribir: $e';
        });
      }
    } else {
      // --- Iniciar grabación ---
      await _whisperService.startRecording();
      setState(() {
        _isRecording = true;
        _statusMessage = 'Grabando... Presiona de nuevo para detener.';
      });
    }
  }

  Future<void> _sendToLlm() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isThinking) return;

    setState(() {
      _isThinking = true;
      _llmResponse = '';
      _statusMessage = 'Consultando al asistente de carpintería...';
    });

    try {
      final response = await _llmService.generate(text);
      setState(() {
        _llmResponse = response;
        _isThinking = false;
        _statusMessage = 'Respuesta recibida.';
      });
    } catch (e) {
      setState(() {
        _llmResponse = 'Error: $e';
        _isThinking = false;
        _statusMessage = 'Error al consultar el LLM.';
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _whisperService.dispose();
    _llmService.dispose(); // fire-and-forget, no podemos await en dispose()
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Prueba de Voz + IA'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Estado actual
            Text(
              _statusMessage,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),

            // Campo de texto editable con la transcripción
            TextField(
              controller: _controller,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Texto (transcripción o escribe manualmente)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // Botón de micrófono
            Center(
              child: GestureDetector(
                onTap: _toggleRecording,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _isRecording
                        ? Colors.red
                        : (_isInitialized ? Colors.blue : Colors.grey),
                    boxShadow: _isRecording
                        ? [
                            BoxShadow(
                              color: Colors.red.withOpacity(0.5),
                              blurRadius: 20,
                              spreadRadius: 5,
                            )
                          ]
                        : [],
                  ),
                  child: Icon(
                    _isTranscribing
                        ? Icons.hourglass_top
                        : (_isRecording ? Icons.stop : Icons.mic),
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _isRecording ? 'Grabando...' : 'Toca para hablar',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 16),

            // Botón enviar al LLM
            ElevatedButton.icon(
              onPressed: (_isThinking || _isRecording) ? null : _sendToLlm,
              icon: _isThinking
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send),
              label: Text(_isThinking ? 'Procesando...' : 'Enviar al asistente IA'),
            ),
            const SizedBox(height: 16),

            // Respuesta del LLM
            if (_llmResponse.isNotEmpty) ...[
              const Text(
                'Respuesta del asistente:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: SingleChildScrollView(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Text(_llmResponse),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}