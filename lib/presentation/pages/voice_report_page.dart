import 'package:flutter/material.dart';
import 'package:carpinteria_movil_sw2/core/services/llm_service.dart';
import 'package:carpinteria_movil_sw2/core/services/model_installer.dart';
import 'package:carpinteria_movil_sw2/core/services/report_export_service.dart';
import 'package:carpinteria_movil_sw2/domain/entities/entity.dart';
import 'package:carpinteria_movil_sw2/presentation/pages/splash/splash_page.dart';
import 'package:carpinteria_movil_sw2/presentation/pages/voice_test/voice_test_page.dart';
import 'package:carpinteria_movil_sw2/presentation/providers/app_provider.dart';
import 'package:carpinteria_movil_sw2/theme/app_theme.dart';

class VoiceReportPage extends StatefulWidget {
  const VoiceReportPage({super.key});

  @override
  State<VoiceReportPage> createState() => _VoiceReportPageState();
}

class _VoiceReportPageState extends State<VoiceReportPage> {
  final _llmService = LlmService();
  final _onlineQueryCtrl = TextEditingController();
  final _agentQueryCtrl = TextEditingController();

  bool _useOnlineBackend = true;
  bool _loadingReport = false;
  bool _loadingAgent = false;

  AiSqlReportResult? _quickReport;
  OnlineNlReportEntity? _onlineReport;
  OnlineAgentReplyEntity? _agentReply;

  @override
  void dispose() {
    _onlineQueryCtrl.dispose();
    _agentQueryCtrl.dispose();
    super.dispose();
  }

