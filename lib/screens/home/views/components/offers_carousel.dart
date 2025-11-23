import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shop/components/Banner/M/banner_m_style_1.dart';
import 'package:shop/components/Banner/M/banner_m_style_2.dart';
import 'package:shop/components/Banner/M/banner_m_style_3.dart';
import 'package:shop/components/Banner/M/banner_m_style_4.dart';
import 'package:shop/components/Banner/M/banner_m_dynamic.dart';
import 'package:shop/components/dot_indicators.dart';
import 'package:shop/models/promotional_advertisement.dart';
import 'package:shop/services/promotion/promotional_service.dart';

import 'package:shop/constants.dart';
import 'promotion_detail_page.dart';

class OffersCarousel extends StatefulWidget {
  const OffersCarousel({
    super.key,
  });

  @override
  State<OffersCarousel> createState() => _OffersCarouselState();
}

class _OffersCarouselState extends State<OffersCarousel> {
  int _selectedIndex = 0;
  late PageController _pageController;
  Timer? _timer;
  List<PromotionalAdvertisement> _promotions = [];
  bool _isLoading = true;

  // Default fallback offers
  List get _fallbackOffers => [
        BannerMStyle1(
          text: "New items with \nFree shipping",
          press: () {},
        ),
        BannerMStyle2(
          title: "Black \nfriday",
          subtitle: "Collection",
          discountParcent: 50,
          press: () {},
        ),
        BannerMStyle3(
          title: "Grab \nyours now",
          discountParcent: 50,
          press: () {},
        ),
        BannerMStyle4(
          title: "SUMMER \nSALE",
          subtitle: "SPECIAL OFFER",
          discountParcent: 80,
          press: () {},
        ),
      ];

  @override
  void initState() {
    super.initState();
    print('[OffersCarousel] Initializing carousel...');
    _pageController = PageController(initialPage: 0);
    _loadPromotions();
  }

  Future<void> _loadPromotions({bool manual = false}) async {
    if (manual) {
      print('[OffersCarousel] Manual refresh requested');
      setState(() => _isLoading = true);
    }
    try {
      final promotions = await PromotionalService.getActivePromotions(retries: 1);
      print('[OffersCarousel] Received ${promotions.length} promotions (after retry)');
      if (!mounted) return;
      setState(() {
        _promotions = promotions;
        _isLoading = false;
      });
      if (_promotions.isEmpty) {
        print('[OffersCarousel] Still empty after retry - staying on fallback banners');
      }
      _startAutoPlay();
    } catch (e, st) {
      print('[OffersCarousel] ERROR loading promotions: $e');
      print('[OffersCarousel] Stack: $st');
      if (!mounted) return;
      setState(() => _isLoading = false);
      _startAutoPlay();
    }
  }

  void _startAutoPlay() {
    _timer?.cancel();
    final useFallback = _promotions.isEmpty;
    final offersCount = useFallback ? _fallbackOffers.length : _promotions.length;
    // Only autoplay dynamic promotions; for fallback keep but can disable if desired
    if (offersCount <= 1) return;
    _timer = Timer.periodic(const Duration(seconds: 4), (timer) {
      _selectedIndex = (_selectedIndex + 1) % offersCount;
      if (_pageController.hasClients) {
        _pageController.animateToPage(
          _selectedIndex,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _showPromotionDetails(PromotionalAdvertisement promo) {
    print('[OffersCarousel] Opening details for promo: ${promo.title}');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        final dateFmt = DateFormat('MMM d, y');
        String dateRange = '';
        if (promo.startDate != null || promo.endDate != null) {
          final start = promo.startDate != null ? dateFmt.format(promo.startDate!) : 'Started';
          final end = promo.endDate != null ? dateFmt.format(promo.endDate!) : 'Ongoing';
          dateRange = '$start  •  $end';
        }
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 8),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 12),
                if (promo.imageUrl != null)
                  Hero(
                    tag: 'promo_image_${promo.id}',
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: AspectRatio(
                        aspectRatio: 16 / 9,
                        child: Image.network(
                          promo.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: Colors.grey[300],
                            alignment: Alignment.center,
                            child: const Icon(Icons.broken_image),
                          ),
                        ),
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      promo.title,
                      style: const TextStyle(
                        fontFamily: grandisExtendedFont,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                if (promo.description != null && promo.description!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        promo.description!,
                        style: const TextStyle(fontSize: 14, height: 1.35),
                      ),
                    ),
                  ),
                if (dateRange.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    child: Row(
                      children: [
                        const Icon(Icons.event, size: 16, color: Colors.black54),
                        const SizedBox(width: 6),
                        Text(
                          dateRange,
                          style: const TextStyle(fontSize: 12, color: Colors.black54),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.open_in_full),
                          label: const Text('Open Full Page'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          onPressed: () {
                            Navigator.pop(ctx);
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => PromotionDetailPage(promotion: promo),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      IconButton(
                        tooltip: 'Close',
                        onPressed: () => Navigator.pop(ctx),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      print('[OffersCarousel] Showing loading indicator...');
      return AspectRatio(
        aspectRatio: 1.87,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: defaultPadding),
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(defaultBorderRadious),
          ),
          child: const Center(child: CircularProgressIndicator()),
        ),
      );
    }
    final usingFallback = _promotions.isEmpty;
    final displayOffers = usingFallback ? _fallbackOffers : _promotions;
    print('[OffersCarousel] Displaying ${displayOffers.length} offers (${_promotions.isEmpty ? "fallback" : "API"})');

    return AspectRatio(
      aspectRatio: 1.87,
      child: Stack(
        alignment: Alignment.bottomRight,
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: displayOffers.length,
            onPageChanged: (int index) {
              setState(() => _selectedIndex = index);
            },
            itemBuilder: (context, index) {
              if (usingFallback) {
                print('[OffersCarousel] Building fallback banner at index $index');
                return _fallbackOffers[index];
              }
              print('[OffersCarousel] Building dynamic banner: ${_promotions[index].title}');
              return BannerMDynamic(
                advertisement: _promotions[index],
                press: () => _showPromotionDetails(_promotions[index]),
              );
            },
          ),
          // Refresh button
          Positioned(
            top: 8,
            right: 8,
            child: Material(
              color: Colors.black45,
              shape: const CircleBorder(),
              child: IconButton(
                icon: const Icon(Icons.refresh, color: Colors.white, size: 20),
                tooltip: 'Refresh promotions',
                onPressed: () => _loadPromotions(manual: true),
              ),
            ),
          ),
          // Empty overlay notice when using fallback due to empty API list
          if (usingFallback)
            Positioned(
              left: 12,
              top: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Showing default offers (no active promotions)',
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ),
          FittedBox(
            child: Padding(
              padding: const EdgeInsets.all(defaultPadding),
              child: SizedBox(
                height: 16,
                child: Row(
                  children: List.generate(
                    displayOffers.length,
                    (index) {
                      return Padding(
                        padding:
                            const EdgeInsets.only(left: defaultPadding / 4),
                        child: DotIndicator(
                          isActive: index == _selectedIndex,
                          activeColor: Colors.white70,
                          inActiveColor: Colors.white54,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}
