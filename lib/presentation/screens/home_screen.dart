import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../data/datasources/ad_service.dart';
import '../providers/settings_provider.dart';
import 'import_screen.dart';
import 'paste_text_screen.dart';
import 'history_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 190,
            floating: false,
            pinned: true,
            backgroundColor: AppTheme.primaryColor,
            automaticallyImplyLeading: false,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                    colors: [Color(0xFF1D4ED8), Color(0xFF2563EB)],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        const Icon(Icons.table_chart_rounded, color: Colors.white, size: 28),
                        Row(children: [
                          _iconBtn(context, Icons.history_rounded, () => _goto(context, const HistoryScreen())),
                          const SizedBox(width: 4),
                          _iconBtn(context, Icons.settings_rounded, () => _goto(context, const SettingsScreen())),
                        ]),
                      ]),
                      const SizedBox(height: 16),
                      const Text('Smart Data Organizer',
                          style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 4),
                      const Text('Import messy data → Clean structured table',
                          style: TextStyle(color: Colors.white70, fontSize: 13)),
                    ]),
                  ),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // API key warning banner
                if (!settings.hasApiKey) ...[
                  FadeInDown(
                    child: GestureDetector(
                      onTap: () => _goto(context, const SettingsScreen()),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF7ED),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppTheme.warningColor.withOpacity(0.4)),
                        ),
                        child: const Row(children: [
                          Icon(Icons.warning_amber_rounded, color: AppTheme.warningColor, size: 18),
                          SizedBox(width: 10),
                          Expanded(child: Text(
                            'Add your OpenAI API key in Settings to enable AI parsing.',
                            style: TextStyle(fontSize: 12, color: AppTheme.warningColor, fontWeight: FontWeight.w600),
                          )),
                          Icon(Icons.arrow_forward_ios_rounded, size: 12, color: AppTheme.warningColor),
                        ]),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                FadeInUp(child: _sectionTitle('Import Data')),
                const SizedBox(height: 12),
                FadeInUp(
                  delay: const Duration(milliseconds: 80),
                  child: _ImportCard(
                    icon: Icons.upload_file_rounded, title: 'Upload File',
                    subtitle: '.xlsx  ·  .xls  ·  .csv  ·  .txt  ·  .json',
                    color: AppTheme.primaryColor,
                    onTap: () => _goto(context, const ImportScreen()),
                  ),
                ),
                const SizedBox(height: 12),
                FadeInUp(
                  delay: const Duration(milliseconds: 140),
                  child: _ImportCard(
                    icon: Icons.content_paste_rounded, title: 'Paste Raw Text',
                    subtitle: 'Paste any messy data and AI organizes it',
                    color: AppTheme.accentColor,
                    onTap: () => _goto(context, const PasteTextScreen()),
                  ),
                ),
                const SizedBox(height: 16),
                const Center(child: BannerAdWidget()),
                const SizedBox(height: 20),
                FadeInUp(delay: const Duration(milliseconds: 200), child: _sectionTitle('Features')),
                const SizedBox(height: 12),
                FadeInUp(delay: const Duration(milliseconds: 250), child: const _FeaturesGrid()),
                const SizedBox(height: 24),
                FadeInUp(delay: const Duration(milliseconds: 300), child: const _FormatsCard()),
                const SizedBox(height: 30),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _iconBtn(BuildContext context, IconData icon, VoidCallback onTap) => Material(
    color: Colors.white.withOpacity(0.15),
    borderRadius: BorderRadius.circular(10),
    child: InkWell(
      borderRadius: BorderRadius.circular(10), onTap: onTap,
      child: Padding(padding: const EdgeInsets.all(8), child: Icon(icon, color: Colors.white, size: 22)),
    ),
  );

  Widget _sectionTitle(String t) => Text(t, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700));
  void _goto(BuildContext context, Widget screen) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
}

class _ImportCard extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  final Color color;
  final VoidCallback onTap;
  const _ImportCard({required this.icon, required this.title, required this.subtitle, required this.color, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white, borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14), onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), border: Border.all(color: AppTheme.borderColor)),
          child: Row(children: [
            Container(
              width: 50, height: 50,
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 3),
              Text(subtitle, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
            ])),
            Icon(Icons.arrow_forward_ios_rounded, size: 15, color: color.withOpacity(0.7)),
          ]),
        ),
      ),
    );
  }
}

class _FeaturesGrid extends StatelessWidget {
  const _FeaturesGrid();
  static const _items = [
    {'icon': Icons.auto_fix_high_rounded,    'label': 'AI Schema\nDetection', 'c': 0xFF8B5CF6},
    {'icon': Icons.table_rows_rounded,       'label': 'Excel Editor',         'c': 0xFF059669},
    {'icon': Icons.file_download_rounded,    'label': 'Export 5\nFormats',    'c': 0xFFDC2626},
    {'icon': Icons.history_rounded,          'label': 'File History',         'c': 0xFFF59E0B},
    {'icon': Icons.wifi_off_rounded,         'label': 'Works Offline',        'c': 0xFF0891B2},
    {'icon': Icons.cleaning_services_rounded,'label': 'Auto Clean\n& Format', 'c': 0xFF7C3AED},
  ];
  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3, mainAxisSpacing: 10, crossAxisSpacing: 10, childAspectRatio: 1.05),
      itemCount: _items.length,
      itemBuilder: (_, i) {
        final item = _items[i];
        final color = Color(item['c'] as int);
        return Container(
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.borderColor)),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(item['icon'] as IconData, color: color, size: 28),
            const SizedBox(height: 8),
            Text(item['label'] as String, textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
          ]),
        );
      },
    );
  }
}

class _FormatsCard extends StatelessWidget {
  const _FormatsCard();
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.primaryLight, borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primaryColor.withOpacity(0.2)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Row(children: [
          Icon(Icons.info_outline_rounded, size: 16, color: AppTheme.primaryColor),
          SizedBox(width: 8),
          Text('Supported Formats', style: TextStyle(fontWeight: FontWeight.w700, color: AppTheme.primaryColor, fontSize: 13)),
        ]),
        const SizedBox(height: 10),
        Wrap(
          spacing: 6, runSpacing: 6,
          children: ['.xlsx', '.xls', '.csv', '.txt', '.json', 'Raw Text']
              .map((f) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: AppTheme.primaryColor, borderRadius: BorderRadius.circular(6)),
                child: Text(f, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
              )).toList(),
        ),
      ]),
    );
  }
}
