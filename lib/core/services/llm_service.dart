import 'package:llamadart/llamadart.dart';

class LlmService {
  LlamaEngine? _engine;
  ChatSession? _session;

  /// Carga el modelo LLM desde el path en disco.
  /// Es una operación lenta (~segundos). Llama esto una vez al iniciar.
  Future<void> loadModel(String modelPath) async {
    _engine = await LlamaEngine.load(
      LlamaModel(ModelSource.path(modelPath)),
    );

    _session = ChatSession(
      _engine!,
      systemPrompt:
          'Eres un asistente experto en carpintería. '
          'Responde de forma clara, concisa y en español.',
    );
  }

  /// Envía un mensaje al LLM y devuelve la respuesta completa como String.
  Future<String> generate(String userMessage) async {
    if (_session == null) {
      throw Exception('El modelo LLM no ha sido cargado. Llama loadModel() primero.');
    }

    final reply = await _session!.send(userMessage);
    return reply.text.trim();
  }

  Future<void> dispose() async {
    await _engine?.dispose();
    _engine = null;
    _session = null;
  }
}