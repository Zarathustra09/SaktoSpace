// lib/screens/checkout/views/checkout_screen.dart
import 'package:flutter/material.dart';
import 'package:shop/services/payment/payment_service.dart';
import 'package:shop/services/cart/cart_service.dart';
import 'package:shop/constants.dart'; // added

class CheckoutScreen extends StatefulWidget {
  final double total;
  final List<dynamic> cartItems;
  final bool isDirectPurchase;
  final Map<String, dynamic>? directPurchaseData; // Add this parameter

  const CheckoutScreen({
    super.key,
    required this.total,
    required this.cartItems,
    this.isDirectPurchase = false,
    this.directPurchaseData, // Add this parameter
  });

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final PaymentService _paymentService = PaymentService();
  final CartService _cartService = CartService();

  final _formKey = GlobalKey<FormState>();
  final _billingAddressController = TextEditingController();
  final _shippingAddressController = TextEditingController();
  final _shippingNameController = TextEditingController();
  final _shippingContactController = TextEditingController();

  String _selectedPaymentMethod = 'credit_card';
  bool _sameAsShipping = true;
  bool _isProcessing = false;

  final List<Map<String, String>> _paymentMethods = [
    {'value': 'credit_card', 'label': 'Credit Card', 'icon': '💳'},
    {'value': 'debit_card', 'label': 'Debit Card', 'icon': '💳'},
    // {'value': 'paypal', 'label': 'PayPal', 'icon': '📱'}, // PayPal temporarily disabled
    {'value': 'gcash', 'label': 'GCash', 'icon': '💰'},
    // {'value': 'paymaya', 'label': 'PayMaya', 'icon': '💵'},
    {'value': 'bank_transfer', 'label': 'Bank Transfer', 'icon': '🏦'},
    {'value': 'cash_on_delivery', 'label': 'Cash on Delivery', 'icon': '📦'},
  ];

  @override
  void dispose() {
    _billingAddressController.dispose();
    _shippingAddressController.dispose();
    _shippingNameController.dispose();
    _shippingContactController.dispose();
    super.dispose();
  }

