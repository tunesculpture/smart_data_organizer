import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/constants/app_constants.dart';
import '../../domain/entities/parsed_dataset.dart';

/// Universal AI Parser — ALWAYS runs when API key is set.
/// Step 1: Send 5 sample rows → AI returns column schema JSON
/// Step 2: App applies schema to ALL rows locally (zero extra API calls)
/// Supports: OpenAI, Gemini, Claude, Groq, xAI, Together, HuggingFace, Custom
class AiParserService {
  final String apiKey;
  final String providerId;
  final String endpointUrl;
  final String modelName;

  AiParserService({
    required this.apiKey,
    required this.providerId,
    required this.endpointUrl,
    required this.modelName,
  });

  // Very tight prompt — ensures clean JSON output always
  static const _systemPrompt =
      'You are a data schema detector. Analyze raw data rows and return ONLY valid JSON.\n'
      'No markdown. No explanation. No code blocks. Just the JSON object.\n\n'
      'Return this exact format:\n'
      '{"separator":"~","sub_separator":"|","has_header":false,'
      '"columns":[{"name":"Booking ID","type":"ID"}]}\n\n'
      'Rules:\n'
      '- separator: single char between columns (~, |, comma, semicolon, tab)\n'
      '- sub_separator: char inside tokens like "CheckIn|01-03-2026" → "|" (null if none)\n'
      '- has_header: true only if first row is column labels\n'
      '- columns: one object per column, use meaningful names\n'
      '- types: ID, Name, City, Phone, Email, Date, Amount, Number, Status, Text\n'
      '- For "CheckIn|01-03-2026" → column name is "Check In", type "Date"\n'
      '- For natural language: extract all fields as separate columns\n\n'
      'Examples:\n'
      'Input: B001~Rahul~Delhi~CheckIn|01-03-2026~4500~Confirmed\n'
      'Output: {"separator":"~","sub_separator":"|","has_header":false,'
      '"columns":[{"name":"Booking ID","type":"ID"},{"name":"Name","type":"Name"},'
      '{"name":"City","type":"City"},{"name":"Check In","type":"Date"},'
      '{"name":"Amount","type":"Amount"},{"name":"Status","type":"Status"}]}\n\n'
      'Input: Rahul Sharma, Delhi, 9876543210, rahul@gmail.com\n'
      'Output: {"separator":",","sub_separator":null,"has_header":false,'
      '"columns":[{"name":"Name","type":"Name"},{"name":"City","type":"City"},'
      '{"name":"Phone","type":"Phone"},{"name":"Email","type":"Email"}]}';

  static const _userPromptPrefix = 'Detect the schema for this data:\n\n';

  // ── Main: detect schema from sample rows ──────────────────────────────────
  Future<AiSchemaResult> detectSchema(List<String> allLines) async {
    final sample = allLines.take(AppConstants.aiSampleRows).join('\n');
    try {
      switch (providerId) {
        case 'gemini': return await _callGemini(sample);
        case 'claude': return await _callClaude(sample);
        default:       return await _callOpenAiCompatible(sample);
        // Covers: openai, groq, xai, together, hf, custom, deepseek, mistral, etc.
      }
    } catch (e) {
      return AiSchemaResult.failure('Network error: $e');
    }
  }

  // ── OpenAI-compatible (OpenAI, Groq, xAI, Together, DeepSeek, HF, custom) ─
  Future<AiSchemaResult> _callOpenAiCompatible(String sample) async {
    final resp = await http.post(
      Uri.parse(endpointUrl),
      headers: {
        'Content-Type':  'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode({
        'model': modelName,
        'messages': [
          {'role': 'system', 'content': _systemPrompt},
          {'role': 'user',   'content': '$_userPromptPrefix$sample'},
        ],
        'max_tokens':  600,
        'temperature': 0.0,
      }),
    ).timeout(const Duration(seconds: 25));

