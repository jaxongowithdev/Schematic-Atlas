import 'package:flutter/material.dart';
import 'dart:math';
import '../database/storage_manager.dart';
import '../models/symbol_model.dart';
import '../models/category_model.dart';
import '../models/user_stats.dart';
import '../utils/visual_themes.dart';
import 'symbol_detail_view.dart';
import 'category_symbols_view.dart';
import 'symbol_converter_view.dart';
import 'reference_sheet_builder.dart';

class DashboardView extends StatefulWidget {
  const DashboardView({super.key});

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  final _storage = StorageManager.instance;
  List<SymbolModel> _recentSymbols = [];
  List<SymbolModel> _featuredSymbols = [];
  List<CategoryModel> _categories = [];
  UserStats? _stats;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final recent = await _storage.getRecentlyViewed(limit: 5);
      final all = await _storage.getAllSymbols();
      final categories = await _storage.getAllCategories();
      final stats = await _storage.getUserStats();

      // Get 10 random symbols for featured
      final featured = <SymbolModel>[];
      if (all.isNotEmpty) {
        final random = Random();
        final indices = <int>{};
        while (indices.length < min(10, all.length)) {
          indices.add(random.nextInt(all.length));
        }
        for (final index in indices) {
          featured.add(all[index]);
        }
      }

      setState(() {
        _recentSymbols = recent;
        _featuredSymbols = featured;
        _categories = categories.take(6).toList();
        _stats = stats;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading dashboard data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Schematic Atlas',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            key: const ValueKey('favorites_button'),
            icon: const Icon(Icons.favorite_border),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const FavoritesView(),
                ),
              ).then((_) => _loadData());
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Search box
                  _buildSearchBox(),
                  const SizedBox(height: 24),

                  // Professional Tools section
                  _buildSectionHeader('Professional Tools'),
                  const SizedBox(height: 12),
                  _buildProfessionalTools(),
                  const SizedBox(height: 24),

                  // Continue Learning section
                  if (_recentSymbols.isNotEmpty) ...[
                    _buildSectionHeader('Continue Learning'),
                    const SizedBox(height: 12),
                    _buildRecentSymbols(),
                    const SizedBox(height: 24),
                  ],

                  // Categories Grid
                  _buildSectionHeader('Categories'),
                  const SizedBox(height: 12),
                  _buildCategoriesGrid(),
                  const SizedBox(height: 24),

                  // Featured Symbols
                  _buildSectionHeader('Featured Symbols'),
                  const SizedBox(height: 12),
                  _buildFeaturedSymbols(),
                  const SizedBox(height: 24),

                  // Statistics
                  _buildSectionHeader('Your Progress'),
                  const SizedBox(height: 12),
                  _buildStatistics(),
                ],
              ),
            ),
    );
  }

  Widget _buildSearchBox() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).dividerColor.withOpacity(0.3),
        ),
      ),
      child: TextField(
        key: const ValueKey('search_field'),
        decoration: InputDecoration(
          hintText: 'Search symbols...',
          prefixIcon: Icon(
            Icons.search,
            color: VisualThemes.industrialOrange,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
        onTap: () {
          // Navigate to search screen
          DefaultTabController.of(context).animateTo(2);
        },
        readOnly: true,
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: VisualThemes.industrialOrange,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );
  }

  Widget _buildProfessionalTools() {
    return Row(
      children: [
        Expanded(
          child: _buildToolCard(
            title: 'Symbol Converter',
            subtitle: 'IEC ↔ ANSI ↔ ISO',
            icon: Icons.swap_horiz,
            color: Colors.blue,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SymbolConverterView(),
                ),
              );
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildToolCard(
            title: 'Reference Sheet',
            subtitle: 'Create PDF',
            icon: Icons.picture_as_pdf,
            color: Colors.red,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ReferenceSheetBuilder(),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildToolCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              color.withOpacity(0.8),
              color,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              color: Colors.white,
              size: 32,
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentSymbols() {
    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _recentSymbols.length,
        itemBuilder: (context, index) {
          final symbol = _recentSymbols[index];
          return GestureDetector(
            onTap: () => _openSymbolDetail(symbol),
            child: Container(
              width: 100,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: VisualThemes.getCategoryColor(symbol.categoryName)
                      .withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: VisualThemes.getCategoryColor(symbol.categoryName)
                          .withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      symbol.icon,
                      color: VisualThemes.getCategoryColor(symbol.categoryName),
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      symbol.name,
                      style: Theme.of(context).textTheme.bodySmall,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCategoriesGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.0,
      ),
      itemCount: _categories.length,
      itemBuilder: (context, index) {
        final category = _categories[index];
        final color = VisualThemes.getCategoryColor(category.name);

        return GestureDetector(
          onTap: () => _openCategory(category),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  color.withOpacity(0.8),
                  color,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  category.iconPath,
                  style: const TextStyle(fontSize: 32),
                ),
                const SizedBox(height: 8),
                Text(
                  category.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
                Text(
                  '${category.symbolCount} symbols',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFeaturedSymbols() {
    return SizedBox(
      height: 140,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _featuredSymbols.length,
        itemBuilder: (context, index) {
          final symbol = _featuredSymbols[index];
          return GestureDetector(
            onTap: () => _openSymbolDetail(symbol),
            child: Container(
              width: 120,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 80,
                    decoration: BoxDecoration(
                      color: VisualThemes.getCategoryColor(symbol.categoryName)
                          .withOpacity(0.1),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(12),
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        symbol.icon,
                        size: 40,
                        color: VisualThemes.getCategoryColor(symbol.categoryName),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          symbol.name,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
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
        },
      ),
    );
  }

  Widget _buildStatistics() {
    if (_stats == null) return const SizedBox.shrink();

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Viewed',
            _stats!.symbolsViewed.toString(),
            Icons.visibility,
            Colors.blue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Favorites',
            _stats!.favoriteCount.toString(),
            Icons.favorite,
            Colors.red,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Accuracy',
            '${_stats!.accuracy.toStringAsFixed(0)}%',
            Icons.trending_up,
            Colors.green,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  void _openSymbolDetail(SymbolModel symbol) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SymbolDetailView(symbolId: symbol.id!),
      ),
    ).then((_) => _loadData());
  }

  void _openCategory(CategoryModel category) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CategorySymbolsView(category: category),
      ),
    ).then((_) => _loadData());
  }
}

// Favorites View
class FavoritesView extends StatefulWidget {
  const FavoritesView({super.key});

  @override
  State<FavoritesView> createState() => _FavoritesViewState();
}

class _FavoritesViewState extends State<FavoritesView> {
  final _storage = StorageManager.instance;
  List<SymbolModel> _favorites = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    final favorites = await _storage.getFavoriteSymbols();
    setState(() {
      _favorites = favorites;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Favorites'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _favorites.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.favorite_border,
                        size: 64,
                        color: Theme.of(context).disabledColor,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No favorites yet',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tap the heart icon on symbols to save them here',
                        style: Theme.of(context).textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _favorites.length,
                  itemBuilder: (context, index) {
                    final symbol = _favorites[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: VisualThemes.getCategoryColor(
                            symbol.categoryName,
                          ).withOpacity(0.1),
                          child: Icon(
                            symbol.icon,
                            color: VisualThemes.getCategoryColor(
                              symbol.categoryName,
                            ),
                          ),
                        ),
                        title: Text(symbol.name),
                        subtitle: Text('${symbol.code} • ${symbol.categoryName}'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  SymbolDetailView(symbolId: symbol.id!),
                            ),
                          ).then((_) => _loadFavorites());
                        },
                      ),
                    );
                  },
                ),
    );
  }
}
