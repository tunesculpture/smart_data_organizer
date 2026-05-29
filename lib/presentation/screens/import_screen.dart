import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:dotted_border/dotted_border.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/app_utils.dart';
import '../providers/app_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/history_provider.dart';
import 'parsing_progress_screen.dart';

class ImportScreen extends StatefulWidget {
  const ImportScreen({super.key});
  @override
  State<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends State<ImportScreen> {
  PlatformFile? _file;
  String?       _preview;

  Future<void> _pick() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: AppConstants.supportedExtensions,
        withData: true,
      );
      if (result == null || result.files.isEmpty) return;
      final f = result.files.first;
      setState(() { _file = f; _preview = _genPreview(f); });
    } catch (e) {
      _snack('Could not open file: $e');
    }
  }

  String? _genPreview(PlatformFile f) {
    if (f.bytes == null) return null;
    final ext = f.extension?.toLowerCase() ?? '';
    if (['txt', 'csv', 'json'].contains(ext)) {
      try { return String.fromCharCodes(f.bytes!.take(1500)); } catch (_) {}
    }
    return '${f.name} — ${AppUtils.formatFileSize(f.size)}';
  }

  Future<void> _process() async {
    if (_file == null) return;
    final settings = context.read<SettingsProvider>();
    final app      = context.read<AppProvider>();
    final history  = context.read<HistoryProvider>();
    if (!mounted) return;

    Navigator.push(context, MaterialPageRoute(
      builder: (_) => ParsingProgressScreen(
        fileName:   _file!.name,
        onComplete: (ds) => history.addRecord(ds),
      ),
    ));

    try {
      final tmp  = await getTemporaryDirectory();
      final tmpF = File('${tmp.path}/${_file!.name}');
      await tmpF.writeAsBytes(_file!.bytes!);
      await app.parseFile(
        filePath:    tmpF.path,
        fileName:    _file!.name,
        aiEnabled:   settings.aiEnabled,
        apiKey:      settings.userApiKey,
        providerId:  settings.resolvedProviderId,
        endpointUrl: settings.resolvedEndpoint,
        modelName:   settings.resolvedModel,
      );
    } catch (e) {
      if (mounted) _snack('Error: $e');
    }
  }

  void _snack(String msg) => ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppTheme.errorColor));

  @override
  Widget build(BuildContext context) {
    final isDark  = Theme.of(context).brightness == Brightness.dark;
    final cardBg  = isDark ? AppTheme.darkCard : Colors.white;
    final borderC = isDark ? AppTheme.darkBorder : AppTheme.borderColor;
    final scaffBg = isDark ? AppTheme.darkBg : AppTheme.surfaceColor;

    return Scaffold(
      backgroundColor: scaffBg,
      appBar: AppBar(title: const Text('Upload File')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          // Drop zone
          GestureDetector(
            onTap: _pick,
            child: DottedBorder(
              color: _file != null ? AppTheme.accentColor : AppTheme.primaryColor.withOpacity(0.5),
              strokeWidth: 2, dashPattern: const [8, 4],
              borderType: BorderType.RRect, radius: const Radius.circular(16),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 44),
                decoration: BoxDecoration(
                  color: _file != null
                      ? AppTheme.accentColor.withOpacity(0.06)
                      : AppTheme.primaryColor.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(children: [
                  Icon(
                    _file != null ? Icons.check_circle_rounded : Icons.cloud_upload_rounded,
                    size: 54,
                    color: _file != null ? AppTheme.accentColor : AppTheme.primaryColor,
                  ),
                  const SizedBox(height: 14),
                  Text(
                    _file != null ? _file!.name : 'Tap to select a file',
                    style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700,
                      color: _file != null ? AppTheme.accentColor : AppTheme.primaryColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _file != null
                        ? AppUtils.formatFileSize(_file!.size)
                        : '.xlsx  .xls  .csv  .txt  .json',
                    style: TextStyle(
                      fontSize: 12,
                      color: _file != null
                          ? AppTheme.accentColor.withOpacity(0.8)
                          : AppTheme.textSecondary,
                    ),
                  ),
                ]),
              ),
            ),
          ),

          // Raw preview
          if (_preview != null && _preview!.length > 5) ...[
            const SizedBox(height: 20),
            Text('Raw Preview',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700,
                    color: isDark ? AppTheme.darkText : AppTheme.textPrimary)),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxHeight: 180),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(10),
              ),
              child: SingleChildScrollView(
                child: Text(
                  _preview!.length > 900 ? '${_preview!.substring(0, 900)}…' : _preview!,
                  style: const TextStyle(
                      fontFamily: 'monospace', fontSize: 11, color: Color(0xFF94D2BD)),
                ),
              ),
            ),
          ],

          const SizedBox(height: 20),

          // Info card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: cardBg, borderRadius: BorderRadius.circular(10),
              border: Border.all(color: borderC),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Supported formats',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13,
                      color: isDark ? AppTheme.darkText : AppTheme.textPrimary)),
              const SizedBox(height: 10),
              ...[
                'Excel .xlsx / .xls — single or multiple sheets',
                'CSV — comma, tab, semicolon delimiters',
                'Text files — pipe |, tilde ~, mixed separators',
                'JSON — arrays and objects',
                'Any messy/complex data — AI organizes perfectly (add key in Settings)',
              ].map((t) => Padding(
                padding: const EdgeInsets.only(bottom: 5),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('• ', style: TextStyle(
                      color: AppTheme.primaryColor, fontWeight: FontWeight.w700)),
                  Expanded(child: Text(t, style: const TextStyle(
                      fontSize: 12, color: AppTheme.textSecondary))),
                ]),
              )),
            ]),
          ),
          const SizedBox(height: 100),
        ]),
      ),
      bottomNavigationBar: _file != null
          ? SafeArea(child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: Row(children: [
                Expanded(child: OutlinedButton(
                  onPressed: () => setState(() { _file = null; _preview = null; }),
                  child: const Text('Clear'),
                )),
                const SizedBox(width: 12),
                Expanded(flex: 2, child: ElevatedButton.icon(
                  onPressed: _process,
                  icon: const Icon(Icons.auto_fix_high_rounded),
                  label: const Text('Parse & Organize'),
                )),
              ]),
            ))
          : null,
    );
  }
}
