import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../data/datasources/export_service.dart';
import '../../domain/entities/parsed_dataset.dart';
import '../providers/settings_provider.dart';

class ExportScreen extends StatefulWidget {
  final ParsedDataset dataset;
  const ExportScreen({super.key, required this.dataset});
  @override
  State<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends State<ExportScreen> {
  final _svc = ExportService();
  late String _fmt;
  bool _loading = false;
  String? _savedPath;

  @override
  void initState() {
    super.initState();
    _fmt = context.read<SettingsProvider>().defaultExportFormat;
  }

  Future<void> _export({bool share = false}) async {
    setState(() { _loading = true; _savedPath = null; });
    final result = await _svc.export(dataset: widget.dataset, format: _fmt, shareAfter: share);
    setState(() => _loading = false);
    if (result.success) {
      setState(() => _savedPath = result.filePath);
      _snack('Saved to Downloads/SmartDataOrganizer/', success: true);
    } else {
      _snack(result.error ?? 'Export failed', success: false);
    }
  }

  void _snack(String msg, {required bool success}) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg),
        backgroundColor: success ? AppTheme.accentColor : AppTheme.errorColor,
        duration: const Duration(seconds: 4),
      ));

  @override
  Widget build(BuildContext context) {
    final ds = widget.dataset;
    return Scaffold(
      appBar: AppBar(title: const Text('Export Data'), elevation: 0,
          bottom: PreferredSize(preferredSize: const Size.fromHeight(1),
              child: Container(color: AppTheme.borderColor, height: 1))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Summary
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.borderColor)),
            child: Row(children: [
              Container(width: 50, height: 50,
                  decoration: BoxDecoration(color: AppTheme.primaryLight, borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.table_chart_rounded, color: AppTheme.primaryColor, size: 26)),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(ds.fileName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                    overflow: TextOverflow.ellipsis),
                Text('${ds.rowCount} rows · ${ds.columnCount} columns',
                    style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                Text('AI: ${ds.wasAiParsed ? "Yes" : "No"}  ·  Confidence: ${(ds.confidence * 100).toStringAsFixed(0)}%',
                    style: const TextStyle(fontSize: 11, color: AppTheme.textHint)),
              ])),
            ]),
          ),
          const SizedBox(height: 24),
          const Text('Select Format', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          ...AppConstants.exportFormats.map((f) => _FmtTile(
            format: f, selected: _fmt == f, onTap: () => setState(() => _fmt = f),
          )),
          const SizedBox(height: 20),
          if (_savedPath != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: const Color(0xFFF0FDF4), borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.accentColor.withOpacity(0.4))),
              child: Row(children: [
                const Icon(Icons.check_circle_rounded, color: AppTheme.accentColor, size: 20),
                const SizedBox(width: 10),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Saved!', style: TextStyle(fontWeight: FontWeight.w700, color: AppTheme.accentColor, fontSize: 13)),
                  Text(_savedPath!, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                      overflow: TextOverflow.ellipsis),
                ])),
              ]),
            ),
            const SizedBox(height: 16),
          ],
          if (_loading)
            const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()))
          else ...[
            ElevatedButton.icon(
              onPressed: () => _export(share: false),
              icon: const Icon(Icons.save_alt_rounded),
              label: const Text('Save to Downloads'),
              style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () => _export(share: true),
              icon: const Icon(Icons.share_rounded),
              label: const Text('Export & Share'),
              style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: _svc.getClipboardText(ds)));
                _snack('Copied to clipboard!', success: true);
              },
              icon: const Icon(Icons.copy_rounded),
              label: const Text('Copy Table to Clipboard'),
              style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
            ),
          ],
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: const Color(0xFFFFFBEB), borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.warningColor.withOpacity(0.3))),
            child: const Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(Icons.folder_open_rounded, size: 16, color: AppTheme.warningColor),
              SizedBox(width: 8),
              Expanded(child: Text('Files saved to: Downloads/SmartDataOrganizer/\nStorage permission will be requested automatically.',
                  style: TextStyle(fontSize: 12, color: AppTheme.textSecondary))),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _FmtTile extends StatelessWidget {
  final String format; final bool selected; final VoidCallback onTap;
  const _FmtTile({required this.format, required this.selected, required this.onTap});
  static const _meta = {
    'xlsx': {'icon': Icons.table_chart_rounded,      'color': 0xFF059669, 'desc': 'Excel Spreadsheet'},
    'csv':  {'icon': Icons.grid_on_rounded,           'color': 0xFF0891B2, 'desc': 'Comma-Separated Values'},
    'json': {'icon': Icons.data_object_rounded,       'color': 0xFFF59E0B, 'desc': 'JSON — for developers'},
    'txt':  {'icon': Icons.text_snippet_rounded,      'color': 0xFF64748B, 'desc': 'Plain text table'},
    'pdf':  {'icon': Icons.picture_as_pdf_rounded,    'color': 0xFFDC2626, 'desc': 'PDF — for printing'},
  };
  @override
  Widget build(BuildContext context) {
    final m = _meta[format] ?? _meta['txt']!;
    final color = Color(m['color'] as int);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.06) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: selected ? color : AppTheme.borderColor, width: selected ? 2 : 1),
        ),
        child: Row(children: [
          Icon(m['icon'] as IconData, color: color, size: 26),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('.${format.toUpperCase()}', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: color)),
            Text(m['desc'] as String, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
          ])),
          if (selected) Icon(Icons.check_circle_rounded, color: color)
          else const Icon(Icons.radio_button_unchecked_rounded, color: AppTheme.textHint),
        ]),
      ),
    );
  }
}
