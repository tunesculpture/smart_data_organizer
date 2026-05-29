import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../domain/entities/parsed_dataset.dart';

class ColumnMappingScreen extends StatefulWidget {
  final ParsedDataset dataset;

  const ColumnMappingScreen({super.key, required this.dataset});

  @override
  State<ColumnMappingScreen> createState() => _ColumnMappingScreenState();
}

class _ColumnMappingScreenState extends State<ColumnMappingScreen> {
  late List<String> _headers;
  late List<String> _types;
  late List<TextEditingController> _controllers;

  @override
  void initState() {
    super.initState();
    _headers = List<String>.from(widget.dataset.headers);
    _types = List<String>.from(widget.dataset.columnTypes);
    _controllers =
        _headers.map((h) => TextEditingController(text: h)).toList();
  }

  @override
  void dispose() {
    for (final c in _controllers) c.dispose();
    super.dispose();
  }

  void _apply() {
    for (int i = 0; i < _controllers.length; i++) {
      _headers[i] = _controllers[i].text.trim().isEmpty
          ? 'Column ${i + 1}'
          : _controllers[i].text.trim();
    }
    final updated = widget.dataset.copyWith(
      headers: _headers,
      columnTypes: _types,
    );
    Navigator.pop(context, updated);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceColor,
      appBar: AppBar(
        title: const Text('Column Mapping'),
        backgroundColor: Colors.white,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppTheme.borderColor, height: 1),
        ),
        actions: [
          TextButton(
            onPressed: _apply,
            child: const Text('Apply',
                style: TextStyle(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.w700)),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: AppTheme.primaryLight,
            child: const Row(
              children: [
                Icon(Icons.info_outline_rounded,
                    size: 16, color: AppTheme.primaryColor),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Rename columns and set their data type. This helps export and validation.',
                    style:
                        TextStyle(fontSize: 12, color: AppTheme.primaryColor),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _headers.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, i) {
                return _ColumnCard(
                  index: i + 1,
                  controller: _controllers[i],
                  selectedType: _types.length > i ? _types[i] : 'Text',
                  sampleValues: widget.dataset.rows
                      .take(3)
                      .map((r) => i < r.length ? r[i] : '')
                      .where((v) => v.isNotEmpty)
                      .toList(),
                  onTypeChanged: (type) {
                    setState(() {
                      if (i < _types.length) _types[i] = type;
                    });
                  },
                );
              },
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton(
                onPressed: _apply,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: const Text('Apply Column Mapping'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ColumnCard extends StatelessWidget {
  final int index;
  final TextEditingController controller;
  final String selectedType;
  final List<String> sampleValues;
  final ValueChanged<String> onTypeChanged;

  const _ColumnCard({
    required this.index,
    required this.controller,
    required this.selectedType,
    required this.sampleValues,
    required this.onTypeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Center(
                  child: Text(
                    '$index',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: controller,
                  decoration: const InputDecoration(
                    hintText: 'Column name',
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    isDense: true,
                  ),
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 14),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Text('Type: ',
                  style: TextStyle(
                      fontSize: 12, color: AppTheme.textSecondary)),
              const SizedBox(width: 4),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: selectedType,
                  isDense: true,
                  decoration: const InputDecoration(
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    isDense: true,
                  ),
                  items: AppConstants.columnTypes
                      .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) onTypeChanged(v);
                  },
                ),
              ),
            ],
          ),
          if (sampleValues.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Sample: ${sampleValues.take(3).join(', ')}',
              style: const TextStyle(
                  fontSize: 11, color: AppTheme.textHint),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}
