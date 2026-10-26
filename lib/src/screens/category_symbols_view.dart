import 'package:flutter/material.dart';
import '../database/storage_manager.dart';
import '../models/category_model.dart';
import '../models/symbol_model.dart';
import '../utils/visual_themes.dart';
import 'symbol_detail_view.dart';

class CategorySymbolsView extends StatefulWidget {
  final CategoryModel category;

  const CategorySymbolsView({
    super.key,
    required this.category,
  });

  @override
  State<CategorySymbolsView> createState() => _CategorySymbolsViewState();
}

class _CategorySymbolsViewState extends State<CategorySymbolsView> {
  final _storage = StorageManager.instance;
  List<SymbolModel> _symbols = [];
  bool _isLoading = true;
  bool _isGridView = false;

  @override
  void initState() {
    super.initState();
    _loadSymbols();
  }

  Future<void> _loadSymbols() async {
    final symbols = await _storage.getSymbolsByCategory(widget.category.name);
    setState(() {
      _symbols = symbols;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final color = VisualThemes.getCategoryColor(widget.category.name);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 180,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(widget.category.name),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      color.withOpacity(0.8),
                      color,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        widget.category.iconPath,
                        style: const TextStyle(fontSize: 48),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${widget.category.symbolCount} symbols',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: Icon(_isGridView ? Icons.list : Icons.grid_view),
                onPressed: () {
                  setState(() {
                    _isGridView = !_isGridView;
                  });
                },
              ),
            ],
          ),
          if (_isLoading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_symbols.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.engineering,
                      size: 64,
                      color: Theme.of(context).disabledColor,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No symbols in this category',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ],
                ),
              ),
            )
          else if (_isGridView)
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.85,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final symbol = _symbols[index];
                    return _buildGridItem(symbol, color);
                  },
                  childCount: _symbols.length,
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final symbol = _symbols[index];
                    return _buildListItem(symbol, color);
                  },
                  childCount: _symbols.length,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildGridItem(SymbolModel symbol, Color color) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SymbolDetailView(symbolId: symbol.id!),
          ),
        ).then((_) => _loadSymbols());
      },
      child: Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                ),
                child: Center(
                  child: Icon(
                    symbol.icon,
                    size: 48,
                    color: color,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    symbol.name,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    symbol.code,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.color
                              ?.withOpacity(0.6),
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListItem(SymbolModel symbol, Color color) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          child: Icon(
            symbol.icon,
            color: color,
          ),
        ),
        title: Text(symbol.name),
        subtitle: Text('${symbol.code} • ${symbol.standard}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (symbol.isFavorite)
              Icon(
                Icons.favorite,
                color: Colors.red,
                size: 18,
              ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right),
          ],
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SymbolDetailView(symbolId: symbol.id!),
            ),
          ).then((_) => _loadSymbols());
        },
      ),
    );
  }
}
