import 'package:flutter/material.dart';
import '../../../constants.dart';

class ProductFullDescription extends StatelessWidget {
  const ProductFullDescription({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Full Details"),
        leading: const BackButton(),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text("Modern Sofa",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            SizedBox(height: defaultPadding),
            Text("Brand: HomeStyle", style: TextStyle(fontSize: 16)),
            SizedBox(height: defaultPadding),
            Text("Category: Furniture", style: TextStyle(fontSize: 16)),
            SizedBox(height: defaultPadding),
            Text("Stock: 5", style: TextStyle(fontSize: 16)),
            SizedBox(height: defaultPadding * 2),
            Text("Description",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
            SizedBox(height: defaultPadding / 2),
            Text(
                "A luxurious 3‑seater fabric sofa with wooden legs, comfortable and sturdy."),
            SizedBox(height: defaultPadding * 2),
            Text("Materials",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
            SizedBox(height: defaultPadding / 2),
            Text("Solid wood frame, premium fabric upholstery."),
            SizedBox(height: defaultPadding * 2),
            Text("Origin",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
            SizedBox(height: defaultPadding / 2),
            Text("Made in Philippines."),
            SizedBox(height: defaultPadding * 2),
            Text("Dimensions",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
            SizedBox(height: defaultPadding / 2),
            Text("Length: 200 cm   Height: 85 cm   Seat depth: 60 cm"),
          ],
        ),
      ),
    );
  }
}
