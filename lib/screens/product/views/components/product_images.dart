import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import '/components/network_image_with_loader.dart';

import '../../../../constants.dart';

class ProductImages extends StatefulWidget {
  const ProductImages({
    super.key,
    required this.images,
    this.arModelUrl,
    this.productName,
  });

  final List<String> images;
  final String? arModelUrl;
  final String? productName;

  @override
  State<ProductImages> createState() => _ProductImagesState();
}

class _ProductImagesState extends State<ProductImages> {
  late PageController _controller;

  int _currentPage = 0;

  bool _isValidUrl(String url) {
    try {
      final uri = Uri.tryParse(url);
      return uri != null && uri.hasScheme && uri.hasAuthority;
    } catch (e) {
      return false;
    }
  }

  @override
  void initState() {
    _controller =
        PageController(viewportFraction: 0.9, initialPage: _currentPage);
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: AspectRatio(
        aspectRatio: 1,
        child: Stack(
          children: [
            PageView.builder(
              controller: _controller,
              onPageChanged: (pageNum) {
                setState(() {
                  _currentPage = pageNum;
                });
              },
              itemCount: widget.images.length,
              itemBuilder: (context, index) => Padding(
                padding: const EdgeInsets.only(right: defaultPadding),
                child: ClipRRect(
                  borderRadius: const BorderRadius.all(
                    Radius.circular(defaultBorderRadious * 2),
                  ),
                  child: NetworkImageWithLoader(widget.images[index]),
                ),
              ),
            ),
            // AR Button positioned at bottom left
            if (widget.arModelUrl != null &&
                widget.arModelUrl!.isNotEmpty &&
                _isValidUrl(widget.arModelUrl!))
              Positioned(
                bottom: 24,
                left: 24,
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    borderRadius: const BorderRadius.all(Radius.circular(12)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _showARViewer(context),
                      borderRadius: const BorderRadius.all(Radius.circular(12)),
                      child: const Padding(
                        padding:
                            EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.view_in_ar,
                              color: Colors.white,
                              size: 20,
                            ),
                            SizedBox(width: 6),
                            Text(
                              'AR View',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            if (widget.images.length > 1)
              Positioned(
                height: 20,
                bottom: 24,
                right: MediaQuery.of(context).size.width * 0.15,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: defaultPadding * 0.75,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    borderRadius: const BorderRadius.all(Radius.circular(50)),
                  ),
                  child: Row(
                    children: List.generate(
                      widget.images.length,
                      (index) => Padding(
                        padding: EdgeInsets.only(
                            right: index == (widget.images.length - 1)
                                ? 0
                                : defaultPadding / 4),
                        child: CircleAvatar(
                          radius: 3,
                          backgroundColor: Theme.of(context)
                              .textTheme
                              .bodyLarge!
                              .color!
                              .withOpacity(index == _currentPage ? 1 : 0.2),
                        ),
                      ),
                    ),
                  ),
                ),
              )
          ],
        ),
      ),
    );
  }

  void _showARViewer(BuildContext context) {
    print('=== AR VIEWER DEBUG ===');
    print('AR Model URL: ${widget.arModelUrl}');
    print('Product Name: ${widget.productName}');
    print(
        'URL is valid: ${widget.arModelUrl != null ? _isValidUrl(widget.arModelUrl!) : false}');

    if (widget.arModelUrl == null || widget.arModelUrl!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('AR model not available')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _ARViewerScreen(
          arModelUrl: widget.arModelUrl!,
          productName: widget.productName ?? 'Product',
        ),
      ),
    );
  }
}

// AR Viewer Screen - Similar to ModelViewerPage from ar.dart
class _ARViewerScreen extends StatefulWidget {
  final String arModelUrl;
  final String productName;

  const _ARViewerScreen({
    required this.arModelUrl,
    required this.productName,
  });

  @override
  State<_ARViewerScreen> createState() => _ARViewerScreenState();
}

class _ARViewerScreenState extends State<_ARViewerScreen> {
  Future<void> _validateModelUrl() async {
    try {
      // Basic URL validation
      if (widget.arModelUrl.isEmpty) {
        throw Exception('AR model URL is empty');
      }

      // Check if URL is properly formatted
      final uri = Uri.tryParse(widget.arModelUrl);
      if (uri == null || (!uri.hasScheme || !uri.hasAuthority)) {
        throw Exception('Invalid AR model URL format');
      }

      // Additional validation could be added here
      // For now, we'll assume the URL is valid if it passes basic checks
      print('AR Model URL validated: ${widget.arModelUrl}');
    } catch (e) {
      print('AR Model URL validation failed: $e');
      throw e;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Add debug information
    print('Building AR Viewer with URL: ${widget.arModelUrl}');
    print('Product name: ${widget.productName}');

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.productName,
          style: const TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline, color: Colors.black87),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text(widget.productName),
                  content: const Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                          'View this product in augmented reality to see how it looks in your space.'),
                      SizedBox(height: 12),
                      Text(
                        'Instructions:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text('• Tap the AR button to enter AR mode'),
                      Text('• Point your camera at a flat surface'),
                      Text('• Drag to rotate • Pinch to zoom'),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Got it'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // 3D Model Viewer Container
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: FutureBuilder<void>(
                  future: _validateModelUrl(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.error_outline,
                              size: 64,
                              color: Colors.red,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'AR Model Not Available',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[800],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'The 3D model could not be loaded.',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return ModelViewer(
                      // Background Color
                      backgroundColor: const Color.fromARGB(255, 245, 245, 245),
                      // Model Source Path - Use complete URL
                      src: widget.arModelUrl,
                      alt: widget.productName,
                      // AR Support Configuration
                      ar: true,
                      arModes: const ['scene-viewer', 'quick-look'],
                      // AR Placement Configuration
                      arPlacement: ArPlacement.floor,
                      // Basic Camera Controls
                      cameraControls: true,
                      autoRotate: true,
                      disableZoom: false,
                      // Simplified camera settings
                      cameraOrbit: '0deg 75deg 105%',
                      fieldOfView: '30deg',
                      // iOS AR configuration
                      iosSrc: widget.arModelUrl,
                      // Loading behavior
                      loading: Loading.lazy,
                      // Basic interaction
                      interactionPrompt: InteractionPrompt.auto,
                      interactionPromptStyle: InteractionPromptStyle.basic,
                    );
                  },
                ),
              ),
            ),
          ),
          // Information Panel
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.productName,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Experience this product in augmented reality',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.blue.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.view_in_ar,
                        size: 18,
                        color: Colors.blue[700],
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'AR Instructions',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.blue,
                              ),
                            ),
                            Text(
                              'Drag to rotate • Pinch to zoom • Tap AR button for real-world view',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.blue,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
