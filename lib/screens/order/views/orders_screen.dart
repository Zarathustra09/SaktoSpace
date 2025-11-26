import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shop/constants.dart';
import 'package:shop/services/orders/order_service.dart';
import 'package:shop/screens/order/views/order_status_tracker_screen.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen>
    with SingleTickerProviderStateMixin {
  final OrderService _orderService = OrderService();
  List<Map<String, dynamic>> _orders = []; // Changed from _payments to _orders
  Map<String, dynamic>? _orderStats;
  bool _isLoading = true;
  String? _error;
  late TabController _tabController;
  List<String> _orderStatuses = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    await Future.wait([
      _loadOrders(),
      _loadOrderStats(),
      _loadOrderStatuses(),
    ]);
  }

  Future<void> _loadOrders() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Use the individual orders endpoint instead of grouped by payment
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

  Future<void> _loadOrderStatuses() async {
    try {
      final statuses = await _orderService.getAvailableOrderStatuses();
      setState(() {
        _orderStatuses = statuses;
      });
    } catch (e) {
      print('Error loading order statuses: $e');
      setState(() {
        _orderStatuses = _orderService.getDefaultOrderStatuses();
      });
    }
  }

  /// Get order status color (separate from payment status)
  Color _getOrderStatusColor(String status) {
    return _orderService.getOrderStatusColor(status);
  }

  /// Get payment status color (separate from order status)
  Color _getPaymentStatusColor(String status) {
    return _orderService.getPaymentStatusColor(status);
  }

  /// Get order status icon
  IconData _getOrderStatusIcon(String status) {
    return _orderService.getOrderStatusIcon(status);
  }

  /// Get payment status icon
  IconData _getPaymentStatusIcon(String status) {
    return _orderService.getPaymentStatusIcon(status);
  }

  /// Get order status description
  String _getOrderStatusDescription(String status) {
    return _orderService.getOrderStatusDescription(status);
  }

  /// Get payment status description
  String _getPaymentStatusDescription(String status) {
    return _orderService.getPaymentStatusDescription(status);
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
            onPressed: _loadData,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'All Orders', icon: Icon(Icons.list_alt)),
            Tab(text: 'Statistics', icon: Icon(Icons.analytics)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOrdersTab(),
          _buildStatsTab(),
        ],
      ),
    );
  }

  Widget _buildOrdersTab() {
    return RefreshIndicator(
      onRefresh: _loadOrders,
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorWidget()
              : _orders.isEmpty
                  ? _buildEmptyWidget()
                  : _buildOrdersList(), // Changed from _buildPaymentsList
    );
  }

  Widget _buildStatsTab() {
    if (_orderStats == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _loadOrderStats,
      child: ListView(
        padding: const EdgeInsets.all(defaultPadding),
        children: [
          // Overall Statistics
          Card(
            child: Padding(
              padding: const EdgeInsets.all(defaultPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Overall Statistics',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),
                  _buildStatRow(
                      'Total Orders', '${_orderStats!['total_orders'] ?? 0}'),
                  _buildStatRow('Total Payments',
                      '${_orderStats!['total_payments'] ?? 0}'),
                  _buildStatRow(
                      'Total Spent', formatPeso(_orderStats!['total_spent'])),
                  _buildStatRow('Items Purchased',
                      '${_orderStats!['total_items_purchased'] ?? 0}'),
                  _buildStatRow('Average Order Value',
                      formatPeso(_orderStats!['average_order_value'])),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Payment Status Breakdown
          Card(
            child: Padding(
              padding: const EdgeInsets.all(defaultPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Payment Status',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),
                  if (_orderStats!['payments_by_status'] != null)
                    ..._buildPaymentStatusRows(
                        _orderStats!['payments_by_status']),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Order Status Breakdown
          Card(
            child: Padding(
              padding: const EdgeInsets.all(defaultPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Order Status',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),
                  if (_orderStats!['orders_by_status'] != null)
                    ..._buildOrderStatusRows(_orderStats!['orders_by_status']),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildPaymentStatusRows(Map<String, dynamic> paymentStatuses) {
    return paymentStatuses.entries.map((entry) {
      final status = entry.key;
      final count = entry.value ?? 0;
      final statusColor = _getPaymentStatusColor(status);
      final statusIcon = _getPaymentStatusIcon(status);

      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Icon(statusIcon, color: statusColor, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                status,
                style:
                    TextStyle(color: statusColor, fontWeight: FontWeight.w500),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  List<Widget> _buildOrderStatusRows(Map<String, dynamic> orderStatuses) {
    return orderStatuses.entries.map((entry) {
      final status = entry.key;
      final count = entry.value ?? 0;
      final statusColor = _getOrderStatusColor(status);
      final statusIcon = _getOrderStatusIcon(status);

      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Icon(statusIcon, color: statusColor, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                status,
                style:
                    TextStyle(color: statusColor, fontWeight: FontWeight.w500),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: blackColor60),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
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
    );
  }

  Widget _buildEmptyWidget() {
    return Center(
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
    );
  }

  // Helper method to extract shipping fee from order data
  double _getShippingFee(Map<String, dynamic> order) {
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
          metadata = jsonDecode(metadata);
        } catch (e) {
          // Silently handle JSON parse errors
        }
      }
      if (metadata is Map && metadata['shipping_fee'] != null) {
        final fee = metadata['shipping_fee'];
        if (fee is num) return fee.toDouble();
        if (fee is String) return double.tryParse(fee) ?? 0.0;
      }
    }

    // Temporary fallback: Use 0 for now since backend doesn't include shipping_fee
    // TODO: Backend needs to include shipping_fee from payments table
    return 0.0;
  }

  Widget _buildOrdersList() {
    return ListView.builder(
      padding: const EdgeInsets.all(defaultPadding),
      itemCount: _orders.length,
      itemBuilder: (context, index) {
        final order = _orders[index];
        final orderStatus = order['status'] ?? 'Preparing';
        final paymentStatus = order['payment_status'] ?? 'Pending';
        final orderStatusColor = _getOrderStatusColor(orderStatus);
        final paymentStatusColor = _getPaymentStatusColor(paymentStatus);
        final orderStatusIcon = _getOrderStatusIcon(orderStatus);
        final paymentStatusIcon = _getPaymentStatusIcon(paymentStatus);

        // Get shipping fee and calculate total
        final subtotalValue = order['subtotal'] ?? 0;
        final subtotal = subtotalValue is num
            ? subtotalValue.toDouble()
            : (subtotalValue is String
                ? double.tryParse(subtotalValue) ?? 0.0
                : 0.0);
        final shippingFee = _getShippingFee(order);
        final totalWithShipping = subtotal + shippingFee;

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
                    children: [
                      // Product Image
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.grey[200],
                        ),
                        child: (order['product']?['image'] != null)
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  order['product']['image']
                                          .toString()
                                          .startsWith('http')
                                      ? order['product']['image']
                                      : '$storageUrl${order['product']['image']}',
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Icon(
                                    Icons.image_not_supported,
                                    color: Colors.grey[400],
                                  ),
                                ),
                              )
                            : Icon(Icons.shopping_bag, color: Colors.grey[400]),
                      ),
                      const SizedBox(width: 12),

                      // Order Details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              order['product_name'] ?? 'Unknown Item',
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
                            Text(
                              'Qty: ${order['quantity']} | Subtotal: ${formatPeso(subtotal)}',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: blackColor60,
                                  ),
                            ),
                            Text(
                              'Shipping: ${formatPeso(shippingFee)}',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: blackColor60,
                                  ),
                            ),
                            Text(
                              'Total: ${formatPeso(totalWithShipping)}',
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
                  const SizedBox(height: 12),

                  // Status Section
                  Row(
                    children: [
                      // Order Status
                      Flexible(
                        flex: 1,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 4),
                          decoration: BoxDecoration(
                            color: orderStatusColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                                color: orderStatusColor.withOpacity(0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(orderStatusIcon,
                                  size: 12, color: orderStatusColor),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      orderStatus,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: orderStatusColor,
                                        fontSize: 9,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      _getOrderStatusDescription(orderStatus),
                                      style: TextStyle(
                                        color:
                                            orderStatusColor.withOpacity(0.8),
                                        fontSize: 8,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),

                      // Payment Status
                      Flexible(
                        flex: 1,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 4),
                          decoration: BoxDecoration(
                            color: paymentStatusColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                                color: paymentStatusColor.withOpacity(0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(paymentStatusIcon,
                                  size: 12, color: paymentStatusColor),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      paymentStatus,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: paymentStatusColor,
                                        fontSize: 9,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      _getPaymentStatusDescription(
                                          paymentStatus),
                                      style: TextStyle(
                                        color:
                                            paymentStatusColor.withOpacity(0.8),
                                        fontSize: 8,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Order Date and Payment Method
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Date: ${order['purchased_at']?.toString().split(' ')[0] ?? order['created_at']?.toString().split(' ')[0] ?? 'N/A'}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: blackColor60,
                            ),
                      ),
                      Text(
                        '${order['payment_method'] ?? 'N/A'}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: blackColor60,
                            ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showOrderDetails(Map<String, dynamic> order) async {
    // Navigate to the new status tracker screen instead of showing a dialog
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OrderStatusTrackerScreen(order: order),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: blackColor60,
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 12),
            ),
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
}
