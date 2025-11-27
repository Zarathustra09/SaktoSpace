import 'package:flutter/material.dart';
import 'package:shop/constants.dart';
import 'package:shop/models/promotional_advertisement.dart';

class BannerMDynamic extends StatelessWidget {
  const BannerMDynamic({
    super.key,
    required this.advertisement,
    required this.press,
  });

  final PromotionalAdvertisement advertisement;
  final VoidCallback press;

  @override
  Widget build(BuildContext context) {
    print('[BannerMDynamic] Building banner for: ${advertisement.title}');
    print('[BannerMDynamic] Image URL: ${advertisement.imageUrl}');
    print('[BannerMDynamic] Description: ${advertisement.description}');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: defaultPadding),
      child: GestureDetector(
        onTap: press,
        child: Container(
          decoration: BoxDecoration(
            borderRadius:
                const BorderRadius.all(Radius.circular(defaultBorderRadious)),
            gradient: const LinearGradient(
              colors: [primaryColor, accentBlueColor],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: ClipRRect(
            borderRadius:
                const BorderRadius.all(Radius.circular(defaultBorderRadious)),
            child: Stack(
              children: [
                // Background Image
                if (advertisement.imageUrl != null)
                  Positioned.fill(
                    child: Hero(
                      tag: 'promo_image_${advertisement.id}',
                      child: Image.network(
                        advertisement.imageUrl!,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) {
                            print('[BannerMDynamic] Image loaded successfully: ${advertisement.imageUrl}');
                            return child;
                          }
                          final progress = loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                              : null;
                          print('[BannerMDynamic] Loading image... Progress: ${progress != null ? (progress * 100).toStringAsFixed(1) : "unknown"}%');
                          return Center(
                            child: CircularProgressIndicator(
                              value: progress,
                              color: Colors.white,
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          print('[BannerMDynamic] ERROR loading image: $error');
                          print('[BannerMDynamic] Failed URL: ${advertisement.imageUrl}');
                          // Show gradient background if image fails to load
                          return Container(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [primaryColor, accentBlueColor],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  )
                else
                  // Show gradient if no image URL
                  Positioned.fill(
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [primaryColor, accentBlueColor],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                    ),
                  ),
                // Gradient overlay for better text visibility
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withOpacity(0.6),
                        Colors.black.withOpacity(0.3),
                        Colors.transparent,
                      ],
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      stops: const [0.0, 0.3, 0.6],
                    ),
                  ),
                ),
                // Text Content
                Padding(
                  padding: const EdgeInsets.all(defaultPadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        advertisement.title,
                        style: const TextStyle(
                          fontFamily: grandisExtendedFont,
                          fontWeight: FontWeight.bold,
                          fontSize: 24,
                          color: Colors.white,
                          height: 1.1,
                          shadows: [
                            Shadow(
                              offset: Offset(0, 1),
                              blurRadius: 3.0,
                              color: Colors.black45,
                            ),
                          ],
                        ),
                      ),
                      if (advertisement.description != null &&
                          advertisement.description!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            advertisement.description!,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.white,
                              shadows: [
                                Shadow(
                                  offset: Offset(0, 1),
                                  blurRadius: 3.0,
                                  color: Colors.black45,
                                ),
                              ],
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
