import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:carpinteria_movil_sw2/core/services/push_notification_service.dart';

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
    await PushNotificationService.showSystemPush(
      title: 'Informe PDF generado',
      body:
          'El archivo PDF para "$userQuery" (${rows.length} registros) está listo.',
    );

    await Printing.sharePdf(bytes: bytes, filename: fileName);
    return file.path;
  }

  /// Genera un archivo Microsoft Excel (.xlsx) estándar OpenXML usando `archive ^4.x`
  /// (compatible al 100% con `llamadart` sin conflictos de versión).
  static Future<String> exportToExcel({
    required String userQuery,
    required String sqlExecuted,
    required String aiConclusion,
    required List<Map<String, dynamic>> rows,
  }) async {
    final allRows = <List<dynamic>>[
      ['CARPINTERIA EL ROBLE - REPORTE OFFLINE IA'],
      ['Consulta:', userQuery],
      ['SQL Ejecutado:', sqlExecuted],
      ['Conclusion IA:', aiConclusion],
      [],
    ];

    if (rows.isNotEmpty) {
      allRows.add(rows.first.keys.map((k) => k.toUpperCase()).toList());
      for (final row in rows) {
        allRows.add(row.values.map((v) => v ?? '').toList());
      }
    } else {
      allRows.add(['Sin registros para esta consulta']);
    }

    final fileBytes = _buildXlsxBytes(allRows);

    final dir = await getApplicationDocumentsDirectory();
    final fileName =
        'informe_carpinteria_${DateTime.now().millisecondsSinceEpoch}.xlsx';
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(fileBytes, flush: true);
    await PushNotificationService.showSystemPush(
      title: 'Informe Excel (.xlsx) generado',
      body:
          'El reporte en Excel para "$userQuery" (${rows.length} registros) fue exportado.',
    );

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
    await PushNotificationService.showSystemPush(
      title: 'Informe CSV generado',
      body:
          'El archivo CSV para "$userQuery" (${rows.length} registros) fue exportado.',
    );

    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'Informe CSV - Carpintería El Roble',
    );
    return file.path;
  }

  // ── Generador OpenXML (.xlsx) compatible con archive ^4.x ─────────────────

  static List<int> _buildXlsxBytes(List<List<dynamic>> rows) {
    final archive = Archive();

    void addXmlFile(String path, String xmlContent) {
      final bytes = utf8.encode(xmlContent);
      archive.addFile(ArchiveFile(path, bytes.length, bytes));
    }

    addXmlFile('[Content_Types].xml', '''<?xml version="1.0" encoding="UTF-8"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
  <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
  <Default Extension="xml" ContentType="application/xml"/>
  <Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>
  <Override PartName="/xl/worksheets/sheet1.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>
</Types>''');

    addXmlFile('_rels/.rels', '''<?xml version="1.0" encoding="UTF-8"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/>
</Relationships>''');

    addXmlFile('xl/workbook.xml', '''<?xml version="1.0" encoding="UTF-8"?>
<workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">
  <sheets>
    <sheet name="Informe_Carpinteria" sheetId="1" r:id="rId1"/>
  </sheets>
</workbook>''');

    addXmlFile('xl/_rels/workbook.xml.rels', '''<?xml version="1.0" encoding="UTF-8"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet1.xml"/>
</Relationships>''');

    final sb = StringBuffer();
    sb.write('<?xml version="1.0" encoding="UTF-8"?>');
    sb.write(
        '<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main"><sheetData>');

    for (var r = 0; r < rows.length; r++) {
      final rowIndex = r + 1;
      final row = rows[r];
      sb.write('<row r="$rowIndex">');
      for (var c = 0; c < row.length; c++) {
        final colLetter = _colIndexToLetter(c);
        final cellRef = '$colLetter$rowIndex';
        final val = row[c];
        if (val is num) {
          sb.write('<c r="$cellRef"><v>$val</v></c>');
        } else {
          final escaped = _escapeXml((val ?? '').toString());
          sb.write(
              '<c r="$cellRef" t="inlineStr"><is><t>$escaped</t></is></c>');
        }
      }
      sb.write('</row>');
    }

    sb.write('</sheetData></worksheet>');
    addXmlFile('xl/worksheets/sheet1.xml', sb.toString());

    return ZipEncoder().encode(archive);
  }

  static String _colIndexToLetter(int index) {
    var col = '';
    var n = index;
    while (n >= 0) {
      col = String.fromCharCode((n % 26) + 65) + col;
      n = (n ~/ 26) - 1;
    }
    return col;
  }

  static String _escapeXml(String input) {
    return input
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');
  }
}
