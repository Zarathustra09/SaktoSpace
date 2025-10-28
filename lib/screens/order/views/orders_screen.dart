import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shop/constants.dart';
import 'package:shop/services/orders/order_service.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  final OrderService _orderService = OrderService();
  List<Map<String, dynamic>> _orders = [];
  Map<String, dynamic>? _orderStats;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadOrders();
    _loadOrderStats();
  }

  Future<void> _loadOrders() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final orders = await _orderService.getOrders();
      setState(() {
        _orders = orders;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadOrderStats() async {
    try {
      final stats = await _orderService.getOrderStats();
      setState(() {
        _orderStats = stats;
      });
    } catch (e) {
      print('Error loading order stats: $e');
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return successColor;
      case 'pending':
        return warningColor;
      case 'cancelled':
        return errorColor;
      case 'processing':
        return primaryColor;
      default:
        return primaryColor;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Icons.check_circle;
      case 'pending':
        return Icons.access_time;
      case 'cancelled':
        return Icons.cancel;
      case 'processing':
        return Icons.hourglass_empty;
      default:
        return Icons.shopping_bag;
    }
  }

  List<Map<String, dynamic>> _parseItems(dynamic purchasedItems) {
    try {
      if (purchasedItems == null) return [];

      if (purchasedItems is String) {
        final decoded = jsonDecode(purchasedItems);
        if (decoded is List) {
          return decoded.map((item) {
            if (item is Map) {
              return Map<String, dynamic>.from(item);
            }
            return <String, dynamic>{};
          }).toList();
        }
      } else if (purchasedItems is List) {
        return purchasedItems.map((item) {
          if (item is Map) {
            return Map<String, dynamic>.from(item);
          }
          return <String, dynamic>{};
        }).toList();
      }

      return [];
    } catch (e) {
      print('Error parsing items: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Orders'),
        centerTitle: true,
        leading: const BackButton(),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _loadOrders();
              _loadOrderStats();
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await _loadOrders();
          await _loadOrderStats();
        },
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Error loading orders',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.grey[600],
                              ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadOrders,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                : Column(
                    children: [
                      // Order Statistics
                      if (_orderStats != null)
                        Container(
                          margin: const EdgeInsets.all(defaultPadding),
                          padding: const EdgeInsets.all(defaultPadding),
                          decoration: BoxDecoration(
                            color: primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(defaultBorderRadious),
                            border: Border.all(color: primaryColor.withOpacity(0.2)),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  children: [
                                    Text(
                                      '${_orderStats!['total_orders'] ?? 0}',
                                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: primaryColor,
                                          ),
                                    ),
                                    Text(
                                      'Total Orders',
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                            color: blackColor60,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  children: [
                                    Text(
                                      formatPeso(_orderStats!['total_spent']),
                                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: successColor,
                                          ),
                                    ),
                                    Text(
                                      'Total Spent',
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                            color: blackColor60,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                      // Orders List
                      Expanded(
                        child: _orders.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.shopping_bag_outlined,
                                      size: 64,
                                      color: Colors.grey[400],
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'No orders yet',
                                      style: Theme.of(context).textTheme.titleMedium,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Start shopping to see your orders here',
                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                            color: Colors.grey[600],
                                          ),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.all(defaultPadding),
                                itemCount: _orders.length,
                                itemBuilder: (context, index) {
                                  final order = _orders[index];
                                  final status = order['status'] ?? 'pending';
                                  final statusColor = _getStatusColor(status);
                                  final statusIcon = _getStatusIcon(status);
                                  final items = _parseItems(order['purchased_items']);

                                  return Card(
                                    margin: const EdgeInsets.only(bottom: defaultPadding),
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(defaultBorderRadious),
                                      onTap: () => _showOrderDetails(order),
                                      child: Padding(
                                        padding: const EdgeInsets.all(defaultPadding),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Text(
                                                  'Order #${order['order_id']}',
                                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                ),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 4,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: statusColor.withOpacity(0.1),
                                                    borderRadius: BorderRadius.circular(12),
                                                  ),
                                                  child: Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      Icon(
                                                        statusIcon,
                                                        size: 16,
                                                        color: statusColor,
                                                      ),
                                                      const SizedBox(width: 4),
                                                      Text(
                                                        status.toUpperCase(),
                                                        style: TextStyle(
                                                          color: statusColor,
                                                          fontWeight: FontWeight.bold,
                                                          fontSize: 12,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              'Total: ${formatPeso(order['total_amount'])}',
                                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                                    color: primaryColor,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'Date: ${order['order_date']?.toString().split(' ')[0] ?? 'N/A'}',
                                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                    color: blackColor60,
                                                  ),
                                            ),
                                            if (items.isNotEmpty) ...[
                                              const SizedBox(height: 8),
                                              Text(
                                                '${items.length} item${items.length > 1 ? 's' : ''}',
                                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                      color: blackColor60,
                                                    ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
      ),
    );
  }

  void _showOrderDetails(Map<String, dynamic> order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(defaultPadding),
              child: Text(
                'Order #${order['order_id']}',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.all(defaultPadding),
                children: [
                  _buildDetailRow('Transaction ID', order['transaction_id'] ?? 'N/A'),
                  _buildDetailRow('Status', order['status'] ?? 'N/A'),
                  _buildDetailRow('Payment Method', order['payment_method'] ?? 'N/A'),
                  _buildDetailRow('Total Amount', formatPeso(order['total_amount'])),
                  _buildDetailRow('Order Date', order['order_date']?.toString().split(' ')[0] ?? 'N/A'),

                  // Items Section
                  if (order['purchased_items'] != null) ...[
                    const SizedBox(height: 20),
                    Text(
                      'Ordered Items',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 12),
                    ..._buildItemsList(order['purchased_items']),
                  ],

                  if (order['billing_address'] != null) ...[
                    const SizedBox(height: 20),
                    Text(
                      'Billing Address',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    _buildAddressCard(order['billing_address']),
                  ],

                  if (order['shipping_address'] != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      'Shipping Address',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    _buildAddressCard(order['shipping_address']),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildItemsList(dynamic purchasedItems) {
    final items = _parseItems(purchasedItems);

    if (items.isEmpty) {
      return [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            'No items found',
            style: TextStyle(color: Colors.grey[600]),
          ),
        )
      ];
    }

    return items.map((item) => Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Card(
        elevation: 1,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => _showItemDetails(item),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Item Image
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.grey[200],
                  ),
                  child: item['image'] != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            item['image'].toString().startsWith('http')
                                ? item['image']
                                : '$storageUrl${item['image']}',
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Icon(
                              Icons.image_not_supported,
                              color: Colors.grey[400],
                            ),
                          ),
                        )
                      : Icon(
                          Icons.shopping_bag,
                          color: Colors.grey[400],
                        ),
                ),
                const SizedBox(width: 12),

                // Item Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['name'] ?? 'Unknown Item',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      if (item['quantity'] != null)
                        Text(
                          'Qty: ${item['quantity']}',
                          style: TextStyle(
                            color: blackColor60,
                            fontSize: 12,
                          ),
                        ),
                      if (item['price'] != null)
                        Text(
                          formatPeso(item['price']),
                          style: const TextStyle(
                            color: primaryColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                    ],
                  ),
                ),

                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Colors.grey[400],
                ),
              ],
            ),
          ),
        ),
      ),
    )).toList();
  }

  void _showItemDetails(Map<String, dynamic> item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(item['name'] ?? 'Item Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (item['image'] != null) ...[
              Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey[200],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    item['image'].toString().startsWith('http')
                        ? item['image']
                        : '$storageUrl${item['image']}',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Icon(
                      Icons.image_not_supported,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            if (item['description'] != null) ...[
              Text(
                'Description:',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(item['description']),
              const SizedBox(height: 12),
            ],
            if (item['quantity'] != null) ...[
              Text('Quantity: ${item['quantity']}'),
              const SizedBox(height: 8),
            ],
            if (item['price'] != null) ...[
              Text(
                'Price: ${formatPeso(item['price'])}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressCard(dynamic address) {
    String addressText = '';

    try {
      if (address is String) {
        // Try to parse as JSON first
        try {
          final parsed = jsonDecode(address);
          if (parsed is Map) {
            addressText = _formatAddressFromMap(parsed);
          } else {
            addressText = address;
          }
        } catch (e) {
          addressText = address;
        }
      } else if (address is Map) {
        addressText = _formatAddressFromMap(address);
      } else {
        addressText = address.toString();
      }
    } catch (e) {
      addressText = address.toString();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Text(
        addressText,
        style: const TextStyle(fontSize: 14),
      ),
    );
  }

 String _formatAddressFromMap(Map addressMap) {
   final parts = <String>[];

   // Convert to Map<String, dynamic> for safe access
   final safeMap = Map<String, dynamic>.from(addressMap);

   if (safeMap['street'] != null) parts.add(safeMap['street'].toString());
   if (safeMap['city'] != null) parts.add(safeMap['city'].toString());
   if (safeMap['state'] != null) parts.add(safeMap['state'].toString());
   if (safeMap['zip'] != null) parts.add(safeMap['zip'].toString());
   if (safeMap['country'] != null) parts.add(safeMap['country'].toString());

   return parts.isNotEmpty ? parts.join(', ') : addressMap.toString();
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
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: blackColor60,
                  ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

