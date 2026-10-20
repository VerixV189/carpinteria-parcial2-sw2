import 'dart:io';
import 'package:csv/csv.dart';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

class ReportExportService {
  /// Genera un documento PDF profesional con la consulta, conclusión de la IA
  /// y la tabla completa de resultados SQLite, abriendo el diálogo nativo para
  /// previsualizar, guardar o compartir.
  static Future<String> exportToPdf({
    required String title,
    required String userQuery,
    required String sqlExecuted,
    required String aiConclusion,
    required List<Map<String, dynamic>> rows,
  }) async {
    final doc = pw.Document();
    final now = DateTime.now();
    final dateStr =
        '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    final headers = rows.isNotEmpty
        ? rows.first.keys.map((k) => k.toUpperCase()).toList()
        : <String>['SIN RESULTADOS'];

    final dataMatrix = rows.isNotEmpty
        ? rows
            .map((r) => r.values.map((v) => (v ?? '').toString()).toList())
            .toList()
        : [
            ['La consulta no devolvió registros']
          ];

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        build: (context) => [
          // Encabezado del Informe
          pw.Container(
            padding: const pw.EdgeInsets.all(14),
            decoration: pw.BoxDecoration(
              color: PdfColor.fromHex('#3E1C00'),
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'CARPINTERÍA EL ROBLE - INFORME INTELIGENTE',
                      style: pw.TextStyle(
                        color: PdfColors.white,
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      title,
                      style: pw.TextStyle(
                        color: PdfColor.fromHex('#FFB74D'),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                pw.Text(
                  'Fecha: $dateStr',
                  style: const pw.TextStyle(
                    color: PdfColors.white,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 14),

          // Solicitud y Resumen Ejecutivo IA
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: PdfColor.fromHex('#FAF6F1'),
              border: pw.Border.all(color: PdfColor.fromHex('#C67C3B')),
              borderRadius: pw.BorderRadius.circular(6),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Solicitud del usuario: "$userQuery"',
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 6),
                pw.Text(
                  'Análisis Ejecutivo (IA Local):',
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColor.fromHex('#6D3B14'),
                  ),
                ),
                pw.SizedBox(height: 3),
                pw.Text(
                  aiConclusion,
                  style: const pw.TextStyle(fontSize: 9.5),
                ),
                pw.SizedBox(height: 6),
                pw.Text(
                  'SQL Verificado: $sqlExecuted',
                  style: const pw.TextStyle(
                    fontSize: 8,
                    color: PdfColors.grey700,
                  ),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 14),

          // Tabla de datos extraída de SQLite
          pw.Text(
            'Registros encontrados (${rows.length}):',
            style: pw.TextStyle(
              fontSize: 11,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 6),
          pw.TableHelper.fromTextArray(
            headers: headers,
            data: dataMatrix,
            headerStyle: pw.TextStyle(
              color: PdfColors.white,
              fontSize: 8.5,
              fontWeight: pw.FontWeight.bold,
            ),
            headerDecoration: pw.BoxDecoration(
              color: PdfColor.fromHex('#6D3B14'),
            ),
            cellStyle: const pw.TextStyle(fontSize: 8),
            cellAlignment: pw.Alignment.centerLeft,
            oddRowDecoration: pw.BoxDecoration(
              color: PdfColor.fromHex('#F5EFEA'),
            ),
          ),
        ],
      ),
    );

    final bytes = await doc.save();
    final dir = await getApplicationDocumentsDirectory();
    final fileName =
        'informe_carpinteria_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(bytes, flush: true);

    await Printing.sharePdf(bytes: bytes, filename: fileName);
    return file.path;
  }

  /// Genera un archivo Microsoft Excel (.xlsx) con los resultados de la consulta
  /// SQLite y el análisis de la IA, y abre el menú de compartir.
  static Future<String> exportToExcel({
    required String userQuery,
    required String sqlExecuted,
    required String aiConclusion,
    required List<Map<String, dynamic>> rows,
  }) async {
    final excel = Excel.createExcel();
    final sheetName = 'Informe_Carpinteria';
    excel.rename(excel.getDefaultSheet() ?? 'Sheet1', sheetName);
    final sheet = excel[sheetName];

    // Metadatos del reporte en las primeras filas
    sheet.appendRow([TextCellValue('CARPINTERÍA EL ROBLE - REPORTE OFFLINE IA')]);
    sheet.appendRow([TextCellValue('Consulta:'), TextCellValue(userQuery)]);
    sheet.appendRow([TextCellValue('SQL Ejecutado:'), TextCellValue(sqlExecuted)]);
    sheet.appendRow([TextCellValue('Conclusión IA:'), TextCellValue(aiConclusion)]);
    sheet.appendRow([TextCellValue('')]);

    if (rows.isNotEmpty) {
      // Encabezados de columna
      final headers =
          rows.first.keys.map((k) => TextCellValue(k.toUpperCase())).toList();
      sheet.appendRow(headers);

      // Filas de datos
      for (final row in rows) {
        final cells = row.values.map<CellValue>((val) {
          if (val is int) return IntCellValue(val);
          if (val is double) return DoubleCellValue(val);
          return TextCellValue((val ?? '').toString());
        }).toList();
        sheet.appendRow(cells);
      }
    } else {
      sheet.appendRow([TextCellValue('Sin registros para esta consulta')]);
    }

    final fileBytes = excel.save();
    if (fileBytes == null) {
      throw Exception('No se pudo generar el archivo Excel.');
    }

    final dir = await getApplicationDocumentsDirectory();
    final fileName =
        'informe_carpinteria_${DateTime.now().millisecondsSinceEpoch}.xlsx';
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(fileBytes, flush: true);

    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'Informe Excel - Carpintería El Roble',
    );
    return file.path;
  }

  /// Genera un archivo CSV (.csv) con los resultados de la consulta SQLite
  /// y abre el menú de compartir.
  static Future<String> exportToCsv({
    required String userQuery,
    required String aiConclusion,
    required List<Map<String, dynamic>> rows,
  }) async {
    final List<List<dynamic>> csvData = [];

    // Encabezado informativo
    csvData.add(['# Informe Carpinteria El Roble']);
    csvData.add(['# Solicitud', userQuery]);
    csvData.add(['# Resumen IA', aiConclusion.replaceAll('\n', ' ')]);
    csvData.add([]);

    if (rows.isNotEmpty) {
      csvData.add(rows.first.keys.map((k) => k.toUpperCase()).toList());
      for (final row in rows) {
        csvData.add(row.values.map((v) => v ?? '').toList());
      }
    } else {
      csvData.add(['Sin resultados']);
    }

    final csvString = const ListToCsvConverter().convert(csvData);
    final dir = await getApplicationDocumentsDirectory();
    final fileName =
        'informe_carpinteria_${DateTime.now().millisecondsSinceEpoch}.csv';
    final file = File('${dir.path}/$fileName');
    await file.writeAsString(csvString, flush: true);

    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'Informe CSV - Carpintería El Roble',
    );
    return file.path;
  }
}
