// lib/screens/checkout/views/cart_screen.dart
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:shop/services/cart/cart_service.dart';
import 'package:shop/constants.dart';
import 'package:shop/components/network_image_with_loader.dart';
import 'package:shop/route/route_constants.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final CartService _cartService = CartService();
  List<dynamic> _cartItems = [];
  // _total is no longer needed because we compute the selected total
  // Items selected for checkout (product IDs)
  Set<int> _selectedItems = {};
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchCart();
  }

  Future<void> _fetchCart() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final cartData = await _cartService.getCart();
      final data = cartData['data'];
      if (mounted) {
        setState(() {
          _cartItems = data['items'] ?? [];
          // total from API kept for possible reference (not used for checkout)
          // Default: select all items. If selections already exist, keep only
          // the intersection so we preserve previously toggled choices.
          final newIds = _cartItems.map<int>((i) => i['id'] as int).toSet();
          // Always select all items by default.
          _selectedItems = newIds;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _addQuantity(int productId) async {
    if (_isLoading) return;
    try {
      await _cartService.addToCart(productId: productId, quantity: 1);
      await _fetchCart();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _subtractQuantity(int productId, int quantity) async {
    if (_isLoading) return;
    try {
      if (quantity > 1) {
        await _cartService.updateQuantity(
            itemId: productId, quantity: quantity - 1);
      } else {
        await _cartService.removeItem(productId);
      }
      await _fetchCart();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  double _getItemSubtotal(dynamic item) {
    final val = item['subtotal'];
    if (val == null) return 0.0;
    if (val is num) return val.toDouble();
    return double.tryParse(val.toString()) ?? 0.0;
  }

  double get _selectedTotal {
    return _cartItems
        .where((i) => _selectedItems.contains(i['id'] as int))
        .fold(0.0, (acc, i) => acc + _getItemSubtotal(i));
  }

  // Selection is always enabled — items are always selected in this release.
  void _toggleSelection(int productId) {
    setState(() {
      if (_selectedItems.contains(productId)) {
        _selectedItems.remove(productId);
      } else {
        _selectedItems.add(productId);
      }
    });
  }

  void _navigateToCheckout() {
    if (_selectedItems.isEmpty) return; // no items selected for checkout

    Navigator.pushNamed(
      context,
      checkoutScreenRoute,
      arguments: {
        'total': _selectedTotal,
        'cartItems': _cartItems
            .where((i) => _selectedItems.contains(i['id'] as int))
            .toList(),
      },
    ).then((_) {
      // Refresh cart when returning from checkout
      _fetchCart();
    });
  }

  Widget _buildShimmerImage() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Container(
        width: 70,
        height: 70,
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  Widget _buildProductImage(dynamic item) {
    final imagePath = item['product']?['image'];
    String? imageUrl;
    if (imagePath != null && imagePath.toString().isNotEmpty) {
      imageUrl = imagePath.toString().startsWith('http')
          ? imagePath
          : '$storageUrl$imagePath';
    }
    print('Cart item image URL: $imageUrl');
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: 70,
        height: 70,
        child: imageUrl != null
            ? NetworkImageWithLoader(
                imageUrl,
                radius: 8,
              )
            : _buildShimmerImage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // leading: BackButton(),
        title: const Text('Cart'),
        actions: [
          IconButton(
            tooltip: 'Select / Deselect all',
            onPressed: () {
              // Toggle select all
              if (_cartItems.isEmpty) return;
              final allIds = _cartItems.map<int>((i) => i['id'] as int).toSet();
              setState(() {
                if (_selectedItems.length == allIds.length) {
                  _selectedItems.clear();
                } else {
                  _selectedItems = allIds;
                }
              });
            },
            icon: Icon(_selectedItems.length == _cartItems.length
                ? Icons.check_box
                : Icons.check_box_outline_blank),
          ),
        ],
        centerTitle: true,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('Error: $_error'))
              : _cartItems.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.shopping_cart_outlined,
                            size: 64,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Your cart is empty',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _cartItems.length,
                      itemBuilder: (context, index) {
                        final item = _cartItems[index];
                        final int productId = item['id'];
                        final int quantity = item['quantity'];

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.grey.shade200,
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              children: [
                                // We overlay a read-only checkbox on the
                                // top-right of the card instead of showing it
                                // on the left side.
                                Stack(
                                  children: [
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        _buildProductImage(item),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            mainAxisAlignment:
                                                MainAxisAlignment.start,
                                            children: [
                                              Text(
                                                item['name'] ?? '',
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w600,
                                                  height: 1.3,
                                                ),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                '$pesoSymbol${item['price'].toString()}',
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  color: Colors.grey.shade600,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    // Top-right overlayed checkbox always checked.
                                    Positioned(
                                      top: 0,
                                      right: 0,
                                      child: Transform.scale(
                                        scale: 0.85,
                                        child: Checkbox(
                                          value: _selectedItems
                                              .contains(productId),
                                          onChanged: (_) =>
                                              _toggleSelection(productId),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Subtotal',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.grey.shade600,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '$pesoSymbol${item['subtotal']}',
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w700,
                                              color: Colors.green,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade100,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Material(
                                            color: Colors.transparent,
                                            child: InkWell(
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                              onTap: () => _subtractQuantity(
                                                  productId, quantity),
                                              child: Container(
                                                width: 32,
                                                height: 32,
                                                alignment: Alignment.center,
                                                child: const Icon(
                                                  Icons.remove,
                                                  size: 18,
                                                ),
                                              ),
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 12),
                                            child: Text(
                                              '$quantity',
                                              style: const TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                          Material(
                                            color: Colors.transparent,
                                            child: InkWell(
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                              onTap: () =>
                                                  _addQuantity(productId),
                                              child: Container(
                                                width: 32,
                                                height: 32,
                                                alignment: Alignment.center,
                                                child: const Icon(
                                                  Icons.add,
                                                  size: 18,
                                                ),
                                              ),
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
                        );
                      },
                    ),
      bottomNavigationBar: _cartItems.isEmpty
          ? null
          : Container(
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
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Total',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            Text(
                              '$pesoSymbol${_selectedTotal.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 3,
                        child: ElevatedButton(
                          onPressed: _selectedItems.isEmpty
                              ? null
                              : _navigateToCheckout,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).primaryColor,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Checkout',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
