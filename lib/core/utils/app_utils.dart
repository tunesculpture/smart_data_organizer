import 'dart:math';
import 'package:intl/intl.dart';

class AppUtils {

  // ── Separator Detection ────────────────────────────────────────────────────
  static String detectSeparator(String text) {
    final lines = text.split('\n')
        .map((l) => l.trim()).where((l) => l.isNotEmpty).take(10).toList();
    if (lines.isEmpty) return ',';
    final candidates = ['\t', '|', '~', ';', ','];
    final scores = <String, double>{};
    for (final sep in candidates) {
      final counts = lines.map((l) => sep.allMatches(l).length).toList();
      if (counts.every((c) => c == 0)) { scores[sep] = 0; continue; }
      final avg     = counts.reduce((a, b) => a + b) / counts.length;
      final nonZero = counts.where((c) => c > 0).length / counts.length;
      final maxC    = counts.reduce(max).toDouble();
      final consist = maxC > 0
          ? counts.where((c) => c == counts.reduce(max)).length / counts.length
          : 0.0;
      scores[sep] = avg * nonZero * (0.5 + 0.5 * consist);
    }
    final best = scores.entries.where((e) => e.value > 0).toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return best.isEmpty ? ',' : best.first.key;
  }

  // ── Sub-field: "CheckIn|01-03-2026" → key="CheckIn", value="01-03-2026" ──
  static MapEntry<String, String>? parseKeyValue(String token) {
    final m = RegExp(r'^([A-Za-z][A-Za-z\s]{0,14})[|=:](.+)$').firstMatch(token.trim());
    if (m != null) return MapEntry(m.group(1)!.trim(), m.group(2)!.trim());
    return null;
  }

  // ── Pattern Detectors ──────────────────────────────────────────────────────

  // FIX BUG 1: isDate MUST be checked before isPhoneNumber.
  // Dates like "01-03-2026" stripped of dashes = "01032026" (8 digits) = falsely matches phone regex.
  static bool isDate(String v) => [
    RegExp(r'^\d{1,2}[-/]\d{1,2}[-/]\d{2,4}$'),
    RegExp(r'^\d{4}[-/]\d{1,2}[-/]\d{1,2}$'),
    RegExp(r'^\d{1,2}\s+(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)\w*\s+\d{4}$', caseSensitive: false),
    RegExp(r'^(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)\w*\s+\d{1,2},?\s+\d{4}$', caseSensitive: false),
  ].any((p) => p.hasMatch(v.trim()));

  // FIX BUG 1: Check date first, then phone — prevents date-as-phone false positive
  static bool isPhoneNumber(String v) {
    if (isDate(v)) return false; // dates stripped of dashes look like phone numbers — reject
    final c = v.replaceAll(RegExp(r'[\s\-\(\)\+]'), '');
    return RegExp(r'^\d{7,15}$').hasMatch(c);
  }

