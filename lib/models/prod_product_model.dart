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
  final Map<String, int>? ratingBreakdown; // Add this property

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
    this.ratingBreakdown, // Add this parameter
  });

  factory ProdProductModel.fromJson(Map<String, dynamic> json) {
    // Helper to parse double from dynamic (num or string like "4.0000")
    double? _parseDouble(dynamic v) {
      if (v == null) return null;
      if (v is num) {
        if (v.isNaN || v.isInfinite) return null;
        return v.toDouble();
      }
      if (v is String) {
        final parsed = double.tryParse(v);
        if (parsed != null && !parsed.isNaN && !parsed.isInfinite) {
          return parsed;
        }
      }
      return null;
    }

    // Helper to parse int from num/string
    int? _parseInt(dynamic v) {
      if (v == null) return null;
      if (v is int) return v;
      if (v is num) {
        if (v.isNaN || v.isInfinite) return null;
        return v.toInt();
      }
      if (v is String) return int.tryParse(v);
      return null;
    }

    // Parse rating breakdown with safe integer conversion
    Map<String, int>? _parseRatingBreakdown(dynamic breakdown) {
      if (breakdown == null) return null;
      if (breakdown is Map) {
        final result = <String, int>{};
        breakdown.forEach((key, value) {
          if (value != null) {
            int? intValue;
            if (value is num) {
              if (!value.isNaN && !value.isInfinite) {
                intValue = value.toInt();
              }
            } else if (value is String) {
              final parsed = int.tryParse(value);
              intValue = parsed;
            }
            result[key.toString()] = (intValue ?? 0) < 0 ? 0 : (intValue ?? 0);
          } else {
            result[key.toString()] = 0;
          }
        });
        return result;
      }
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
      totalRatings: _parseInt(json['total_ratings']),
      ratings: json['ratings'],
      ratingBreakdown: _parseRatingBreakdown(json['rating_breakdown']),
    );
  }
}