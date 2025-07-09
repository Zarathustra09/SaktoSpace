// lib/models/prod_category_model.dart
import 'package:shop/models/prod_product_model.dart';

class ProdCategoryModel {
  final int id;
  final String name;
  final String? description;
  final String? type;
  final String? createdAt;
  final String? updatedAt;
  final List<ProdProductModel>? products;

  ProdCategoryModel({
    required this.id,
    required this.name,
    this.description,
    this.type,
    this.createdAt,
    this.updatedAt,
    this.products,
  });

  factory ProdCategoryModel.fromJson(Map<String, dynamic> json) {
    return ProdCategoryModel(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      type: json['type'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
      products: json['products'] != null
          ? (json['products'] as List)
              .map((product) => ProdProductModel.fromJson(product))
              .toList()
          : null,
    );
  }
}