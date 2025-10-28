import 'dart:convert';
  import 'package:http/http.dart' as http;
  import '../../constants.dart';
  import '../auth/login_service.dart';

  class OrderService {
    final AuthService _authService = AuthService();

    Future<List<Map<String, dynamic>>> getOrders() async {
      try {
        final headers = await _authService.getHeaders();
        final response = await http.get(
          Uri.parse('$baseUrl/orders'),
          headers: headers,
        );

        print('Orders response status: ${response.statusCode}');
        print('Orders response body: ${response.body}');

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data['success'] == true) {
            return List<Map<String, dynamic>>.from(data['data']);
          } else {
            throw Exception('Failed to load orders');
          }
        } else {
          throw Exception('Failed to load orders: ${response.statusCode}');
        }
      } catch (e) {
        print('Error getting orders: $e');
        throw Exception('Error getting orders: $e');
      }
    }

    Future<Map<String, dynamic>> getOrder(int orderId) async {
      try {
        final headers = await _authService.getHeaders();
        final response = await http.get(
          Uri.parse('$baseUrl/orders/$orderId'),
          headers: headers,
        );

        print('Order detail response status: ${response.statusCode}');
        print('Order detail response body: ${response.body}');

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data['success'] == true) {
            return data['data'];
          } else {
            throw Exception('Failed to load order');
          }
        } else if (response.statusCode == 404) {
          throw Exception('Order not found');
        } else {
          throw Exception('Failed to load order: ${response.statusCode}');
        }
      } catch (e) {
        print('Error getting order: $e');
        throw Exception('Error getting order: $e');
      }
    }

    Future<Map<String, dynamic>> getOrderStats() async {
      try {
        final headers = await _authService.getHeaders();
        final response = await http.get(
          Uri.parse('$baseUrl/orders/stats'),
          headers: headers,
        );

        print('Order stats response status: ${response.statusCode}');
        print('Order stats response body: ${response.body}');

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data['success'] == true) {
            return data['data'];
          } else {
            throw Exception('Failed to load order statistics');
          }
        } else {
          throw Exception('Failed to load order statistics: ${response.statusCode}');
        }
      } catch (e) {
        print('Error getting order stats: $e');
        throw Exception('Error getting order stats: $e');
      }
    }

    String getStatusColor(String status) {
      switch (status.toLowerCase()) {
        case 'completed':
          return 'success';
        case 'pending':
          return 'warning';
        case 'cancelled':
          return 'error';
        case 'processing':
          return 'primary';
        default:
          return 'primary';
      }
    }

    String formatCurrency(dynamic amount) {
      if (amount == null) return '\$0.00';
      final double value = amount is String ? double.tryParse(amount) ?? 0.0 : amount.toDouble();
      return '\$${value.toStringAsFixed(2)}';
    }
  }