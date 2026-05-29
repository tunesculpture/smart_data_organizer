import 'dart:convert';
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import '../../domain/entities/parsed_dataset.dart';

class ExportService {

  // ── Request storage permission before saving ───────────────────────────────
  Future<bool> _requestStoragePermission() async {
    if (!Platform.isAndroid) return true;

    // Android 13+ (API 33+) uses granular permissions — no WRITE needed
    // Android 11-12 (API 30-32) needs MANAGE_EXTERNAL_STORAGE for Downloads
    // Android ≤10 (API ≤29) needs WRITE_EXTERNAL_STORAGE

    // Try WRITE first (works up to API 29)
    var status = await Permission.storage.request();
    if (status.isGranted) return true;

    // Try MANAGE_EXTERNAL_STORAGE for Android 11+
    status = await Permission.manageExternalStorage.request();
    return status.isGranted;
  }

  // ── Get Downloads/SmartDataOrganizer directory ────────────────────────────
  Future<String> _getExportDir() async {
    // Try the standard Downloads folder first
    final downloadsDir = Directory('/storage/emulated/0/Download/SmartDataOrganizer');
    try {
      if (!await downloadsDir.exists()) {
        await downloadsDir.create(recursive: true);
      }
      // Quick write test
      final test = File('${downloadsDir.path}/.test');
      await test.writeAsString('ok');
      await test.delete();
      return downloadsDir.path;
    } catch (_) {
      // Fallback to app documents directory (always writable)
      final appDir = await getApplicationDocumentsDirectory();
      return appDir.path;
    }
  }

  Future<ExportResult> export({
    required ParsedDataset dataset,
    required String format,
    bool shareAfter = false,
  }) async {
    try {
      // Request permission
      final hasPermission = await _requestStoragePermission();
      if (!hasPermission) {
        // Fall back to app docs dir without permission
      }

      final dir = await _getExportDir();
      final baseName = dataset.fileName
          .replaceAll(RegExp(r'\.[^.]+$'), '')
          .replaceAll(RegExp(r'[^\w\-]'), '_');
      final ts = DateTime.now().millisecondsSinceEpoch;
      final filePath = '$dir/${baseName}_$ts.$format';

      List<int> bytes;
      switch (format.toLowerCase()) {
        case 'xlsx': bytes = _buildXlsx(dataset); break;
        case 'csv':  bytes = _buildCsv(dataset);  break;
        case 'json': bytes = _buildJson(dataset);  break;
        case 'txt':  bytes = _buildTxt(dataset);   break;
        case 'pdf':  bytes = await _buildPdf(dataset); break;
        default: return ExportResult.failure('Unknown format: $format');
      }

      await File(filePath).writeAsBytes(bytes);

      if (shareAfter) {
        await Share.shareXFiles(
          [XFile(filePath)],
          subject: 'Exported: ${dataset.fileName}',
        );
      }

      return ExportResult.success(filePath);
    } catch (e) {
      return ExportResult.failure('Export failed: $e');
    }
  }

  List<int> _buildXlsx(ParsedDataset dataset) {
    final excel = Excel.createExcel();
    final sheet = excel['Sheet1'];

    final headerStyle = CellStyle(
      bold: true,
      backgroundColorHex: ExcelColor.fromHexString('#2563EB'),
      fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
    );

    for (int c = 0; c < dataset.headers.length; c++) {
      final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: 0));
      cell.value = TextCellValue(dataset.headers[c]);
      cell.cellStyle = headerStyle;
      sheet.setColumnWidth(c, 20);
    }

    for (int r = 0; r < dataset.rows.length; r++) {
      for (int c = 0; c < dataset.rows[r].length; c++) {
        final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: r + 1));
        cell.value = TextCellValue(dataset.rows[r][c]);
      }
    }

    return excel.encode()!;
  }

  List<int> _buildCsv(ParsedDataset dataset) {
    final rows = [dataset.headers, ...dataset.rows];
    return utf8.encode(const ListToCsvConverter().convert(rows));
  }

  List<int> _buildJson(ParsedDataset dataset) {
    final records = dataset.rows.map((row) {
      final m = <String, String>{};
      for (int i = 0; i < dataset.headers.length; i++) {
        m[dataset.headers[i]] = i < row.length ? row[i] : '';
      }
      return m;
    }).toList();
    return utf8.encode(const JsonEncoder.withIndent('  ').convert(records));
  }

  List<int> _buildTxt(ParsedDataset dataset) {
    final buf = StringBuffer();
    const sep = ' | ';
    final widths = List.generate(dataset.headers.length, (i) {
      int w = dataset.headers[i].length;
      for (final row in dataset.rows) {
        if (i < row.length && row[i].length > w) w = row[i].length;
      }
      return w + 2;
    });

    for (int i = 0; i < dataset.headers.length; i++) {
      buf.write(dataset.headers[i].padRight(widths[i]));
      if (i < dataset.headers.length - 1) buf.write(sep);
    }
    buf.writeln();
    buf.writeln('-' * (widths.fold(0, (a, b) => a + b) + sep.length * (widths.length - 1)));

    for (final row in dataset.rows) {
      for (int i = 0; i < dataset.headers.length; i++) {
        buf.write((i < row.length ? row[i] : '').padRight(widths[i]));
        if (i < dataset.headers.length - 1) buf.write(sep);
      }
      buf.writeln();
    }
    return utf8.encode(buf.toString());
  }

  Future<List<int>> _buildPdf(ParsedDataset dataset) async {
    final pdf = pw.Document();
    pdf.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4.landscape,
      margin: const pw.EdgeInsets.all(20),
      build: (ctx) => [
        pw.Text(dataset.fileName,
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 6),
        pw.Text('${dataset.rowCount} rows × ${dataset.columnCount} columns',
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
        pw.SizedBox(height: 12),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
          children: [
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.blue700),
              children: dataset.headers.map((h) => pw.Padding(
                padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 4),
                child: pw.Text(h, style: pw.TextStyle(
                    color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 8)),
              )).toList(),
            ),
            ...dataset.rows.asMap().entries.map((entry) => pw.TableRow(
              decoration: pw.BoxDecoration(
                  color: entry.key % 2 == 0 ? PdfColors.white : PdfColors.blue50),
              children: entry.value.map((cell) => pw.Padding(
                padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 3),
                child: pw.Text(cell, style: const pw.TextStyle(fontSize: 7)),
              )).toList(),
            )),
          ],
        ),
      ],
    ));
    return pdf.save();
  }

  String getClipboardText(ParsedDataset dataset) {
    final rows = [dataset.headers, ...dataset.rows];
    return rows.map((r) => r.join('\t')).join('\n');
  }
}

class ExportResult {
  final String? filePath;
  final String? error;
  final bool success;

  const ExportResult._({this.filePath, this.error, required this.success});
  factory ExportResult.success(String p) => ExportResult._(filePath: p, success: true);
  factory ExportResult.failure(String e) => ExportResult._(error: e, success: false);
}