    return _parseOpenAiResponse(resp);
  }

  AiSchemaResult _parseOpenAiResponse(http.Response resp) {
    switch (resp.statusCode) {
      case 401: return AiSchemaResult.failure(
          'Invalid API key. Please check your key in Settings.');
      case 403: return AiSchemaResult.failure(
          'API key does not have permission. Check your account.');
      case 429: return AiSchemaResult.failure(
          'Rate limit reached. Wait a moment and try again.');
      case 404: return AiSchemaResult.failure(
          'API endpoint not found. Check your custom URL in Settings.');
      case 500:
      case 502:
      case 503: return AiSchemaResult.failure(
          'AI service temporarily unavailable. Try again shortly.');
    }
    if (resp.statusCode != 200) {
      // Extract message from response body if possible
      try {
        final b = jsonDecode(resp.body) as Map<String, dynamic>;
        final msg = b['error']?['message'] as String? ?? resp.body.substring(0, resp.body.length.clamp(0, 150));
        return AiSchemaResult.failure('AI error: $msg');
      } catch (_) {
        return AiSchemaResult.failure('AI error ${resp.statusCode}');
      }
    }
    try {
      final body = jsonDecode(resp.body) as Map<String, dynamic>;
      final text = body['choices'][0]['message']['content'] as String;
      return _parseJson(text);
    } catch (e) {
      return AiSchemaResult.failure('Could not read AI response: $e');
    }
  }

  // ── Google Gemini ──────────────────────────────────────────────────────────
  Future<AiSchemaResult> _callGemini(String sample) async {
    final resp = await http.post(
      Uri.parse('$endpointUrl?key=$apiKey'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'contents': [{'parts': [{'text': '$_systemPrompt\n\n$_userPromptPrefix$sample'}]}],
        'generationConfig': {'temperature': 0.0, 'maxOutputTokens': 600},
      }),
    ).timeout(const Duration(seconds: 25));

    switch (resp.statusCode) {
      case 400: return AiSchemaResult.failure('Invalid Gemini API key. Get yours free at aistudio.google.com');
      case 403: return AiSchemaResult.failure('Gemini key does not have access. Check billing/quota.');
      case 429: return AiSchemaResult.failure('Gemini rate limit. Wait or switch provider.');
    }
    if (resp.statusCode != 200) return AiSchemaResult.failure('Gemini error ${resp.statusCode}');
    try {
      final body = jsonDecode(resp.body) as Map<String, dynamic>;
      final text = body['candidates'][0]['content']['parts'][0]['text'] as String;
      return _parseJson(text);
    } catch (e) {
      return AiSchemaResult.failure('Could not read Gemini response: $e');
    }
  }

  // ── Anthropic Claude ───────────────────────────────────────────────────────
  Future<AiSchemaResult> _callClaude(String sample) async {
    final resp = await http.post(
      Uri.parse(endpointUrl),
      headers: {
        'Content-Type':      'application/json',
        'x-api-key':         apiKey,
        'anthropic-version': '2023-06-01',
      },
      body: jsonEncode({
        'model':      modelName,
        'max_tokens': 600,
        'system':     _systemPrompt,
        'messages':   [{'role': 'user', 'content': '$_userPromptPrefix$sample'}],
      }),
    ).timeout(const Duration(seconds: 25));

    switch (resp.statusCode) {
      case 401: return AiSchemaResult.failure('Invalid Claude API key. Check console.anthropic.com');
      case 429: return AiSchemaResult.failure('Claude rate limit. Try again shortly.');
    }
    if (resp.statusCode != 200) return AiSchemaResult.failure('Claude error ${resp.statusCode}');
    try {
      final body = jsonDecode(resp.body) as Map<String, dynamic>;
      final text = body['content'][0]['text'] as String;
      return _parseJson(text);
    } catch (e) {
      return AiSchemaResult.failure('Could not read Claude response: $e');
    }
  }

  // ── Parse JSON schema from any response text ──────────────────────────────
  AiSchemaResult _parseJson(String text) {
    try {
      // Strip markdown if present
      var cleaned = text
          .replaceAll('```json', '')
          .replaceAll('```', '')
          .trim();

      // Find first { and last } to extract JSON even if there's surrounding text
      final start = cleaned.indexOf('{');
      final end   = cleaned.lastIndexOf('}');
      if (start == -1 || end == -1 || end <= start) {
        return AiSchemaResult.failure('AI did not return valid JSON. Try again.');
      }
      cleaned = cleaned.substring(start, end + 1);

      final schema = jsonDecode(cleaned) as Map<String, dynamic>;

      final columnsList = schema['columns'] as List?;
      if (columnsList == null || columnsList.isEmpty) {
        return AiSchemaResult.failure('AI returned empty column list.');
      }

      final columns = columnsList.map((c) {
        final map = c as Map<String, dynamic>;
        return _Col(
          name: (map['name'] as String?)?.trim() ?? 'Column',
          type: (map['type'] as String?)?.trim() ?? 'Text',
        );
      }).toList();

      // Validate separator
      final sep = (schema['separator'] as String?)?.trim() ?? ',';
      final subSep = schema['sub_separator'] as String?;

      return AiSchemaResult.success(
        separator:    sep.isEmpty ? ',' : sep,
        subSeparator: (subSep == null || subSep == 'null') ? null : subSep,
        hasHeader:    (schema['has_header'] as bool?) ?? false,
        columns:      columns,
      );
    } catch (e) {
      return AiSchemaResult.failure('Schema parse failed: $e');
    }
  }

  // ── Apply schema to ALL rows locally (zero extra API calls) ───────────────
  ParsedDataset applySchema({
    required AiSchemaResult schema,
    required List<String>   allLines,
    required String         fileName,
    required String         sourceType,
  }) {
    final sep      = schema.separator!;
    final subSep   = schema.subSeparator;
    final cols     = schema.columns!;
    final colCount = cols.length;

    final dataLines = (schema.hasHeader == true)
        ? allLines.skip(1).toList()
        : allLines;

    final rows = <List<String>>[];

    for (final line in dataLines) {
      if (line.trim().isEmpty) continue;

      // Split by primary separator
      final tokens = sep == '\t'
          ? line.split('\t')
          : line.split(sep);

      // For each token: strip Key from Key|Value pairs
      final values = tokens.map((t) {
        final trimmed = t.trim();
        if (subSep != null &&
            subSep.isNotEmpty &&
            trimmed.contains(subSep)) {
          final idx = trimmed.indexOf(subSep);
          return trimmed.substring(idx + 1).trim();
        }
        // Clean surrounding quotes
        return trimmed.replaceAll(RegExp(r"""^['"]+|['"]+$"""), '');
      }).toList();

      // Pad or trim to column count
      final row = List.generate(
        colCount,
        (i) => i < values.length ? values[i] : '',
      );

      if (row.any((c) => c.isNotEmpty)) rows.add(row);
    }

    return ParsedDataset(
      id:          DateTime.now().millisecondsSinceEpoch.toString(),
      fileName:    fileName,
      sourceType:  sourceType,
      headers:     cols.map((c) => c.name).toList(),
      rows:        rows,
      columnTypes: cols.map((c) => c.type).toList(),
      confidence:  0.95,
      wasAiParsed: true,
      createdAt:   DateTime.now(),
    );
  }
}

class _Col {
  final String name, type;
  _Col({required this.name, required this.type});
}

class AiSchemaResult {
  final String?     separator;
  final String?     subSeparator;
  final bool?       hasHeader;
  final List<_Col>? columns;
  final String?     error;
  final bool        success;

  const AiSchemaResult._({
    this.separator, this.subSeparator, this.hasHeader,
    this.columns,   this.error,        required this.success,
  });

  factory AiSchemaResult.success({
    required String     separator,
    required String?    subSeparator,
    required bool       hasHeader,
    required List<_Col> columns,
  }) => AiSchemaResult._(
    separator: separator, subSeparator: subSeparator,
    hasHeader: hasHeader, columns: columns, success: true,
  );

  factory AiSchemaResult.failure(String error) =>
      AiSchemaResult._(error: error, success: false);
}
