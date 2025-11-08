import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../constants.dart';
import '../auth/login_service.dart';
import 'package:flutter/material.dart'; // added to use Color and IconData

class OrderService {
  final AuthService _authService = AuthService();

  /// Get all individual orders for the authenticated user
  Future<List<Map<String, dynamic>>> getOrders() async {
    print('=== OrderService.getOrders() START ===');
    try {
      final headers = await _authService.getHeaders();
      print('Headers obtained: $headers');

      final url = Uri.parse('$baseUrl/orders');
      print('Making GET request to: $url');

      final response = await http.get(url, headers: headers);
      print('Response status: ${response.statusCode}');
      print('Response headers: ${response.headers}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('Parsed response data: $data');

        if (data['success'] == true) {
          final orders = List<Map<String, dynamic>>.from(data['data']);
          print('Successfully parsed ${orders.length} orders');
          return orders;
        } else {
          print('API returned success=false');
          throw Exception('Failed to load orders');
        }
      } else {
        print('HTTP error with status: ${response.statusCode}');
        throw Exception('Failed to load orders: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in getOrders(): $e');
      print('Error type: ${e.runtimeType}');
      throw Exception('Error getting orders: $e');
    } finally {
      print('=== OrderService.getOrders() END ===');
    }
  }

  /// Get orders grouped by payment (similar to old payment history)
  Future<List<Map<String, dynamic>>> getOrdersByPayment() async {
    print('=== OrderService.getOrdersByPayment() START ===');
    try {
      final headers = await _authService.getHeaders();
      print('Headers obtained: $headers');

      final url = Uri.parse('$baseUrl/orders/by-payment');
      print('Making GET request to: $url');

      final response = await http.get(url, headers: headers);
      print('Response status: ${response.statusCode}');
      print('Response headers: ${response.headers}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('Parsed response data: $data');

        if (data['success'] == true) {
          final payments = List<Map<String, dynamic>>.from(data['data']);
          print('Successfully parsed ${payments.length} payments with orders');

          // Log each payment's order count
          for (int i = 0; i < payments.length; i++) {
            final payment = payments[i];
            final orders = payment['orders'] as List? ?? [];
            print('Payment $i (ID: ${payment['payment_id']}) has ${orders.length} orders');
          }

          return payments;
        } else {
          print('API returned success=false');
          throw Exception('Failed to load orders by payment');
        }
      } else {
        print('HTTP error with status: ${response.statusCode}');
        throw Exception('Failed to load orders by payment: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in getOrdersByPayment(): $e');
      print('Error type: ${e.runtimeType}');
      throw Exception('Error getting orders by payment: $e');
    } finally {
      print('=== OrderService.getOrdersByPayment() END ===');
    }
  }

  /// Get a specific order by ID
  Future<Map<String, dynamic>> getOrder(int orderId) async {
    print('=== OrderService.getOrder($orderId) START ===');
    try {
      final headers = await _authService.getHeaders();
      print('Headers obtained: $headers');

      final url = Uri.parse('$baseUrl/orders/$orderId');
      print('Making GET request to: $url');

      final response = await http.get(url, headers: headers);
      print('Response status: ${response.statusCode}');
      print('Response headers: ${response.headers}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('Parsed response data: $data');

        if (data['success'] == true) {
          final order = data['data'] as Map<String, dynamic>;
          print('Successfully retrieved order: ${order['id']} - ${order['product_name']}');
          print('Order status: ${order['status']}');
          print('Payment status: ${order['payment_status']}');
          return order;
        } else {
          print('API returned success=false');
          throw Exception('Failed to load order');
        }
      } else if (response.statusCode == 404) {
        print('Order not found (404)');
        throw Exception('Order not found');
      } else {
        print('HTTP error with status: ${response.statusCode}');
        throw Exception('Failed to load order: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in getOrder($orderId): $e');
      print('Error type: ${e.runtimeType}');
      throw Exception('Error getting order: $e');
    } finally {
      print('=== OrderService.getOrder($orderId) END ===');
    }
  }

  /// Get a specific payment with all its orders
  Future<Map<String, dynamic>> getPayment(int paymentId) async {
    print('=== OrderService.getPayment($paymentId) START ===');
    try {
      final headers = await _authService.getHeaders();
      print('Headers obtained: $headers');

      final url = Uri.parse('$baseUrl/payments/$paymentId/orders');
      print('Making GET request to: $url');

      final response = await http.get(url, headers: headers);
      print('Response status: ${response.statusCode}');
      print('Response headers: ${response.headers}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('Parsed response data: $data');

        if (data['success'] == true) {
          final payment = data['data'] as Map<String, dynamic>;
          final orders = payment['orders'] as List? ?? [];
          print('Successfully retrieved payment: ${payment['payment_id']} with ${orders.length} orders');
          print('Payment status: ${payment['status']}');
          print('Total amount: ${payment['total_amount']}');
          return payment;
        } else {
          print('API returned success=false');
          throw Exception('Failed to load payment');
        }
      } else if (response.statusCode == 404) {
        print('Payment not found (404)');
        throw Exception('Payment not found');
      } else {
        print('HTTP error with status: ${response.statusCode}');
        throw Exception('Failed to load payment: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in getPayment($paymentId): $e');
      print('Error type: ${e.runtimeType}');
      throw Exception('Error getting payment: $e');
    } finally {
      print('=== OrderService.getPayment($paymentId) END ===');
    }
  }

  /// Get order statistics for the authenticated user
  Future<Map<String, dynamic>> getOrderStats() async {
    print('=== OrderService.getOrderStats() START ===');
    try {
      final headers = await _authService.getHeaders();
      print('Headers obtained: $headers');

      final url = Uri.parse('$baseUrl/orders/stats');
      print('Making GET request to: $url');

      final response = await http.get(url, headers: headers);
      print('Response status: ${response.statusCode}');
      print('Response headers: ${response.headers}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('Parsed response data: $data');

        if (data['success'] == true) {
          final stats = data['data'] as Map<String, dynamic>;
          print('Successfully retrieved order statistics:');
          print('- Total orders: ${stats['total_orders']}');
          print('- Total payments: ${stats['total_payments']}');
          print('- Total spent: ${stats['total_spent']}');
          print('- Orders by status: ${stats['orders_by_status']}');
          print('- Payments by status: ${stats['payments_by_status']}');
          return stats;
        } else {
          print('API returned success=false');
          throw Exception('Failed to load order statistics');
        }
      } else {
        print('HTTP error with status: ${response.statusCode}');
        throw Exception('Failed to load order statistics: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in getOrderStats(): $e');
      print('Error type: ${e.runtimeType}');
      throw Exception('Error getting order stats: $e');
    } finally {
      print('=== OrderService.getOrderStats() END ===');
    }
  }

  /// Get orders for a specific product
  Future<List<Map<String, dynamic>>> getOrdersByProduct(int productId) async {
    print('=== OrderService.getOrdersByProduct($productId) START ===');
    try {
      final headers = await _authService.getHeaders();
      print('Headers obtained: $headers');

      final url = Uri.parse('$baseUrl/products/$productId/orders');
      print('Making GET request to: $url');

      final response = await http.get(url, headers: headers);
      print('Response status: ${response.statusCode}');
      print('Response headers: ${response.headers}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('Parsed response data: $data');

        if (data['success'] == true) {
          final orders = List<Map<String, dynamic>>.from(data['data']);
          print('Successfully retrieved ${orders.length} orders for product $productId');
          return orders;
        } else {
          print('API returned success=false');
          throw Exception('Failed to load orders for product');
        }
      } else {
        print('HTTP error with status: ${response.statusCode}');
        throw Exception('Failed to load orders for product: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in getOrdersByProduct($productId): $e');
      print('Error type: ${e.runtimeType}');
      throw Exception('Error getting orders by product: $e');
    } finally {
      print('=== OrderService.getOrdersByProduct($productId) END ===');
    }
  }

  /// Get orders by status for the authenticated user
  Future<List<Map<String, dynamic>>> getOrdersByStatus(String status) async {
    print('=== OrderService.getOrdersByStatus("$status") START ===');
    try {
      final headers = await _authService.getHeaders();
      print('Headers obtained: $headers');

      final url = Uri.parse('$baseUrl/orders/status/$status');
      print('Making GET request to: $url');

      final response = await http.get(url, headers: headers);
      print('Response status: ${response.statusCode}');
      print('Response headers: ${response.headers}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('Parsed response data: $data');

        if (data['success'] == true) {
          final orders = List<Map<String, dynamic>>.from(data['data']);
          print('Successfully retrieved ${orders.length} orders with status "$status"');
          return orders;
        } else {
          print('API returned success=false');
          throw Exception('Failed to load orders by status');
        }
      } else if (response.statusCode == 400) {
        print('Invalid status provided (400)');
        throw Exception('Invalid status provided');
      } else {
        print('HTTP error with status: ${response.statusCode}');
        throw Exception('Failed to load orders by status: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in getOrdersByStatus("$status"): $e');
      print('Error type: ${e.runtimeType}');
      throw Exception('Error getting orders by status: $e');
    } finally {
      print('=== OrderService.getOrdersByStatus("$status") END ===');
    }
  }

  /// Get available order statuses from the server
  Future<List<String>> getOrderStatuses() async {
    print('=== OrderService.getOrderStatuses() START ===');
    try {
      final headers = await _authService.getHeaders();
      print('Headers obtained: $headers');

      final url = Uri.parse('$baseUrl/orders/statuses');
      print('Making GET request to: $url');

      final response = await http.get(url, headers: headers);
      print('Response status: ${response.statusCode}');
      print('Response headers: ${response.headers}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('Parsed response data: $data');

        if (data['success'] == true) {
          final statuses = List<String>.from(data['data']);
          print('Successfully retrieved ${statuses.length} order statuses: $statuses');
          return statuses;
        } else {
          print('API returned success=false');
          throw Exception('Failed to load order statuses');
        }
      } else {
        print('HTTP error with status: ${response.statusCode}');
        throw Exception('Failed to load order statuses: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in getOrderStatuses(): $e');
      print('Error type: ${e.runtimeType}');
      print('Falling back to default order statuses');
      // Return default statuses if API call fails
      final defaultStatuses = getDefaultOrderStatuses();
      print('Default statuses: $defaultStatuses');
      return defaultStatuses;
    } finally {
      print('=== OrderService.getOrderStatuses() END ===');
    }
  }

  /// Update order status (Admin only - for future use)
  Future<Map<String, dynamic>> updateOrderStatus(int orderId, String status) async {
    print('=== OrderService.updateOrderStatus($orderId, "$status") START ===');
    try {
      final headers = await _authService.getHeaders();
      print('Headers obtained: $headers');

      final url = Uri.parse('$baseUrl/orders/$orderId/status');
      final body = jsonEncode({'status': status});
      print('Making PATCH request to: $url');
      print('Request body: $body');

      final response = await http.patch(url, headers: headers, body: body);
      print('Response status: ${response.statusCode}');
      print('Response headers: ${response.headers}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('Parsed response data: $data');

        if (data['success'] == true) {
          final result = data['data'] as Map<String, dynamic>;
          print('Successfully updated order status:');
          print('- Order ID: ${result['id']}');
          print('- New status: ${result['status']}');
          print('- Product: ${result['product_name']}');
          return result;
        } else {
          print('API returned success=false');
          throw Exception('Failed to update order status');
        }
      } else if (response.statusCode == 404) {
        print('Order not found (404)');
        throw Exception('Order not found');
      } else if (response.statusCode == 422) {
        final data = jsonDecode(response.body);
        final errors = data['errors'] as Map<String, dynamic>?;
        final firstError = errors?.values.first;
        final errorMessage = firstError is List ? firstError.first : firstError;
        print('Validation error (422): $errorMessage');
        throw Exception('Validation error: $errorMessage');
      } else {
        print('HTTP error with status: ${response.statusCode}');
        throw Exception('Failed to update order status: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in updateOrderStatus($orderId, "$status"): $e');
      print('Error type: ${e.runtimeType}');
      throw Exception('Error updating order status: $e');
    } finally {
      print('=== OrderService.updateOrderStatus($orderId, "$status") END ===');
    }
  }

  // Helper methods with logging
  String getStatusColor(String status) {
    print('Getting status color for: $status');
    final color = switch (status.toLowerCase()) {
      'completed' => 'success',
      'pending' => 'warning',
      'cancelled' => 'error',
      'processing' => 'primary',
      'preparing' => 'info',
      'to ship' => 'primary',
      'in transit' => 'warning',
      'out for delivery' => 'warning',
      'delivered' => 'success',
      _ => 'primary',
    };
    print('Status color for "$status": $color');
    return color;
  }

  /// Get order status color for UI
  Color getOrderStatusColor(String status) {
    print('Getting order status color for: $status');
    final color = switch (status.toLowerCase()) {
      'preparing' => const Color(0xFF2196F3),
      'to ship' => const Color(0xFF9C27B0),
      'in transit' => const Color(0xFFFF9800),
      'out for delivery' => const Color(0xFFFF5722),
      'delivered' => const Color(0xFF4CAF50),
      'cancelled' => const Color(0xFFF44336),
      _ => const Color(0xFF607D8B),
    };
    print('Order status color for "$status": ${color.value.toRadixString(16)}');
    return color;
  }

  /// Get order status icon (returns IconData now)
  IconData getOrderStatusIcon(String status) {
    print('Getting order status icon for: $status');
    final icon = switch (status.toLowerCase()) {
      'preparing' => Icons.engineering, // For preparing/processing furniture
      'to ship' => Icons.inventory_2,
      'in transit' => Icons.local_shipping,
      'out for delivery' => Icons.delivery_dining,
      'delivered' => Icons.check_circle,
      'cancelled' => Icons.cancel,
      _ => Icons.shopping_bag,
    };
    print('Order status icon for "$status": ${icon.codePoint}');
    return icon;
  }

  /// Get payment status color (UI-friendly)
  Color getPaymentStatusColor(String status) {
    print('Getting payment status color for: $status');
    final color = switch (status.toLowerCase()) {
      'completed' => Colors.green,
      'pending' => Colors.orange,
      'cancelled' => Colors.red,
      'refunded' => Colors.blue,
      _ => Colors.grey,
    };
    print('Payment status color for "$status": ${color.value.toRadixString(16)}');
    return color;
  }

  /// Get payment status icon (UI-friendly)
  IconData getPaymentStatusIcon(String status) {
    print('Getting payment status icon for: $status');
    final icon = switch (status.toLowerCase()) {
      'completed' => Icons.check_circle,
      'pending' => Icons.access_time,
      'cancelled' => Icons.cancel,
      'refunded' => Icons.refresh,
      _ => Icons.payment,
    };
    print('Payment status icon for "$status": ${icon.codePoint}');
    return icon;
  }

  /// Get payment status description text
  String getPaymentStatusDescription(String status) {
    print('Getting payment status description for: $status');
    final description = switch (status.toLowerCase()) {
      'completed' => 'Payment received successfully',
      'pending' => 'Payment pending (COD)',
      'cancelled' => 'Payment was cancelled',
      'refunded' => 'Payment was refunded',
      _ => 'Payment status updated',
    };
    print('Payment status description for "$status": $description');
    return description;
  }

  /// Async wrapper to obtain order statuses (attempt to ask API, fallback to defaults)
  Future<List<String>> getAvailableOrderStatuses() async {
    print('=== OrderService.getAvailableOrderStatuses() START ===');
    try {
      final headers = await _authService.getHeaders();
      print('Headers obtained: $headers');

      final url = Uri.parse('$baseUrl/orders/statuses');
      print('Making GET request to: $url');

      final response = await http.get(url, headers: headers);
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('Parsed response data: $data');

        if (data['success'] == true && data['data'] != null && data['data'] is List) {
          final statuses = List<String>.from(data['data']);
          print('Successfully obtained ${statuses.length} statuses from API: $statuses');
          return statuses;
        }
      }
      print('API call failed or returned invalid data, falling back to defaults');
    } catch (e) {
      print('Error in getAvailableOrderStatuses(): $e');
      print('Falling back to default statuses');
    }

    final defaultStatuses = getDefaultOrderStatuses();
    print('Using default statuses: $defaultStatuses');
    print('=== OrderService.getAvailableOrderStatuses() END ===');
    return defaultStatuses;
  }

  /// Synchronous default statuses (used as fallback)
  List<String> getDefaultOrderStatuses() {
    print('Getting default order statuses');
    final statuses = getAvailableStatuses();
    print('Default order statuses: $statuses');
    return statuses;
  }

  /// Get order status description
  String getOrderStatusDescription(String status) {
    print('Getting order status description for: $status');
    final description = switch (status.toLowerCase()) {
      'preparing' => 'Processing order',
      'to ship' => 'Ready for delivery',
      'in transit' => 'On the way',
      'out for delivery' => 'Out for delivery',
      'delivered' => 'Delivered',
      'cancelled' => 'Cancelled',
      _ => 'Order status unknown',
    };
    print('Order status description for "$status": $description');
    return description;
  }

  /// Get available order statuses
  List<String> getAvailableStatuses() {
    print('Getting available order statuses list');
    final statuses = [
      'Preparing',
      'To Ship',
      'In Transit',
      'Out for Delivery',
      'Delivered',
      'Cancelled',
    ];
    print('Available statuses: $statuses');
    return statuses;
  }

  String formatCurrency(dynamic amount) {
    print('Formatting currency for: $amount (type: ${amount.runtimeType})');
    if (amount == null) {
      print('Amount is null, returning ₱0.00');
      return '₱0.00';
    }

    final double value = amount is String ? double.tryParse(amount) ?? 0.0 : amount.toDouble();
    final formatted = '₱${value.toStringAsFixed(2)}';
    print('Formatted currency: $formatted');
    return formatted;
  }

  /// Get a specific order by ID with full details including payment info
  Future<Map<String, dynamic>> getOrderDetails(int orderId) async {
    print('=== OrderService.getOrderDetails($orderId) START ===');
    print('This is an alias for getOrder($orderId)');
    final result = await getOrder(orderId);
    print('=== OrderService.getOrderDetails($orderId) END ===');
    return result;
  }
}
