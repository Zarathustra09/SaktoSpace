import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  // Sample cart items
  final List<Map<String, dynamic>> _cartItems = [
    {
      'name': 'Product 1',
      'price': 29.99,
      'quantity': 1,
    },
    {
      'name': 'Product 2',
      'price': 49.99,
      'quantity': 2,
    },
    // Add more items as needed
  ];

  double get _totalPrice {
    return _cartItems.fold(
        0.0, (sum, item) => sum + (item['price'] * item['quantity']));
  }

  void _incrementQuantity(int index) {
    setState(() {
      _cartItems[index]['quantity']++;
    });
  }

  void _decrementQuantity(int index) {
    setState(() {
      if (_cartItems[index]['quantity'] > 1) {
        _cartItems[index]['quantity']--;
      }
    });
  }

  void _removeItem(int index) {
    setState(() {
      _cartItems.removeAt(index);
    });
  }

  Widget _buildShimmerImage() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(),
        title: const Text('Cart'),
        centerTitle: true,
      ),
      body: _cartItems.isEmpty
          ? const Center(
              child: Text('Your cart is empty.'),
            )
          : ListView.builder(
              itemCount: _cartItems.length,
              itemBuilder: (context, index) {
                final item = _cartItems[index];
                return Card(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    leading: _buildShimmerImage(),
                    title: Text(item['name']),
                    subtitle: Text('\$${item['price'].toStringAsFixed(2)}'),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove),
                              onPressed: () => _decrementQuantity(index),
                            ),
                            Text(item['quantity'].toString()),
                            IconButton(
                              icon: const Icon(Icons.add),
                              onPressed: () => _incrementQuantity(index),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () => _removeItem(index),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      bottomNavigationBar: _cartItems.isEmpty
          ? null
          : Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    offset: Offset(0, -1),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total: \$${_totalPrice.toStringAsFixed(2)}',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      // TODO: Implement checkout functionality
                    },
                    child: const Text('Checkout'),
                  ),
                ],
              ),
            ),
    );
  }
}
