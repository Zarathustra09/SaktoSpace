import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shop/constants.dart';
import 'package:shop/models/promotional_advertisement.dart';

class PromotionDetailPage extends StatelessWidget {
  const PromotionDetailPage({super.key, required this.promotion});

  final PromotionalAdvertisement promotion;

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('MMM d, y');
    String dateRange = '';
    if (promotion.startDate != null || promotion.endDate != null) {
      final start = promotion.startDate != null ? dateFmt.format(promotion.startDate!) : 'Started';
      final end = promotion.endDate != null ? dateFmt.format(promotion.endDate!) : 'Ongoing';
      dateRange = '$start  •  $end';
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(promotion.title),
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          if (promotion.imageUrl != null)
            Hero(
              tag: 'promo_image_${promotion.id}',
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Image.network(
                  promotion.imageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: Colors.grey[300],
                    alignment: Alignment.center,
                    child: const Icon(Icons.broken_image, size: 48),
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
            child: Text(
              promotion.title,
              style: const TextStyle(
                fontFamily: grandisExtendedFont,
                fontSize: 26,
                fontWeight: FontWeight.bold,
                height: 1.1,
              ),
            ),
          ),
          if (promotion.description != null && promotion.description!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Text(
                promotion.description!,
                style: const TextStyle(fontSize: 15, height: 1.4),
              ),
            ),
          if (dateRange.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Row(
                children: [
                  const Icon(Icons.event, size: 18, color: Colors.black54),
                  const SizedBox(width: 8),
                  Text(
                    dateRange,
                    style: const TextStyle(fontSize: 13, color: Colors.black54),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.shopping_cart_outlined),
              label: const Text('Browse Furniture'),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ),
        ],
      ),
    );
  }
}

