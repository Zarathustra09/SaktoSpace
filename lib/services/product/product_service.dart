// lib/services/product/product_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shop/models/prod_product_model.dart';
import 'package:shop/services/auth/login_service.dart';
import '../../constants.dart';

class ProductService {
  final AuthService _authService = AuthService();

  Future<List<ProdProductModel>> getAllProducts() async {
    try {
      final headers = await _authService.getHeaders();

      print("Making API request to: $baseUrl/products");
      print("Using headers: $headers");

      final response = await http.get(
        Uri.parse('$baseUrl/products'),
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
            // Print each product's name and image URL
            for (var item in data) {
              print("Product: ${item['name']}, Image URL: ${item['image']}");
            }
            return data.map((item) => ProdProductModel.fromJson(item)).toList();
          } else {
            throw Exception('Invalid response structure: ${response.body}');
          }
        } catch (parseError) {
          print("JSON parsing error: $parseError");
          print("Response body: ${response.body}");
          throw Exception('Failed to parse response: $parseError');
        }
      } else {
        throw Exception('Failed to load products: ${response.statusCode}, Body: ${response.body}');
      }
    } catch (e) {
      print("Error in getAllProducts: $e");
      throw Exception('Error fetching products: $e');
    }
  }

  Future<ProdProductModel> getProductById(int id) async {
    try {
      // Get authentication headers
      final headers = await _authService.getHeaders();

      final response = await http.get(
        Uri.parse('$baseUrl/products/$id'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        if (responseData['success'] == true && responseData['data'] != null) {
          return ProdProductModel.fromJson(responseData['data']);
        } else {
          throw Exception('Failed to parse product data');
        }
      } else {
        throw Exception('Failed to load product with ID $id: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching product: $e');
    }
  }


  // Add this method to lib/services/product/product_service.dart
  Future<List<ProdProductModel>> searchProducts({
    required String query,
    int? categoryId,
    int limit = 20,
  }) async {
    try {
      final headers = await _authService.getHeaders();

      // Build query parameters
      final queryParams = {
        'query': query,
        'limit': limit.toString(),
        if (categoryId != null) 'category_id': categoryId.toString(),
      };

      final uri = Uri.parse('$baseUrl/products/search').replace(
        queryParameters: queryParams,
      );

      print("Making search API request to: $uri");
      print("Using headers: $headers");

      final response = await http.get(uri, headers: headers);

      print("Search response status code: ${response.statusCode}");
      print("Search response body (first 100 chars): ${response.body.length > 100 ? response.body.substring(0, 100) : response.body}");

      if (response.statusCode == 200) {
        if (response.body.isEmpty) {
          throw Exception('Empty response from server');
        }

        try {
          final Map<String, dynamic> responseData = json.decode(response.body);
          if (responseData['success'] == true && responseData['data'] != null) {
            final List<dynamic> data = responseData['data'];
            return data.map((item) => ProdProductModel.fromJson(item)).toList();
          } else {
            throw Exception('Invalid search response structure: ${response.body}');
          }
        } catch (parseError) {
          print("JSON parsing error: $parseError");
          print("Response body: ${response.body}");
          throw Exception('Failed to parse search response: $parseError');
        }
      } else {
        throw Exception('Failed to search products: ${response.statusCode}, Body: ${response.body}');
      }
    } catch (e) {
      print("Error in searchProducts: $e");
      throw Exception('Error searching products: $e');
    }
  }
}