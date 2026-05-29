import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/app_utils.dart';
import '../providers/history_provider.dart';
import '../providers/app_provider.dart';
import '../../domain/entities/parsed_dataset.dart';
import 'spreadsheet_editor_screen.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceColor,
      appBar: AppBar(
        title: const Text('History'),
        backgroundColor: Colors.white,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppTheme.borderColor, height: 1),
        ),
        actions: [
          Consumer<HistoryProvider>(
            builder: (_, history, __) => history.records.isNotEmpty
                ? TextButton(
                    onPressed: () => _confirmClear(context, history),
                    child: const Text('Clear All',
                        style: TextStyle(color: AppTheme.errorColor)),
                  )
                : const SizedBox(),
          ),
        ],
      ),
      body: Consumer<HistoryProvider>(
        builder: (context, history, _) {
          if (history.records.isEmpty) {
            return const _EmptyHistory();
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: history.records.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final record = history.records[i];
              return _HistoryCard(
                record: record,
                onOpen: () => _openRecord(context, record, history),
                onDelete: () => history.deleteRecord(record.id),
              );
            },
          );
        },
      ),
    );
  }

  void _openRecord(BuildContext context, HistoryRecord record, HistoryProvider history) {
    final dataset = history.getDataset(record.id);
    if (dataset == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not load this file')),
      );
      return;
    }
    context.read<AppProvider>().loadDataset(dataset);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => SpreadsheetEditorScreen(dataset: dataset)),
    );
  }

  void _confirmClear(BuildContext context, HistoryProvider history) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear History'),
        content: const Text('This will remove all history records. This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () { Navigator.pop(ctx); history.clearAll(); },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorColor),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final HistoryRecord record;
  final VoidCallback onOpen;
  final VoidCallback onDelete;
  const _HistoryCard({required this.record, required this.onOpen, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(record.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppTheme.errorColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
      ),
      onDismissed: (_) => onDelete(),
      child: GestureDetector(
        onTap: onOpen,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.borderColor),
          ),
          child: Row(
            children: [
              Container(
                width: 46, height: 46,
                decoration: BoxDecoration(
                  color: record.sourceType == 'paste'
                      ? AppTheme.accentColor.withOpacity(0.1)
                      : AppTheme.primaryLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  record.sourceType == 'paste'
                      ? Icons.content_paste_rounded
                      : Icons.table_chart_rounded,
                  color: record.sourceType == 'paste'
                      ? AppTheme.accentColor
                      : AppTheme.primaryColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(record.fileName,
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                              overflow: TextOverflow.ellipsis),
                        ),
                        if (record.wasAiParsed)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF3E8FF),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text('AI', style: TextStyle(fontSize: 10, color: Color(0xFF7C3AED), fontWeight: FontWeight.w700)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text('${record.rowCount} rows · ${record.columnCount} columns',
                        style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                    const SizedBox(height: 2),
                    Text(AppUtils.formatDateTime(record.processedAt),
                        style: const TextStyle(fontSize: 11, color: AppTheme.textHint)),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppTheme.textHint),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history_rounded, size: 72, color: AppTheme.textHint.withOpacity(0.4)),
          const SizedBox(height: 16),
          const Text('No history yet',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.textSecondary)),
          const SizedBox(height: 8),
          const Text('Files you process will appear here',
              style: TextStyle(fontSize: 13, color: AppTheme.textHint)),
        ],
      ),
    );
  }
}
