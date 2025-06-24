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
  });

  factory ProdProductModel.fromJson(Map<String, dynamic> json) {
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
    );
  }
}