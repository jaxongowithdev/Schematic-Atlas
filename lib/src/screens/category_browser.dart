import 'package:flutter/material.dart';
import '../database/storage_manager.dart';
import '../models/category_model.dart';
import '../utils/visual_themes.dart';
import 'category_symbols_view.dart';

class CategoryBrowser extends StatefulWidget {
  const CategoryBrowser({super.key});

  @override
  State<CategoryBrowser> createState() => _CategoryBrowserState();
}

class _CategoryBrowserState extends State<CategoryBrowser> {
  final _storage = StorageManager.instance;
  List<CategoryModel> _categories = [];
  bool _isLoading = true;
  String _sortBy = 'name'; // 'name', 'count'

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final categories = await _storage.getAllCategories();
    setState(() {
      _categories = categories;
      _isLoading = false;
    });
    _sortCategories();
  }

  void _sortCategories() {
    setState(() {
      if (_sortBy == 'name') {
        _categories.sort((a, b) => a.name.compareTo(b.name));
      } else if (_sortBy == 'count') {
        _categories.sort((a, b) => b.symbolCount.compareTo(a.symbolCount));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Categories'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort),
            onSelected: (value) {
              setState(() {
                _sortBy = value;
              });
              _sortCategories();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'name',
                child: Text('Sort A-Z'),
              ),
              const PopupMenuItem(
                value: 'count',
                child: Text('Most Symbols'),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                final color = VisualThemes.getCategoryColor(category.name);

                return Card(
                  key: ValueKey('category_${category.name}'),
                  margin: const EdgeInsets.only(bottom: 12),
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              CategorySymbolsView(category: category),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            width: 60,
                            height: 60,
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
                            child: Center(
                              child: Text(
                                category.iconPath,
                                style: const TextStyle(fontSize: 28),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  category.name,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${category.symbolCount} symbols',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  category.description,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.color
                                            ?.withOpacity(0.7),
                                      ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.chevron_right,
                            color: color,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
