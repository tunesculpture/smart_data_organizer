import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../data/datasources/local_parser_service.dart';
import '../../data/datasources/ai_parser_service.dart';
import '../../domain/entities/parsed_dataset.dart';
import '../../core/constants/app_constants.dart';

enum AppState { idle, parsing, success, error }

class AppProvider extends ChangeNotifier {
  AppState       _state    = AppState.idle;
  ParsedDataset? _dataset;
  String?        _error;
  String         _status   = '';
  double         _progress = 0.0;

  AppState       get state           => _state;
  ParsedDataset? get currentDataset  => _dataset;
  String?        get errorMessage    => _error;
  String         get parsingStatus   => _status;
  double         get parsingProgress => _progress;

  final _local = LocalParserService();

  // ─────────────────────────────────────────────────────────────────────────
  // Parse uploaded file
  // Flow:
  //   1. If API key set  → AI detects schema → apply to ALL rows locally
  //   2. If no API key   → local parser for clean Excel/CSV only
  //   3. Messy text without key → error telling user to add key
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> parseFile({
    required String filePath,
    required String fileName,
    required bool   aiEnabled,
    required String apiKey,
    required String providerId,
    required String endpointUrl,
    required String modelName,
  }) async {
    _begin();
    _tick('Reading file...', 0.10);

    try {
      final file = File(filePath);
      if (!await file.exists())                         { _fail('File not found'); return; }
      final bytes = await file.readAsBytes();
      if (bytes.isEmpty)                               { _fail('File is empty'); return; }
      if (bytes.length > AppConstants.maxFileSizeBytes) { _fail('File too large (max 50 MB)'); return; }

      final rawLines = utf8.decode(bytes, allowMalformed: true)
          .split('\n').where((l) => l.trim().isNotEmpty).toList();

      // ── Step 1: AI always runs first when key is available ─────────────────
      if (apiKey.isNotEmpty) {
        final count = rawLines.length > AppConstants.aiSampleRows
            ? AppConstants.aiSampleRows : rawLines.length;
        _tick('Sending $count rows to AI for schema detection...', 0.25);
        final ok = await _runAi(
            rawLines, fileName, 'file', apiKey, providerId, endpointUrl, modelName);
        if (ok) return; // AI succeeded — done
        // If AI returned hardStop, _fail was already called — check state
        if (_state == AppState.error) return;
        // AI gave bad/empty result — try local as last resort
      }

      // ── Step 2: Local parser (clean Excel/CSV without key, or AI fallback) ─
      _tick('Parsing file structure...', 0.45);
      final result = await _local.parseFile(fileName: fileName, bytes: bytes);
      if (!result.success || result.dataset == null || result.dataset!.rowCount == 0) {
        _fail(apiKey.isEmpty
            ? 'Could not parse this file.\n\nTip: Add an AI API key in Settings → it handles any file format automatically.'
            : 'Could not organize data. Try again or check your API key in Settings.');
        return;
      }
      _tick('Organizing table...', 0.85);
      _done(result.dataset!);
    } catch (e) {
      _fail('Unexpected error: $e');
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Parse pasted text
  // Flow:
  //   1. If API key set  → AI detects schema → apply to ALL rows locally
  //   2. If no API key   → local parser (basic structured text only)
  //   3. Natural language without key → error
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> parsePastedText({
    required String text,
    required bool   aiEnabled,
    required String apiKey,
    required String providerId,
    required String endpointUrl,
    required String modelName,
  }) async {
    if (text.trim().isEmpty) { _fail('Please enter some text'); return; }
    _begin();

    final rawLines = text.split('\n').where((l) => l.trim().isNotEmpty).toList();

    // ── Step 1: AI always runs first when key is available ─────────────────
    if (apiKey.isNotEmpty) {
      final count = rawLines.length > AppConstants.aiSampleRows
          ? AppConstants.aiSampleRows : rawLines.length;
      _tick('Sending $count rows to AI for schema detection...', 0.25);
      final ok = await _runAi(
          rawLines, 'Pasted Data', 'paste', apiKey, providerId, endpointUrl, modelName);
      if (ok) return;
      if (_state == AppState.error) return;
    }

    // ── Step 2: Local parser (basic structured text fallback) ──────────────
    _tick('Parsing text structure...', 0.45);
    try {
      final result = _local.parseText(text, 'Pasted Data');
      if (!result.success || result.dataset == null || result.dataset!.rowCount == 0) {
        _fail(apiKey.isEmpty
            ? 'Could not parse this text.\n\nTip: Add an AI API key in Settings → AI handles any text format including natural language.'
            : 'Could not organize text. Try again or check your API key in Settings.');
        return;
      }
      _tick('Organizing table...', 0.85);
      _done(result.dataset!);
    } catch (e) {
      _fail('Error: $e');
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // _runAi: sends sample rows to AI, applies schema to ALL rows locally
  // Returns true  = success, dataset set
  // Returns false = failed, caller should try local or show error
  // Side effect   = _fail() called for hard errors (auth, rate limit)
  // ─────────────────────────────────────────────────────────────────────────
  Future<bool> _runAi(
    List<String> rawLines,
    String fileName,
    String sourceType,
    String apiKey,
    String providerId,
    String endpointUrl,
    String modelName,
  ) async {
    try {
      final ai = AiParserService(
        apiKey:      apiKey,
        providerId:  providerId,
        endpointUrl: endpointUrl,
        modelName:   modelName,
      );

      _tick('AI analyzing data structure...', 0.40);
      final schema = await ai.detectSchema(rawLines);

      if (!schema.success) {
        final err = schema.error ?? 'AI failed';
        // Hard errors: invalid key, auth, rate limit → stop and show user
        if (_isHardError(err)) {
          _fail(err);
          return true; // true = stop, don't try local
        }
        // Soft errors: network, parse issue → return false to try local
        return false;
      }

      _tick(
        'Schema detected! Organizing ${rawLines.length} rows...',
        0.75,
      );

      final ds = ai.applySchema(
        schema:     schema,
        allLines:   rawLines,
        fileName:   fileName,
        sourceType: sourceType,
      );

      if (ds.rowCount == 0) {
        // AI returned valid schema but no rows → try local
        return false;
      }

      _tick('Done!', 1.0);
      _done(ds);
      return true;
    } catch (e) {
      // Network or timeout — fall through to local
      return false;
    }
  }

  bool _isHardError(String err) {
    final e = err.toLowerCase();
    return e.contains('invalid api key') ||
        e.contains('invalid key') ||
        e.contains('check your key') ||
        e.contains('rate limit') ||
        e.contains('does not have permission') ||
        e.contains('401') ||
        e.contains('403') ||
        e.contains('429');
  }

  // ── Dataset editing ────────────────────────────────────────────────────────
  void updateDataset(ParsedDataset ds) { _dataset = ds; notifyListeners(); }

  void addRow() {
    if (_dataset == null) return;
    final rows = _dataset!.rows.map((r) => List<String>.from(r)).toList()
      ..add(List.filled(_dataset!.columnCount, ''));
    _dataset = _dataset!.copyWith(rows: rows);
    notifyListeners();
  }

  void deleteRow(int i) {
    if (_dataset == null || i >= _dataset!.rows.length) return;
    final rows = _dataset!.rows.map((r) => List<String>.from(r)).toList()
      ..removeAt(i);
    _dataset = _dataset!.copyWith(rows: rows);
    notifyListeners();
  }

  void duplicateRow(int i) {
    if (_dataset == null || i >= _dataset!.rows.length) return;
    final rows = _dataset!.rows.map((r) => List<String>.from(r)).toList();
    rows.insert(i + 1, List<String>.from(rows[i]));
    _dataset = _dataset!.copyWith(rows: rows);
    notifyListeners();
  }

  void renameColumn(int i, String name) {
    if (_dataset == null || i >= _dataset!.headers.length) return;
    final h = List<String>.from(_dataset!.headers)..[i] = name;
    _dataset = _dataset!.copyWith(headers: h);
    notifyListeners();
  }

  void addColumn(String name) {
    if (_dataset == null) return;
    final h = List<String>.from(_dataset!.headers)..add(name);
    final t = List<String>.from(_dataset!.columnTypes)..add('Text');
    final rows = _dataset!.rows.map((r) => List<String>.from(r)..add('')).toList();
    _dataset = _dataset!.copyWith(headers: h, columnTypes: t, rows: rows);
    notifyListeners();
  }

  void deleteColumn(int i) {
    if (_dataset == null) return;
    final h = List<String>.from(_dataset!.headers);
    final t = List<String>.from(_dataset!.columnTypes);
    if (i < h.length) h.removeAt(i);
    if (i < t.length) t.removeAt(i);
    final rows = _dataset!.rows.map((r) {
      final row = List<String>.from(r);
      if (i < row.length) row.removeAt(i);
      return row;
    }).toList();
    _dataset = _dataset!.copyWith(headers: h, columnTypes: t, rows: rows);
    notifyListeners();
  }

  void sortByColumn(int col, bool asc) {
    if (_dataset == null) return;
    final rows = _dataset!.rows.map((r) => List<String>.from(r)).toList();
    rows.sort((a, b) {
      final va = col < a.length ? a[col] : '';
      final vb = col < b.length ? b[col] : '';
      final na = double.tryParse(va.replaceAll(RegExp(r'[,₹\$€]'), ''));
      final nb = double.tryParse(vb.replaceAll(RegExp(r'[,₹\$€]'), ''));
      final cmp = (na != null && nb != null)
          ? na.compareTo(nb)
          : va.toLowerCase().compareTo(vb.toLowerCase());
      return asc ? cmp : -cmp;
    });
    _dataset = _dataset!.copyWith(rows: rows);
    notifyListeners();
  }

  void loadDataset(ParsedDataset ds) {
    _dataset = ds;
    _state = AppState.success;
    notifyListeners();
  }

  void reset() {
    _dataset  = null;
    _error    = null;
    _status   = '';
    _progress = 0.0;
    _state    = AppState.idle;
    notifyListeners();
  }

  void _begin() {
    _state    = AppState.parsing;
    _error    = null;
    _dataset  = null;
    _progress = 0.0;
    _status   = '';
    notifyListeners();
  }

  void _tick(String s, double p) {
    _status   = s;
    _progress = p;
    notifyListeners();
  }

  void _done(ParsedDataset ds) {
    _dataset  = ds;
    _state    = AppState.success;
    _progress = 1.0;
    _status   = 'Done!';
    notifyListeners();
  }

  void _fail(String msg) {
    _error = msg;
    _state = AppState.error;
    notifyListeners();
  }
}
