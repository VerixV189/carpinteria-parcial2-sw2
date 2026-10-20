import 'package:flutter/material.dart';
import 'package:carpinteria_movil_sw2/core/services/whisper_service.dart';
import 'package:carpinteria_movil_sw2/core/services/llm_service.dart';
import 'package:carpinteria_movil_sw2/core/services/model_installer.dart';
import 'package:carpinteria_movil_sw2/core/services/report_export_service.dart';
import 'package:carpinteria_movil_sw2/theme/app_theme.dart';

class VoiceTestPage extends StatefulWidget {
  final String? initialQuery;

  const VoiceTestPage({super.key, this.initialQuery});

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
  bool _sqlReportMode = true;

  String _llmResponse = '';
  AiSqlReportResult? _sqlReportResult;
  String _statusMessage = 'Inicializando modelos offline (Whisper + Qwen3)...';

  @override
  void initState() {
    super.initState();
    if (widget.initialQuery != null && widget.initialQuery!.isNotEmpty) {
      _controller.text = widget.initialQuery!;
    }
    _initServices();
  }

  Future<void> _initServices() async {
    try {
      await _whisperService.initialize();
      if (ModelInstaller.llmModelPath.isNotEmpty) {
        await _llmService.loadModel(ModelInstaller.llmModelPath);
      }

      if (!mounted) return;
      setState(() {
        _isInitialized = true;
        _statusMessage = 'Listo. Habla con el micrófono o genera tu reporte.';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isInitialized = true; // Permite usar el motor SQLite aun si el modelo GGUF falla
        _statusMessage = 'Modo SQLite activo (Detalle IA: $e)';
      });
    }
  }

