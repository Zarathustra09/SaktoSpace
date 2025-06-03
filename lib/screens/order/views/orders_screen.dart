import 'package:flutter/material.dart';

class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Sample list of orders
    final List<Map<String, String>> orders = [
      {
        'orderNumber': 'Order #12345',
        'date': 'June 3, 2025',
        'status': 'Delivered',
        'total': '\$59.99',
      },
      {
        'orderNumber': 'Order #12346',
        'date': 'June 2, 2025',
        'status': 'Processing',
        'total': '\$89.50',
      },
      {
        'orderNumber': 'Order #12347',
        'date': 'June 1, 2025',
        'status': 'Cancelled',
        'total': '\$42.75',
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Orders'),
        centerTitle: true,
        leading: const BackButton(),
      ),
      body: ListView.builder(
        itemCount: orders.length,
        itemBuilder: (context, index) {
          final order = orders[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              title: Text(order['orderNumber']!),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Date: ${order['date']}'),
                  Text('Status: ${order['status']}'),
                ],
              ),
              trailing: Text(
                order['total']!,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              onTap: () {
                // Navigate to order details screen
                // Navigator.push(context, MaterialPageRoute(builder: (context) => OrderDetailsScreen(orderId: order['orderNumber'])));
              },
            ),
          );
        },
      ),
    );
  }
}
