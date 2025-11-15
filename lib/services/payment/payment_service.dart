// lib/services/payment/payment_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shop/constants.dart';
import 'package:shop/services/auth/login_service.dart';

class PaymentService {
  final AuthService _authService = AuthService();

  /// Process direct payment for buy now functionality
  Future<Map<String, dynamic>> processDirectPayment({
    required int productId,
    required int quantity,
    required String paymentMethod,
    required String billingAddress,
    required String shippingAddress,
    String? recipientName,
    String? recipientContact,
    String? orderId,
    String? status,
  }) async {
    print('=== DIRECT PAYMENT SERVICE CALL ===');

    final url = Uri.parse('$baseUrl/payment/direct');
    print('Payment URL: $url');

    final headers = await _authService.getHeaders();
    print('Request Headers: $headers');

    // Set payment status based on payment method using new constants
    String paymentStatus = status ?? _getPaymentStatusFromMethod(paymentMethod);
    print('Payment Method: $paymentMethod');
    print('Auto-determined Payment Status: $paymentStatus');

    final requestBody = {
      'product_id': productId,
      'quantity': quantity,
      'payment_method': paymentMethod,
      'billing_address': billingAddress,
      'shipping_address': shippingAddress,
      if (recipientName != null) 'recipient_name': recipientName,
      if (recipientContact != null) 'recipient_contact': recipientContact,
      'status': paymentStatus,
      if (orderId != null) 'order_id': orderId,
    };

    final body = jsonEncode(requestBody);
    print('Request Body: $body');

    try {
      print('Making HTTP POST request...');
      final response = await http.post(url, headers: headers, body: body);

      print('=== PAYMENT RESPONSE ===');
      print('Response Status: ${response.statusCode}');
      print('Response Headers: ${response.headers}');
      print('Response Body: ${response.body}');

      if (response.body.isEmpty) {
        throw Exception('Empty response from payment server');
      }

      Map<String, dynamic> responseData;
      try {
        responseData = jsonDecode(response.body);
        print('Parsed Response Data: $responseData');
      } catch (e) {
        print('JSON Parse Error: $e');
        throw Exception(
            'Invalid JSON response from payment server: ${response.body}');
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (responseData['success'] == true) {
          print('Payment successful!');

          // Process the response to handle new Order model structure
          final processedResponse = _processPaymentResponse(responseData);
          return processedResponse;
        } else {
          print('Payment failed - success flag is false');
          String errorMessage =
              responseData['message'] ?? 'Payment processing failed';
          throw Exception(errorMessage);
        }
      } else {
        print('HTTP Error - Status: ${response.statusCode}');
        String errorMessage = 'Direct payment processing failed';

        if (responseData.containsKey('message')) {
          errorMessage = responseData['message'];
        } else if (responseData.containsKey('errors')) {
          // Handle validation errors
          final errors = responseData['errors'] as Map<String, dynamic>;
          final firstError = errors.values.first;
          if (firstError is List && firstError.isNotEmpty) {
            errorMessage = firstError.first.toString();
          } else {
            errorMessage = firstError.toString();
          }
        }

        throw Exception(errorMessage);
      }
    } catch (e) {
      print('=== PAYMENT SERVICE ERROR ===');
      print('Error Type: ${e.runtimeType}');
      print('Error Message: $e');
      if (e is! Exception) {
        // Wrap non-Exception errors
        throw Exception('Payment service error: $e');
      }
      rethrow;
    }
  }

  /// Process payment from cart or direct purchase
  Future<Map<String, dynamic>> processPayment({
    required String paymentMethod,
    required String billingAddress,
    required String shippingAddress,
    String? recipientName,
    String? recipientContact,
    String? orderId,
    String? status,
    List<Map<String, dynamic>>?
        cartItems, // Add this parameter for direct purchases
  }) async {
    final url = Uri.parse('$baseUrl/payment/process');
    final headers = await _authService.getHeaders();

    // Set payment status based on payment method using new constants
    String paymentStatus = status ?? _getPaymentStatusFromMethod(paymentMethod);
    print('Payment Method: $paymentMethod');
    print('Auto-determined Payment Status: $paymentStatus');

    final requestBody = {
      'payment_method': paymentMethod,
      'billing_address': billingAddress,
      'shipping_address': shippingAddress,
      if (recipientName != null) 'recipient_name': recipientName,
      if (recipientContact != null) 'recipient_contact': recipientContact,
      'status': paymentStatus,
      if (orderId != null) 'order_id': orderId,
      if (cartItems != null && cartItems.isNotEmpty)
        'items': cartItems, // Include items for direct purchase
    };

    final body = jsonEncode(requestBody);

    print('POST $url');
    print('Headers: $headers');
    print('Body: $body');

    final response = await http.post(url, headers: headers, body: body);
    print('Response status: ${response.statusCode}');
    print('Response body: ${response.body}');

    final responseData = jsonDecode(response.body);

    if (response.statusCode == 200 && responseData['success'] == true) {
      // Process the response to handle new Order model structure
      final processedResponse = _processPaymentResponse(responseData);
      return processedResponse;
    } else {
      String errorMessage = 'Payment processing failed';

      if (responseData.containsKey('message')) {
        errorMessage = responseData['message'];
      } else if (responseData.containsKey('errors')) {
        // Handle validation errors
        final errors = responseData['errors'] as Map<String, dynamic>;
        errorMessage = errors.values.first.toString();
      }

      throw Exception(errorMessage);
    }
  }

