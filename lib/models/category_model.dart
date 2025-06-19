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
      CategoryModel(title: "Sofas"),
      CategoryModel(title: "Beds"),
      CategoryModel(title: "Dining Tables"),
      CategoryModel(title: "Chairs"),
    ],
  ),
  CategoryModel(
    title: "Decor",
    svgSrc: "assets/icons/decor.svg",
    subCategories: [
      CategoryModel(title: "Wall Art"),
      CategoryModel(title: "Mirrors"),
      CategoryModel(title: "Vases"),
    ],
  ),
  CategoryModel(
    title: "Lighting",
    svgSrc: "assets/icons/lighting.svg",
    subCategories: [
      CategoryModel(title: "Ceiling Lights"),
      CategoryModel(title: "Lamps"),
      CategoryModel(title: "LED Strips"),
    ],
  ),
  CategoryModel(
    title: "Outdoor",
    svgSrc: "assets/icons/outdoor.svg",
    subCategories: [
      CategoryModel(title: "Garden Furniture"),
      CategoryModel(title: "Patio Sets"),
      CategoryModel(title: "Umbrellas"),
    ],
  ),
];
