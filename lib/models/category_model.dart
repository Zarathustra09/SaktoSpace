class CategoryModel {
  final String title;
  final String? image;
  final String? svgSrc;
  final List<CategoryModel>? subCategories;

  CategoryModel({
    required this.title,
    this.image,
    this.svgSrc,
    this.subCategories,
  });
}

// Categories with images (for main shop screen tiles)
final List<CategoryModel> demoCategoriesWithImage = [
  CategoryModel(
    title: "Furniture",
    image: "assets/images/furniture1.png",
  ),
  CategoryModel(
    title: "Decor",
    image: "assets/images/decor1.png",
  ),
  CategoryModel(
    title: "Lighting",
    image: "assets/images/lighting1.png",
  ),
  CategoryModel(
    title: "Outdoor",
    image: "assets/images/outdoor1.png",
  ),
];

// Categories with optional icons and subcategories
final List<CategoryModel> demoCategories = [
  CategoryModel(
    title: "Furniture",
    svgSrc: "assets/icons/furniture.svg",
    subCategories: [
      CategoryModel(title: "All Furniture"),
      CategoryModel(title: "New In"),
      CategoryModel(title: "Sofas"),
      CategoryModel(title: "Beds"),
      CategoryModel(title: "Chairs"),
    ],
  ),
  CategoryModel(
    title: "Decoration",
    svgSrc: "assets/icons/decor.svg",
    subCategories: [
      CategoryModel(title: "All Decoration"),
      CategoryModel(title: "New In"),
      CategoryModel(title: "Vases"),
      CategoryModel(title: "Wall Art"),
    ],
  ),
  CategoryModel(
    title: "Lighting",
    svgSrc: "assets/icons/lighting.svg",
    subCategories: [
      CategoryModel(title: "All Lighting"),
      CategoryModel(title: "New In"),
      CategoryModel(title: "Ceiling Lights"),
      CategoryModel(title: "Table Lamps"),
    ],
  ),
  CategoryModel(
    title: "Outdoor",
    svgSrc: "assets/icons/outdoor.svg",
    subCategories: [
      CategoryModel(title: "All Outdoor Furniture"),
      CategoryModel(title: "New In"),
      CategoryModel(title: "Patio Sets"),
      CategoryModel(title: "Garden Decor"),
    ],
  ),
];
