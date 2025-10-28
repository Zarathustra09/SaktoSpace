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
    String? orderId,
    String? status,
  }) async {
    print('=== DIRECT PAYMENT SERVICE CALL ===');

    final url = Uri.parse('$baseUrl/payment/direct');
    print('Payment URL: $url');

    final headers = await _authService.getHeaders();
    print('Request Headers: $headers');

    // Automatically set status based on payment method
    String paymentStatus = status ?? (paymentMethod == 'cash_on_delivery' ? 'pending' : 'completed');
    print('Payment Method: $paymentMethod');
    print('Auto-determined Status: $paymentStatus');

    final requestBody = {
      'product_id': productId,
      'quantity': quantity,
      'payment_method': paymentMethod,
      'billing_address': billingAddress,
      'shipping_address': shippingAddress,
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
        throw Exception('Invalid JSON response from payment server: ${response.body}');
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (responseData['success'] == true) {
          print('Payment successful!');
          return responseData;
        } else {
          print('Payment failed - success flag is false');
          String errorMessage = responseData['message'] ?? 'Payment processing failed';
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
    String? orderId,
    String? status,
    List<Map<String, dynamic>>? cartItems, // Add this parameter for direct purchases
  }) async {
    final url = Uri.parse('$baseUrl/payment/process');
    final headers = await _authService.getHeaders();

    // Automatically set status based on payment method
    String paymentStatus = status ?? (paymentMethod == 'cash_on_delivery' ? 'pending' : 'completed');
    print('Payment Method: $paymentMethod');
    print('Auto-determined Status: $paymentStatus');

    final requestBody = {
      'payment_method': paymentMethod,
      'billing_address': billingAddress,
      'shipping_address': shippingAddress,
      'status': paymentStatus,
      if (orderId != null) 'order_id': orderId,
      if (cartItems != null && cartItems.isNotEmpty) 'items': cartItems, // Include items for direct purchase
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
      return responseData;
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

  /// Get payment details by ID
  Future<Map<String, dynamic>> getPayment(int paymentId) async {
    final url = Uri.parse('$baseUrl/payment/$paymentId');
    final headers = await _authService.getHeaders();

    print('GET $url');
    print('Headers: $headers');

    final response = await http.get(url, headers: headers);
    print('Response status: ${response.statusCode}');
    print('Response body: ${response.body}');

    final responseData = jsonDecode(response.body);

    if (response.statusCode == 200 && responseData['success'] == true) {
      return responseData;
    } else {
      String errorMessage = 'Failed to fetch payment details';

      if (responseData.containsKey('message')) {
        errorMessage = responseData['message'];
      }

      throw Exception(errorMessage);
    }
  }

  /// Get payment history for authenticated user
  Future<Map<String, dynamic>> getPaymentHistory() async {
    final url = Uri.parse('$baseUrl/payments/history');
    final headers = await _authService.getHeaders();

    print('GET $url');
    print('Headers: $headers');

    final response = await http.get(url, headers: headers);
    print('Response status: ${response.statusCode}');
    print('Response body: ${response.body}');

    final responseData = jsonDecode(response.body);

    if (response.statusCode == 200 && responseData['success'] == true) {
      return responseData;
    } else {
      String errorMessage = 'Failed to fetch payment history';

      if (responseData.containsKey('message')) {
        errorMessage = responseData['message'];
      }

      throw Exception(errorMessage);
    }
  }
}