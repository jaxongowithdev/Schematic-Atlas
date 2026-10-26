import 'package:flutter/material.dart';
import '../database/storage_manager.dart';
import '../models/symbol_model.dart';
import '../utils/visual_themes.dart';
import 'symbol_detail_view.dart';

class SymbolConverterView extends StatefulWidget {
  const SymbolConverterView({super.key});

  @override
  State<SymbolConverterView> createState() => _SymbolConverterViewState();
}

class _SymbolConverterViewState extends State<SymbolConverterView> {
  final _storage = StorageManager.instance;
  List<SymbolModel> _symbols = [];
  List<SymbolModel> _filteredSymbols = [];
  String _selectedStandard = 'IEC';
  String _targetStandard = 'ANSI';
  final _searchController = TextEditingController();
  bool _isLoading = true;

  final List<String> _standards = ['IEC', 'ANSI', 'ISO', 'DIN', 'ASHRAE'];

  @override
  void initState() {
    super.initState();
    _loadSymbols();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadSymbols() async {
    final symbols = await _storage.getAllSymbols();
    setState(() {
      _symbols = symbols;
      _filteredSymbols = symbols.where((s) => s.standard == _selectedStandard).toList();
      _isLoading = false;
    });
  }

  void _filterByStandard() {
    setState(() {
      _filteredSymbols = _symbols
          .where((s) => s.standard == _selectedStandard)
          .where((s) =>
              _searchController.text.isEmpty ||
              s.name.toLowerCase().contains(_searchController.text.toLowerCase()) ||
              s.code.toLowerCase().contains(_searchController.text.toLowerCase()))
          .toList();
    });
  }

  SymbolModel _findEquivalent(SymbolModel symbol) {
    // Find equivalent symbol in target standard
    // This is simplified - in real app, you'd have a mapping table
    try {
      return _symbols.firstWhere(
        (s) => s.standard == _targetStandard &&
               s.name == symbol.name && // Same name
               s.categoryName == symbol.categoryName, // Same category
      );
    } catch (e) {
      // Return same symbol if no equivalent found
      return symbol;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Symbol Converter'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Container(
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).colorScheme.surface,
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search symbols...',
                prefixIcon: Icon(
                  Icons.search,
                  color: VisualThemes.industrialOrange,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) => _filterByStandard(),
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Standard selectors
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'FROM',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<String>(
                              value: _selectedStandard,
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: VisualThemes.industrialOrange.withOpacity(0.1),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                              items: _standards.map((standard) {
                                return DropdownMenuItem(
                                  value: standard,
                                  child: Text(standard),
                                );
                              }).toList(),
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() {
                                    _selectedStandard = value;
                                  });
                                  _filterByStandard();
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Icon(
                          Icons.arrow_forward,
                          color: VisualThemes.industrialOrange,
                          size: 32,
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'TO',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<String>(
                              value: _targetStandard,
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: VisualThemes.technicalYellow.withOpacity(0.1),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                              items: _standards.map((standard) {
                                return DropdownMenuItem(
                                  value: standard,
                                  child: Text(standard),
                                );
                              }).toList(),
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() {
                                    _targetStandard = value;
                                  });
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Info banner
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue.shade700),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Select a symbol to see its equivalent in ${_targetStandard} standard',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.blue.shade900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Results list
                Expanded(
                  child: _filteredSymbols.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.search_off,
                                size: 64,
                                color: Theme.of(context).disabledColor,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No symbols found for $_selectedStandard',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _filteredSymbols.length,
                          itemBuilder: (context, index) {
                            final symbol = _filteredSymbols[index];
                            final equivalent = _findEquivalent(symbol);
                            final hasEquivalent = equivalent.standard == _targetStandard;

                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: InkWell(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          SymbolDetailView(symbolId: symbol.id!),
                                    ),
                                  );
                                },
                                borderRadius: BorderRadius.circular(12),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Row(
                                    children: [
                                      // Source symbol
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 4,
                                              ),
                                              decoration: BoxDecoration(
                                                color: VisualThemes.industrialOrange
                                                    .withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                symbol.standard,
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                  color: VisualThemes.industrialOrange,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Row(
                                              children: [
                                                Icon(
                                                  symbol.icon,
                                                  size: 24,
                                                  color: VisualThemes.getCategoryColor(
                                                    symbol.categoryName,
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment.start,
                                                    children: [
                                                      Text(
                                                        symbol.name,
                                                        style: const TextStyle(
                                                          fontWeight: FontWeight.bold,
                                                        ),
                                                      ),
                                                      Text(
                                                        symbol.code,
                                                        style: Theme.of(context)
                                                            .textTheme
                                                            .bodySmall,
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),

                                      // Arrow
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 16),
                                        child: Icon(
                                          Icons.arrow_forward,
                                          color: hasEquivalent
                                              ? VisualThemes.industrialOrange
                                              : Colors.grey,
                                        ),
                                      ),

                                      // Target symbol
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 4,
                                              ),
                                              decoration: BoxDecoration(
                                                color: hasEquivalent
                                                    ? VisualThemes.technicalYellow
                                                        .withOpacity(0.1)
                                                    : Colors.grey.withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                hasEquivalent
                                                    ? equivalent.standard
                                                    : 'N/A',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                  color: hasEquivalent
                                                      ? VisualThemes.technicalYellow
                                                      : Colors.grey,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            if (hasEquivalent)
                                              Row(
                                                children: [
                                                  Icon(
                                                    equivalent.icon,
                                                    size: 24,
                                                    color: VisualThemes.getCategoryColor(
                                                      equivalent.categoryName,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment.start,
                                                      children: [
                                                        Text(
                                                          equivalent.name,
                                                          style: const TextStyle(
                                                            fontWeight: FontWeight.bold,
                                                          ),
                                                        ),
                                                        Text(
                                                          equivalent.code,
                                                          style: Theme.of(context)
                                                              .textTheme
                                                              .bodySmall,
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              )
                                            else
                                              Text(
                                                'No equivalent',
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodySmall
                                                    ?.copyWith(
                                                      color: Colors.grey,
                                                      fontStyle: FontStyle.italic,
                                                    ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
