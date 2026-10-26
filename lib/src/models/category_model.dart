class CategoryModel {
  final int? id;
  final String name;
  final String iconPath;
  final String description;
  final int symbolCount;

  CategoryModel({
    this.id,
    required this.name,
    required this.iconPath,
    required this.description,
    this.symbolCount = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'icon_path': iconPath,
      'description': description,
      'symbol_count': symbolCount,
    };
  }

  factory CategoryModel.fromMap(Map<String, dynamic> map) {
    return CategoryModel(
      id: map['id'] as int?,
      name: map['name'] as String,
      iconPath: map['icon_path'] as String,
      description: map['description'] as String,
      symbolCount: map['symbol_count'] as int? ?? 0,
    );
  }

  CategoryModel copyWith({
    int? id,
    String? name,
    String? iconPath,
    String? description,
    int? symbolCount,
  }) {
    return CategoryModel(
      id: id ?? this.id,
      name: name ?? this.name,
      iconPath: iconPath ?? this.iconPath,
      description: description ?? this.description,
      symbolCount: symbolCount ?? this.symbolCount,
    );
  }
}
