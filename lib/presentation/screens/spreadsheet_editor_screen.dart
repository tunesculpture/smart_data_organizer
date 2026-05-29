import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:pluto_grid/pluto_grid.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/entities/parsed_dataset.dart';
import '../providers/app_provider.dart';
import 'export_screen.dart';
import 'column_mapping_screen.dart';

class SpreadsheetEditorScreen extends StatefulWidget {
  final ParsedDataset dataset;
  const SpreadsheetEditorScreen({super.key, required this.dataset});
  @override
  State<SpreadsheetEditorScreen> createState() => _SpreadsheetEditorScreenState();
}

class _SpreadsheetEditorScreenState extends State<SpreadsheetEditorScreen> {
  late PlutoGridStateManager _sm;
  late List<PlutoColumn> _columns;
  late List<PlutoRow> _rows;
  late ParsedDataset _dataset;
  final _searchCtrl = TextEditingController();
  bool _showSearch = false;
  final List<ParsedDataset> _undoStack = [];
  final List<ParsedDataset> _redoStack = [];

  @override
  void initState() {
    super.initState();
    _dataset = widget.dataset;
    _buildGrid(_dataset);
  }

  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  void _buildGrid(ParsedDataset ds) {
    _columns = ds.headers.asMap().entries.map((e) {
      return PlutoColumn(
        title: e.value, field: 'c${e.key}',
        type: PlutoColumnType.text(), width: 150,
        enableSorting: true, enableContextMenu: true,
        titleTextAlign: PlutoColumnTextAlign.left,
      );
    }).toList();
    _rows = ds.rows.map((row) {
      final cells = <String, PlutoCell>{};
      for (int i = 0; i < ds.headers.length; i++) {
        cells['c$i'] = PlutoCell(value: i < row.length ? row[i] : '');
      }
      return PlutoRow(cells: cells);
    }).toList();
  }

  ParsedDataset _extract() {
    final headers = _columns.map((c) => c.title).toList();
    final rows = _sm.rows.map((row) =>
        _columns.map((c) => row.cells[c.field]?.value.toString() ?? '').toList()).toList();
    return _dataset.copyWith(headers: headers, rows: rows);
  }

  void _saveUndo() => _undoStack.add(_extract());

  void _undo() {
    if (_undoStack.isEmpty) return;
    _redoStack.add(_extract());
    _reload(_undoStack.removeLast());
  }

  void _redo() {
    if (_redoStack.isEmpty) return;
    _undoStack.add(_extract());
    _reload(_redoStack.removeLast());
  }

  void _reload(ParsedDataset ds) {
    setState(() { _dataset = ds; _buildGrid(ds); });
  }

  void _addRow() {
    _saveUndo();
    final cells = <String, PlutoCell>{};
    for (final c in _columns) cells[c.field] = PlutoCell(value: '');
    _sm.appendRows([PlutoRow(cells: cells)]);
  }

  void _deleteSelected() {
    _saveUndo();
    final sel = _sm.currentSelectingRows;
    if (sel.isNotEmpty) {
      _sm.removeRows(sel);
    } else if (_sm.currentRow != null) {
      _sm.removeCurrentRow();
    }
  }

  void _duplicateRow() {
    _saveUndo();
    final row = _sm.currentRow;
    if (row == null) return;
    final cells = <String, PlutoCell>{};
    for (final c in _columns) cells[c.field] = PlutoCell(value: row.cells[c.field]?.value ?? '');
    _sm.insertRows(_sm.rows.indexOf(row) + 1, [PlutoRow(cells: cells)]);
  }

