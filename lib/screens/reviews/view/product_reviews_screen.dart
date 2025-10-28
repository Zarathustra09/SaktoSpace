import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shop/constants.dart';
import 'package:shop/models/rating_model.dart';
import 'package:shop/models/prod_product_model.dart';
import 'package:shop/services/rating/rating_service.dart';

class ProductReviewsScreen extends StatefulWidget {
  const ProductReviewsScreen({super.key, this.productId}); // productId optional

  final int? productId;

  @override
  State<ProductReviewsScreen> createState() => _ProductReviewsScreenState();
}

class _ProductReviewsScreenState extends State<ProductReviewsScreen> {
  final RatingService _ratingService = RatingService();
  Future<ProdProductModel>? _productFuture;
  int? _productId; // effective product id

  // Add a simple logger to tag messages from this screen
  void _log(String message) => print('[ProductReviews] $message');

  @override
  void initState() {
    super.initState();
    _productId = widget.productId;
    _log('initState, widget.productId=$_productId');

    // If provided via constructor, call immediately
    if (_productId != null) {
      _loadProductWithRatings(_productId!);
    }

    // Also try to read route args after first frame if not provided via constructor
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_productId != null) return;
      final args = ModalRoute.of(context)?.settings.arguments;
      _log('postFrame route args: $args (${args.runtimeType})');
      int? parsed;
      if (args is int) parsed = args;
      if (args is String) parsed = int.tryParse(args);
      if (parsed != null) {
        setState(() {
          _productId = parsed;
        });
        _log('Resolved productId from args: $_productId');
        _loadProductWithRatings(_productId!);
      } else {
        _log('No productId in constructor or route args.');
        setState(() {}); // trigger UI to show message
      }
    });
  }

  void _loadProductWithRatings(int id) {
    final url = '$baseUrl/ratings/$id';
    _log('Calling GET $url');
    setState(() {
      _productFuture = _ratingService
          .getProductWithRatings(id)
          .then((p) {
            _log('GET success: id=${p.id}, name=${p.name}, ratings=${(p.ratings?.length ?? 0)}, avg=${p.averageRating}, total=${p.totalRatings}');
            return p;
          })
          .catchError((e) {
            _log('GET error: $e');
            throw e;
          });
    });
  }

  void _showAddReviewDialog() {
    int selectedRating = 5;
    final commentController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add Review'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Rating:'),
              const SizedBox(height: 8),
              Row(
                children: List.generate(5, (index) {
                  return GestureDetector(
                    onTap: () => setDialogState(() => selectedRating = index + 1),
                    child: Icon(
                      Icons.star,
                      color: index < selectedRating ? Colors.amber : Colors.grey,
                      size: 32,
                    ),
                  );
                }),
              ),
              const SizedBox(height: 16),
              const Text('Comment (optional):'),
              const SizedBox(height: 8),
              TextField(
                controller: commentController,
                maxLines: 3,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Share your thoughts about this product...',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (_productId == null) {
                  _log('Submit blocked: _productId is null');
                  return;
                }
                _log('Submitting rating: productId=${_productId}, rating=$selectedRating, commentLen=${commentController.text.length}');
                try {
                  await _ratingService.createRating(
                    productId: _productId!,
                    rating: selectedRating,
                    comment: commentController.text.isNotEmpty ? commentController.text : null,
                  );
                  _log('Create rating success. Refreshing product with ratings...');
                  if (!mounted) return;
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Review added successfully!')),
                  );
                  _loadProductWithRatings(_productId!);
                } catch (e) {
                  _log('Create rating failed: $e');
                  if (!mounted) return;
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              },
              child: const Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    _log('Building with _productId=${_productId}');
    if (_productId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Reviews')),
        body: const Center(child: Text('Product ID not provided')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reviews'),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _showAddReviewDialog,
            icon: const Icon(Icons.add),
            tooltip: 'Add Review',
          ),
        ],
      ),
      body: FutureBuilder<ProdProductModel>(
        future: _productFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            _log('FutureBuilder: waiting for product response...');
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            _log('FutureBuilder: error -> ${snapshot.error}');
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.grey),
                  const SizedBox(height: 12),
                  Text('Error loading product: ${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () {
                      _log('Retry tapped. Re-calling product API...');
                      _loadProductWithRatings(_productId!);
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }
          if (!snapshot.hasData) {
            _log('FutureBuilder: no data in snapshot');
            return const Center(child: CircularProgressIndicator());
          }

          final product = snapshot.data!;
          final List<RatingModel> ratings = (product.ratings ?? [])
              .whereType<Map<String, dynamic>>()
              .map((e) => RatingModel.fromJson(e))
              .toList();

          _log('Rendering UI: productId=${product.id}, ratings=${ratings.length}, avg=${product.averageRating}, total=${product.totalRatings}');

          // Use slivers to avoid unbounded constraints with Column/Expanded
          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.all(defaultPadding),
                  padding: const EdgeInsets.all(defaultPadding),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(defaultBorderRadious),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(product.name, style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 4),
                      Text('Reviews (${product.totalRatings ?? 0})',
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          ...List.generate(5, (i) {
                            final r = product.averageRating ?? 0.0;
                            return Icon(Icons.star, size: 20, color: i < r.round() ? Colors.amber : Colors.grey);
                          }),
                          const SizedBox(width: 8),
                          Text('${(product.averageRating ?? 0.0).toStringAsFixed(1)} average'),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _showAddReviewDialog,
                          child: const Text('Add Review')
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (ratings.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(defaultPadding),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Keep the same empty state layout
                          // Using basic icons/text to ensure stable layout
                          Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text('No reviews yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
                          SizedBox(height: 8),
                          Text('Be the first to review this product!'),
                        ],
                      ),
                    ),
                  ),
                )
              else
                SliverList.separated(
                  itemCount: ratings.length,
                  separatorBuilder: (_, __) => const SizedBox(height: defaultPadding),
                  itemBuilder: (context, index) {
                    final rating = ratings[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: defaultPadding),
                      child: Container(
                        padding: const EdgeInsets.all(defaultPadding),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(defaultBorderRadious),
                          border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.1)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: primaryColor,
                                  child: Text(
                                    rating.user?.name.substring(0, 1).toUpperCase() ?? 'U',
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(rating.user?.name ?? 'Anonymous', style: const TextStyle(fontWeight: FontWeight.w600)),
                                      Row(
                                        children: [
                                          ...List.generate(5, (starIndex) {
                                            return Icon(
                                              Icons.star,
                                              size: 16,
                                              color: starIndex < rating.rating ? Colors.amber : Colors.grey,
                                            );
                                          }),
                                          const SizedBox(width: 8),
                                          Text(
                                            DateTime.tryParse(rating.createdAt)?.toString().split(' ').first ?? rating.createdAt,
                                            style: Theme.of(context).textTheme.bodySmall,
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            if (rating.comment != null && rating.comment!.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              Text(rating.comment!, style: Theme.of(context).textTheme.bodyMedium),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
              const SliverToBoxAdapter(child: SizedBox(height: defaultPadding)),
            ],
          );
        },
      ),
    );
  }
}
