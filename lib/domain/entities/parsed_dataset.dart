class ParsedDataset {
  final String id;
  final String fileName;
  final String sourceType; // 'file' | 'paste'
  final List<String> headers;
  final List<List<String>> rows;
  final List<String> columnTypes;
  final double confidence;
  final bool wasAiParsed;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const ParsedDataset({
    required this.id,
    required this.fileName,
    required this.sourceType,
    required this.headers,
    required this.rows,
    required this.columnTypes,
    required this.confidence,
    this.wasAiParsed = false,
    required this.createdAt,
    this.updatedAt,
  });

  int get rowCount => rows.length;
  int get columnCount => headers.length;

  ParsedDataset copyWith({
    String? id,
    String? fileName,
    String? sourceType,
    List<String>? headers,
    List<List<String>>? rows,
    List<String>? columnTypes,
    double? confidence,
    bool? wasAiParsed,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ParsedDataset(
      id: id ?? this.id,
      fileName: fileName ?? this.fileName,
      sourceType: sourceType ?? this.sourceType,
      headers: headers ?? this.headers,
      rows: rows ?? this.rows,
      columnTypes: columnTypes ?? this.columnTypes,
      confidence: confidence ?? this.confidence,
      wasAiParsed: wasAiParsed ?? this.wasAiParsed,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fileName': fileName,
      'sourceType': sourceType,
      'headers': headers,
      'rows': rows,
      'columnTypes': columnTypes,
      'confidence': confidence,
      'wasAiParsed': wasAiParsed,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  factory ParsedDataset.fromJson(Map<String, dynamic> json) {
    return ParsedDataset(
      id: json['id'] as String,
      fileName: json['fileName'] as String,
      sourceType: json['sourceType'] as String,
      headers: List<String>.from(json['headers'] as List),
      rows: (json['rows'] as List)
          .map((r) => List<String>.from(r as List))
          .toList(),
      columnTypes: List<String>.from(json['columnTypes'] as List),
      confidence: (json['confidence'] as num).toDouble(),
      wasAiParsed: json['wasAiParsed'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }
}

class HistoryRecord {
  final String id;
  final String fileName;
  final String sourceType;
  final int rowCount;
  final int columnCount;
  final bool wasAiParsed;
  final DateTime processedAt;
  final String datasetJson;

  const HistoryRecord({
    required this.id,
    required this.fileName,
    required this.sourceType,
    required this.rowCount,
    required this.columnCount,
    required this.wasAiParsed,
    required this.processedAt,
    required this.datasetJson,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'fileName': fileName,
    'sourceType': sourceType,
    'rowCount': rowCount,
    'columnCount': columnCount,
    'wasAiParsed': wasAiParsed,
    'processedAt': processedAt.toIso8601String(),
    'datasetJson': datasetJson,
  };

  factory HistoryRecord.fromJson(Map<String, dynamic> json) => HistoryRecord(
    id: json['id'] as String,
    fileName: json['fileName'] as String,
    sourceType: json['sourceType'] as String,
    rowCount: json['rowCount'] as int,
    columnCount: json['columnCount'] as int,
    wasAiParsed: json['wasAiParsed'] as bool? ?? false,
    processedAt: DateTime.parse(json['processedAt'] as String),
    datasetJson: json['datasetJson'] as String,
  );
}