  Future<void> _processPayment() async {
    print('=== PAYMENT PROCESSING STARTED ===');
    print('Form validation: ${_formKey.currentState?.validate()}');

    if (!_formKey.currentState!.validate()) {
      print('Form validation failed - stopping payment process');
      return;
    }

    print('Setting processing state to true');
    setState(() {
      _isProcessing = true;
    });

    try {
      final billingAddress = _sameAsShipping
          ? _shippingAddressController.text
          : _billingAddressController.text;

      print('=== PAYMENT DATA ===');
      print('Is Direct Purchase: ${widget.isDirectPurchase}');
      print('Direct Purchase Data: ${widget.directPurchaseData}');
      print('Selected Payment Method: $_selectedPaymentMethod');
      print('Billing Address: $billingAddress');
      print('Shipping Address: ${_shippingAddressController.text}');
      print('Total Amount: ${widget.total}');

      Map<String, dynamic> result;

      if (widget.isDirectPurchase && widget.directPurchaseData != null) {
        print('=== USING DIRECT PAYMENT API ===');
        print('Product ID: ${widget.directPurchaseData!['productId']}');
        print('Quantity: ${widget.directPurchaseData!['quantity']}');

        // Use direct payment API for buy now
        result = await _paymentService.processDirectPayment(
          productId: widget.directPurchaseData!['productId'],
          quantity: widget.directPurchaseData!['quantity'],
          paymentMethod: _selectedPaymentMethod,
          billingAddress: billingAddress,
          shippingAddress: _shippingAddressController.text,
          recipientName: _shippingNameController.text,
          recipientContact: _shippingContactController.text,
        );
        print('Direct payment result: $result');
      } else {
        print('=== USING CART PAYMENT API ===');
        // Use cart payment API for cart checkout
        List<Map<String, dynamic>>? paymentItems;
        if (widget.cartItems.isNotEmpty) {
          paymentItems = widget.cartItems
              .map((item) => {
                    'product_id': item['id'] ?? item['product_id'],
                    'quantity': item['quantity'] ?? 1,
                    'price': item['price'],
                    'name': item[
                        'name'], // Include product name for better tracking
                  })
              .toList();
          print('Payment items from cart: $paymentItems');
        }

        result = await _paymentService.processPayment(
          paymentMethod: _selectedPaymentMethod,
          billingAddress: billingAddress,
          shippingAddress: _shippingAddressController.text,
          recipientName: _shippingNameController.text,
          recipientContact: _shippingContactController.text,
          cartItems: paymentItems,
        );
        print('Cart payment result: $result');
      }

      // Validate the response structure
      if (result['success'] != true) {
        throw Exception(result['message'] ?? 'Payment processing failed');
      }

      // Extract payment data - handle new structure with orders
      final paymentData = result['data'];
      if (paymentData == null) {
        throw Exception('Invalid payment response: missing payment data');
      }

      print(
          'Payment processed successfully with orders: ${paymentData['orders']?.length ?? 0}');

      // Only clear cart if this is NOT a direct purchase (i.e., it's from cart)
      if (!widget.isDirectPurchase) {
        print('Clearing cart after successful payment...');
        try {
          await _cartService.clearCart();
          print('Cart cleared successfully');
        } catch (e) {
          print('Warning: Failed to clear cart after payment: $e');
          // Don't fail the whole process if cart clear fails
        }
      } else {
        print('Skipping cart clear for direct purchase');
      }

      if (mounted) {
        print('Showing success dialog...');
        // Show success dialog with payment data
        _showSuccessDialog(paymentData);
      } else {
        print('Widget not mounted, skipping success dialog');
      }
    } catch (e) {
      print('=== PAYMENT ERROR ===');
      print('Error type: ${e.runtimeType}');
      print('Error message: $e');

      if (mounted) {
        // Show more user-friendly error messages
        String errorMessage = _getFormattedErrorMessage(e.toString());

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: () {
                // Allow user to retry the payment
                _processPayment();
              },
            ),
          ),
        );
      }
    } finally {
      print('Setting processing state to false');
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
    print('=== PAYMENT PROCESSING ENDED ===');
  }

  /// Format error messages to be more user-friendly
  String _getFormattedErrorMessage(String error) {
    // Remove technical prefixes
    String cleanError = error.replaceFirst('Exception: ', '');

    // Handle common error scenarios
    if (cleanError.toLowerCase().contains('network')) {
      return 'Network error. Please check your connection and try again.';
    } else if (cleanError.toLowerCase().contains('timeout')) {
      return 'Request timed out. Please try again.';
    } else if (cleanError.toLowerCase().contains('server')) {
      return 'Server error. Please try again later.';
    } else if (cleanError.toLowerCase().contains('validation')) {
      return 'Please check your payment details and try again.';
    } else if (cleanError.toLowerCase().contains('unauthorized')) {
      return 'Session expired. Please log in again.';
    }

    // Return the clean error message or a generic one
    return cleanError.isNotEmpty
        ? cleanError
        : 'Payment failed. Please try again.';
  }

  void _showSuccessDialog(Map<String, dynamic> paymentData) {
    final bool isCashOnDelivery = _selectedPaymentMethod == 'cash_on_delivery';

    // Payment status using new constants (separate from order status)
    final String paymentStatus =
        paymentData['status'] ?? (isCashOnDelivery ? 'Pending' : 'Completed');

    // Order status (separate from payment status) - defaults to 'Preparing'
    final orderStatus = paymentData['orders']?.isNotEmpty == true
        ? paymentData['orders'][0]['status'] ?? 'Preparing'
        : 'Preparing';

    // Handle orders count for display
    final ordersCount = paymentData['orders']?.length ??
        paymentData['purchased_items']?.length ??
        widget.cartItems.length;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _getPaymentStatusColor(paymentStatus).withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _getPaymentStatusIcon(paymentStatus),
                  color: _getPaymentStatusColor(paymentStatus),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _getPaymentStatusTitle(paymentStatus),
                  style: const TextStyle(fontSize: 18),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Transaction ID: ${paymentData['transaction_id'] ?? 'N/A'}'),
              const SizedBox(height: 8),
              Text(
                'Amount: $pesoSymbol${paymentData['amount'] ?? widget.total.toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              Text(
                  'Items: $ordersCount ${ordersCount == 1 ? 'item' : 'items'}'),
              const SizedBox(height: 12),

              // Payment Status Section
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _getPaymentStatusColor(paymentStatus).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: _getPaymentStatusColor(paymentStatus)
                          .withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(
                      _getPaymentStatusIcon(paymentStatus),
                      size: 16,
                      color: _getPaymentStatusColor(paymentStatus),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Payment: $paymentStatus',
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              color: _getPaymentStatusColor(paymentStatus),
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            _getPaymentStatusDescription(paymentStatus),
                            style: TextStyle(
                              color: _getPaymentStatusColor(paymentStatus)
                                  .withOpacity(0.8),
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // Order Status Section (separate from payment)
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _getOrderStatusColor(orderStatus).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color:
                          _getOrderStatusColor(orderStatus).withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(
                      _getOrderStatusIcon(orderStatus),
                      size: 16,
                      color: _getOrderStatusColor(orderStatus),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Order: $orderStatus',
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              color: _getOrderStatusColor(orderStatus),
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            _getOrderStatusDescription(orderStatus),
                            style: TextStyle(
                              color: _getOrderStatusColor(orderStatus)
                                  .withOpacity(0.8),
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _getSuccessMessage(paymentStatus),
                style: const TextStyle(fontSize: 14),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                Navigator.of(context)
                    .popUntil((route) => route.isFirst); // Go back to home
              },
              child: const Text('Continue Shopping'),
            ),
          ],
        );
      },
    );
  }

  /// Get payment status color using new constants
  Color _getPaymentStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      case 'refunded':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  /// Get payment status icon using new constants
  IconData _getPaymentStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Icons.check_circle;
      case 'pending':
        return Icons.access_time;
      case 'cancelled':
        return Icons.cancel;
      case 'refunded':
        return Icons.refresh;
      default:
        return Icons.payment;
    }
  }

  /// Get order status color
  Color _getOrderStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'preparing':
        return const Color(0xFF2196F3);
      case 'to ship':
        return const Color(0xFF9C27B0);
      case 'in transit':
        return const Color(0xFFFF9800);
      case 'out for delivery':
        return const Color(0xFFFF5722);
      case 'delivered':
        return const Color(0xFF4CAF50);
      case 'cancelled':
        return const Color(0xFFF44336);
      default:
        return const Color(0xFF607D8B);
    }
  }

  /// Get order status icon
  IconData _getOrderStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'preparing':
        return Icons.engineering; // For preparing/processing furniture
      case 'to ship':
        return Icons.inventory_2;
      case 'in transit':
        return Icons.local_shipping;
      case 'out for delivery':
        return Icons.delivery_dining;
      case 'delivered':
        return Icons.check_circle;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.shopping_bag;
    }
  }

  /// Get payment status title using new constants
  String _getPaymentStatusTitle(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return 'Payment Successful';
      case 'pending':
        return 'Order Placed';
      case 'cancelled':
        return 'Payment Cancelled';
      case 'refunded':
        return 'Payment Refunded';
      default:
        return 'Payment Processed';
    }
  }

  /// Get payment status description using new constants
  String _getPaymentStatusDescription(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return 'Payment received successfully';
      case 'pending':
        return 'Payment pending (COD)';
      case 'cancelled':
        return 'Payment was cancelled';
      case 'refunded':
        return 'Payment was refunded';
      default:
        return 'Payment status updated';
    }
  }

  /// Get order status description
  String _getOrderStatusDescription(String status) {
    switch (status.toLowerCase()) {
      case 'preparing':
        return 'Processing your order';
      case 'to ship':
        return 'Ready for pickup/delivery';
      case 'in transit':
        return 'Package on the way';
      case 'out for delivery':
        return 'Out for delivery today';
      case 'delivered':
        return 'Successfully delivered';
      case 'cancelled':
        return 'Order was cancelled';
      default:
        return 'Order status updated';
    }
  }

  /// Get success message based on payment status
  String _getSuccessMessage(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return 'Your payment has been processed successfully! Your order is now being prepared. You can track both payment and order status in the Orders section.';
      case 'pending':
        return 'Your order has been placed successfully! Payment will be collected upon delivery. Your order is now being prepared and you can track both payment and order status in the Orders section.';
      case 'cancelled':
        return 'Your payment was cancelled. Please try again or contact support if you need assistance.';
      case 'refunded':
        return 'Your payment has been refunded. The refund should appear in your account within 3-5 business days.';
      default:
        return 'Your order has been processed. You can track the status in the Orders section.';
    }
  }

  Widget _buildPaymentMethodTile(Map<String, String> method) {
    final isSelected = _selectedPaymentMethod == method['value'];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        border: Border.all(
          color: isSelected
              ? Theme.of(context).primaryColor
              : Colors.grey.shade300,
          width: isSelected ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Text(
          method['icon']!,
          style: const TextStyle(fontSize: 24),
        ),
        title: Text(method['label']!),
        trailing: Radio<String>(
          value: method['value']!,
          groupValue: _selectedPaymentMethod,
          onChanged: (value) {
            setState(() {
              _selectedPaymentMethod = value!;
            });
          },
        ),
        onTap: () {
          setState(() {
            _selectedPaymentMethod = method['value']!;
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
        centerTitle: true,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Order Summary Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Order Summary',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ...widget.cartItems.map((item) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  '${item['name']} x ${item['quantity']}',
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ),
                              Text(
                                '$kInterPunctChr $pesoSymbol${item['subtotal']}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        )),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '$pesoSymbol${widget.total.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Shipping Address
            const Text(
              'Shipping Address',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            // Recipient name
            TextFormField(
              controller: _shippingNameController,
              decoration: const InputDecoration(
                labelText: 'Recipient Name',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter recipient name';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            // Recipient contact number
            TextFormField(
              controller: _shippingContactController,
              decoration: const InputDecoration(
                labelText: 'Contact Number',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.phone),
              ),
              keyboardType: TextInputType.phone,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter contact number';
                }
                // basic phone validation: only digits and optional leading +
                final cleaned = value.replaceAll(RegExp(r'[^\d+]'), '');
                if (!RegExp(r'^\+?\d{7,15}\$').hasMatch(cleaned)) {
                  return 'Enter a valid contact number';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _shippingAddressController,
              decoration: const InputDecoration(
                labelText: 'Shipping Address',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.location_on),
              ),
              maxLines: 3,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter shipping address';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            // Billing Address
            const Text(
              'Billing Address',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            CheckboxListTile(
              title: const Text('Same as shipping address'),
              value: _sameAsShipping,
              onChanged: (value) {
                setState(() {
                  _sameAsShipping = value ?? true;
                });
              },
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),
            if (!_sameAsShipping) ...[
              const SizedBox(height: 12),
              TextFormField(
                controller: _billingAddressController,
                decoration: const InputDecoration(
                  labelText: 'Billing Address',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_on),
                ),
                maxLines: 3,
                validator: (value) {
                  if (!_sameAsShipping &&
                      (value == null || value.trim().isEmpty)) {
                    return 'Please enter billing address';
                  }
                  return null;
                },
              ),
            ],
            const SizedBox(height: 24),

            // Payment Methods
            const Text(
              'Payment Method',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            ..._paymentMethods.map((method) => _buildPaymentMethodTile(method)),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isProcessing ? null : _processPayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isProcessing
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                          SizedBox(width: 12),
                          Text('Processing...'),
                        ],
                      )
                    : Text(
                        'Pay $pesoSymbol${widget.total.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
