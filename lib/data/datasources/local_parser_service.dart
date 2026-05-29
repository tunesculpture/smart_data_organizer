import 'dart:convert';
import 'dart:math';
import 'package:csv/csv.dart';
import 'package:excel/excel.dart';
import '../../domain/entities/parsed_dataset.dart';
import '../../core/utils/app_utils.dart';

class LocalParserService {

  Future<ParseResult> parseFile({required String fileName, required List<int> bytes}) async {
    final ext = fileName.split('.').last.toLowerCase();
    try {
      switch (ext) {
        case 'xlsx': case 'xls': return _parseExcel(bytes, fileName);
        case 'csv':              return _parseCsv(bytes, fileName);
        case 'txt':              return parseText(utf8.decode(bytes, allowMalformed: true), fileName);
        case 'json':             return _parseJson(utf8.decode(bytes, allowMalformed: true), fileName);
        default: return ParseResult.failure('Unsupported format: .$ext');
      }
    } catch (e) {
      return ParseResult.failure('File parse error: $e');
    }
  }

  // ── Excel ──────────────────────────────────────────────────────────────────
  ParseResult _parseExcel(List<int> bytes, String fileName) {
    try {
      final excel = Excel.decodeBytes(bytes);
      ParsedDataset? best;
      for (final sheetName in excel.tables.keys) {
        final sheet = excel.tables[sheetName]!;
        if (sheet.rows.isEmpty) continue;
        final rawRows = sheet.rows.map((row) => row.map((cell) {
          final v = cell?.value;
          if (v == null) return '';
          if (v is TextCellValue) return v.value.toString().trim();
          if (v is IntCellValue)    return v.value.toString();
          if (v is DoubleCellValue) return v.value.toString();
          if (v is BoolCellValue)   return v.value.toString();
          return v.toString().trim();
        }).toList()).toList();
        final normalized = _normalize(rawRows)
    .map((row) => row.map((cell) => cell.toString()).toList())
    .toList();

final ds = _buildDataset(normalized, '$fileName - $sheetName', 'file');
        if (best == null || ds.rowCount > best.rowCount) best = ds;
      }
      if (best == null || best.rowCount == 0) return ParseResult.failure('Excel file appears empty');
      return ParseResult.success(best);
    } catch (e) {
      return ParseResult.failure('Excel parse error: $e');
    }
  }

  // ── CSV ────────────────────────────────────────────────────────────────────
  ParseResult _parseCsv(List<int> bytes, String fileName) {
    final text = utf8.decode(bytes, allowMalformed: true);
    try {
      final rows = const CsvToListConverter(eol: '\n', shouldParseNumbers: false).convert(text);
      final strRows = rows
          .map((r) => r.map((c) => AppUtils.cleanCell(c.toString())).toList())
          .where((r) => r.any((c) => c.isNotEmpty)).toList();
      if (strRows.isEmpty) return ParseResult.failure('CSV is empty');
      return ParseResult.success(_buildDataset(_normalize(strRows), fileName, 'file'));
    } catch (_) {
      return parseText(text, fileName);
    }
  }

  // ── JSON ───────────────────────────────────────────────────────────────────
  ParseResult _parseJson(String text, String fileName) {
    try {
      final decoded = jsonDecode(text);
      List<Map<String, dynamic>> records = [];
      if (decoded is List) {
        records = decoded.whereType<Map<String, dynamic>>().toList();
      } else if (decoded is Map<String, dynamic>) {
        for (final k in decoded.keys) {
          if (decoded[k] is List) {
            records = (decoded[k] as List).whereType<Map<String, dynamic>>().toList();
            break;
          }
        }
        if (records.isEmpty) records = [decoded];
      }
      if (records.isEmpty) return ParseResult.failure('No records in JSON');
      final keys = <String>{};
      for (final r in records) keys.addAll(r.keys);
      final headers = keys.toList();
      final rows = records.map((r) =>
          headers.map((h) => (r[h] ?? '').toString()).toList()).toList();
      return ParseResult.success(_buildDataset(_normalize([headers, ...rows]), fileName, 'file'));
    } catch (e) {
      return ParseResult.failure('Invalid JSON: $e');
    }
  }

