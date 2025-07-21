import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import '/components/network_image_with_loader.dart';
import 'dart:io';
import 'package:url_launcher/url_launcher.dart';

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
            // AR Button positioned at bottom left - now launches native AR camera directly
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
                      onTap: () => _launchARCamera(context),
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

  void _launchARCamera(BuildContext context) async {
    print('=== NATIVE AR LAUNCH DEBUG ===');
    print('AR Model URL: ${widget.arModelUrl}');
    print('Product Name: ${widget.productName}');
    print('Platform: ${Platform.operatingSystem}');

    if (widget.arModelUrl == null || widget.arModelUrl!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('AR model not available')),
      );
      return;
    }

    try {
      bool launched = false;

      if (Platform.isIOS) {
        print('Launching iOS Quick Look AR...');
        // iOS Quick Look - launches native AR camera
        final quickLookUrl = Uri.parse(widget.arModelUrl!);
        launched = await launchUrl(
          quickLookUrl,
          mode: LaunchMode.externalApplication, // Forces native AR app
        );
        print('iOS AR launch result: $launched');
      } else if (Platform.isAndroid) {
        print('Launching Android Scene Viewer...');
        // Google Scene Viewer - launches native AR camera
        final sceneViewerUrl = Uri.parse(
            'https://arvr.google.com/scene-viewer/1.0?file=${Uri.encodeComponent(widget.arModelUrl!)}&mode=ar_preferred');
        launched = await launchUrl(
          sceneViewerUrl,
          mode: LaunchMode.externalApplication,
        );
        print('Android AR launch result: $launched');
      } else {
        print('Platform not supported for native AR');
        launched = false;
      }

      if (!launched) {
        // Fallback to in-app AR if native launch fails
        print('Native AR launch failed, falling back to in-app AR');
        _showInAppAR(context);
      } else {
        print('Native AR launched successfully');
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                    'AR Camera launched for ${widget.productName ?? "product"}'),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('Error launching AR: $e');
      // Fallback to in-app AR if native launch fails
      _showInAppAR(context);
    }
  }

  void _showInAppAR(BuildContext context) {
    print('Showing fallback in-app AR viewer');
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (context) => Dialog.fullscreen(
        child: _FallbackARViewer(
          arModelUrl: widget.arModelUrl!,
          productName: widget.productName ?? 'Product',
          onRetryNativeAR: () =>
              _launchARCamera(context), // Pass the retry callback
        ),
      ),
    );
  }
}

// Fallback AR Viewer for when native AR launch fails
class _FallbackARViewer extends StatelessWidget {
  final String arModelUrl;
  final String productName;
  final VoidCallback? onRetryNativeAR; // Add this parameter

  const _FallbackARViewer({
    required this.arModelUrl,
    required this.productName,
    this.onRetryNativeAR, // Add this parameter
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ModelViewer configured for AR
          ModelViewer(
            backgroundColor: const Color.fromARGB(0, 0, 0, 0),
            src: arModelUrl,
            alt: productName,

            // Force AR mode
            ar: true,
            arModes: const ['scene-viewer', 'webxr', 'quick-look'],
            arPlacement: ArPlacement.floor,

            // Auto-launch AR when possible
            autoPlay: true,
            loading: Loading.eager,

            // Minimal 3D controls to encourage AR use
            cameraControls: true,
            autoRotate: false,

            // iOS Quick Look
            iosSrc: arModelUrl,

            // Interaction settings
            interactionPrompt: InteractionPrompt.whenFocused,
            interactionPromptStyle: InteractionPromptStyle.wiggle,
            interactionPromptThreshold: 3000,
          ),

          // Top controls
          Positioned(
            top: MediaQuery.of(context).padding.top,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(Icons.close, color: Colors.white),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.info_outline,
                            color: Colors.orange, size: 16),
                        const SizedBox(width: 4),
                        const Text(
                          'Fallback AR - ',
                          style: TextStyle(color: Colors.orange, fontSize: 12),
                        ),
                        Text(
                          productName,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // AR Instructions overlay
          Positioned(
            bottom: 120,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.camera_alt, color: Colors.white, size: 32),
                  SizedBox(height: 8),
                  Text(
                    'Look for the AR button to view in your space',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Native AR launch failed - using fallback viewer',
                    style: TextStyle(color: Colors.orange, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),

          // Try native AR again button - Fixed version
          Positioned(
            bottom: 40,
            left: 20,
            right: 20,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                // Call the retry callback if provided
                if (onRetryNativeAR != null) {
                  onRetryNativeAR!();
                }
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Try Native AR Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
