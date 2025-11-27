import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shop/constants.dart';
import 'package:url_launcher/url_launcher.dart';

class OrderStatusTrackerScreen extends StatelessWidget {
  final Map<String, dynamic> order;

  const OrderStatusTrackerScreen({
    super.key,
    required this.order,
  });

  // Helper method to extract shipping fee from order data
  double _getShippingFee() {
    // NOTE: Backend needs to be updated to include shipping_fee and metadata from payments table
    // The /orders endpoint should JOIN payments table on payment_id and include these fields

    // Try to get shipping fee directly (will work once backend is fixed)
    if (order['shipping_fee'] != null) {
      final fee = order['shipping_fee'];
      if (fee is num) return fee.toDouble();
      if (fee is String) return double.tryParse(fee) ?? 0.0;
    }

    // Try to get from metadata (will work once backend is fixed)
    if (order['metadata'] != null) {
      var metadata = order['metadata'];
      if (metadata is String) {
        try {
          final decoded = jsonDecode(metadata);
          if (decoded is Map && decoded['shipping_fee'] != null) {
            final fee = decoded['shipping_fee'];
            if (fee is num) return fee.toDouble();
            if (fee is String) return double.tryParse(fee) ?? 0.0;
          }
        } catch (e) {
          // Silently handle JSON parse errors
        }
      } else if (metadata is Map && metadata['shipping_fee'] != null) {
        final fee = metadata['shipping_fee'];
        if (fee is num) return fee.toDouble();
        if (fee is String) return double.tryParse(fee) ?? 0.0;
      }
    }

    // Temporary fallback: Use 0 for now since backend doesn't include shipping_fee
    // TODO: Backend needs to include shipping_fee from payments table
    return 0.0;
  }

  // Helper method to safely convert subtotal to double
  double _getSubtotal() {
    final subtotalValue = order['subtotal'] ?? 0;
    if (subtotalValue is num) return subtotalValue.toDouble();
    if (subtotalValue is String) return double.tryParse(subtotalValue) ?? 0.0;
    return 0.0;
  }

