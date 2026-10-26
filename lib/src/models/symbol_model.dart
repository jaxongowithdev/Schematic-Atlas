import 'package:flutter/material.dart';

class SymbolModel {
  final int? id;
  final String name;
  final String categoryName;
  final String code;
  final String description;
  final List<String> usage;
  final List<String> keywords;
  final List<int> relatedIds;
  final int iconCode; // Flutter icon code point
  final String standard; // IEC, ANSI, ISO, etc.
  final bool isFavorite;
  final DateTime? lastViewed;

  SymbolModel({
    this.id,
    required this.name,
    required this.categoryName,
    required this.code,
    required this.description,
    required this.usage,
    required this.keywords,
    required this.relatedIds,
    required this.iconCode,
    this.standard = 'IEC',
    this.isFavorite = false,
    this.lastViewed,
  });

  IconData get icon => IconData(iconCode, fontFamily: 'MaterialIcons');

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'category_name': categoryName,
      'code': code,
      'description': description,
      'usage': usage.join('|'),
      'keywords': keywords.join('|'),
      'related_ids': relatedIds.join(','),
      'icon_code': iconCode,
      'standard': standard,
      'is_favorite': isFavorite ? 1 : 0,
      'last_viewed': lastViewed?.millisecondsSinceEpoch,
    };
  }

  factory SymbolModel.fromMap(Map<String, dynamic> map) {
    return SymbolModel(
      id: map['id'] as int?,
      name: map['name'] as String,
      categoryName: map['category_name'] as String,
      code: map['code'] as String,
      description: map['description'] as String,
      usage: (map['usage'] as String).split('|'),
      keywords: (map['keywords'] as String).split('|'),
      relatedIds: (map['related_ids'] as String).isEmpty
          ? []
          : (map['related_ids'] as String)
              .split(',')
              .map((e) => int.parse(e))
              .toList(),
      iconCode: map['icon_code'] as int,
      standard: map['standard'] as String? ?? 'IEC',
      isFavorite: (map['is_favorite'] as int?) == 1,
      lastViewed: map['last_viewed'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['last_viewed'] as int)
          : null,
    );
  }

  SymbolModel copyWith({
    int? id,
    String? name,
    String? categoryName,
    String? code,
    String? description,
    List<String>? usage,
    List<String>? keywords,
    List<int>? relatedIds,
    int? iconCode,
    String? standard,
    bool? isFavorite,
    DateTime? lastViewed,
  }) {
    return SymbolModel(
      id: id ?? this.id,
      name: name ?? this.name,
      categoryName: categoryName ?? this.categoryName,
      code: code ?? this.code,
      description: description ?? this.description,
      usage: usage ?? this.usage,
      keywords: keywords ?? this.keywords,
      relatedIds: relatedIds ?? this.relatedIds,
      iconCode: iconCode ?? this.iconCode,
      standard: standard ?? this.standard,
      isFavorite: isFavorite ?? this.isFavorite,
      lastViewed: lastViewed ?? this.lastViewed,
    );
  }
}