  void _addColumn() async {
    final ctrl = TextEditingController(text: 'Column ${_columns.length + 1}');
    final name = await showDialog<String>(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Add Column'),
      content: TextField(controller: ctrl, autofocus: true,
          decoration: const InputDecoration(hintText: 'Column name')),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        ElevatedButton(onPressed: () => Navigator.pop(ctx, ctrl.text), child: const Text('Add')),
      ],
    ));
    if (name == null || name.isEmpty) return;
    _saveUndo();
    final fid = 'cx${DateTime.now().millisecondsSinceEpoch}';
    _sm.insertColumns(_columns.length, [
      PlutoColumn(title: name, field: fid, type: PlutoColumnType.text(), width: 150),
    ]);
  }

  void _searchFilter(String q) {
    if (q.isEmpty) {
      _sm.setFilter(null);
    } else {
      _sm.setFilter((row) =>
        row.cells.values.any((c) => c.value.toString().toLowerCase().contains(q.toLowerCase())));
    }
  }

  void _export() {
    final ds = _extract();
    context.read<AppProvider>().updateDataset(ds);
    Navigator.push(context, MaterialPageRoute(builder: (_) => ExportScreen(dataset: ds)));
  }

  void _openColumnMapping() async {
    final ds = _extract();
    final result = await Navigator.push<ParsedDataset>(
      context,
      MaterialPageRoute(builder: (_) => ColumnMappingScreen(dataset: ds)),
    );
    if (result != null) { _saveUndo(); _reload(result); }
  }

  void _copyTable() {
    final ds = _extract();
    final text = [ds.headers.join('\t'), ...ds.rows.map((r) => r.join('\t'))].join('\n');
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Table copied to clipboard')));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(_dataset.fileName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                overflow: TextOverflow.ellipsis),
            Text('${_dataset.rowCount} rows · ${_dataset.columnCount} cols'
                '${_dataset.wasAiParsed ? " · AI" : ""}',
                style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
          ]),
        ),
        elevation: 0,
        bottom: PreferredSize(preferredSize: const Size.fromHeight(1),
            child: Container(color: AppTheme.borderColor, height: 1)),
        actions: [
          IconButton(
            icon: Icon(_showSearch ? Icons.search_off_rounded : Icons.search_rounded),
            onPressed: () => setState(() {
              _showSearch = !_showSearch;
              if (!_showSearch) { _searchCtrl.clear(); _searchFilter(''); }
            }),
          ),
          IconButton(icon: const Icon(Icons.view_column_rounded), onPressed: _openColumnMapping, tooltip: 'Columns'),
          PopupMenuButton<String>(
            onSelected: (v) {
              switch (v) {
                case 'undo':    _undo(); break;
                case 'redo':    _redo(); break;
                case 'add_col': _addColumn(); break;
                case 'dup':     _duplicateRow(); break;
                case 'copy':    _copyTable(); break;
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'undo',    child: _Mi(Icons.undo_rounded,         'Undo')),
              const PopupMenuItem(value: 'redo',    child: _Mi(Icons.redo_rounded,         'Redo')),
              const PopupMenuDivider(),
              const PopupMenuItem(value: 'add_col', child: _Mi(Icons.add_box_rounded,      'Add Column')),
              const PopupMenuItem(value: 'dup',     child: _Mi(Icons.content_copy_rounded, 'Duplicate Row')),
              const PopupMenuDivider(),
              const PopupMenuItem(value: 'copy',    child: _Mi(Icons.copy_rounded,         'Copy Table')),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ElevatedButton.icon(
              onPressed: _export,
              icon: const Icon(Icons.file_download_rounded, size: 16),
              label: const Text('Export'),
              style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  textStyle: const TextStyle(fontSize: 13)),
            ),
          ),
        ],
      ),
      body: Column(children: [
        if (_dataset.wasAiParsed)
          Container(
            width: double.infinity, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            color: const Color(0xFFF3E8FF),
            child: const Row(children: [
              Icon(Icons.auto_awesome_rounded, size: 14, color: Color(0xFF7C3AED)),
              SizedBox(width: 6),
              Text('Organized using AI schema detection',
                  style: TextStyle(fontSize: 12, color: Color(0xFF7C3AED), fontWeight: FontWeight.w500)),
            ]),
          ),
        if (_showSearch)
          Container(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            child: TextField(
              controller: _searchCtrl, autofocus: true, onChanged: _searchFilter,
              decoration: InputDecoration(
                hintText: 'Search rows...', isDense: true,
                prefixIcon: const Icon(Icons.search_rounded, size: 18),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(icon: const Icon(Icons.clear_rounded, size: 16),
                        onPressed: () { _searchCtrl.clear(); _searchFilter(''); setState(() {}); })
                    : null,
              ),
            ),
          ),
        // Toolbar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            border: const Border(bottom: BorderSide(color: AppTheme.borderColor)),
          ),
          child: Row(children: [
            _Btn(Icons.add_rounded, 'Add Row', AppTheme.accentColor, _addRow),
            const SizedBox(width: 8),
            _Btn(Icons.delete_outline_rounded, 'Delete', AppTheme.errorColor, _deleteSelected),
          ]),
        ),
        Expanded(
          child: PlutoGrid(
            columns: _columns, rows: _rows,
            onLoaded: (e) {
              _sm = e.stateManager;
              _sm.setSelectingMode(PlutoGridSelectingMode.row);
            },
            configuration: PlutoGridConfiguration(
              style: PlutoGridStyleConfig(
                gridBorderColor: AppTheme.borderColor,
                columnTextStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                cellTextStyle: const TextStyle(fontSize: 13, color: AppTheme.textPrimary),
                gridBackgroundColor: isDark ? const Color(0xFF0F172A) : AppTheme.surfaceColor,
                rowColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                oddRowColor: isDark ? const Color(0xFF172032) : const Color(0xFFF8FAFC),
                activatedColor: AppTheme.primaryColor.withOpacity(0.12),
                activatedBorderColor: AppTheme.primaryColor,
                columnHeight: 46, rowHeight: 42,
              ),
              columnSize: const PlutoGridColumnSizeConfig(autoSizeMode: PlutoAutoSizeMode.none),
            ),
          ),
        ),
      ]),
    );
  }
}

class _Btn extends StatelessWidget {
  final IconData icon; final String label; final Color color; final VoidCallback onTap;
  const _Btn(this.icon, this.label, this.color, this.onTap);
  @override
  Widget build(BuildContext context) => Material(
    color: color.withOpacity(0.09), borderRadius: BorderRadius.circular(8),
    child: InkWell(borderRadius: BorderRadius.circular(8), onTap: onTap,
      child: Padding(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
        ]))),
  );
}

class _Mi extends StatelessWidget {
  final IconData icon; final String label;
  const _Mi(this.icon, this.label);
  @override
  Widget build(BuildContext context) => Row(children: [
    Icon(icon, size: 18), const SizedBox(width: 10), Text(label),
  ]);
}
