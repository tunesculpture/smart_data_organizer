import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../providers/app_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/history_provider.dart';
import 'parsing_progress_screen.dart';
import 'settings_screen.dart';

class PasteTextScreen extends StatefulWidget {
  const PasteTextScreen({super.key});
  @override
  State<PasteTextScreen> createState() => _PasteTextScreenState();
}

class _PasteTextScreenState extends State<PasteTextScreen> {
  final _ctrl = TextEditingController();
  bool _hasText = false;

  static const _examples = [
    {
      'label': 'CSV (comma separated)',
      'text':
          'Rahul Sharma, Delhi, 9876543210, rahul@gmail.com\n'
          'Priya Verma, Mumbai, 8765432109, priya@yahoo.com\n'
          'Ajay Kumar, Kolkata, 7654321098, ajay@outlook.com',
    },
    {
      'label': 'Booking (tilde + Key|Value)',
      'text':
          'B001~Rahul Sharma~Delhi~CheckIn|01-03-2026~CheckOut|03-03-2026~Guests|2~4500~Confirmed\n'
          'B002~Priya Verma~Mumbai~CheckIn|05-03-2026~CheckOut|07-03-2026~Guests|1~3200~Pending\n'
          'B003~Ajay Kumar~Kolkata~CheckIn|10-03-2026~CheckOut|12-03-2026~Guests|3~6000~Confirmed',
    },
    {
      'label': 'Natural language (AI)',
      'text':
          'Rahul from Delhi arriving 1 March, 2 guests, paid 4500, confirmed\n'
          'Priya from Mumbai arriving 5 March, 1 guest, paid 3200, pending\n'
          'Ajay from Kolkata arriving 10 March, 3 guests, paid 6000, confirmed',
    },
  ];

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  Future<void> _parse() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;

    final settings = context.read<SettingsProvider>();

    if (settings.aiEnabled && !settings.hasApiKey) {
      final go = await _noKeyDialog();
      if (go == null) return;
      if (go == 'settings') {
        if (mounted) Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
        return;
      }
    }

    final app     = context.read<AppProvider>();
    final history = context.read<HistoryProvider>();
    if (!mounted) return;

    Navigator.push(context, MaterialPageRoute(
      builder: (_) => ParsingProgressScreen(
        fileName:   'Pasted Data',
        onComplete: (ds) => history.addRecord(ds),
      ),
    ));

    await app.parsePastedText(
      text:        text,
      aiEnabled:   settings.aiEnabled,
      apiKey:      settings.userApiKey,
      providerId:  settings.resolvedProviderId,
      endpointUrl: settings.resolvedEndpoint,
      modelName:   settings.resolvedModel,
    );
  }

  Future<String?> _noKeyDialog() => showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('No AI Key Set'),
      content: const Text(
        'No API key found. Add one in Settings for best results.\n\n'
        'Continue without AI for basic structured text.',
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, 'settings'), child: const Text('Go to Settings')),
        ElevatedButton(onPressed: () => Navigator.pop(ctx, 'continue'), child: const Text('Continue')),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceColor,
      appBar: AppBar(
        title: const Text('Paste Raw Text'),
        backgroundColor: Colors.white,
        elevation: 0,
        bottom: PreferredSize(preferredSize: const Size.fromHeight(1),
            child: Container(color: AppTheme.borderColor, height: 1)),
      ),
      body: Column(children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _hasText ? AppTheme.primaryColor : AppTheme.borderColor,
                    width: _hasText ? 2 : 1,
                  ),
                ),
                child: Column(children: [
                  TextField(
                    controller: _ctrl,
                    maxLines: 12,
                    onChanged: (v) => setState(() => _hasText = v.trim().isNotEmpty),
                    style: const TextStyle(fontSize: 13, fontFamily: 'monospace'),
                    decoration: const InputDecoration(
                      hintText:
                          'Paste your messy data here...\n\n'
                          'Examples:\n'
                          '• Name, City, Phone, Email\n'
                          '• ID~Name~City~Amount~Status\n'
                          '• B001~Rahul~Delhi~CheckIn|01-03-2026~4500~Confirmed\n'
                          '• Natural language sentences',
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: EdgeInsets.all(16),
                    ),
                  ),
                  if (_ctrl.text.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        Text('${_ctrl.text.split('\n').length} lines',
                            style: const TextStyle(fontSize: 11, color: AppTheme.textHint)),
                        TextButton(
                          onPressed: () { _ctrl.clear(); setState(() => _hasText = false); },
                          child: const Text('Clear', style: TextStyle(color: AppTheme.errorColor)),
                        ),
                      ]),
                    ),
                ]),
              ),
              const SizedBox(height: 20),
              const Text('Try an example:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
              const SizedBox(height: 10),
              ..._examples.map((ex) => _ExTile(
                label: ex['label']!,
                text:  ex['text']!,
                onTap: () { _ctrl.text = ex['text']!; setState(() => _hasText = true); },
              )),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.warningColor.withOpacity(0.3)),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Row(children: [
                    Icon(Icons.lightbulb_outline_rounded, size: 16, color: AppTheme.warningColor),
                    SizedBox(width: 6),
                    Text('Tips', style: TextStyle(fontWeight: FontWeight.w700, color: AppTheme.warningColor, fontSize: 13)),
                  ]),
                  const SizedBox(height: 8),
                  ...[
                    'Each line = one record',
                    'Separators: comma, pipe |, tilde ~, tab, semicolon',
                    'Sub-tokens like CheckIn|01-03-2026 are split correctly',
                    'Natural language needs an AI API key in Settings',
                  ].map((t) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('• ', style: TextStyle(color: AppTheme.warningColor, fontWeight: FontWeight.w700)),
                      Expanded(child: Text(t, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary))),
                    ]),
                  )),
                ]),
              ),
            ]),
          ),
        ),
        SafeArea(
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: AppTheme.borderColor)),
            ),
            child: ElevatedButton.icon(
              onPressed: _hasText ? _parse : null,
              icon: const Icon(Icons.auto_fix_high_rounded),
              label: const Text('Parse & Organize'),
              style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
            ),
          ),
        ),
      ]),
    );
  }
}

class _ExTile extends StatelessWidget {
  final String label, text;
  final VoidCallback onTap;
  const _ExTile({required this.label, required this.text, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppTheme.borderColor)),
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: AppTheme.primaryColor)),
          const SizedBox(height: 3),
          Text(text.length > 90 ? '${text.substring(0, 90)}…' : text,
              style: const TextStyle(fontSize: 11, fontFamily: 'monospace', color: AppTheme.textSecondary)),
        ])),
        const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppTheme.textHint),
      ]),
    ),
  );
}
