import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import '../database/storage_manager.dart';
import '../models/symbol_model.dart';
import '../models/category_model.dart';
import '../utils/visual_themes.dart';

class ReferenceSheetBuilder extends StatefulWidget {
  const ReferenceSheetBuilder({super.key});

  @override
  State<ReferenceSheetBuilder> createState() => _ReferenceSheetBuilderState();
}

class _ReferenceSheetBuilderState extends State<ReferenceSheetBuilder> {
  final _storage = StorageManager.instance;
  List<CategoryModel> _categories = [];
  Map<String, List<SymbolModel>> _symbolsByCategory = {};
  Set<int> _selectedSymbolIds = {};
  String? _selectedCategory;
  bool _isLoading = true;
  bool _isGenerating = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final categories = await _storage.getAllCategories();
    final allSymbols = await _storage.getAllSymbols();

    // Group symbols by category
    final Map<String, List<SymbolModel>> grouped = {};
    for (final symbol in allSymbols) {
      if (!grouped.containsKey(symbol.categoryName)) {
        grouped[symbol.categoryName] = [];
      }
      grouped[symbol.categoryName]!.add(symbol);
    }

    setState(() {
      _categories = categories;
      _symbolsByCategory = grouped;
      _isLoading = false;
    });
  }

  void _toggleSymbol(int symbolId) {
    setState(() {
      if (_selectedSymbolIds.contains(symbolId)) {
        _selectedSymbolIds.remove(symbolId);
      } else {
        _selectedSymbolIds.add(symbolId);
      }
    });
  }

  void _selectAllInCategory(String category) {
    setState(() {
      final symbols = _symbolsByCategory[category] ?? [];
      for (final symbol in symbols) {
        _selectedSymbolIds.add(symbol.id!);
      }
    });
  }

  void _deselectAllInCategory(String category) {
    setState(() {
      final symbols = _symbolsByCategory[category] ?? [];
      for (final symbol in symbols) {
        _selectedSymbolIds.remove(symbol.id!);
      }
    });
  }

  Future<void> _generatePDF() async {
    if (_selectedSymbolIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one symbol')),
      );
      return;
    }

    setState(() {
      _isGenerating = true;
    });

    try {
      // Get selected symbols
      final selectedSymbols = <SymbolModel>[];
      for (final id in _selectedSymbolIds) {
        final symbol = await _storage.getSymbolById(id);
        if (symbol != null) {
          selectedSymbols.add(symbol);
        }
      }

      // Sort by category and name
      selectedSymbols.sort((a, b) {
        final catCompare = a.categoryName.compareTo(b.categoryName);
        if (catCompare != 0) return catCompare;
        return a.name.compareTo(b.name);
      });

      // Generate PDF
      final pdf = pw.Document();

      // Add cover page
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (context) {
            return pw.Center(
              child: pw.Column(
                mainAxisAlignment: pw.MainAxisAlignment.center,
                children: [
                  pw.Text(
                    'Schematic Atlas',
                    style: pw.TextStyle(
                      fontSize: 32,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 16),
                  pw.Text(
                    'Quick Reference Sheet',
                    style: const pw.TextStyle(fontSize: 20),
                  ),
                  pw.SizedBox(height: 32),
                  pw.Text(
                    '${selectedSymbols.length} Symbols Selected',
                    style: const pw.TextStyle(fontSize: 16),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text(
                    'Generated: ${DateTime.now().toString().split('.')[0]}',
                    style: pw.TextStyle(
                      fontSize: 12,
                      color: PdfColors.grey700,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      );

      // Add symbols grouped by category
      String? currentCategory;
      List<pw.Widget> pageContent = [];

      for (final symbol in selectedSymbols) {
        // Add category header if changed
        if (currentCategory != symbol.categoryName) {
          if (pageContent.isNotEmpty) {
            pdf.addPage(
              pw.Page(
                pageFormat: PdfPageFormat.a4,
                build: (context) => pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: pageContent,
                ),
              ),
            );
            pageContent = [];
          }

          currentCategory = symbol.categoryName;
          pageContent.add(
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(12),
              margin: const pw.EdgeInsets.only(bottom: 16, top: 8),
              decoration: pw.BoxDecoration(
                color: PdfColors.orange100,
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Text(
                symbol.categoryName,
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.orange900,
                ),
              ),
            ),
          );
        }

        // Add symbol info
        pageContent.add(
          pw.Container(
            margin: const pw.EdgeInsets.only(bottom: 12),
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey300),
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Symbol placeholder (icon can't be rendered, use code)
                pw.Container(
                  width: 60,
                  height: 60,
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey200,
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  child: pw.Center(
                    child: pw.Text(
                      symbol.code,
                      style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                pw.SizedBox(width: 12),
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        symbol.name,
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Code: ${symbol.code} | Standard: ${symbol.standard}',
                        style: pw.TextStyle(
                          fontSize: 10,
                          color: PdfColors.grey700,
                        ),
                      ),
                      pw.SizedBox(height: 6),
                      pw.Text(
                        symbol.description,
                        style: const pw.TextStyle(fontSize: 10),
                        maxLines: 3,
                      ),
                      pw.SizedBox(height: 6),
                      pw.Text(
                        'Usage: ${symbol.usage.join(", ")}',
                        style: pw.TextStyle(
                          fontSize: 9,
                          color: PdfColors.grey600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );

        // Add page if content is getting long (rough estimate)
        if (pageContent.length > 8) {
          pdf.addPage(
            pw.Page(
              pageFormat: PdfPageFormat.a4,
              build: (context) => pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: pageContent,
              ),
            ),
          );
          pageContent = [
            // Re-add category header for continuity
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(12),
              margin: const pw.EdgeInsets.only(bottom: 16, top: 8),
              decoration: pw.BoxDecoration(
                color: PdfColors.orange100,
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Text(
                '$currentCategory (continued)',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.orange900,
                ),
              ),
            ),
          ];
        }
      }

      // Add remaining content
      if (pageContent.isNotEmpty) {
        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            build: (context) => pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: pageContent,
            ),
          ),
        );
      }

      // Save PDF
      final output = await getTemporaryDirectory();
      final file = File('${output.path}/symbol_reference_${DateTime.now().millisecondsSinceEpoch}.pdf');
      await file.writeAsBytes(await pdf.save());

      setState(() {
        _isGenerating = false;
      });

      // Share PDF
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'Schematic Atlas Reference Sheet',
        text: 'Reference sheet with ${selectedSymbols.length} engineering symbols',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PDF generated successfully!')),
        );
      }
    } catch (e) {
      setState(() {
        _isGenerating = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating PDF: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reference Sheet Builder'),
        actions: [
          if (_selectedSymbolIds.isNotEmpty)
            TextButton.icon(
              onPressed: _isGenerating ? null : _generatePDF,
              icon: _isGenerating
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.picture_as_pdf),
              label: Text('Export (${_selectedSymbolIds.length})'),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Info banner
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: VisualThemes.industrialOrange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: VisualThemes.industrialOrange.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: VisualThemes.industrialOrange,
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Select symbols to include in your reference sheet',
                          style: TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),

                // Category selector
                Container(
                  height: 60,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _categories.length,
                    itemBuilder: (context, index) {
                      final category = _categories[index];
                      final isSelected = _selectedCategory == category.name;

                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          selected: isSelected,
                          label: Text(category.name),
                          avatar: Text(category.iconPath),
                          onSelected: (selected) {
                            setState(() {
                              _selectedCategory = selected ? category.name : null;
                            });
                          },
                        ),
                      );
                    },
                  ),
                ),

                // Symbols list
                Expanded(
                  child: _buildSymbolsList(),
                ),
              ],
            ),
      floatingActionButton: _selectedSymbolIds.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: _isGenerating ? null : _generatePDF,
              icon: _isGenerating
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.picture_as_pdf),
              label: Text('Generate PDF (${_selectedSymbolIds.length})'),
            )
          : null,
    );
  }

  Widget _buildSymbolsList() {
    final categoriesToShow = _selectedCategory != null
        ? [_selectedCategory!]
        : _symbolsByCategory.keys.toList();

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: categoriesToShow.length,
      itemBuilder: (context, catIndex) {
        final categoryName = categoriesToShow[catIndex];
        final symbols = _symbolsByCategory[categoryName] ?? [];
        if (symbols.isEmpty) return const SizedBox.shrink();

        final allSelected = symbols.every((s) => _selectedSymbolIds.contains(s.id));
        final someSelected = symbols.any((s) => _selectedSymbolIds.contains(s.id));

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category header with select all
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: VisualThemes.getCategoryColor(categoryName).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Text(
                    categoryName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: allSelected
                        ? () => _deselectAllInCategory(categoryName)
                        : () => _selectAllInCategory(categoryName),
                    child: Text(allSelected ? 'Deselect All' : 'Select All'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Symbols
            ...symbols.map((symbol) {
              final isSelected = _selectedSymbolIds.contains(symbol.id);
              return CheckboxListTile(
                key: ValueKey('symbol_${symbol.id}'),
                value: isSelected,
                onChanged: (value) => _toggleSymbol(symbol.id!),
                title: Text(symbol.name),
                subtitle: Text('${symbol.code} • ${symbol.standard}'),
                secondary: CircleAvatar(
                  backgroundColor:
                      VisualThemes.getCategoryColor(symbol.categoryName)
                          .withOpacity(0.1),
                  child: Icon(
                    symbol.icon,
                    color: VisualThemes.getCategoryColor(symbol.categoryName),
                    size: 20,
                  ),
                ),
              );
            }),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }
}
