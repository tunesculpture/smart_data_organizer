import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../providers/settings_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg   = isDark ? AppTheme.darkCard    : Colors.white;
    final borderC  = isDark ? AppTheme.darkBorder  : AppTheme.borderColor;
    final scaffBg  = isDark ? AppTheme.darkBg      : AppTheme.surfaceColor;

    return Scaffold(
      backgroundColor: scaffBg,
      appBar: AppBar(title: const Text('Settings')),
      body: Consumer<SettingsProvider>(
        builder: (context, s, _) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [

              // ── AI API Key ────────────────────────────────────────────────
              _Header('AI Parsing'),
              _Card(bg: cardBg, border: borderC, children: [
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    // Status row
                    Row(children: [
                      Icon(
                        s.hasApiKey ? Icons.check_circle_rounded : Icons.warning_amber_rounded,
                        color: s.hasApiKey ? AppTheme.accentColor : AppTheme.warningColor,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          s.hasApiKey
                              ? 'API Key Set — ${s.providerDisplayName}'
                              : 'No API Key — AI parsing disabled',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: s.hasApiKey ? AppTheme.accentColor : AppTheme.warningColor,
                          ),
                        ),
                      ),
                    ]),
                    if (s.hasApiKey) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Auto-detected: ${s.providerDisplayName} · ${s.resolvedModel}',
                        style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                      ),
                    ],
                    const SizedBox(height: 12),
                    // Info box
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1A2744) : AppTheme.primaryLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Works with any AI API:\n'
                        '• OpenAI  (sk-proj-...)\n'
                        '• Google Gemini  (AIza...)\n'
                        '• Groq — free & fast  (gsk_...)\n'
                        '• Anthropic Claude  (sk-ant-...)\n'
                        '• DeepSeek  (sk-...)\n'
                        '• Any OpenAI-compatible API',
                        style: TextStyle(fontSize: 11, color: AppTheme.primaryColor, height: 1.6),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Main key button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _showApiKeyDialog(context, s),
                        icon: Icon(s.hasApiKey ? Icons.edit_rounded : Icons.add_rounded, size: 18),
                        label: Text(s.hasApiKey ? 'Update API Key' : 'Add API Key'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: s.hasApiKey ? AppTheme.primaryColor : AppTheme.warningColor,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    if (s.hasApiKey) ...[
                      const SizedBox(height: 8),
                      Center(
                        child: TextButton(
                          onPressed: () { s.setUserApiKey(''); s.setCustomEndpoint(''); s.setCustomModel(''); },
                          child: const Text('Remove Key', style: TextStyle(color: AppTheme.errorColor, fontSize: 12)),
                        ),
                      ),
                    ],
                  ]),
                ),
                Divider(height: 1, color: borderC),
                SwitchListTile(
                  value: s.aiEnabled,
                  onChanged: s.setAiEnabled,
                  title: const Text('Enable AI Parsing', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  subtitle: const Text('Sends only 5 rows to AI — saves your token quota',
                      style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                  secondary: Container(
                    width: 38, height: 38,
                    decoration: BoxDecoration(color: const Color(0xFFF3E8FF), borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.auto_awesome_rounded, color: Color(0xFF7C3AED), size: 20),
                  ),
                  activeColor: AppTheme.primaryColor,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                ),
              ]),

              const SizedBox(height: 8),

              // ── Appearance ─────────────────────────────────────────────────
              _Header('Appearance'),
              _Card(bg: cardBg, border: borderC, children: [
                _Tile(icon: Icons.palette_rounded, iconColor: AppTheme.primaryColor,
                    bgColor: AppTheme.primaryLight,
                    title: 'Theme', subtitle: _themeName(s.themeMode),
                    onTap: () => _picker(context, isDark: isDark,
                        title: 'Select Theme',
                        options: ['Light', 'Dark', 'System Default'],
                        selected: _themeName(s.themeMode),
                        onSelected: (v) => s.setThemeMode(
                          v == 'Dark' ? ThemeMode.dark
                              : v == 'System Default' ? ThemeMode.system
                              : ThemeMode.light,
                        ))),
              ]),

              const SizedBox(height: 8),

              // ── Export ─────────────────────────────────────────────────────
              _Header('Export'),
              _Card(bg: cardBg, border: borderC, children: [
                _Tile(icon: Icons.file_download_rounded, iconColor: AppTheme.warningColor,
                    bgColor: const Color(0xFFFFF7ED),
                    title: 'Default Format', subtitle: '.${s.defaultExportFormat.toUpperCase()}',
                    onTap: () => _picker(context, isDark: isDark,
                        title: 'Default Export Format',
                        options: AppConstants.exportFormats.map((f) => '.${f.toUpperCase()}').toList(),
                        selected: '.${s.defaultExportFormat.toUpperCase()}',
                        onSelected: (v) => s.setDefaultExportFormat(v.replaceAll('.', '').toLowerCase()))),
              ]),

              const SizedBox(height: 8),

              // ── Data Formatting ────────────────────────────────────────────
              _Header('Data Formatting'),
              _Card(bg: cardBg, border: borderC, children: [
                _Tile(icon: Icons.calendar_today_rounded, iconColor: AppTheme.primaryColor,
                    bgColor: const Color(0xFFEFF6FF),
                    title: 'Date Format', subtitle: s.dateFormat,
                    onTap: () => _picker(context, isDark: isDark,
                        title: 'Date Format', options: AppConstants.dateFormats,
                        selected: s.dateFormat, onSelected: s.setDateFormat)),
                Divider(height: 1, indent: 66, color: borderC),
                _Tile(icon: Icons.currency_rupee_rounded, iconColor: AppTheme.accentColor,
                    bgColor: const Color(0xFFF0FDF4),
                    title: 'Currency Format', subtitle: s.currencyFormat,
                    onTap: () => _picker(context, isDark: isDark,
                        title: 'Currency Format', options: AppConstants.currencyFormats,
                        selected: s.currencyFormat, onSelected: s.setCurrencyFormat)),
              ]),

              const SizedBox(height: 8),

              // ── About ──────────────────────────────────────────────────────
              _Header('About'),
              _Card(bg: cardBg, border: borderC, children: [
                _Tile(icon: Icons.info_outline_rounded, iconColor: AppTheme.primaryColor,
                    bgColor: AppTheme.primaryLight,
                    title: 'App Version', subtitle: 'v${AppConstants.appVersion}', onTap: null),
              ]),
              const SizedBox(height: 30),
            ],
          );
        },
      ),
    );
  }

  // ── API Key Dialog — simple single input ───────────────────────────────────
  void _showApiKeyDialog(BuildContext context, SettingsProvider s) {
    final keyCtrl      = TextEditingController(text: s.userApiKey);
    final urlCtrl      = TextEditingController(text: s.customEndpoint);
    final modelCtrl    = TextEditingController(text: s.customModel);
    bool obscure       = true;
    bool showAdvanced  = s.customEndpoint.isNotEmpty;
    final isDark       = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          backgroundColor: isDark ? AppTheme.darkCard : Colors.white,
          title: const Text('AI API Key'),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Supported providers info
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1A2744) : AppTheme.primaryLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Paste your API key below.\nSupports: OpenAI, Gemini, Groq, Claude, DeepSeek or any compatible API.\nProvider is auto-detected from your key.',
                  style: TextStyle(fontSize: 11, color: AppTheme.primaryColor, height: 1.5),
                ),
              ),
              const SizedBox(height: 14),
              // API Key input
              TextField(
                controller: keyCtrl,
                obscureText: obscure,
                decoration: InputDecoration(
                  labelText: 'API Key',
                  hintText: 'sk-..., AIza..., gsk_..., sk-ant-...',
                  suffixIcon: IconButton(
                    icon: Icon(obscure ? Icons.visibility_rounded : Icons.visibility_off_rounded, size: 20),
                    onPressed: () => setState(() => obscure = !obscure),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // Advanced toggle
              TextButton.icon(
                onPressed: () => setState(() => showAdvanced = !showAdvanced),
                icon: Icon(showAdvanced ? Icons.expand_less : Icons.expand_more, size: 16),
                label: Text(showAdvanced ? 'Hide Advanced' : 'Advanced (custom endpoint)',
                    style: const TextStyle(fontSize: 12)),
              ),
              if (showAdvanced) ...[
                const SizedBox(height: 8),
                TextField(
                  controller: urlCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Custom Endpoint URL (optional)',
                    hintText: 'https://api.example.com/v1/chat/completions',
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: modelCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Custom Model Name (optional)',
                    hintText: 'gpt-3.5-turbo / llama3 / etc.',
                  ),
                ),
              ],
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                s.setUserApiKey(keyCtrl.text);
                s.setCustomEndpoint(urlCtrl.text);
                s.setCustomModel(modelCtrl.text);
                Navigator.pop(ctx);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  String _themeName(ThemeMode m) {
    switch (m) {
      case ThemeMode.light:  return 'Light';
      case ThemeMode.dark:   return 'Dark';
      case ThemeMode.system: return 'System Default';
    }
  }

  void _picker(BuildContext context, {
    required bool isDark,
    required String title,
    required List<String> options,
    required String selected,
    required ValueChanged<String> onSelected,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppTheme.darkCard : Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
          child: Row(children: [
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const Spacer(),
            IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(ctx)),
          ]),
        ),
        Divider(height: 1, color: isDark ? AppTheme.darkBorder : AppTheme.borderColor),
        ...options.map((opt) => ListTile(
          title: Text(opt),
          trailing: opt == selected ? const Icon(Icons.check_rounded, color: AppTheme.primaryColor) : null,
          onTap: () { onSelected(opt); Navigator.pop(ctx); },
        )),
        const SizedBox(height: 8),
      ])),
    );
  }
}

class _Header extends StatelessWidget {
  final String title;
  const _Header(this.title);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(4, 10, 0, 8),
    child: Text(title, style: const TextStyle(
        fontSize: 11, fontWeight: FontWeight.w700,
        color: AppTheme.textSecondary, letterSpacing: 0.5)),
  );
}

class _Card extends StatelessWidget {
  final List<Widget> children;
  final Color bg, border;
  const _Card({required this.children, required this.bg, required this.border});
  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: bg, borderRadius: BorderRadius.circular(12),
      border: Border.all(color: border),
    ),
    child: Column(children: children),
  );
}

class _Tile extends StatelessWidget {
  final IconData icon; final Color iconColor, bgColor;
  final String title, subtitle; final VoidCallback? onTap;
  const _Tile({required this.icon, required this.iconColor, required this.bgColor,
      required this.title, required this.subtitle, required this.onTap});
  @override
  Widget build(BuildContext context) => ListTile(
    leading: Container(width: 38, height: 38,
        decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, color: iconColor, size: 20)),
    title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
    subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
    trailing: onTap != null ? const Icon(Icons.arrow_forward_ios_rounded, size: 14) : null,
    onTap: onTap,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
  );
}
