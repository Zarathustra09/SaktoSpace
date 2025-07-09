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

// AR Viewer Screen - Following the pattern from ar.dart
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
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],

      // App Bar (following ar.dart pattern)
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
          // 3D Model Viewer Container (following ar.dart pattern)
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  children: [
                    // ModelViewer Widget - Following ar.dart configuration
                    ModelViewer(
                      // Background Color
                      backgroundColor: const Color.fromARGB(255, 245, 245, 245),
                      // Model Source Path - Use the URL directly
                      src: widget.arModelUrl,
                      alt: widget.productName,
                      // AR Support Configuration with Scale
                      ar: true,
                      arModes: const ['scene-viewer'],
                      // AR Placement Configuration
                      arPlacement: ArPlacement.floor,
                      // Automatic Model Rotation
                      autoRotate: true,
                      // Interactive Camera Controls
                      cameraControls: true,
                      disableZoom: false,
                      // Camera Positioning & View Settings
                      cameraOrbit: '0deg 75deg 105%',
                      fieldOfView: '30deg',
                      minFieldOfView: '10deg',
                      maxFieldOfView: '90deg',
                      minCameraOrbit: 'auto auto 1%',
                      maxCameraOrbit: 'auto auto 1000%',
                      // Animation Control
                      autoPlay: false,
                      // User Interaction Guidance
                      interactionPrompt: InteractionPrompt.whenFocused,
                      interactionPromptStyle: InteractionPromptStyle.basic,
                      // iOS AR Quick Look Configuration
                      iosSrc: widget.arModelUrl,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Information Panel (following ar.dart pattern)
          Container(
            width: double.infinity,
            constraints: const BoxConstraints(
              maxHeight: 150,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Product Title Display
                  Text(
                    widget.productName,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Product Description Display
                  Text(
                    'Experience this product in augmented reality',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 16),
                  // User Interaction Instructions with AR Preparation
                  Row(
                    children: [
                      const Icon(
                        Icons.view_in_ar,
                        size: 18,
                        color: Colors.deepPurple,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Drag to rotate • Pinch to zoom • Tap AR button for real-world view',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                    ],
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
