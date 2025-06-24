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
      // Get authentication headers that include the bearer token
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

        // Try to decode JSON
        try {
          final Map<String, dynamic> responseData = json.decode(response.body);
          if (responseData['success'] == true && responseData['data'] != null) {
            final List<dynamic> data = responseData['data'];
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
}