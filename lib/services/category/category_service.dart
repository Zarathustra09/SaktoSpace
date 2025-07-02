// lib/services/category/category_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shop/models/prod_category_model.dart';
import 'package:shop/services/auth/login_service.dart';
import '../../constants.dart';

class CategoryService {
  final AuthService _authService = AuthService();

  // GET /api/categories - Get all categories
  Future<List<ProdCategoryModel>> getAllCategories() async {
    try {
      final headers = await _authService.getHeaders();

      print("Making API request to: $baseUrl/categories");
      print("Using headers: $headers");

      final response = await http.get(
        Uri.parse('$baseUrl/categories'),
        headers: headers,
      );

      print("Response status code: ${response.statusCode}");
      print("Response body (first 100 chars): ${response.body.length > 100 ? response.body.substring(0, 100) : response.body}");

      if (response.statusCode == 200) {
        if (response.body.isEmpty) {
          throw Exception('Empty response from server');
        }

        try {
          final Map<String, dynamic> responseData = json.decode(response.body);
          if (responseData['success'] == true && responseData['data'] != null) {
            final List<dynamic> data = responseData['data'];
            return data.map((item) => ProdCategoryModel.fromJson(item)).toList();
          } else {
            throw Exception('Invalid response structure: ${response.body}');
          }
        } catch (parseError) {
          print("JSON parsing error: $parseError");
          print("Response body: ${response.body}");
          throw Exception('Failed to parse categories response: $parseError');
        }
      } else {
        throw Exception('Failed to load categories: ${response.statusCode}, Body: ${response.body}');
      }
    } catch (e) {
      print("Error in getAllCategories: $e");
      throw Exception('Error fetching categories: $e');
    }
  }

  // GET /api/categories/{id} - Get category by ID
  Future<ProdCategoryModel> getCategoryById(int id) async {
    try {
      final headers = await _authService.getHeaders();

      final response = await http.get(
        Uri.parse('$baseUrl/categories/$id'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        if (responseData['success'] == true && responseData['data'] != null) {
          return ProdCategoryModel.fromJson(responseData['data']);
        } else {
          throw Exception('Failed to parse category data');
        }
      } else {
        throw Exception('Failed to load category with ID $id: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching category: $e');
    }
  }

  // POST /api/categories - Create new category
  Future<ProdCategoryModel> createCategory({
    required String name,
    String? description,
    String? type,
  }) async {
    try {
      final headers = await _authService.getHeaders();

      final body = json.encode({
        'name': name,
        if (description != null) 'description': description,
        if (type != null) 'type': type,
      });

      final response = await http.post(
        Uri.parse('$baseUrl/categories'),
        headers: headers,
        body: body,
      );

      if (response.statusCode == 201) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        if (responseData['success'] == true && responseData['data'] != null) {
          return ProdCategoryModel.fromJson(responseData['data']);
        } else {
          throw Exception('Failed to parse created category data');
        }
      } else {
        throw Exception('Failed to create category: ${response.statusCode}, Body: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error creating category: $e');
    }
  }

  // PUT /api/categories/{id} - Update category
  Future<ProdCategoryModel> updateCategory({
    required int id,
    required String name,
    String? description,
    String? type,
  }) async {
    try {
      final headers = await _authService.getHeaders();

      final body = json.encode({
        'name': name,
        if (description != null) 'description': description,
        if (type != null) 'type': type,
      });

      final response = await http.put(
        Uri.parse('$baseUrl/categories/$id'),
        headers: headers,
        body: body,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        if (responseData['success'] == true && responseData['data'] != null) {
          return ProdCategoryModel.fromJson(responseData['data']);
        } else {
          throw Exception('Failed to parse updated category data');
        }
      } else {
        throw Exception('Failed to update category: ${response.statusCode}, Body: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error updating category: $e');
    }
  }

  // DELETE /api/categories/{id} - Delete category
  Future<bool> deleteCategory(int id) async {
    try {
      final headers = await _authService.getHeaders();

      final response = await http.delete(
        Uri.parse('$baseUrl/categories/$id'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        return responseData['success'] == true;
      } else {
        throw Exception('Failed to delete category: ${response.statusCode}, Body: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error deleting category: $e');
    }
  }
}