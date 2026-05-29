import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/entities/parsed_dataset.dart';
import '../providers/app_provider.dart';
import 'spreadsheet_editor_screen.dart';

class ParsingProgressScreen extends StatefulWidget {
  final String fileName;
  final Function(ParsedDataset)? onComplete;
  const ParsingProgressScreen({
    super.key,
    required this.fileName,
    this.onComplete,
  });
  @override
  State<ParsingProgressScreen> createState() => _State();
}

class _State extends State<ParsingProgressScreen> {
  bool _done = false;

  @override
  void initState() {
    super.initState();
    // Listen AFTER the first frame so provider is fully ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AppProvider>().addListener(_onChanged);
      // Check immediately in case parsing already finished
      _onChanged();
    });
  }

  @override
  void dispose() {
    // Safe remove — provider may already be disposed
    try { context.read<AppProvider>().removeListener(_onChanged); } catch (_) {}
    super.dispose();
  }

  void _onChanged() {
    if (_done || !mounted) return;
    final prov = context.read<AppProvider>();

    if (prov.state == AppState.success && prov.currentDataset != null) {
      _done = true;
      final ds = prov.currentDataset!;
      widget.onComplete?.call(ds);
      // Use addPostFrameCallback so we never navigate during a build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => SpreadsheetEditorScreen(dataset: ds),
          ),
        );
      });
    } else if (prov.state == AppState.error) {
      _done = true;
      final err = prov.errorMessage ?? 'Parsing failed';
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        // Pop back so user can try again — NEVER stuck
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(err),
            backgroundColor: AppTheme.errorColor,
            duration: const Duration(seconds: 6),
            action: SnackBarAction(
              label: 'OK',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // canPop:false only while actively parsing — error releases it via Navigator.pop
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: Consumer<AppProvider>(
          builder: (_, prov, __) => Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF1D4ED8), Color(0xFF2563EB), Color(0xFF0EA5E9)],
              ),
            ),
            child: SafeArea(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 36),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Spinner
                      Container(
                        width: 110,
                        height: 110,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const SpinKitDoubleBounce(
                            color: Colors.white, size: 80),
                      ),
                      const SizedBox(height: 36),
                      const Text(
                        'Processing Your Data',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.fileName,
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 13),
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                      ),
                      const SizedBox(height: 32),
                      // Progress bar
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: prov.parsingProgress,
                          minHeight: 8,
                          backgroundColor: Colors.white24,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                              Colors.white),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        prov.parsingStatus.isEmpty
                            ? 'Initializing...'
                            : prov.parsingStatus,
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 52),
                      _Steps(progress: prov.parsingProgress),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Steps extends StatelessWidget {
  final double progress;
  const _Steps({required this.progress});

  @override
  Widget build(BuildContext context) {
    final steps = [
      {'label': 'Read',    'at': 0.15},
      {'label': 'AI',      'at': 0.40},
      {'label': 'Schema',  'at': 0.70},
      {'label': 'Apply',   'at': 0.88},
      {'label': 'Done',    'at': 1.00},
    ];
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: steps.asMap().entries.map((e) {
        final done = progress >= (e.value['at'] as double);
        return Row(children: [
          Column(children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: done ? Colors.white : Colors.white24,
                shape: BoxShape.circle,
              ),
              child: Icon(
                done ? Icons.check_rounded : Icons.circle,
                size: done ? 18 : 8,
                color: done ? AppTheme.primaryColor : Colors.white54,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              e.value['label'] as String,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: done ? Colors.white : Colors.white38,
              ),
            ),
          ]),
          if (e.key < steps.length - 1)
            Container(
              width: 26,
              height: 2,
              color: progress > (e.value['at'] as double)
                  ? Colors.white
                  : Colors.white24,
            ),
        ]);
      }).toList(),
    );
  }
}