  // Helper method to safely convert quantity to int
  int _getQuantity() {
    final qtyValue = order['quantity'] ?? 1;
    if (qtyValue is int) return qtyValue;
    if (qtyValue is String) return int.tryParse(qtyValue) ?? 1;
    if (qtyValue is num) return qtyValue.toInt();
    return 1;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Status'),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order Header Info
            Card(
              child: Padding(
                padding: const EdgeInsets.all(defaultPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (order['product']?['image'] != null) ...[
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              color: Colors.grey[200],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                order['product']['image']
                                        .toString()
                                        .startsWith('http')
                                    ? order['product']['image']
                                    : '$storageUrl${order['product']['image']}',
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Icon(
                                  Icons
                                      .chair, // Changed from Icons.furniture to Icons.chair
                                  color: Colors.grey[400],
                                  size: 30,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                        ],
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                order['product_name'] ?? 'Unknown Product',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Order #${order['transaction_id'] ?? order['payment_id']}',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: blackColor60,
                                    ),
                              ),
                              if (order['category_name'] != null)
                                Text(
                                  'Category: ${order['category_name']}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: blackColor60,
                                      ),
                                ),
                              const SizedBox(height: 8),
                              Text(
                                'Qty: ${_getQuantity()} × ${formatPeso(_getSubtotal() / _getQuantity())}',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: blackColor60,
                                    ),
                              ),
                              Text(
                                'Subtotal: ${formatPeso(_getSubtotal())}',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: blackColor60,
                                    ),
                              ),
                              Text(
                                'Shipping Fee: ${formatPeso(_getShippingFee())}',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: blackColor60,
                                    ),
                              ),
                              Text(
                                'Total: ${formatPeso(_getSubtotal() + _getShippingFee())}',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall
                                    ?.copyWith(
                                      color: primaryColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Status Tracker
            Text(
              'Order Progress',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            _buildStatusTracker(context),
            const SizedBox(height: 20),

            // Order Details
            Card(
              child: Padding(
                padding: const EdgeInsets.all(defaultPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Order Details',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 12),
                    _buildDetailRow(
                        'Order Date',
                        order['purchased_at']?.toString().split(' ')[0] ??
                            'N/A'),
                    _buildDetailRow(
                        'Payment Method', order['payment_method'] ?? 'N/A'),
                    _buildDetailRow(
                        'Payment Status', order['payment_status'] ?? 'N/A'),
                    if (order['status_updated_at'] != null)
                      _buildDetailRow('Last Updated',
                          order['status_updated_at'].toString().split(' ')[0]),
                    if (order['category_name'] != null)
                      _buildDetailRow('Category', order['category_name']),
                  ],
                ),
              ),
            ),

            // Address Information (if available)
            if (order['shipping_address'] != null ||
                order['billing_address'] != null) ...[
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(defaultPadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Delivery Information',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      const SizedBox(height: 12),
                      if (order['shipping_address'] != null) ...[
                        const Text(
                          'Shipping Address:',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 4),
                        Text(order['shipping_address'].toString()),
                      ],
                      if (order['billing_address'] != null) ...[
                        if (order['shipping_address'] != null)
                          const SizedBox(height: 12),
                        const Text(
                          'Billing Address:',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 4),
                        Text(order['billing_address'].toString()),
                      ],
                    ],
                  ),
                ),
              ),
            ],

            // Help Section
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(defaultPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.help_outline, color: primaryColor),
                        const SizedBox(width: 8),
                        Text(
                          'Need Help?',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                        'If you have any questions about your order, please contact our customer support.'),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: () => _contactSupport(context),
                      icon: const Icon(Icons.phone, size: 16),
                      label: const Text('Contact Support'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _contactSupport(BuildContext context) async {
    final String phone = supportPhoneNumber;
    final String serviceName = 'Customer Support';

    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.phone, color: primaryColor),
              const SizedBox(width: 8),
              const Expanded(child: Text('Confirm Call')),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Do you want to call $serviceName?'),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.phone, color: Colors.green, size: 18),
                    const SizedBox(width: 8),
                    Text(phone,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton.icon(
              onPressed: () => Navigator.of(context).pop(true),
              icon: const Icon(Icons.phone, size: 16),
              label: const Text('Call Now'),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    final cleanNumber = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    final Uri telUri = Uri(scheme: 'tel', path: cleanNumber);

    try {
      if (await canLaunchUrl(telUri)) {
        await launchUrl(telUri, mode: LaunchMode.externalApplication);
      } else {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch phone dialer')),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error launching phone dialer: $e')),
      );
    }
  }

  Widget _buildStatusTracker(BuildContext context) {
    final String currentStatus = order['status'] ?? 'Preparing';
    final List<Map<String, dynamic>> statuses = [
      {
        'status': 'Preparing',
        'title': 'Order Placed',
        'subtitle': 'We received your order',
        'icon': Icons.receipt_outlined,
      },
      {
        'status': 'To Ship',
        'title': 'Ready to Ship',
        'subtitle': 'Order is packed and ready',
        'icon': Icons.inventory_2_outlined,
      },
      {
        'status': 'In Transit',
        'title': 'In Transit',
        'subtitle': 'Your order is on the way',
        'icon': Icons.local_shipping_outlined,
      },
      {
        'status': 'Out for Delivery',
        'title': 'Out for Delivery',
        'subtitle': 'Driver is nearby',
        'icon': Icons.delivery_dining_outlined,
      },
      {
        'status': 'Delivered',
        'title': 'Delivered',
        'subtitle': 'Order has been delivered',
        'icon': Icons.check_circle_outline,
      },
    ];

    // Handle cancelled status
    if (currentStatus == 'Cancelled') {
      return _buildCancelledStatus(context);
    }

    final int currentIndex =
        statuses.indexWhere((s) => s['status'] == currentStatus);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          for (int i = 0; i < statuses.length; i++) ...[
            _buildStatusItem(
              context,
              statuses[i],
              isActive: i <= currentIndex,
              isCurrent: i == currentIndex,
              isCompleted: i < currentIndex,
            ),
            if (i < statuses.length - 1)
              _buildConnector(isActive: i < currentIndex),
          ],
        ],
      ),
    );
  }

  Widget _buildCancelledStatus(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Column(
        children: [
          Icon(
            Icons.cancel_outlined,
            size: 64,
            color: Colors.red[600],
          ),
          const SizedBox(height: 12),
          Text(
            'Order Cancelled',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.red[700],
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'This order has been cancelled.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.red[600],
                ),
            textAlign: TextAlign.center,
          ),
          if (order['status_updated_at'] != null) ...[
            const SizedBox(height: 8),
            Text(
              'Cancelled on: ${order['status_updated_at'].toString().split(' ')[0]}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.red[500],
                  ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusItem(
    BuildContext context,
    Map<String, dynamic> statusData, {
    required bool isActive,
    required bool isCurrent,
    required bool isCompleted,
  }) {
    Color statusColor;
    if (isCompleted) {
      statusColor = Colors.green;
    } else if (isCurrent) {
      statusColor = primaryColor;
    } else {
      statusColor = Colors.grey;
    }

    return Row(
      children: [
        // Status Icon
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: isActive ? statusColor : Colors.grey[200],
            shape: BoxShape.circle,
            border: Border.all(
              color: isActive ? statusColor : Colors.grey[300]!,
              width: 2,
            ),
          ),
          child: Icon(
            isCompleted ? Icons.check : statusData['icon'],
            color: isActive ? Colors.white : Colors.grey[400],
            size: 24,
          ),
        ),
        const SizedBox(width: 16),

        // Status Text
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                statusData['title'],
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isActive ? statusColor : Colors.grey[600],
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                statusData['subtitle'],
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: isActive ? Colors.grey[700] : Colors.grey[500],
                    ),
              ),
              // Show timestamp for current status
              if (isCurrent && order['status_updated_at'] != null) ...[
                const SizedBox(height: 2),
                Text(
                  'Updated: ${order['status_updated_at'].toString().split(' ')[0]}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: statusColor,
                        fontStyle: FontStyle.italic,
                      ),
                ),
              ],
            ],
          ),
        ),

        // Status indicator
        if (isCurrent)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: statusColor.withOpacity(0.3)),
            ),
            child: Text(
              'Current',
              style: TextStyle(
                color: statusColor,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildConnector({required bool isActive}) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          const SizedBox(width: 24), // Center with icon
          Container(
            width: 2,
            height: 24,
            color: isActive ? Colors.green : Colors.grey[300],
          ),
          const SizedBox(width: 22), // Complete the centering
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: blackColor60,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w400),
            ),
          ),
        ],
      ),
    );
  }
}
