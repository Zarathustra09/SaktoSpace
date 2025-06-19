class CategoryModel {
  final String title;
  final String? image, svgSrc;
  final List<CategoryModel>? subCategories;

  CategoryModel({
    required this.title,
    this.image,
    this.svgSrc,
    this.subCategories,
  });
}

final List<CategoryModel> demoCategoriesWithImage = [
  CategoryModel(title: "Woman’s", image: "https://i.imgur.com/5M89G2P.png"),
  CategoryModel(title: "Man’s", image: "https://i.imgur.com/UM3GdWg.png"),
  CategoryModel(title: "Kid’s", image: "https://i.imgur.com/Lp0D6k5.png"),
  CategoryModel(title: "Accessories", image: "https://i.imgur.com/3mSE5sN.png"),
];

final List<CategoryModel> demoCategories = [
  CategoryModel(
    title: "Furniture",
    svgSrc: "assets/icons/furniture.svg",
    subCategories: [
      CategoryModel(title: "All Furniture"),
      CategoryModel(title: "New In"),
      CategoryModel(title: "Sofas"),
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
      CategoryModel(title: "All Outdoor"),
      CategoryModel(title: "New In"),
      CategoryModel(title: "Patio Furniture"),
      CategoryModel(title: "Garden Decor"),
    ],
  ),
];
