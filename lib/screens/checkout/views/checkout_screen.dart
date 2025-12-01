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

  // GCash payment fields
  final _gcashNumberController = TextEditingController();
  final _gcashReferenceController = TextEditingController();

  String _selectedPaymentMethod = 'credit_card';
  String _selectedShippingType = 'standard'; // 'standard' or 'express'
  bool _sameAsShipping = true;
  bool _isProcessing = false;

  // Shipping fee calculation
  double get _shippingFee {
    if (widget.total >= freeShippingThreshold) {
      return 0.0; // Free shipping
    }
    return _selectedShippingType == 'express'
        ? expressShippingFee
        : standardShippingFee;
  }

  double get _totalWithShipping => widget.total + _shippingFee;

  final List<Map<String, String>> _paymentMethods = [
    {'value': 'credit_card', 'label': 'Credit Card', 'icon': '💳'},
    {'value': 'debit_card', 'label': 'Debit Card', 'icon': '💳'},
    {'value': 'gcash', 'label': 'GCash', 'icon': '💰'},
    {'value': 'paymaya', 'label': 'PayMaya', 'icon': '💵'},
    {'value': 'bank_transfer', 'label': 'Bank Transfer', 'icon': '🏦'},
    {'value': 'cash_on_delivery', 'label': 'Cash on Delivery', 'icon': '📦'},
  ];

  @override
  void dispose() {
    _billingAddressController.dispose();
    _shippingAddressController.dispose();
    _shippingNameController.dispose();
    _shippingContactController.dispose();
    _gcashNumberController.dispose();
    _gcashReferenceController.dispose();
    super.dispose();
  }

  Future<void> _processPayment() async {
    print('=== PAYMENT PROCESSING STARTED ===');
    print('Form validation: ${_formKey.currentState?.validate()}');

    if (!_formKey.currentState!.validate()) {
      print('Form validation failed - stopping payment process');
      return;
    }

    // Special validation for GCash
    if (_selectedPaymentMethod == 'gcash') {
      if (!await _validateGCashPayment()) {
        return;
      }
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      final billingAddress = _sameAsShipping
          ? _shippingAddressController.text
          : _billingAddressController.text;

      // Add shipping fee to payment metadata
      final shippingMetadata = {
        'shipping_type': _selectedShippingType,
        'shipping_fee': _shippingFee,
        'free_shipping': _shippingFee == 0.0,
      };

      // Add GCash reference if applicable
      if (_selectedPaymentMethod == 'gcash') {
        shippingMetadata['gcash_number'] = _gcashNumberController.text;
        shippingMetadata['gcash_reference'] = _gcashReferenceController.text;
      }

      Map<String, dynamic> result;

      if (widget.isDirectPurchase && widget.directPurchaseData != null) {
        result = await _paymentService.processDirectPayment(
          productId: widget.directPurchaseData!['productId'],
          quantity: widget.directPurchaseData!['quantity'],
          paymentMethod: _selectedPaymentMethod,
          billingAddress: billingAddress,
          shippingAddress: _shippingAddressController.text,
          recipientName: _shippingNameController.text,
          recipientContact: _shippingContactController.text,
          shippingFee: _shippingFee,
          metadata: shippingMetadata,
        );
      } else {
        List<Map<String, dynamic>>? paymentItems;
        if (widget.cartItems.isNotEmpty) {
          paymentItems = widget.cartItems
              .map((item) {
                // Prefer product id from nested product object if available
                final productId = item['product'] != null
                    ? (item['product']['id'] ?? item['product']['product_id'])
                    : (item['product_id'] ?? item['id']);

                if (productId == null) return null;

                return {
                  'product_id': productId,
                  'quantity': item['quantity'] ?? 1,
                  'price': item['price'] ?? item['product']?['price'],
                  'name': item['name'] ?? item['product']?['name'],
                };
              })
              .where((e) => e != null)
              .cast<Map<String, dynamic>>()
              .toList();
        }

        print('DEBUG: Sending paymentItems: $paymentItems');
        result = await _paymentService.processPayment(
          paymentMethod: _selectedPaymentMethod,
          billingAddress: billingAddress,
          shippingAddress: _shippingAddressController.text,
          recipientName: _shippingNameController.text,
          recipientContact: _shippingContactController.text,
          cartItems: paymentItems,
          shippingFee: _shippingFee,
          metadata: shippingMetadata,
        );
      }

      if (result['success'] != true) {
        throw Exception(result['message'] ?? 'Payment processing failed');
      }

      final paymentData = result['data'];
      if (paymentData == null) {
        throw Exception('Invalid payment response: missing payment data');
      }

      if (!widget.isDirectPurchase) {
        // Remove only the purchased items from the cart, not all items
        for (final item in widget.cartItems) {
          final cartItemId = item['id'];
          if (cartItemId != null) {
            try {
              await _cartService.removeItem(cartItemId);
            } catch (e) {
              // Ignore errors removing individual items (they may already be gone)
              print('Warning: Could not remove cart item $cartItemId: $e');
            }
          }
        }
      }

      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
        _showSuccessDialog(paymentData);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
        final errorMessage = _getFormattedErrorMessage(e.toString());
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  // Validate GCash payment
  Future<bool> _validateGCashPayment() async {
    if (_gcashNumberController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your GCash number'),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }

    if (_gcashReferenceController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter the GCash reference number'),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm GCash Payment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Please confirm your GCash payment details:'),
            const SizedBox(height: 16),
            Text('Amount: ${formatPeso(_totalWithShipping)}'),
            Text('GCash Number: ${_gcashNumberController.text}'),
            Text('Reference: ${_gcashReferenceController.text}'),
            const SizedBox(height: 16),
            const Text(
              'Make sure you have sent the payment to the merchant before confirming.',
              style: TextStyle(fontSize: 12, color: Colors.red),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    return confirmed ?? false;
  }

  // Build GCash payment form
  Widget _buildGCashForm() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  '💰',
                  style: TextStyle(fontSize: 24),
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'GCash Payment Instructions',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Step 1: Send payment to',
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  gcashMerchantNumber,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  gcashMerchantName,
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Step 2: Enter your details',
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _gcashNumberController,
            decoration: const InputDecoration(
              labelText: 'Your GCash Number',
              hintText: '09171234567',
              prefixIcon: Icon(Icons.phone),
            ),
            keyboardType: TextInputType.phone,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your GCash number';
              }
              if (!RegExp(r'^09\d{9}$').hasMatch(value)) {
                return 'Please enter a valid GCash number';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _gcashReferenceController,
            decoration: const InputDecoration(
              labelText: 'GCash Reference Number',
              hintText: 'Enter reference number from receipt',
              prefixIcon: Icon(Icons.receipt),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter the reference number';
              }
              if (value.length < 10) {
                return 'Reference number must be at least 10 characters';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.orange.shade700),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Your order will be verified before processing',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Build shipping options
  Widget _buildShippingOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Shipping Options',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),

        // Free shipping notice
        if (widget.total >= freeShippingThreshold)
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.local_shipping, color: Colors.green.shade700),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'You qualify for FREE SHIPPING! 🎉',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.green,
                    ),
                  ),
                ),
              ],
            ),
          ),

        // Standard Shipping
        _buildShippingOption(
          'standard',
          'Standard Shipping',
          'Delivery in 3-5 business days',
          widget.total >= freeShippingThreshold ? 0.0 : standardShippingFee,
          Icons.local_shipping,
        ),
        const SizedBox(height: 12),

        // Express Shipping
        _buildShippingOption(
          'express',
          'Express Shipping',
          'Delivery in 1-2 business days',
          widget.total >= freeShippingThreshold ? 0.0 : expressShippingFee,
          Icons.electric_bolt,
        ),
      ],
    );
  }

  Widget _buildShippingOption(
    String value,
    String title,
    String description,
    double fee,
    IconData icon,
  ) {
    final isSelected = _selectedShippingType == value;

    return Container(
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
        leading: Icon(
          icon,
          color: isSelected ? Theme.of(context).primaryColor : Colors.grey,
        ),
        title: Text(title),
        subtitle: Text(description),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              fee == 0.0 ? 'FREE' : formatPeso(fee),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: fee == 0.0 ? Colors.green : Colors.black,
              ),
            ),
            if (fee == 0.0)
              Text(
                'was ${formatPeso(value == 'express' ? expressShippingFee : standardShippingFee)}',
                style: TextStyle(
                  fontSize: 10,
                  decoration: TextDecoration.lineThrough,
                  color: Colors.grey.shade600,
                ),
              ),
          ],
        ),
        onTap: () {
          setState(() {
            _selectedShippingType = value;
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
                                formatPeso(item['subtotal']),
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
                        const Text('Subtotal'),
                        Text(formatPeso(widget.total)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Shipping Fee'),
                        Text(
                          _shippingFee == 0.0
                              ? 'FREE'
                              : formatPeso(_shippingFee),
                          style: TextStyle(
                            color: _shippingFee == 0.0
                                ? Colors.green
                                : Colors.black,
                            fontWeight: _shippingFee == 0.0
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
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
                          formatPeso(_totalWithShipping),
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

            // Shipping Options
            _buildShippingOptions(),
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
                if (!RegExp(r'^\+?\d{7,15}$').hasMatch(cleaned)) {
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

            // GCash Form (shown only when GCash is selected)
            if (_selectedPaymentMethod == 'gcash') ...[
              const SizedBox(height: 16),
              _buildGCashForm(),
            ],
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
                        'Pay ${formatPeso(_totalWithShipping)}',
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
                'Amount: $pesoSymbol${paymentData['total_amount']?.toString() ?? paymentData['amount']?.toString() ?? _totalWithShipping.toStringAsFixed(2)}',
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
}
