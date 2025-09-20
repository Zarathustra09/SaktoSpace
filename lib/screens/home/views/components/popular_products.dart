// lib/screens/home/views/components/popular_products.dart
import 'package:flutter/material.dart';
import 'package:shop/components/product/product_card.dart';
import 'package:shop/models/prod_product_model.dart';
import 'package:shop/route/screen_export.dart';
import 'package:shop/services/product/product_service.dart';
import '../../../../constants.dart';

class PopularProducts extends StatefulWidget {
  final int? categoryId;
  const PopularProducts({
    super.key,
    this.categoryId,
  });

  @override
  State<PopularProducts> createState() => _PopularProductsState();
}

class _PopularProductsState extends State<PopularProducts> {
  final ProductService _productService = ProductService();
  late Future<List<ProdProductModel>> _productsFuture;

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  @override
  void didUpdateWidget(covariant PopularProducts oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.categoryId != widget.categoryId) {
      _fetchProducts();
    }
  }

  void _fetchProducts() {
    if (widget.categoryId != null) {
      _productsFuture = _productService.getAllProducts(categoryId: widget.categoryId);
    } else {
      _productsFuture = _productService.getAllProducts();
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: defaultPadding / 2),
        Padding(
          padding: const EdgeInsets.all(defaultPadding),
          child: Text(
            "Popular products",
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ),
        FutureBuilder<List<ProdProductModel>>(
          future: _productsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                height: 220,
                child: Center(child: CircularProgressIndicator()),
              );
            } else if (snapshot.hasError) {
              return SizedBox(
                height: 220,
                child: Center(child: Text('Error: ${snapshot.error}')),
              );
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const SizedBox(
                height: 220,
                child: Center(child: Text('No products found')),
              );
            }

            final products = snapshot.data!;

            return SizedBox(
              height: 220,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: products.length,
                itemBuilder: (context, index) => Padding(
                  padding: EdgeInsets.only(
                    left: defaultPadding,
                    right: index == products.length - 1 ? defaultPadding : 0,
                  ),
                  child: ProductCard(
                    image: products[index].image.startsWith('http')
                      ? products[index].image
                      : '$storageUrl${products[index].image}',
                    brandName: products[index].category?.name ?? "Unknown",
                    title: products[index].name,
                    price: products[index].price,
                    // We don't have discount info in API, so not using priceAfterDiscount
                    // and discountPercent properties
                    press: () {
                      Navigator.pushNamed(context, productDetailsScreenRoute,
                          arguments: products[index].id);
                    },
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}