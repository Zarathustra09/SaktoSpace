// For demo only
import 'package:shop/constants.dart';

class ProductModel {
  final String image, brandName, title, description, category;
  final double price;
  final double? priceAfetDiscount;
  final int? dicountpercent;
  final int stock;

  ProductModel({
    required this.image,
    required this.brandName,
    required this.title,
    required this.description,
    required this.category,
    required this.price,
    this.priceAfetDiscount,
    this.dicountpercent,
    required this.stock,
  });
}

List<ProductModel> demoPopularProducts = [
  ProductModel(
    image: productDemoImg1,
    title: "Modern Sofa",
    brandName: "HomeStyle",
    description: "3‑seater fabric sofa with wooden legs.",
    category: "Furniture",
    price: 12000,
    priceAfetDiscount: 9600,
    dicountpercent: 20,
    stock: 5,
  ),
  ProductModel(
    image: productDemoImg4,
    title: "Oak Coffee Table",
    brandName: "WoodWorks",
    description: "Solid oak coffee table with a shelf.",
    category: "Furniture",
    price: 4500,
    stock: 8,
  ),
  ProductModel(
    image: productDemoImg5,
    title: "Ceramic Vase Set",
    brandName: "CraftHouse",
    description: "Set of 3 decorative ceramic vases.",
    category: "Decor",
    price: 1500,
    priceAfetDiscount: 1200,
    dicountpercent: 20,
    stock: 10,
  ),
  ProductModel(
    image: productDemoImg6,
    title: "LED Floor Lamp",
    brandName: "BrightHome",
    description: "Modern LED standing lamp with dimmer.",
    category: "Lighting",
    price: 3200,
    priceAfetDiscount: 2560,
    dicountpercent: 20,
    stock: 3,
  ),
  ProductModel(
    image: "https://i.imgur.com/tXyOMMG.png",
    title: "Outdoor Lounge Chair",
    brandName: "GardenEase",
    description: "Weather‑resistant lounge chair.",
    category: "Outdoor",
    price: 2800,
    priceAfetDiscount: 2240,
    dicountpercent: 20,
    stock: 4,
  ),
  ProductModel(
    image: "https://i.imgur.com/h2LqppX.png",
    title: "Patio Umbrella",
    brandName: "SunShield",
    description: "10‑foot outdoor patio umbrella.",
    category: "Outdoor",
    price: 1800,
    stock: 7,
  ),
];

List<ProductModel> demoFlashSaleProducts =
    demoPopularProducts.where((p) => p.dicountpercent != null).toList();

List<ProductModel> demoBestSellersProducts = [
  demoPopularProducts[0],
  demoPopularProducts[2],
  demoPopularProducts[4],
];
