// lib/services/cart/cart_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shop/constants.dart';
import 'package:shop/services/auth/login_service.dart';

class CartService {
  final AuthService _authService = AuthService();

  Future<Map<String, dynamic>> addToCart({
    required int productId,
    int quantity = 1,
  }) async {
    final url = Uri.parse('$baseUrl/cart/add');
    final headers = await _authService.getHeaders();
    final body = jsonEncode({
      'product_id': productId,
      'quantity': quantity,
    });

    print('POST $url');
    print('Headers: $headers');
    print('Body: $body');

    final response = await http.post(url, headers: headers, body: body);
    print('Response status: ${response.statusCode}');
    print('Response body: ${response.body}');

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to add to cart: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> getCart() async {
    final url = Uri.parse('$baseUrl/cart');
    final headers = await _authService.getHeaders();

    print('GET $url');
    print('Headers: $headers');

    final response = await http.get(url, headers: headers);
    print('Response status: ${response.statusCode}');
    print('Response body: ${response.body}');

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to fetch cart: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> updateQuantity({
    required int itemId,
    required int quantity,
  }) async {
    final url = Uri.parse('$baseUrl/cart/$itemId');
    final headers = await _authService.getHeaders();
    final body = jsonEncode({'quantity': quantity});

    print('PUT $url');
    print('Headers: $headers');
    print('Body: $body');

    final response = await http.put(url, headers: headers, body: body);
    print('Response status: ${response.statusCode}');
    print('Response body: ${response.body}');

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to update quantity: ${response.body}');
    }
  }

  Future<void> removeItem(int itemId) async {
    final url = Uri.parse('$baseUrl/cart/$itemId');
    final headers = await _authService.getHeaders();

    print('DELETE $url');
    print('Headers: $headers');

    final response = await http.delete(url, headers: headers);
    print('Response status: ${response.statusCode}');
    print('Response body: ${response.body}');

    if (response.statusCode != 200) {
      throw Exception('Failed to remove item: ${response.body}');
    }
  }

  Future<void> clearCart() async {
    final url = Uri.parse('$baseUrl/cart');
    final headers = await _authService.getHeaders();

    print('DELETE $url');
    print('Headers: $headers');

    final response = await http.delete(url, headers: headers);
    print('Response status: ${response.statusCode}');
    print('Response body: ${response.body}');

    // Accept both 200 (success) and 404 (cart already empty) as valid responses
    if (response.statusCode != 200 && response.statusCode != 404) {
      // Try to parse error message from response
      try {
        final errorData = jsonDecode(response.body);
        final errorMessage = errorData['message'] ?? 'Failed to clear cart';
        throw Exception(errorMessage);
      } catch (e) {
        throw Exception('Failed to clear cart: ${response.body}');
      }
    }
  }

  Future<int> getCartCount() async {
    final url = Uri.parse('$baseUrl/cart/count');
    final headers = await _authService.getHeaders();

    print('GET $url');
    print('Headers: $headers');

    final response = await http.get(url, headers: headers);
    print('Response status: ${response.statusCode}');
    print('Response body: ${response.body}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['count'] ?? 0;
    } else {
      throw Exception('Failed to get cart count: ${response.body}');
    }
  }
}