  static bool isEmail(String v) =>
      RegExp(r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$').hasMatch(v.trim());

  // FIX BUG 2: Amount must have currency symbol OR value >= 10 OR decimals.
  // Small integers (1, 2, 3) without currency = Number/Guest count, NOT Amount.
  static bool isAmount(String v) {
    final hasCurrency = RegExp(r'[₹\$€£¥]').hasMatch(v);
    final c = v.replaceAll(RegExp(r'[₹\$€£¥,\s]'), '').trim();
    if (!RegExp(r'^\d+(\.\d{1,2})?$').hasMatch(c)) return false;
    final n = double.tryParse(c);
    if (n == null) return false;
    // Must have currency symbol OR be >= 10 OR have decimal places
    return hasCurrency || n >= 10 || c.contains('.');
  }

  static bool isId(String v) {
    final t = v.trim();
    return RegExp(r'^[A-Z]{1,4}\d{2,8}$').hasMatch(t) ||
           RegExp(r'^\d{4,10}$').hasMatch(t);
  }

  static bool isStatus(String v) {
    const s = {
      'confirmed','pending','cancelled','canceled','completed','active',
      'inactive','paid','unpaid','processing','shipped','delivered',
      'failed','success','rejected','approved','booked',
    };
    return s.contains(v.trim().toLowerCase());
  }

  /// Name = 2–4 words, each alphabetic ≥2 chars. Single words = NOT name.
  static bool isName(String v) {
    final parts = v.trim().split(RegExp(r'\s+'));
    if (parts.length < 2 || parts.length > 4) return false;
    return parts.every((p) => RegExp(r'^[A-Za-z\.]+$').hasMatch(p) && p.length >= 2);
  }

  /// City = single capitalized word 3+ chars
  static bool isCity(String v) =>
      RegExp(r'^[A-Z][a-z]{2,}$').hasMatch(v.trim());

  /// Small integer (1–9) without currency = guest count / quantity
  static bool isSmallNumber(String v) {
    final c = v.trim();
    final n = int.tryParse(c);
    return n != null && n >= 1 && n <= 9 && !RegExp(r'[₹\$€£¥]').hasMatch(v);
  }

  // ── Column Type Inference — order matters! ─────────────────────────────────
  static String inferColumnType(List<String> values) {
    final ne = values.where((v) => v.isNotEmpty).toList();
    if (ne.isEmpty) return 'Text';
    final t = ne.length.toDouble();
    int phone=0, email=0, date=0, amount=0, id=0, status=0, name=0, city=0, number=0;

    for (final v in ne) {
      // ORDER IS CRITICAL: date before phone (prevents "01032026" phone false-positive)
      if      (isEmail(v))       email++;
      else if (isDate(v))        date++;    // ← MUST come before isPhoneNumber
      else if (isPhoneNumber(v)) phone++;
      else if (isAmount(v))      amount++;  // ← Only real amounts (currency or >=10)
      else if (isSmallNumber(v)) number++;  // ← Guest counts, quantities
      else if (isId(v))          id++;
      else if (isStatus(v))      status++;
      else if (isName(v))        name++;
      else if (isCity(v))        city++;
    }

    if (email/t  > 0.5)  return 'Email';
    if (date/t   > 0.5)  return 'Date';    // ← Before Phone
    if (phone/t  > 0.5)  return 'Phone';
    if (amount/t > 0.5)  return 'Amount';
    if (number/t > 0.5)  return 'Number';
    if (id/t     > 0.4)  return 'ID';
    if (status/t > 0.4)  return 'Status';
    if (name/t   > 0.35) return 'Name';
    if (city/t   > 0.4)  return 'City';
    return 'Text';
  }

  static String columnTypeToLabel(String type, int index) {
    const labels = {
      'Email':'Email','Phone':'Phone','Date':'Date','Amount':'Amount',
      'ID':'ID','Status':'Status','Name':'Name','City':'City',
      'Number':'Number',
    };
    return labels[type] ?? 'Column ${index + 1}';
  }

  /// Generates unique headers — no two columns share the same label
  static List<String> generateUniqueHeaders(List<String> types) {
    final labelCount = <String, int>{};
    for (int i = 0; i < types.length; i++) {
      final base = columnTypeToLabel(types[i], i);
      labelCount[base] = (labelCount[base] ?? 0) + 1;
    }
    final seen = <String, int>{};
    final headers = <String>[];
    for (int i = 0; i < types.length; i++) {
      final base = columnTypeToLabel(types[i], i);
      if ((labelCount[base] ?? 1) > 1) {
        seen[base] = (seen[base] ?? 0) + 1;
        headers.add('$base ${seen[base]}');
      } else {
        headers.add(base);
      }
    }
    return headers;
  }

  // ── Data Cleaning ──────────────────────────────────────────────────────────
  static String cleanCell(String value) {
    return value
        .trim()
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(RegExp(r"""^['"]+|['"]+$"""), '');
  }

  static String normalizeAmount(String v) {
    final c = v.replaceAll(RegExp(r'[₹\$€£¥,\s]'), '').trim();
    final n = double.tryParse(c);
    if (n == null) return v;
    return n == n.roundToDouble() ? n.toInt().toString() : n.toStringAsFixed(2);
  }

  static String normalizeDate(String value, String format) {
    final patterns = [
      {'p': RegExp(r'(\d{1,2})[-/](\d{1,2})[-/](\d{2,4})'), 't': 'dmy'},
      {'p': RegExp(r'(\d{4})[-/](\d{1,2})[-/](\d{1,2})'), 't': 'ymd'},
    ];
    for (final entry in patterns) {
      final m = (entry['p'] as RegExp).firstMatch(value);
      if (m != null) {
        try {
          DateTime? d;
          if (entry['t'] == 'dmy') {
            d = DateTime(
              int.parse(m.group(3)!.length == 2 ? '20${m.group(3)}' : m.group(3)!),
              int.parse(m.group(2)!), int.parse(m.group(1)!));
          } else {
            d = DateTime(int.parse(m.group(1)!), int.parse(m.group(2)!), int.parse(m.group(3)!));
          }
          if (d != null) return DateFormat(format).format(d);
        } catch (_) {}
      }
    }
    return value;
  }

  static String standardizeCapitalization(String value, String type) {
    if (value.isEmpty) return value;
    switch (type) {
      case 'Name': case 'City':
        return value.split(' ').map((w) => w.isEmpty
            ? '' : '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}').join(' ');
      case 'Email':  return value.toLowerCase();
      case 'Status': return '${value[0].toUpperCase()}${value.substring(1).toLowerCase()}';
      default: return value;
    }
  }

  // ── Header Detection ───────────────────────────────────────────────────────
  static bool looksLikeHeader(List<String> row) {
    if (row.isEmpty) return false;
    int textLike = 0;
    for (final cell in row) {
      final c = cell.trim();
      if (c.isEmpty) continue;
      if (c.length <= 30 && RegExp(r'^[A-Za-z\s_\-/]+$').hasMatch(c)) textLike++;
    }
    final nonEmpty = row.where((c) => c.trim().isNotEmpty).length;
    return nonEmpty > 0 && textLike / nonEmpty >= 0.6;
  }

  // ── Confidence ─────────────────────────────────────────────────────────────
  static double calculateParseConfidence(List<List<String>> rows, List<String> columnTypes) {
    if (rows.isEmpty) return 0.0;
    int ok = 0, total = 0;
    for (final row in rows.take(30)) {
      for (int i = 0; i < min(row.length, columnTypes.length); i++) {
        final v = row[i].trim();
        if (v.isEmpty) continue;
        total++;
        switch (columnTypes[i]) {
          case 'Email':  if (isEmail(v))       ok++; break;
          case 'Phone':  if (isPhoneNumber(v)) ok++; break;
          case 'Date':   if (isDate(v))        ok++; break;
          case 'Amount': if (isAmount(v))      ok++; break;
          default:       ok++;
        }
      }
    }
    return total == 0 ? 0.0 : ok / total;
  }

  // ── Formatters ─────────────────────────────────────────────────────────────
  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  static String formatDateTime(DateTime dt) =>
      DateFormat('dd MMM yyyy, hh:mm a').format(dt);
}
