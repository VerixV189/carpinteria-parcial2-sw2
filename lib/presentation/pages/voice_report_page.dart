import 'package:flutter/material.dart';
import 'package:carpinteria_movil_sw2/core/services/llm_service.dart';
import 'package:carpinteria_movil_sw2/core/services/model_installer.dart';
import 'package:carpinteria_movil_sw2/core/services/report_export_service.dart';
import 'package:carpinteria_movil_sw2/presentation/pages/splash/splash_page.dart';
import 'package:carpinteria_movil_sw2/presentation/pages/voice_test/voice_test_page.dart';
import 'package:carpinteria_movil_sw2/theme/app_theme.dart';

class VoiceReportPage extends StatefulWidget {
  const VoiceReportPage({super.key});

  @override
  State<VoiceReportPage> createState() => _VoiceReportPageState();
}

class _VoiceReportPageState extends State<VoiceReportPage> {
  final _llmService = LlmService();
  AiSqlReportResult? _quickReport;
  bool _loadingQuick = false;

  void _openVoiceAssistant(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            ModelInstaller.isReady ? const VoiceTestPage() : const SplashPage(),
      ),
    );
  }

  Future<void> _runQuickOfflineReport(String requestText) async {
    setState(() => _loadingQuick = true);
    try {
      final res = await _llmService.generateSqlReport(requestText);
      if (!mounted) return;
      setState(() {
        _quickReport = res;
        _loadingQuick = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingQuick = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$e'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
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
            padding: const EdgeInsets.all(20),
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
                  width: 68,
                  height: 68,
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
                    size: 36,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Asistente IA + Informes Text-to-SQL',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Whisper ONNX + Qwen3 1.7B + SQLite Local.\nGenera consultas SQL seguras sin internet y exporta a PDF, Excel y CSV.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: Colors.white.withValues(alpha: 0.82),
                  ),
                ),
                const SizedBox(height: 14),
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
                          ? 'Abrir Asistente de Voz Completo'
                          : 'Cargar Modelos IA y Abrir Asistente por Voz',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          const Text(
            'Generar Informes Rápidos desde SQLite Local (PDF / Excel / CSV)',
            style: TextStyle(
              fontSize: 15.5,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryDarkWood,
            ),
          ),
          const SizedBox(height: 10),

          _SuggestionTile(
            icon: Icons.pending_actions_rounded,
            title: 'Informe de Pedidos Pendientes y Saldos',
            subtitle:
                'Ejecuta SELECT seguro en SQLite sobre pedidos pendientes y exporta en PDF, Excel o CSV.',
            onTap: () => _runQuickOfflineReport(
              'Informe de todos los pedidos pendientes con su monto total y saldo por cobrar',
            ),
          ),
          _SuggestionTile(
            icon: Icons.warning_amber_rounded,
            title: 'Informe de Maderas e Insumos con Stock Bajo',
            subtitle:
                'Consulta la tabla materiales filtrando insumos con alerta de reposición.',
            onTap: () => _runQuickOfflineReport(
              'Informe de materiales y maderas con stock bajo en alerta',
            ),
          ),
          _SuggestionTile(
            icon: Icons.chair_rounded,
            title: 'Informe General de Catálogo y Precios',
            subtitle:
                'Consulta la tabla productos en SQLite con dimensiones, maderas y precios.',
            onTap: () => _runQuickOfflineReport(
              'Listado completo del catálogo de productos y precios de la carpintería',
            ),
          ),

          if (_loadingQuick)
            const Padding(
              padding: EdgeInsets.all(20),
              child: Center(child: CircularProgressIndicator()),
            ),

          if (_quickReport != null) ...[
            const SizedBox(height: 12),
            Card(
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.shield_outlined,
                          color: Colors.green,
                          size: 20,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Resultado SQLite (${_quickReport!.rows.length} registros)',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: AppTheme.primaryDarkWood,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade900,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _quickReport!.sqlExecuted,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 11,
                          color: Colors.greenAccent,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _quickReport!.aiConclusion,
                      style: const TextStyle(fontSize: 13),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton.icon(
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.red.shade700,
                            ),
                            onPressed: () => ReportExportService.exportToPdf(
                              title: 'Reporte Offline SQLite',
                              userQuery: _quickReport!.userQuery,
                              sqlExecuted: _quickReport!.sqlExecuted,
                              aiConclusion: _quickReport!.aiConclusion,
                              rows: _quickReport!.rows,
                            ),
                            icon: const Icon(Icons.picture_as_pdf, size: 17),
                            label: const Text('PDF'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: FilledButton.icon(
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.green.shade700,
                            ),
                            onPressed: () => ReportExportService.exportToExcel(
                              userQuery: _quickReport!.userQuery,
                              sqlExecuted: _quickReport!.sqlExecuted,
                              aiConclusion: _quickReport!.aiConclusion,
                              rows: _quickReport!.rows,
                            ),
                            icon: const Icon(Icons.table_view_rounded, size: 17),
                            label: const Text('Excel'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: FilledButton.icon(
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.blueGrey.shade700,
                            ),
                            onPressed: () => ReportExportService.exportToCsv(
                              userQuery: _quickReport!.userQuery,
                              aiConclusion: _quickReport!.aiConclusion,
                              rows: _quickReport!.rows,
                            ),
                            icon: const Icon(Icons.description_outlined, size: 17),
                            label: const Text('CSV'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
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
        trailing: const Icon(Icons.play_circle_outline_rounded),
      ),
    );
  }
}
