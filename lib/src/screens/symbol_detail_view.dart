import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../database/storage_manager.dart';
import '../models/symbol_model.dart';
import '../utils/visual_themes.dart';

class SymbolDetailView extends StatefulWidget {
  final int symbolId;

  const SymbolDetailView({
    super.key,
    required this.symbolId,
  });

  @override
  State<SymbolDetailView> createState() => _SymbolDetailViewState();
}

class _SymbolDetailViewState extends State<SymbolDetailView> {
  final _storage = StorageManager.instance;
  SymbolModel? _symbol;
  List<SymbolModel> _relatedSymbols = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSymbol();
  }

  Future<void> _loadSymbol() async {
    final symbol = await _storage.getSymbolById(widget.symbolId);
    if (symbol == null) {
      if (mounted) {
        Navigator.pop(context);
      }
      return;
    }

    // Mark as viewed
    await _storage.markAsViewed(widget.symbolId);
    await _storage.incrementSymbolsViewed();

    // Load related symbols
    final related = <SymbolModel>[];
    for (final id in symbol.relatedIds) {
      final relatedSymbol = await _storage.getSymbolById(id);
      if (relatedSymbol != null) {
        related.add(relatedSymbol);
      }
    }

    setState(() {
      _symbol = symbol;
      _relatedSymbols = related;
      _isLoading = false;
    });
  }

  Future<void> _toggleFavorite() async {
    if (_symbol == null) return;

    await _storage.toggleFavorite(_symbol!.id!);
    final updated = await _storage.getSymbolById(_symbol!.id!);

    if (updated != null) {
      setState(() {
        _symbol = updated;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            updated.isFavorite ? 'Added to favorites' : 'Removed from favorites',
          ),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  void _copyName() {
    if (_symbol == null) return;
    Clipboard.setData(ClipboardData(text: _symbol!.name));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Symbol name copied'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _symbol == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final color = VisualThemes.getCategoryColor(_symbol!.categoryName);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 250,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
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
                      Container(
                        width: 120,
                        height: 120,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _symbol!.icon,
                          size: 60,
                          color: color,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _symbol!.categoryName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              IconButton(
                key: const ValueKey('favorite_toggle'),
                icon: Icon(
                  _symbol!.isFavorite ? Icons.favorite : Icons.favorite_border,
                ),
                onPressed: _toggleFavorite,
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Basic Info
                  _buildBasicInfo(),
                  const SizedBox(height: 24),

                  // Description
                  _buildSection(
                    'Description',
                    Icons.description_outlined,
                    _symbol!.description,
                  ),
                  const SizedBox(height: 24),

                  // Usage
                  _buildSection(
                    'Usage',
                    Icons.build_outlined,
                    '',
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _symbol!.usage.map((usage) {
                        return Chip(
                          label: Text(usage),
                          backgroundColor: color.withOpacity(0.1),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Example
                  _buildSection(
                    'Example Circuit',
                    Icons.electric_bolt,
                    '',
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.grey[300]!,
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            _symbol!.icon,
                            size: 48,
                            color: color,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Example: ${_symbol!.name} in circuit',
                            style: Theme.of(context).textTheme.bodyMedium,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Related Symbols
                  if (_relatedSymbols.isNotEmpty) ...[
                    _buildSection(
                      'Related Symbols',
                      Icons.link,
                      '',
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 100,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _relatedSymbols.length,
                        itemBuilder: (context, index) {
                          final related = _relatedSymbols[index];
                          return GestureDetector(
                            onTap: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      SymbolDetailView(symbolId: related.id!),
                                ),
                              );
                            },
                            child: Container(
                              width: 100,
                              margin: const EdgeInsets.only(right: 12),
                              decoration: BoxDecoration(
                                color: Theme.of(context).cardColor,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: VisualThemes.getCategoryColor(
                                    related.categoryName,
                                  ).withOpacity(0.3),
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    related.icon,
                                    color: VisualThemes.getCategoryColor(
                                      related.categoryName,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    related.name,
                                    style:
                                        Theme.of(context).textTheme.bodySmall,
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _copyName,
                          icon: const Icon(Icons.copy),
                          label: const Text('Copy Name'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            // Share functionality
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Share feature coming soon'),
                              ),
                            );
                          },
                          icon: const Icon(Icons.share),
                          label: const Text('Share'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              _symbol!.name,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildInfoItem('Category', _symbol!.categoryName, Icons.category),
                _buildInfoItem('Standard', _symbol!.standard, Icons.verified),
                _buildInfoItem('Code', _symbol!.code, Icons.code),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: VisualThemes.industrialOrange, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _buildSection(String title, IconData icon, String? text, {Widget? child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: VisualThemes.industrialOrange),
            const SizedBox(width: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (text != null && text.isNotEmpty)
          Text(
            text,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        if (child != null) child,
      ],
    );
  }
}
