import 'package:flutter/material.dart';
import 'package:shop/models/prod_category_model.dart';

import '../../../../constants.dart';
import 'categories.dart';
import 'offers_carousel.dart';
import 'popular_products.dart';

class OffersCarouselAndCategories extends StatefulWidget {
  const OffersCarouselAndCategories({
    super.key,
  });

  @override
  State<OffersCarouselAndCategories> createState() => _OffersCarouselAndCategoriesState();
}

class _OffersCarouselAndCategoriesState extends State<OffersCarouselAndCategories> {
  int? _selectedCategoryId;

  void _onCategorySelected(ProdCategoryModel category) {
    setState(() {
      _selectedCategoryId = category.id;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // While loading use 👇
        // const OffersSkelton(),
        const OffersCarousel(),
        const SizedBox(height: defaultPadding / 2),
        Padding(
          padding: const EdgeInsets.all(defaultPadding),
          child: Text(
            "Categories",
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ),
        // While loading use 👇
        // const CategoriesSkelton(),
        Categories(
          selectedCategoryId: _selectedCategoryId,
          onCategorySelected: _onCategorySelected,
        ),
        PopularProducts(categoryId: _selectedCategoryId),
      ],
    );
  }
}