  Future<void> _toggleRecording() async {
    if (!_isInitialized) return;

    if (_isRecording) {
      setState(() {
        _isRecording = false;
        _isTranscribing = true;
        _statusMessage = 'Transcribiendo voz offline con Whisper ONNX...';
      });

      try {
        final transcript = await _whisperService.stopAndTranscribe();
        if (!mounted) return;
        setState(() {
          _controller.text = transcript;
          _isTranscribing = false;
          _statusMessage = 'Transcripción lista. Presiona Generar Informe.';
        });
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _isTranscribing = false;
          _statusMessage = 'Error al transcribir: $e';
        });
      }
    } else {
      await _whisperService.startRecording();
      if (!mounted) return;
      setState(() {
        _isRecording = true;
        _statusMessage = 'Grabando voz... Presiona de nuevo para detener.';
      });
    }
  }

  Future<void> _processRequest() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isThinking) return;

    setState(() {
      _isThinking = true;
      _llmResponse = '';
      _sqlReportResult = null;
      _statusMessage = _sqlReportMode
          ? 'Validando seguridad, generando SQL y consultando SQLite...'
          : 'Consultando al asistente experto de carpintería...';
    });

    try {
      if (_sqlReportMode) {
        final report = await _llmService.generateSqlReport(text);
        if (!mounted) return;
        setState(() {
          _sqlReportResult = report;
          _isThinking = false;
          _statusMessage =
              'Informe generado (${report.rows.length} registros en SQLite).';
        });
      } else {
        final response = await _llmService.generate(text);
        if (!mounted) return;
        setState(() {
          _llmResponse = response;
          _isThinking = false;
          _statusMessage = 'Respuesta recibida.';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _llmResponse = '$e';
        _isThinking = false;
        _statusMessage = 'Operación detenida por validación o error.';
      });
    }
  }

  Future<void> _exportReport(String format) async {
    final report = _sqlReportResult;
    if (report == null) return;

    final messenger = ScaffoldMessenger.of(context);
    try {
      String path;
      if (format == 'pdf') {
        path = await ReportExportService.exportToPdf(
          title: 'Reporte de Datos Locales (Text-to-SQL)',
          userQuery: report.userQuery,
          sqlExecuted: report.sqlExecuted,
          aiConclusion: report.aiConclusion,
          rows: report.rows,
        );
      } else if (format == 'excel') {
        path = await ReportExportService.exportToExcel(
          userQuery: report.userQuery,
          sqlExecuted: report.sqlExecuted,
          aiConclusion: report.aiConclusion,
          rows: report.rows,
        );
      } else {
        path = await ReportExportService.exportToCsv(
          userQuery: report.userQuery,
          aiConclusion: report.aiConclusion,
          rows: report.rows,
        );
      }
      messenger.showSnackBar(
        SnackBar(content: Text('Archivo generado: $path')),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Error al exportar: $e'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _whisperService.dispose();
    _llmService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Asistente Voz + Informes SQL'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Estado actual
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.primaryWood.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                _statusMessage,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryDarkWood,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 12),

            // Selector de modo: Informe SQLite vs Consulta libre
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(
                  value: true,
                  icon: Icon(Icons.storage_rounded),
                  label: Text('Informe BD Local (SQL)'),
                ),
                ButtonSegment(
                  value: false,
                  icon: Icon(Icons.chat_bubble_outline_rounded),
                  label: Text('Consulta Libre IA'),
                ),
              ],
              selected: {_sqlReportMode},
              onSelectionChanged: (s) {
                setState(() => _sqlReportMode = s.first);
              },
            ),
            const SizedBox(height: 12),

            // Chips rápidos de prueba
            if (_sqlReportMode) ...[
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _QuickPromptChip(
                      label: 'Pedidos pendientes',
                      onTap: () {
                        _controller.text =
                            'Muestra los pedidos pendientes y su saldo por cobrar';
                        _processRequest();
                      },
                    ),
                    const SizedBox(width: 8),
                    _QuickPromptChip(
                      label: 'Maderas en alerta de stock',
                      onTap: () {
                        _controller.text =
                            'Lista los materiales y maderas con stock bajo en alerta';
                        _processRequest();
                      },
                    ),
                    const SizedBox(width: 8),
                    _QuickPromptChip(
                      label: 'Muebles de Roble',
                      onTap: () {
                        _controller.text =
                            'Muestra todos los pedidos trabajados en madera Roble';
                        _processRequest();
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
            ],

            // Campo de texto editable con la transcripción
            TextField(
              controller: _controller,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Dicta con el micrófono o escribe tu solicitud de informe',
                hintText:
                    'Ej: Dame un informe de los pedidos pendientes en madera Roble',
              ),
            ),
            const SizedBox(height: 14),

            // Fila con Micrófono y Botón de Procesar
            Row(
              children: [
                GestureDetector(
                  onTap: _toggleRecording,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _isRecording
                          ? Colors.red
                          : (_isInitialized ? AppTheme.primaryWood : Colors.grey),
                      boxShadow: _isRecording
                          ? [
                              BoxShadow(
                                color: Colors.red.withValues(alpha: 0.45),
                                blurRadius: 16,
                                spreadRadius: 3,
                              )
                            ]
                          : [],
                    ),
                    child: Icon(
                      _isTranscribing
                          ? Icons.hourglass_top
                          : (_isRecording ? Icons.stop : Icons.mic),
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed:
                          (_isThinking || _isRecording) ? null : _processRequest,
                      icon: _isThinking
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Icon(
                              _sqlReportMode
                                  ? Icons.analytics_outlined
                                  : Icons.send_rounded,
                            ),
                      label: Text(
                        _isThinking
                            ? 'Procesando...'
                            : (_sqlReportMode
                                ? 'Generar Informe SQL + IA'
                                : 'Consultar al Asistente'),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Resultado del Informe Text-to-SQL + Botones PDF / Excel / CSV
            if (_sqlReportResult != null) ...[
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(
                            Icons.verified_user_rounded,
                            color: Colors.green,
                            size: 20,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'Consulta SQL Validada (Solo Lectura)',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13.5,
                              color: AppTheme.primaryDarkWood,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade900,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _sqlReportResult!.sqlExecuted,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 11.5,
                            color: Colors.greenAccent,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Conclusión Ejecutiva IA:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryDarkWood,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _sqlReportResult!.aiConclusion,
                        style: const TextStyle(fontSize: 13.5),
                      ),
                      const SizedBox(height: 14),

                      // Botones de Exportación: PDF, Excel, CSV
                      const Text(
                        'Exportar Informe:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: FilledButton.icon(
                              style: FilledButton.styleFrom(
                                backgroundColor: Colors.red.shade700,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 10),
                              ),
                              onPressed: () => _exportReport('pdf'),
                              icon: const Icon(Icons.picture_as_pdf, size: 18),
                              label: const Text('PDF'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: FilledButton.icon(
                              style: FilledButton.styleFrom(
                                backgroundColor: Colors.green.shade700,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 10),
                              ),
                              onPressed: () => _exportReport('excel'),
                              icon: const Icon(Icons.table_view_rounded, size: 18),
                              label: const Text('Excel'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: FilledButton.icon(
                              style: FilledButton.styleFrom(
                                backgroundColor: Colors.blueGrey.shade700,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 10),
                              ),
                              onPressed: () => _exportReport('csv'),
                              icon: const Icon(Icons.description_outlined, size: 18),
                              label: const Text('CSV'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Vista previa de la tabla SQLite
                      Text(
                        'Vista previa de datos (${_sqlReportResult!.rows.length} filas):',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 6),
                      if (_sqlReportResult!.rows.isEmpty)
                        const Text('Sin registros para esta consulta.')
                      else
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            headingRowHeight: 36,
                            dataRowMinHeight: 32,
                            dataRowMaxHeight: 42,
                            columns: _sqlReportResult!.rows.first.keys
                                .map(
                                  (k) => DataColumn(
                                    label: Text(
                                      k.toUpperCase(),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 11.5,
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                            rows: _sqlReportResult!.rows
                                .map(
                                  (r) => DataRow(
                                    cells: r.values
                                        .map(
                                          (v) => DataCell(
                                            Text(
                                              (v ?? '').toString(),
                                              style: const TextStyle(fontSize: 12),
                                            ),
                                          ),
                                        )
                                        .toList(),
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],

            // Respuesta en modo libre o error de validación
            if (_llmResponse.isNotEmpty) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Respuesta:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      Text(_llmResponse),
                    ],
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

class _QuickPromptChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _QuickPromptChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: const Icon(Icons.auto_awesome, size: 15),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      onPressed: onTap,
    );
  }
}
