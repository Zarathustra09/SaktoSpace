import 'package:flutter/material.dart';

import '../../constants.dart';
import '../network_image_with_loader.dart';

// local helper to render symbol with system font and number with app font
// (use shared `pesoSymbol` from constants.dart)
Widget _currencyText(
  dynamic amount, {
  TextStyle? style,
  String? leading,
}) {
  double value;
  if (amount == null) {
    value = 0.0;
  } else if (amount is num) {
    value = amount.toDouble();
  } else {
    value = double.tryParse(amount.toString()) ?? 0.0;
  }
  final numberText = value.toStringAsFixed(2);
  final TextStyle baseStyle = style ?? const TextStyle();
  final TextStyle symbolStyle = baseStyle.copyWith(fontFamily: null);
  return Text.rich(
    TextSpan(
      children: [
        if (leading != null) TextSpan(text: leading, style: baseStyle),
        TextSpan(text: '$pesoSymbol ', style: symbolStyle),
        TextSpan(text: numberText, style: baseStyle),
      ],
    ),
    maxLines: 1,
    overflow: TextOverflow.ellipsis,
  );
}

class ProductCard extends StatelessWidget {
  const ProductCard({
    super.key,
    required this.image,
    required this.brandName,
    required this.title,
    required this.price,
    this.priceAfetDiscount,
    this.dicountpercent,
    required this.press,
  });
  final String image, brandName, title;
  final double price;
  final double? priceAfetDiscount;
  final int? dicountpercent;
  final VoidCallback press;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: press,
      style: OutlinedButton.styleFrom(
          minimumSize: const Size(140, 220),
          maximumSize: const Size(140, 220),
          padding: const EdgeInsets.all(8)),
      child: Column(
        children: [
          AspectRatio(
            aspectRatio: 1.15,
            child: Stack(
              children: [
                NetworkImageWithLoader(image, radius: defaultBorderRadious),
                if (dicountpercent != null)
                  Positioned(
                    right: defaultPadding / 2,
                    top: defaultPadding / 2,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: defaultPadding / 2),
                      height: 16,
                      decoration: const BoxDecoration(
                        color: errorColor,
                        borderRadius: BorderRadius.all(
                            Radius.circular(defaultBorderRadious)),
                      ),
                      child: Text(
                        "$dicountpercent% off",
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w500),
                      ),
                    ),
                  )
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: defaultPadding / 2, vertical: defaultPadding / 2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    brandName.toUpperCase(),
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium!
                        .copyWith(fontSize: 10),
                  ),
                  const SizedBox(height: defaultPadding / 2),
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall!
                        .copyWith(fontSize: 12),
                  ),
                  const Spacer(),
                  priceAfetDiscount != null
                      ? Row(
                          children: [
                            // discounted price: show Philippine peso
                            _currencyText(
                              priceAfetDiscount,
                              style: const TextStyle(
                                color: Color(0xFF31B0D8),
                                fontWeight: FontWeight.w500,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(width: defaultPadding / 4),
                            // original price with line-through
                            _currencyText(
                              price,
                              style: TextStyle(
                                color: Theme.of(context)
                                    .textTheme
                                    .bodyMedium!
                                    .color,
                                fontSize: 10,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                          ],
                        )
                      : // no discount: show single price
                      _currencyText(
                        price,
                        style: const TextStyle(
                          color: Color(0xFF31B0D8),
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                        ),
                      ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