  /// Get payment details by ID - now uses payments/{id}/orders endpoint
  Future<Map<String, dynamic>> getPayment(int paymentId) async {
    final url = Uri.parse('$baseUrl/payments/$paymentId/orders');
    final headers = await _authService.getHeaders();

    print('GET $url');
    print('Headers: $headers');

    final response = await http.get(url, headers: headers);
    print('Response status: ${response.statusCode}');
    print('Response body: ${response.body}');

    final responseData = jsonDecode(response.body);

    if (response.statusCode == 200 && responseData['success'] == true) {
      // Process the response to handle new Order model structure
      final processedResponse = _processPaymentResponse(responseData);
      return processedResponse;
    } else {
      String errorMessage = 'Failed to fetch payment details';

      if (responseData.containsKey('message')) {
        errorMessage = responseData['message'];
      }

      throw Exception(errorMessage);
    }
  }

  /// Get payment history for authenticated user - now uses orders service
  Future<Map<String, dynamic>> getPaymentHistory() async {
    final url = Uri.parse('$baseUrl/orders/by-payment');
    final headers = await _authService.getHeaders();

    print('GET $url');
    print('Headers: $headers');

    final response = await http.get(url, headers: headers);
    print('Response status: ${response.statusCode}');
    print('Response body: ${response.body}');

    final responseData = jsonDecode(response.body);

    if (response.statusCode == 200 && responseData['success'] == true) {
      // Process the response to handle new Order model structure for payment history
      final processedResponse = _processPaymentHistoryResponse(responseData);
      return processedResponse;
    } else {
      String errorMessage = 'Failed to fetch payment history';

      if (responseData.containsKey('message')) {
        errorMessage = responseData['message'];
      }

      throw Exception(errorMessage);
    }
  }

  /// Get orders by product for a specific product
  Future<List<Map<String, dynamic>>> getOrdersByProduct(int productId) async {
    final url = Uri.parse('$baseUrl/products/$productId/orders');
    final headers = await _authService.getHeaders();

    print('GET $url');
    print('Headers: $headers');

    final response = await http.get(url, headers: headers);
    print('Response status: ${response.statusCode}');
    print('Response body: ${response.body}');

    final responseData = jsonDecode(response.body);

    if (response.statusCode == 200 && responseData['success'] == true) {
      return List<Map<String, dynamic>>.from(responseData['data']);
    } else {
      String errorMessage = 'Failed to fetch orders for product';

      if (responseData.containsKey('message')) {
        errorMessage = responseData['message'];
      }

      throw Exception(errorMessage);
    }
  }

  /// Get available order statuses
  Future<List<String>> getOrderStatuses() async {
    final url = Uri.parse('$baseUrl/orders/statuses');
    final headers = await _authService.getHeaders();

    print('GET $url');
    print('Headers: $headers');

    final response = await http.get(url, headers: headers);
    print('Response status: ${response.statusCode}');
    print('Response body: ${response.body}');

    final responseData = jsonDecode(response.body);

    if (response.statusCode == 200 && responseData['success'] == true) {
      return List<String>.from(responseData['data']);
    } else {
      // Return default statuses if API call fails
      return [
        'Preparing',
        'To Ship',
        'In Transit',
        'Out for Delivery',
        'Delivered',
        'Cancelled',
      ];
    }
  }

  /// Get orders by status
  Future<List<Map<String, dynamic>>> getOrdersByStatus(String status) async {
    final url = Uri.parse('$baseUrl/orders/status/$status');
    final headers = await _authService.getHeaders();

    print('GET $url');
    print('Headers: $headers');

    final response = await http.get(url, headers: headers);
    print('Response status: ${response.statusCode}');
    print('Response body: ${response.body}');

    final responseData = jsonDecode(response.body);

    if (response.statusCode == 200 && responseData['success'] == true) {
      return List<Map<String, dynamic>>.from(responseData['data']);
    } else {
      String errorMessage = 'Failed to fetch orders by status';

      if (responseData.containsKey('message')) {
        errorMessage = responseData['message'];
      }

      throw Exception(errorMessage);
    }
  }

