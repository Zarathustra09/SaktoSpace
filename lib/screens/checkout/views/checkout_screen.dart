// lib/screens/checkout/views/checkout_screen.dart
import 'package:flutter/material.dart';
import 'package:shop/services/payment/payment_service.dart';
import 'package:shop/services/cart/cart_service.dart';

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

  String _selectedPaymentMethod = 'credit_card';
  bool _sameAsShipping = true;
  bool _isProcessing = false;

  final List<Map<String, String>> _paymentMethods = [
    {'value': 'credit_card', 'label': 'Credit Card', 'icon': '💳'},
    {'value': 'debit_card', 'label': 'Debit Card', 'icon': '💳'},
    // {'value': 'paypal', 'label': 'PayPal', 'icon': '📱'}, // PayPal temporarily disabled
    {'value': 'gcash', 'label': 'GCash', 'icon': '💰'},
    {'value': 'paymaya', 'label': 'PayMaya', 'icon': '💵'},
    {'value': 'bank_transfer', 'label': 'Bank Transfer', 'icon': '🏦'},
    {'value': 'cash_on_delivery', 'label': 'Cash on Delivery', 'icon': '📦'},
  ];

  @override
  void dispose() {
    _billingAddressController.dispose();
    _shippingAddressController.dispose();
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
        );
        print('Direct payment result: $result');
      } else {
        print('=== USING CART PAYMENT API ===');
        // Use cart payment API for cart checkout
        List<Map<String, dynamic>>? paymentItems;
        if (widget.isDirectPurchase) {
          paymentItems = widget.cartItems
              .map((item) => {
                    'product_id': item['id'],
                    'quantity': item['quantity'],
                    'price': item['price'],
                  })
              .toList();
          print('Payment items from cart: $paymentItems');
        }

        result = await _paymentService.processPayment(
          paymentMethod: _selectedPaymentMethod,
          billingAddress: billingAddress,
          shippingAddress: _shippingAddressController.text,
          cartItems: paymentItems,
        );
        print('Cart payment result: $result');
      }

      // Only clear cart if this is NOT a direct purchase (i.e., it's from cart)
      if (!widget.isDirectPurchase) {
        print('Clearing cart after successful payment...');
        try {
          await _cartService.clearCart();
          print('Cart cleared successfully');
        } catch (e) {
          print('Warning: Failed to clear cart after payment: $e');
        }
      } else {
        print('Skipping cart clear for direct purchase');
      }

      if (mounted) {
        print('Showing success dialog...');
        // Show success dialog
        _showSuccessDialog(result['data'] ?? result);
      } else {
        print('Widget not mounted, skipping success dialog');
      }
    } catch (e) {
      print('=== PAYMENT ERROR ===');
      print('Error type: ${e.runtimeType}');
      print('Error message: $e');
      print('Stack trace: ${StackTrace.current}');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment failed: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
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

  void _showSuccessDialog(Map<String, dynamic> paymentData) {
    final bool isCashOnDelivery = _selectedPaymentMethod == 'cash_on_delivery';
    final String status = paymentData['status'] ?? 'completed';

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
                  color: isCashOnDelivery
                      ? Colors.orange.shade100
                      : Colors.green.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isCashOnDelivery ? Icons.pending : Icons.check,
                  color: isCashOnDelivery
                      ? Colors.orange.shade600
                      : Colors.green.shade600,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Text(isCashOnDelivery ? 'Order Placed' : 'Payment Successful'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Transaction ID: ${paymentData['transaction_id'] ?? 'N/A'}'),
              const SizedBox(height: 8),
              Text(
                  'Amount: ₱${paymentData['amount'] ?? widget.total.toStringAsFixed(2)}'),
              const SizedBox(height: 8),
              Text('Status: ${status.toUpperCase()}'),
              const SizedBox(height: 8),
              Text(
                isCashOnDelivery
                    ? 'Your order has been placed successfully! Payment will be collected upon delivery.'
                    : 'Your order has been processed successfully!',
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
                                '₱${item['subtotal']}',
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
                          '₱${widget.total.toStringAsFixed(2)}',
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
                        'Pay ₱${widget.total.toStringAsFixed(2)}',
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
