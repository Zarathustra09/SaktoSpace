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

import 'package:shop/route/screen_export.dart';

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
  late Future<ProdProductModel> _productFuture;
  int? productId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Get the product ID from the route arguments
    productId = ModalRoute.of(context)?.settings.arguments as int?;
    if (productId != null) {
      _productFuture = _productService.getProductById(productId!);
    }
  }

  String getFullImageUrl(String imageUrl) {
    return imageUrl.startsWith('http') ? imageUrl : '$storageUrl$imageUrl';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: FutureBuilder<ProdProductModel>(
          future: _productFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            } else if (!snapshot.hasData) {
              return const Center(child: Text('Product not found'));
            }

            final product = snapshot.data!;
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

            // Debug output
            print('=== PRODUCT DETAILS DEBUG ===');
            print('Product name: ${product.name}');
            print('Raw AR model URL: ${product.arModelUrl}');
            print('Full AR model URL: $fullArModelUrl');
            print('Storage URL: $storageUrl');

            return Scaffold(
              bottomNavigationBar: isProductAvailable
                  ? CartButton(
                      price: product.price,
                      press: () {
                        customModalBottomSheet(
                          context,
                          height: MediaQuery.of(context).size.height * 0.92,
                          child: const ProductBuyNowScreen(),
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
                        onPressed: () {},
                        icon: SvgPicture.asset("assets/icons/Bookmark.svg",
                            color:
                                Theme.of(context).textTheme.bodyLarge!.color),
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
                    rating: 4.4, // Placeholder as rating is not in the model
                    numOfReviews:
                        126, // Placeholder as reviews are not in the model
                  ),
                  ProductListTile(
                    svgSrc: "assets/icons/Product.svg",
                    title: "Product Details",
                    press: () {
                      customModalBottomSheet(
                        context,
                        height: MediaQuery.of(context).size.height * 0.92,
                        child: const BuyFullKit(
                            images: ["assets/screens/Product detail.png"]),
                      );
                    },
                  ),
                  ProductListTile(
                    svgSrc: "assets/icons/Delivery.svg",
                    title: "Shipping Information",
                    press: () {
                      customModalBottomSheet(
                        context,
                        height: MediaQuery.of(context).size.height * 0.92,
                        child: const BuyFullKit(
                          images: ["assets/screens/Shipping information.png"],
                        ),
                      );
                    },
                  ),
                  ProductListTile(
                    svgSrc: "assets/icons/Return.svg",
                    title: "Returns",
                    isShowBottomBorder: true,
                    press: () {
                      customModalBottomSheet(
                        context,
                        height: MediaQuery.of(context).size.height * 0.92,
                        child: const ProductReturnsScreen(),
                      );
                    },
                  ),
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(defaultPadding),
                      child: ReviewCard(
                        rating: 4.3,
                        numOfReviews: 128,
                        numOfFiveStar: 80,
                        numOfFourStar: 30,
                        numOfThreeStar: 5,
                        numOfTwoStar: 4,
                        numOfOneStar: 1,
                      ),
                    ),
                  ),
                  ProductListTile(
                    svgSrc: "assets/icons/Chat.svg",
                    title: "Reviews",
                    isShowBottomBorder: true,
                    press: () {
                      Navigator.pushNamed(context, productReviewsScreenRoute);
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
                            itemBuilder: (context, index) => Padding(
                              padding: EdgeInsets.only(
                                  left: defaultPadding,
                                  right: index == relatedProducts.length - 1
                                      ? defaultPadding
                                      : 0),
                              child: ProductCard(
                                image: getFullImageUrl(
                                    relatedProducts[index].image),
                                title: relatedProducts[index].name,
                                brandName:
                                    relatedProducts[index].category?.name ??
                                        "Unknown",
                                price: relatedProducts[index].price,
                                press: () {
                                  Navigator.pushReplacementNamed(
                                      context, productDetailsScreenRoute,
                                      arguments: relatedProducts[index].id);
                                },
                              ),
                            ),
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
