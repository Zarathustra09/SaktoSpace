// lib/models/prod_product_model.dart
import 'package:shop/models/prod_category_model.dart';

class ProdProductModel {
  final int id;
  final String name;
  final String description;
  final double price;
  final int stock;
  final int categoryId;
  final String image;
  final String? arModelUrl;
  final String? createdAt;
  final String? updatedAt;
  final ProdCategoryModel? category;
  final double? averageRating;
  final int? totalRatings;
  final List<dynamic>? ratings; // Changed to dynamic to avoid circular import

  ProdProductModel({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.stock,
    required this.categoryId,
    required this.image,
    this.arModelUrl,
    this.createdAt,
    this.updatedAt,
    this.category,
    this.averageRating,
    this.totalRatings,
    this.ratings,
  });

  factory ProdProductModel.fromJson(Map<String, dynamic> json) {
    // Helper to parse double from dynamic (num or string like "4.0000")
    double? _parseDouble(dynamic v) {
      if (v == null) return null;
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v);
      return null;
    }

    return ProdProductModel(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      price: double.parse(json['price'].toString()),
      stock: json['stock'],
      categoryId: json['category_id'],
      image: json['image'],
      arModelUrl: json['ar_model_url'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
      category: json['category'] != null
          ? ProdCategoryModel.fromJson(json['category'])
          : null,
      averageRating: _parseDouble(json['average_rating']),
      totalRatings: json['total_ratings'],
      ratings: json['ratings'], // Store as raw data to avoid circular import
    );
  }
}