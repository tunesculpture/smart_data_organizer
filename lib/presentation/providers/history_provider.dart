import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/parsed_dataset.dart';
import '../../core/constants/app_constants.dart';

class HistoryProvider extends ChangeNotifier {
  List<HistoryRecord> _records = [];

  List<HistoryRecord> get records => List.unmodifiable(_records);

  Future<void> init() async {
    await _load();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getStringList(AppConstants.keyHistory) ?? [];
      _records = raw
          .map((s) => HistoryRecord.fromJson(json.decode(s) as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => b.processedAt.compareTo(a.processedAt));
      notifyListeners();
    } catch (_) {
      _records = [];
    }
  }

  Future<void> addRecord(ParsedDataset dataset) async {
    final record = HistoryRecord(
      id: dataset.id,
      fileName: dataset.fileName,
      sourceType: dataset.sourceType,
      rowCount: dataset.rowCount,
      columnCount: dataset.columnCount,
      wasAiParsed: dataset.wasAiParsed,
      processedAt: DateTime.now(),
      datasetJson: json.encode(dataset.toJson()),
    );
    _records.insert(0, record);
    // Keep only last 50
    if (_records.length > 50) {
      _records = _records.take(50).toList();
    }
    await _save();
    notifyListeners();
  }

  Future<void> deleteRecord(String id) async {
    _records.removeWhere((r) => r.id == id);
    await _save();
    notifyListeners();
  }

  Future<void> clearAll() async {
    _records.clear();
    await _save();
    notifyListeners();
  }

  ParsedDataset? getDataset(String id) {
    try {
      final record = _records.firstWhere((r) => r.id == id);
      return ParsedDataset.fromJson(
        json.decode(record.datasetJson) as Map<String, dynamic>,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = _records.map((r) => json.encode(r.toJson())).toList();
    await prefs.setStringList(AppConstants.keyHistory, raw);
  }
}