  void _openVoiceAssistant(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            ModelInstaller.isReady ? const VoiceTestPage() : const SplashPage(),
      ),
    );
  }

  Future<void> _askOnlineMcpAgent([String? preset]) async {
    final q = (preset ?? _agentQueryCtrl.text).trim();
    if (q.isEmpty) return;
    _agentQueryCtrl.text = q;
    setState(() => _loadingAgent = true);
    try {
      final provider = AppScope.of(context);
      final reply = await provider.askOnlineAgent(
        query: q,
        sessionId: 'taller-${provider.currentUser?.email ?? "admin"}',
      );
      if (!mounted) return;
      setState(() {
        _agentReply = reply;
        _loadingAgent = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingAgent = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Agente Online no disponible, usa modo local: $e'),
          backgroundColor: Colors.orange.shade800,
        ),
      );
    }
  }

  Future<void> _runReport(String requestText) async {
    setState(() {
      _loadingReport = true;
      _onlineReport = null;
      _quickReport = null;
    });

    if (_useOnlineBackend) {
      try {
        final provider = AppScope.of(context);
        final res = await provider.generateOnlineReport(requestText);
        if (!mounted) return;
        setState(() {
          _onlineReport = res;
          _loadingReport = false;
        });
        return;
      } catch (_) {
        // Si falla el backend online, ejecuta el fallback local SQLite
      }
    }

    try {
      final res = await _llmService.generateSqlReport(requestText);
      if (!mounted) return;
      setState(() {
        _quickReport = res;
        _loadingReport = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingReport = false);
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

    final activeQuery = _onlineReport?.query ?? _quickReport?.userQuery ?? '';
    final activeSql = _onlineReport?.sql ?? _quickReport?.sqlExecuted ?? '';
    final activeConclusion =
        _onlineReport?.narrative ?? _quickReport?.aiConclusion ?? '';
    final activeRows = _onlineReport?.rows ?? _quickReport?.rows ?? const [];
    final activeSource = _onlineReport != null
        ? 'PostgreSQL Online (${_onlineReport!.source})'
        : 'SQLite Local Offline';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Banner Principal Voz + IA ──────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(18),
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
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: AppTheme.accentAmber.withValues(alpha: 0.18),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppTheme.accentAmber.withValues(alpha: 0.6),
                        ),
                      ),
                      child: const Icon(
                        Icons.mic_rounded,
                        color: AppTheme.accentAmber,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Agente IA MCP Online + Voz Offline (CU7)',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'Backend3 Python IA (/api/ai/agent • /api/ai/report) + Whisper ONNX + Qwen3 + SQLite.',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: Colors.white.withValues(alpha: 0.82),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _openVoiceAssistant(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accentAmber,
                      foregroundColor: Colors.black87,
                    ),
                    icon: const Icon(Icons.record_voice_over_rounded),
                    label: Text(
                      ready
                          ? 'Abrir Consola de Voz Interactiva (Whisper + Qwen3)'
                          : 'Cargar Modelos de Voz IA On-Device',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Agente Operativo MCP Online (/api/ai/agent) ────────────────────
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.smart_toy_outlined, color: AppTheme.primaryWood),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Agente Operativo MCP Online (/api/ai/agent)',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: AppTheme.primaryDarkWood,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      ActionChip(
                        label: const Text(
                          '¿Qué materiales tienen stock bajo?',
                          style: TextStyle(fontSize: 11.5),
                        ),
                        onPressed: () => _askOnlineMcpAgent(
                          '¿Qué materiales tienen stock bajo en inventario?',
                        ),
                      ),
                      ActionChip(
                        label: const Text(
                          '¿Hay entrega disponible mañana?',
                          style: TextStyle(fontSize: 11.5),
                        ),
                        onPressed: () => _askOnlineMcpAgent(
                          '¿Hay cupos de entrega disponibles para mañana?',
                        ),
                      ),
                      ActionChip(
                        label: const Text(
                          'Estado del pedido #1',
                          style: TextStyle(fontSize: 11.5),
                        ),
                        onPressed: () =>
                            _askOnlineMcpAgent('Consulta el estado del pedido 1'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _agentQueryCtrl,
                          onSubmitted: (_) => _askOnlineMcpAgent(),
                          decoration: const InputDecoration(
                            hintText:
                                'Pregunta al Agente MCP (pedidos, stock, entregas)...',
                            isDense: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilledButton.icon(
                        onPressed:
                            _loadingAgent ? null : () => _askOnlineMcpAgent(),
                        icon: _loadingAgent
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.send_rounded, size: 16),
                        label: const Text('Consultar'),
                      ),
                    ],
                  ),
                  if (_agentReply != null) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.warmCream,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppTheme.primaryWood.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_agentReply!.tool != null)
                            Text(
                              'Tool MCP: ${_agentReply!.tool} • Fuente: ${_agentReply!.source}',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryWood,
                              ),
                            ),
                          const SizedBox(height: 4),
                          Text(
                            _agentReply!.answer,
                            style: const TextStyle(fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ── Generador de Reportes NL (Online PostgreSQL vs Offline SQLite) ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text(
                  'Reportes NL Text-to-SQL (PDF / Excel / CSV)',
                  style: TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryDarkWood,
                  ),
                ),
              ),
              Row(
                children: [
                  Text(
                    _useOnlineBackend ? 'Online PG' : 'Local SQLite',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Switch(
                    value: _useOnlineBackend,
                    onChanged: (v) => setState(() => _useOnlineBackend = v),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _onlineQueryCtrl,
                  onSubmitted: (v) {
                    if (v.trim().isNotEmpty) _runReport(v.trim());
                  },
                  decoration: const InputDecoration(
                    hintText:
                        'Ej: ¿Cuánto se vendió este mes? o Pedidos pendientes',
                    isDense: true,
                    prefixIcon: Icon(Icons.analytics_outlined),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: () {
                  if (_onlineQueryCtrl.text.trim().isNotEmpty) {
                    _runReport(_onlineQueryCtrl.text.trim());
                  }
                },
                child: const Text('Generar'),
              ),
            ],
          ),
          const SizedBox(height: 10),

          _SuggestionTile(
            icon: Icons.monetization_on_outlined,
            title: 'Ventas Totales del Mes (Online PostgreSQL / Local)',
            subtitle:
                'Consulta ingresos facturados y pedidos activos en lenguaje natural.',
            onTap: () => _runReport('¿Cuánto se vendió este mes?'),
          ),
          _SuggestionTile(
            icon: Icons.pending_actions_rounded,
            title: 'Informe de Pedidos Pendientes y en Producción',
            subtitle:
                'Ejecuta consulta segura sobre pedidos pendientes y exporta en PDF, Excel o CSV.',
            onTap: () => _runReport(
              'Informe de todos los pedidos pendientes con su monto total',
            ),
          ),
          _SuggestionTile(
            icon: Icons.warning_amber_rounded,
            title: 'Informe de Maderas e Insumos con Stock Bajo',
            subtitle:
                'Consulta materiales con cantidad menor o igual al punto de reorden.',
            onTap: () => _runReport(
              'Informe de materiales y maderas con stock bajo en alerta',
            ),
          ),
          _SuggestionTile(
            icon: Icons.people_outline_rounded,
            title: 'Ranking de Clientes Frecuentes y Mayor Gasto',
            subtitle:
                'Analiza los clientes con más pedidos e inversión acumulada.',
            onTap: () => _runReport('Clientes frecuentes con mayor gasto'),
          ),

          if (_loadingReport)
            const Padding(
              padding: EdgeInsets.all(20),
              child: Center(child: CircularProgressIndicator()),
            ),

          if (_onlineReport != null || _quickReport != null) ...[
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
                          Icons.verified_user_rounded,
                          color: Colors.green,
                          size: 20,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            '$activeSource (${activeRows.length} filas)',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14.5,
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
                        activeSql,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 11,
                          color: Colors.greenAccent,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      activeConclusion,
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
                              title: 'Reporte Carpintería ($activeSource)',
                              userQuery: activeQuery,
                              sqlExecuted: activeSql,
                              aiConclusion: activeConclusion,
                              rows: activeRows,
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
                              userQuery: activeQuery,
                              sqlExecuted: activeSql,
                              aiConclusion: activeConclusion,
                              rows: activeRows,
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
                              userQuery: activeQuery,
                              aiConclusion: activeConclusion,
                              rows: activeRows,
                            ),
                            icon: const Icon(
                              Icons.description_outlined,
                              size: 17,
                            ),
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
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: AppTheme.primaryWood.withValues(alpha: 0.12),
          child: Icon(icon, color: AppTheme.primaryWood),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(fontSize: 12, color: Colors.black54),
        ),
        trailing: const Icon(Icons.play_circle_outline_rounded),
      ),
    );
  }
}
