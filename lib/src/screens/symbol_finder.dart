import 'package:flutter/material.dart';
import '../database/storage_manager.dart';
import '../models/symbol_model.dart';
import '../utils/visual_themes.dart';
import 'symbol_detail_view.dart';

class SymbolFinder extends StatefulWidget {
  const SymbolFinder({super.key});

  @override
  State<SymbolFinder> createState() => _SymbolFinderState();
}

class _SymbolFinderState extends State<SymbolFinder> {
  final _storage = StorageManager.instance;
  final _searchController = TextEditingController();
  List<SymbolModel> _results = [];
  List<String> _recentSearches = [];
  bool _isSearching = false;
  bool _showResults = false;

  @override
  void initState() {
    super.initState();
    _loadRecentSearches();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadRecentSearches() async {
    // In a real app, load from SharedPreferences
    setState(() {
      _recentSearches = ['Motor', 'Valve', 'Pump', 'Fuse', 'Switch'];
    });
  }

  Future<void> _search(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _showResults = false;
        _results = [];
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    final results = await _storage.searchSymbols(query);

    setState(() {
      _results = results;
      _showResults = true;
      _isSearching = false;
    });

    // Add to recent searches (in real app, save to SharedPreferences)
    if (!_recentSearches.contains(query) && query.trim().isNotEmpty) {
      setState(() {
        _recentSearches.insert(0, query);
        if (_recentSearches.length > 10) {
          _recentSearches.removeLast();
        }
      });
    }
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _showResults = false;
      _results = [];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Symbols'),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              key: const ValueKey('search_input'),
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by name, code, or keyword...',
                prefixIcon: Icon(
                  Icons.search,
                  color: VisualThemes.industrialOrange,
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: _clearSearch,
                      )
                    : null,
              ),
              onChanged: (value) {
                // Debounce search
                Future.delayed(const Duration(milliseconds: 300), () {
                  if (_searchController.text == value) {
                    _search(value);
                  }
                });
              },
              onSubmitted: _search,
            ),
          ),

          // Results or suggestions
          Expanded(
            child: _isSearching
                ? const Center(child: CircularProgressIndicator())
                : _showResults
                    ? _buildResults()
                    : _buildSuggestions(),
          ),
        ],
      ),
    );
  }

  Widget _buildResults() {
    if (_results.isEmpty) {
      return Center(
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
              'No symbols found',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Try different keywords',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _results.length,
      itemBuilder: (context, index) {
        final symbol = _results[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor:
                  VisualThemes.getCategoryColor(symbol.categoryName)
                      .withOpacity(0.1),
              child: Icon(
                symbol.icon,
                color: VisualThemes.getCategoryColor(symbol.categoryName),
              ),
            ),
            title: Text(symbol.name),
            subtitle: Text('${symbol.code} • ${symbol.categoryName}'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SymbolDetailView(symbolId: symbol.id!),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildSuggestions() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (_recentSearches.isNotEmpty) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Searches',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _recentSearches.clear();
                  });
                },
                child: const Text('Clear'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _recentSearches.map((search) {
              return ActionChip(
                label: Text(search),
                avatar: const Icon(Icons.history, size: 16),
                onPressed: () {
                  _searchController.text = search;
                  _search(search);
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
        ],
        Text(
          'Suggestions',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            'Generator',
            'Bearing',
            'Sensor',
            'Valve',
            'Cylinder',
            'Compressor',
            'Resistor',
            'Diode',
          ].map((suggestion) {
            return ActionChip(
              label: Text(suggestion),
              onPressed: () {
                _searchController.text = suggestion;
                _search(suggestion);
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: VisualThemes.industrialOrange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
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
              Expanded(
                child: Text(
                  'Search by symbol name, code (e.g., E-001), or keywords',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
