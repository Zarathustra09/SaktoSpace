import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shop/components/cart_button.dart';
import 'package:shop/components/custom_modal_bottom_sheet.dart';
import 'package:shop/components/network_image_with_loader.dart';
import 'package:shop/models/prod_product_model.dart';
import 'package:shop/services/cart/cart_service.dart';
import 'package:shop/screens/product/views/added_to_cart_message_screen.dart';
import 'package:shop/screens/product/views/components/product_list_tile.dart';
import 'package:shop/screens/product/views/location_permission_store_availability_screen.dart';
import 'package:shop/screens/product/views/size_guide_screen.dart';
import 'package:shop/screens/checkout/views/checkout_screen.dart';

import '../../../constants.dart';
import 'components/product_quantity.dart';
import 'components/selected_colors.dart';
import 'components/selected_size.dart';
import 'components/unit_price.dart';

class ProductBuyNowScreen extends StatefulWidget {
  final ProdProductModel? product;

  const ProductBuyNowScreen({super.key, this.product});

  @override
  _ProductBuyNowScreenState createState() => _ProductBuyNowScreenState();
}

class _ProductBuyNowScreenState extends State<ProductBuyNowScreen> {
  final CartService _cartService = CartService();

  int _quantity = 1;
  bool _isAddingToCart = false;
  bool _isProcessingPayment = false;

  double get _totalPrice => (widget.product?.price ?? 0) * _quantity;

  void _incrementQuantity() {
    if (widget.product != null && _quantity < widget.product!.stock) {
      setState(() {
        _quantity++;
      });
    }
  }

  void _decrementQuantity() {
    if (_quantity > 1) {
      setState(() {
        _quantity--;
      });
    }
  }

  Future<void> _addToCart() async {
    if (widget.product == null) return;

    setState(() {
      _isAddingToCart = true;
    });

    try {
      await _cartService.addToCart(
        productId: widget.product!.id,
        quantity: _quantity,
      );

      if (mounted) {
        customModalBottomSheet(
          context,
          isDismissible: false,
          child: const AddedToCartMessageScreen(),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add to cart: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isAddingToCart = false;
        });
      }
    }
  }

  Future<void> _buyNow() async {
    print('=== BUY NOW CLICKED ===');
    print('Product: ${widget.product?.name}');
    print('Product ID: ${widget.product?.id}');
    print('Quantity: $_quantity');
    print('Total Price: $_totalPrice');

    if (widget.product == null) {
      print('Product is null - aborting');
      return;
    }

    setState(() {
      _isProcessingPayment = true;
    });

    try {
      // Create cart items data for checkout display
      final cartItems = [
        {
          'id': widget.product!.id,
          'name': widget.product!.name,
          'price': widget.product!.price,
          'quantity': _quantity,
          'subtotal': _totalPrice,
          'image': widget.product!.image,
        }
      ];

      final directPurchaseData = {
        'productId': widget.product!.id,
        'quantity': _quantity,
      };

      print('Cart Items: $cartItems');
      print('Direct Purchase Data: $directPurchaseData');

      if (mounted) {
        print('Navigating to checkout screen...');
        // Navigate to checkout screen with direct purchase flag and product data
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CheckoutScreen(
              total: _totalPrice,
              cartItems: cartItems,
              isDirectPurchase: true,
              directPurchaseData: directPurchaseData,
            ),
          ),
        );
        print('Checkout screen result: $result');
      } else {
        print('Widget not mounted - skipping navigation');
      }
    } catch (e) {
      print('=== BUY NOW ERROR ===');
      print('Error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      print('Resetting processing state');
      if (mounted) {
        setState(() {
          _isProcessingPayment = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;

    return Scaffold(
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Add to Cart Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: defaultPadding, vertical: 8),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isAddingToCart || _isProcessingPayment ? null : _addToCart,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isAddingToCart
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Add to Cart',
                        style: TextStyle(color: Colors.white),
                      ),
              ),
            ),
          ),
          // Buy Now Button
          CartButton(
            price: _totalPrice,
            title: _isProcessingPayment ? "Processing..." : "Buy Now",
            subTitle: "Total price",
            press: _isAddingToCart || _isProcessingPayment
                ? () {} // Empty function when disabled
                : () async {
                    await _buyNow();
                  },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: defaultPadding / 2, vertical: defaultPadding),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const BackButton(),
                Text(
                  product?.name ?? "Product",
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                IconButton(
                  onPressed: () {},
                  icon: SvgPicture.asset("assets/icons/Bookmark.svg",
                      color: Theme.of(context).textTheme.bodyLarge!.color),
                ),
              ],
            ),
          ),
          Expanded(
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: defaultPadding),
                    child: AspectRatio(
                      aspectRatio: 1.05,
                      child: NetworkImageWithLoader(
                        product?.image != null
                          ? (product!.image.startsWith('http')
                              ? product.image
                              : '$storageUrl${product.image}')
                          : productDemoImg1,
                      ),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.all(defaultPadding),
                  sliver: SliverToBoxAdapter(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: UnitPrice(
                            price: product?.price ?? 145,
                            priceAfterDiscount: product?.price ?? 134.7,
                          ),
                        ),
                        ProductQuantity(
                          numOfItem: _quantity,
                          onIncrement: _incrementQuantity,
                          onDecrement: _decrementQuantity,
                        ),
                      ],
                    ),
                  ),
                ),
                // Stock information
                if (product != null)
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: defaultPadding),
                    sliver: SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Stock: ${product.stock} available",
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: product.stock > 0 ? Colors.green : Colors.red,
                            ),
                          ),
                          const SizedBox(height: defaultPadding / 2),
                          if (product.description.isNotEmpty)
                            Text(
                              product.description,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                        ],
                      ),
                    ),
                  ),
                // const SliverToBoxAdapter(child: Divider()),
                // SliverPadding(
                //   padding:
                //       const EdgeInsets.symmetric(horizontal: defaultPadding),
                //   sliver: SliverToBoxAdapter(
                //     child: Column(
                //       crossAxisAlignment: CrossAxisAlignment.start,
                //       children: [
                //         const SizedBox(height: defaultPadding / 2),
                //         Text(
                //           "Store pickup availability",
                //           style: Theme.of(context).textTheme.titleSmall,
                //         ),
                //         const SizedBox(height: defaultPadding / 2),
                //         const Text(
                //             "Select a size to check store availability and In-Store pickup options.")
                //       ],
                //     ),
                //   ),
                // ),
                // SliverPadding(
                //   padding: const EdgeInsets.symmetric(vertical: defaultPadding),
                //   sliver: ProductListTile(
                //     title: "Check stores",
                //     svgSrc: "assets/icons/Stores.svg",
                //     isShowBottomBorder: true,
                //     press: () {
                //       customModalBottomSheet(
                //         context,
                //         height: MediaQuery.of(context).size.height * 0.92,
                //         child: const LocationPermissonStoreAvailabilityScreen(),
                //       );
                //     },
                //   ),
                // ),
                const SliverToBoxAdapter(
                    child: SizedBox(height: defaultPadding))
              ],
            ),
          )
        ],
      ),
    );
  }
}