  /// Get payment status based on payment method using new Payment model constants
  String _getPaymentStatusFromMethod(String paymentMethod) {
    switch (paymentMethod.toLowerCase()) {
      case 'cash_on_delivery':
      case 'cod':
        return 'Pending'; // COD payments are pending until delivery
      case 'credit_card':
      case 'debit_card':
      case 'gcash':
      case 'paymaya':
      case 'bank_transfer':
      case 'paypal':
        return 'Completed'; // Non-COD payments are completed immediately
      default:
        return 'Pending';
    }
  }

  /// Get payment status color for UI using new constants
  String getPaymentStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return 'success';
      case 'pending':
        return 'warning';
      case 'cancelled':
        return 'error';
      case 'refunded':
        return 'info';
      default:
        return 'primary';
    }
  }

  /// Get available payment statuses using new constants
  List<String> getAvailablePaymentStatuses() {
    return [
      'Pending', // For COD
      'Completed', // For other payment methods
      'Cancelled', // For cancelled orders
      'Refunded', // For refunded orders
    ];
  }

  /// Get payment status description using new constants
  String getPaymentStatusDescription(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return 'Payment received successfully';
      case 'pending':
        return 'Payment pending (Cash on Delivery)';
      case 'cancelled':
        return 'Payment cancelled';
      case 'refunded':
        return 'Payment refunded';
      default:
        return 'Payment status unknown';
    }
  }

  /// Process payment response to handle new Order model structure
  /// Maintains backward compatibility by creating purchased_items from orders
  Map<String, dynamic> _processPaymentResponse(Map<String, dynamic> response) {
    try {
      if (response['data'] != null &&
          response['data'] is Map<String, dynamic>) {
        final paymentData = response['data'] as Map<String, dynamic>;

        // Check if orders exist and convert to purchased_items for backward compatibility
        if (paymentData['orders'] != null && paymentData['orders'] is List) {
          final orders = paymentData['orders'] as List;

          // Create purchased_items from orders for backward compatibility
          final purchasedItems = orders.map((order) {
            return {
              'product_id': order['product_id'],
              'name': order['product_name'] ??
                  order['product']?['name'] ??
                  'Unknown Product',
              'price': _parseDouble(order['price']),
              'quantity': order['quantity'] ?? 1,
              'subtotal': _parseDouble(order['subtotal']),
              'category_id': order['category_id'],
              'purchased_at': order['purchased_at'],
              'product': order['product'],
              // Order status (separate from payment status)
              'order_status': order['status'] ?? 'Preparing',
              'status_updated_at': order['status_updated_at'],
              // Include payment status for context
              'payment_status': paymentData['status'] ?? 'Pending',
            };
          }).toList();

          // Add purchased_items for backward compatibility
          paymentData['purchased_items'] = purchasedItems;

          print(
              'Converted ${orders.length} orders to purchased_items with separate status tracking');
        }
      }

      return response;
    } catch (e) {
      print('Error processing payment response: $e');
      // Return original response if processing fails
      return response;
    }
  }

  /// Process payment history response to handle multiple payments with orders
  Map<String, dynamic> _processPaymentHistoryResponse(
      Map<String, dynamic> response) {
    try {
      if (response['data'] != null && response['data'] is List) {
        final payments = response['data'] as List;

        for (var payment in payments) {
          if (payment is Map<String, dynamic>) {
            // Process each payment's orders
            if (payment['orders'] != null && payment['orders'] is List) {
              final orders = payment['orders'] as List;

              // Create purchased_items from orders for backward compatibility
              final purchasedItems = orders.map((order) {
                return {
                  'product_id': order['product_id'],
                  'name': order['product_name'] ??
                      order['product']?['name'] ??
                      'Unknown Product',
                  'price': _parseDouble(order['price']),
                  'quantity': order['quantity'] ?? 1,
                  'subtotal': _parseDouble(order['subtotal']),
                  'category_id': order['category_id'],
                  'purchased_at': order['purchased_at'],
                  'product': order[
                      'product'], // Include full product details if available
                  'status': order['status'] ?? 'Preparing', // Add order status
                  'status_updated_at':
                      order['status_updated_at'], // Add status update timestamp
                };
              }).toList();

              // Add purchased_items for backward compatibility
              payment['purchased_items'] = purchasedItems;
            }
          }
        }

        print(
            'Processed ${payments.length} payments in history with status tracking');
      }

      return response;
    } catch (e) {
      print('Error processing payment history response: $e');
      // Return original response if processing fails
      return response;
    }
  }

  /// Helper method to safely parse double values
  double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value) ?? 0.0;
    }
    return 0.0;
  }
}
