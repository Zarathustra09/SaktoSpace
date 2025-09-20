import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shop/route/screen_export.dart';
import 'package:shop/services/category/category_service.dart';
import 'package:shop/models/prod_category_model.dart';

import '../../../../constants.dart';

class CategoryModel {
  final String name;
  final String? svgSrc, route;

  CategoryModel({
    required this.name,
    this.svgSrc,
    this.route,
  });
}

// Updated category list
List<CategoryModel> demoCategories = [
  CategoryModel(name: "All", svgSrc: "assets/icons/Category.svg"),
  CategoryModel(
    name: "On Sale",
    svgSrc: "assets/icons/Sale.svg",
    route: onSaleScreenRoute,
  ),
  CategoryModel(
    name: "Furniture",
    svgSrc: "assets/icons/furniture.svg",
    route: "/furniture",
  ),
  CategoryModel(
    name: "Decor",
    svgSrc: "assets/icons/decor.svg",
    route: "/decor",
  ),
  CategoryModel(
    name: "Lighting",
    svgSrc: "assets/icons/lighting.svg",
    route: "/lighting",
  ),
  CategoryModel(
    name: "Outdoor",
    svgSrc: "assets/icons/outdoor.svg",
    route: "/outdoor",
  ),
];

class Categories extends StatefulWidget {
  final int? selectedCategoryId;
  final ValueChanged<ProdCategoryModel>? onCategorySelected;
  const Categories({super.key, this.selectedCategoryId, this.onCategorySelected});

  @override
  State<Categories> createState() => _CategoriesState();
}

class _CategoriesState extends State<Categories> {
  late Future<List<ProdCategoryModel>> _categoriesFuture;
  final CategoryService _categoryService = CategoryService();
  int? _selectedIndex;
  List<ProdCategoryModel> _categories = [];

  @override
  void initState() {
    super.initState();
    _categoriesFuture = _categoryService.getAllCategories();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<ProdCategoryModel>>(
      future: _categoriesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Failed to load categories'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(child: Text('No categories found'));
        }
        _categories = snapshot.data!;
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              ...List.generate(
                _categories.length,
                (index) => Padding(
                  padding: EdgeInsets.only(
                    left: index == 0 ? defaultPadding : defaultPadding / 2,
                    right: index == _categories.length - 1 ? defaultPadding : 0,
                  ),
                  child: CategoryBtn(
                    category: _categories[index].name ?? '',
                    svgSrc: null, // You can map icons if available in your model
                    isActive: widget.selectedCategoryId == null
                        ? index == 0
                        : _categories[index].id == widget.selectedCategoryId,
                    press: () {
                      setState(() {
                        _selectedIndex = index;
                      });
                      if (widget.onCategorySelected != null) {
                        widget.onCategorySelected!(_categories[index]);
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class CategoryBtn extends StatelessWidget {
  const CategoryBtn({
    super.key,
    required this.category,
    this.svgSrc,
    required this.isActive,
    required this.press,
  });

  final String category;
  final String? svgSrc;
  final bool isActive;
  final VoidCallback press;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: press,
      borderRadius: const BorderRadius.all(Radius.circular(30)),
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: defaultPadding),
        decoration: BoxDecoration(
          color: isActive ? primaryColor : Colors.transparent,
          border: Border.all(
            color:
                isActive ? Colors.transparent : Theme.of(context).dividerColor,
          ),
          borderRadius: const BorderRadius.all(Radius.circular(30)),
        ),
        child: Row(
          children: [
            if (svgSrc != null)
              SvgPicture.asset(
                svgSrc!,
                height: 20,
                colorFilter: ColorFilter.mode(
                  isActive ? Colors.white : Theme.of(context).iconTheme.color!,
                  BlendMode.srcIn,
                ),
              ),
            if (svgSrc != null) const SizedBox(width: defaultPadding / 2),
            Text(
              category,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isActive
                    ? Colors.white
                    : Theme.of(context).textTheme.bodyLarge!.color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