  // ── Text / Paste ───────────────────────────────────────────────────────────
  ParseResult parseText(String text, String fileName) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return ParseResult.failure('Input is empty');
    final lines = trimmed.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();
    if (lines.isEmpty) return ParseResult.failure('No content');

    final sep = AppUtils.detectSeparator(trimmed);

    // Parse lines — collect both values AND any Key names from Key|Value tokens
    final parsedLines  = lines.map((l) => _parseLine(l, sep)).toList();
    final valueRows    = parsedLines.map((r) => r.values).toList();
    final keyRows      = parsedLines.map((r) => r.keys).toList();

    final normalized = _normalize(valueRows);
    if (normalized.isEmpty) return ParseResult.failure('Could not parse data');

    // Check if Key names are consistent across rows — if so, use them as headers
    final extractedHeaders = _extractConsistentKeys(keyRows, normalized.first.length);

    return ParseResult.success(
      _buildDataset(normalized, fileName, 'paste', extractedHeaders: extractedHeaders),
      separator: sep,
    );
  }

  // ── Line Parser — splits by sep AND extracts Key|Value sub-tokens ──────────
  _ParsedLine _parseLine(String line, String sep) {
    final tokens = line.split(sep).map(AppUtils.cleanCell).toList();
    final values = <String>[];
    final keys   = <String?>[];

    for (final token in tokens) {
      if (token.isEmpty) { values.add(''); keys.add(null); continue; }
      final kv = AppUtils.parseKeyValue(token);
      if (kv != null) {
        values.add(kv.value);   // extract value
        keys.add(kv.key);       // remember the key name
      } else {
        values.add(token);
        keys.add(null);         // no key name for this token
      }
    }
    return _ParsedLine(values, keys);
  }

  // ── Extract consistent key names across all rows ────────────────────────────
  // If the same column position has a Key name in most rows, use it as header.
  List<String>? _extractConsistentKeys(List<List<String?>> keyRows, int colCount) {
    if (keyRows.isEmpty) return null;
    final result = <String>[];
    bool anyFound = false;

    for (int i = 0; i < colCount; i++) {
      final keysAtCol = keyRows
          .where((r) => i < r.length && r[i] != null && r[i]!.isNotEmpty)
          .map((r) => r[i]!)
          .toList();

      if (keysAtCol.isEmpty) {
        result.add('');   // no key found for this column
      } else {
        // Use the most common key name for this column
        final freq = <String, int>{};
        for (final k in keysAtCol) freq[k] = (freq[k] ?? 0) + 1;
        final best = freq.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
        // Only use if it appears in ≥50% of rows
        if ((freq[best] ?? 0) / keyRows.length >= 0.5) {
          result.add(best);
          anyFound = true;
        } else {
          result.add('');
        }
      }
    }
    return anyFound ? result : null;
  }

  // ── Normalize rows ─────────────────────────────────────────────────────────
  List<List<String>> _normalize(List<List<String>> rawRows) {
    if (rawRows.isEmpty) return [];
    final maxCols = rawRows.map((r) => r.length).reduce(max);
    final seen = <String>{};
    final result = <List<String>>[];
    for (final row in rawRows) {
      if (row.every((c) => c.isEmpty)) continue;
      final padded = List<String>.from(row);
      while (padded.length < maxCols) padded.add('');
      final key = padded.join('\x00');
      if (!seen.contains(key)) { seen.add(key); result.add(padded); }
    }
    return result;
  }

  // ── Dataset Builder ────────────────────────────────────────────────────────
  ParsedDataset _buildDataset(
    List<List<String>> rows,
    String fileName,
    String sourceType, {
    List<String>? extractedHeaders,   // Key names from Key|Value sub-tokens
  }) {
    if (rows.isEmpty) {
      return ParsedDataset(id: _id(), fileName: fileName, sourceType: sourceType,
          headers: [], rows: [], columnTypes: [], confidence: 0, createdAt: DateTime.now());
    }

    final colCount = rows.first.length;
    List<String> headers;
    List<List<String>> dataRows;

    if (AppUtils.looksLikeHeader(rows.first)) {
      // First row is a header row
      headers = rows.first.map((h) {
        final c = AppUtils.cleanCell(h);
        return c.isEmpty ? 'Column' : c;
      }).toList();
      dataRows = rows.skip(1).toList();
    } else {
      dataRows = rows;

      // Use extracted Key names where available, fill gaps with type-inferred labels
      final samples = List.generate(colCount, (i) =>
          dataRows.take(20).map((r) => i < r.length ? r[i] : '').toList());
      final types = samples.map(AppUtils.inferColumnType).toList();

      if (extractedHeaders != null && extractedHeaders.length == colCount) {
        // Merge: prefer extracted key name, fall back to type-inferred label
        headers = List.generate(colCount, (i) {
          final extracted = extractedHeaders[i];
          if (extracted.isNotEmpty) {
            // Format the key name nicely: "CheckIn" → "Check In"
            return _formatKeyName(extracted);
          }
          return AppUtils.columnTypeToLabel(types[i], i);
        });
        // Deduplicate
        headers = _deduplicateHeaders(headers);
      } else {
        headers = AppUtils.generateUniqueHeaders(types);
      }
    }

    // Infer column types from actual data
    final colSamples = List.generate(headers.length, (i) =>
        dataRows.take(50).map((r) => i < r.length ? r[i] : '').toList());
    final columnTypes = colSamples.map(AppUtils.inferColumnType).toList();

    // Clean + normalize cells
    final cleanedRows = dataRows.map((row) =>
      List.generate(headers.length, (i) {
        var val = i < row.length ? AppUtils.cleanCell(row[i]) : '';
        if (i < columnTypes.length) {
          val = AppUtils.standardizeCapitalization(val, columnTypes[i]);
          if (columnTypes[i] == 'Amount' && AppUtils.isAmount(val)) {
            val = AppUtils.normalizeAmount(val);
          }
        }
        return val;
      }),
    ).toList();

    return ParsedDataset(
      id: _id(), fileName: fileName, sourceType: sourceType,
      headers: headers, rows: cleanedRows, columnTypes: columnTypes,
      confidence: AppUtils.calculateParseConfidence(cleanedRows, columnTypes),
      wasAiParsed: false, createdAt: DateTime.now(),
    );
  }

  // ── Format key name: "CheckIn" → "Check In", "checkOut" → "Check Out" ─────
  String _formatKeyName(String key) {
    // Insert space before uppercase letters (camelCase)
    final spaced = key.replaceAllMapped(
      RegExp(r'([a-z])([A-Z])'),
      (m) => '${m.group(1)} ${m.group(2)}',
    );
    // Title case each word
    return spaced.split(' ').map((w) => w.isEmpty
        ? '' : '${w[0].toUpperCase()}${w.substring(1)}').join(' ');
  }

  // ── Deduplicate headers ────────────────────────────────────────────────────
  List<String> _deduplicateHeaders(List<String> headers) {
    final count = <String, int>{};
    for (final h in headers) count[h] = (count[h] ?? 0) + 1;
    final seen = <String, int>{};
    return headers.map((h) {
      if ((count[h] ?? 1) > 1) {
        seen[h] = (seen[h] ?? 0) + 1;
        return '$h ${seen[h]}';
      }
      return h;
    }).toList();
  }

  String _id() => DateTime.now().millisecondsSinceEpoch.toString();
}

// ── Helper: parsed line result ────────────────────────────────────────────────
class _ParsedLine {
  final List<String> values;
  final List<String?> keys;
  _ParsedLine(this.values, this.keys);
}

// ── Result Wrapper ─────────────────────────────────────────────────────────────
class ParseResult {
  final ParsedDataset? dataset;
  final String? error;
  final bool success;
  final String? separator;
  const ParseResult._({this.dataset, this.error, required this.success, this.separator});
  factory ParseResult.success(ParsedDataset d, {String? separator}) =>
      ParseResult._(dataset: d, success: true, separator: separator);
  factory ParseResult.failure(String e) => ParseResult._(error: e, success: false);
}
