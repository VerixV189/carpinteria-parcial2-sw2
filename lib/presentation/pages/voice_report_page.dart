import 'package:flutter/material.dart';
import 'package:carpinteria_movil_sw2/core/services/model_installer.dart';
import 'package:carpinteria_movil_sw2/presentation/pages/splash/splash_page.dart';
import 'package:carpinteria_movil_sw2/presentation/pages/voice_test/voice_test_page.dart';
import 'package:carpinteria_movil_sw2/theme/app_theme.dart';

class VoiceReportPage extends StatelessWidget {
  const VoiceReportPage({super.key});

  void _openVoiceAssistant(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            ModelInstaller.isReady ? const VoiceTestPage() : const SplashPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ready = ModelInstaller.isReady;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF281100),
                  Color(0xFF5C2E00),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.brown.withValues(alpha: 0.25),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: AppTheme.accentAmber.withValues(alpha: 0.18),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppTheme.accentAmber.withValues(alpha: 0.6),
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.mic_rounded,
                    color: AppTheme.accentAmber,
                    size: 38,
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Asistente de Carpintería por Voz (Offline)',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Impulsado por Whisper ONNX + Qwen3 1.7B ejecutándose 100% en tu dispositivo sin requerir internet.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: ready
                        ? Colors.green.withValues(alpha: 0.2)
                        : Colors.orange.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        ready ? Icons.check_circle : Icons.downloading_rounded,
                        size: 16,
                        color: ready ? Colors.greenAccent : AppTheme.accentAmber,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        ready
                            ? 'Modelos IA listos en memoria'
                            : 'Se cargarán los modelos al abrir el asistente',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _openVoiceAssistant(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accentAmber,
                      foregroundColor: Colors.black87,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    icon: const Icon(Icons.record_voice_over_rounded),
                    label: Text(
                      ready
                          ? 'Abrir Asistente de Voz'
                          : 'Preparar Modelos y Abrir Asistente',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Consultas frecuentes sugeridas en el taller',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryDarkWood,
            ),
          ),
          const SizedBox(height: 10),
          _SuggestionTile(
            icon: Icons.straighten_rounded,
            title: 'Cálculo de pies cuadrados (pie²)',
            subtitle:
                'Pregunta: "¿Cuántos pies cuadrados tiene un tablón de 2 pulgadas por 8 pulgadas y 3 metros de largo?"',
            onTap: () => _openVoiceAssistant(context),
          ),
          _SuggestionTile(
            icon: Icons.format_paint_rounded,
            title: 'Recomendación de barnices y selladores',
            subtitle:
                'Pregunta: "¿Qué acabado me recomiendas para una puerta de roble expuesta al sol y lluvia?"',
            onTap: () => _openVoiceAssistant(context),
          ),
          _SuggestionTile(
            icon: Icons.carpenter_rounded,
            title: 'Uniones y ensambles de mueblería',
            subtitle:
                'Pregunta: "¿Cuál es la mejor unión para reforzar sillas de comedor de cedro?"',
            onTap: () => _openVoiceAssistant(context),
          ),
        ],
      ),
    );
  }
}

class _SuggestionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SuggestionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: AppTheme.primaryWood.withValues(alpha: 0.12),
          child: Icon(icon, color: AppTheme.primaryWood),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            subtitle,
            style: const TextStyle(fontSize: 12.5, color: Colors.black54),
          ),
        ),
        trailing: const Icon(Icons.chevron_right_rounded),
      ),
    );
  }
}
