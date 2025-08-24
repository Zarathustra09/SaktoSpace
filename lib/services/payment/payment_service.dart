// lib/services/payment/payment_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shop/constants.dart';
import 'package:shop/services/auth/login_service.dart';

class PaymentService {
  final AuthService _authService = AuthService();

  /// Process payment from cart
  Future<Map<String, dynamic>> processPayment({
    required String paymentMethod,
    required String billingAddress,
    required String shippingAddress,
    String? orderId,
    String? status,
  }) async {
    final url = Uri.parse('$baseUrl/payment/process');
    final headers = await _authService.getHeaders();
    final body = jsonEncode({
      'payment_method': paymentMethod,
      'billing_address': billingAddress,
      'shipping_address': shippingAddress,
      if (orderId != null) 'order_id': orderId,
      if (status != null) 'status': status,
    });

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