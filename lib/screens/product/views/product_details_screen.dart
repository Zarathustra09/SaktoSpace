import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:shop/components/buy_full_ui_kit.dart';
import 'package:shop/components/cart_button.dart';
import 'package:shop/components/custom_modal_bottom_sheet.dart';
import 'package:shop/components/product/product_card.dart';
import 'package:shop/constants.dart';
import 'package:shop/models/prod_product_model.dart';
import 'package:shop/screens/product/views/product_returns_screen.dart';
import 'package:shop/services/product/product_service.dart';
import 'package:shop/services/cart/cart_service.dart';
import 'package:shop/route/screen_export.dart';
import 'package:shop/screens/reviews/view/product_reviews_screen.dart'; // ADDED

import 'components/notify_me_card.dart';
import 'components/product_images.dart';
import 'components/product_info.dart';
import 'components/product_list_tile.dart';
import '../../../components/review_card.dart';
import 'product_buy_now_screen.dart';

class ProductDetailsScreen extends StatefulWidget {
  const ProductDetailsScreen({super.key});

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  final ProductService _productService = ProductService();
  final CartService _cartService = CartService();
  Future<ProdProductModel>? _productFuture;
  int? productId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final newProductId = ModalRoute.of(context)?.settings.arguments as int?;

    // Only initialize futures if productId has changed or is being set for the first time
    if (newProductId != null && newProductId != productId) {
      productId = newProductId;
      print('Setting up futures for product ID: $productId');

      // Use the regular product service for basic product details
      _productFuture = _productService.getAllProducts().then((products) {
        try {
          return products.firstWhere((product) => product.id == productId);
        } catch (e) {
          print('Product with ID $productId not found in products list');
          throw Exception('Product not found');
        }
      });
    }
  }

  String getFullImageUrl(String imageUrl) {
    return imageUrl.startsWith('http') ? imageUrl : '$storageUrl$imageUrl';
  }

  @override
  Widget build(BuildContext context) {
    // Check if we have a productId and futures initialized
    if (productId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Product Details')),
        body: const Center(child: Text('No product ID provided')),
      );
    }

    if (_productFuture == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Product Details')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: FutureBuilder<ProdProductModel>(
          future: _productFuture!,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              print('Product details error: ${snapshot.error}');
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 64, color: Colors.grey),
                    const SizedBox(height: 16),
                    const Text('Error loading product'),
                    const SizedBox(height: 8),
                    Text(
                      '${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _productFuture = _productService.getAllProducts().then((products) {
                            try {
                              return products.firstWhere((product) => product.id == productId);
                            } catch (e) {
                              print('Product with ID $productId not found in products list');
                              throw Exception('Product not found');
                            }
                          });
                        });
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            } else if (!snapshot.hasData) {
              return const Center(child: Text('Product not found'));
            }

            final product = snapshot.data!;
            print('Product loaded: ${product.name} (ID: ${product.id})');

            final bool isProductAvailable = product.stock > 0;
            final List<String> productImages = [getFullImageUrl(product.image)];

            // If the product has AR model URL, add it to the images list
            if (product.arModelUrl != null && product.arModelUrl!.isNotEmpty) {
              productImages.add(getFullImageUrl(product.arModelUrl!));
            }

            // Get the full AR model URL for the AR viewer
            final String? fullArModelUrl =
                product.arModelUrl != null && product.arModelUrl!.isNotEmpty
                    ? getFullImageUrl(product.arModelUrl!)
                    : null;

            return Scaffold(
              bottomNavigationBar: isProductAvailable
                  ? CartButton(
                      price: product.price,
                      press: () {
                        customModalBottomSheet(
                          context,
                          height: MediaQuery.of(context).size.height * 0.92,
                          child: ProductBuyNowScreen(product: product),
                        );
                      },
                    )
                  : NotifyMeCard(
                      isNotify: false,
                      onChanged: (value) {},
                    ),
              body: CustomScrollView(
                slivers: [
                  SliverAppBar(
                    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                    floating: true,
                    actions: [
                      IconButton(
                        onPressed: () async {
                          if (productId != null) {
                            try {
                              final result = await _cartService.addToCart(productId: productId!, quantity: 1);
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(result['message'] ?? 'Added to cart!')),
                                );
                              }
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Error: ${e.toString()}')),
                                );
                              }
                            }
                          }
                        },
                        icon: SvgPicture.asset(
                          "assets/icons/Bookmark.svg",
                          color: Theme.of(context).textTheme.bodyLarge!.color,
                        ),
                      ),
                    ],
                  ),
                  ProductImages(
                    images: productImages,
                    arModelUrl: fullArModelUrl,
                    productName: product.name,
                  ),
                  ProductInfo(
                    brand: product.category?.name ?? "Unknown",
                    title: product.name,
                    isAvailable: isProductAvailable,
                    description: product.description,
                    rating: product.averageRating ?? 0.0,
                    numOfReviews: product.totalRatings ?? 0,
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(defaultPadding),
                      child: ReviewCard(
                        rating: product.averageRating ?? 0.0,
                        // Keep non-zero to protect ReviewCard from divide-by-zero if it computes percentages internally
                        numOfReviews: (product.totalRatings ?? 0) == 0 ? 1 : (product.totalRatings ?? 1),
                        numOfFiveStar: 0,
                        numOfFourStar: 0,
                        numOfThreeStar: 0,
                        numOfTwoStar: 0,
                        numOfOneStar: 0,
                      ),
                    ),
                  ),
                  ProductListTile(
                    svgSrc: "assets/icons/Chat.svg",
                    title: "Reviews",
                    isShowBottomBorder: true,
                    press: () {
                      final idToPass = product.id;
                      print('[ProductDetails] Navigating to reviews with productId: $idToPass');
                      // Push via constructor to guarantee productId is delivered
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ProductReviewsScreen(productId: idToPass),
                        ),
                      );
                    },
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.all(defaultPadding),
                    sliver: SliverToBoxAdapter(
                      child: Text(
                        "You may also like",
                        style: Theme.of(context).textTheme.titleSmall!,
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: FutureBuilder<List<ProdProductModel>>(
                      future: _productService.getAllProducts(),
                      builder: (context, relatedSnapshot) {
                        if (relatedSnapshot.connectionState ==
                                ConnectionState.waiting ||
                            relatedSnapshot.hasError ||
                            !relatedSnapshot.hasData) {
                          return const SizedBox(
                            height: 220,
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }

                        final relatedProducts = relatedSnapshot.data!
                            .where((p) => p.id != product.id)
                            .take(5)
                            .toList();

                        return SizedBox(
                          height: 220,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: relatedProducts.length,
                            itemBuilder: (context, index) {
                              return Padding(
                                padding: EdgeInsets.only(
                                  left: defaultPadding,
                                  right: index == relatedProducts.length - 1
                                      ? defaultPadding
                                      : 0,
                                ),
                                child: ProductCard(
                                  image: getFullImageUrl(
                                      relatedProducts[index].image),
                                  title: relatedProducts[index].name,
                                  brandName: relatedProducts[index]
                                          .category
                                          ?.name ??
                                      "Unknown",
                                  price: relatedProducts[index].price,
                                  press: () {
                                    Navigator.pushReplacementNamed(
                                      context,
                                      productDetailsScreenRoute,
                                      arguments: relatedProducts[index].id,
                                    );
                                  },
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
                  ),
                  const SliverToBoxAdapter(
                    child: SizedBox(height: defaultPadding),
                  )
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
