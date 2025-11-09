import 'package:flutter/material.dart';
import 'package:ar_flutter_plugin_plus/ar_flutter_plugin_plus.dart';
import 'package:ar_flutter_plugin_plus/managers/ar_location_manager.dart';
import 'package:ar_flutter_plugin_plus/managers/ar_session_manager.dart';
import 'package:ar_flutter_plugin_plus/managers/ar_object_manager.dart';
import 'package:ar_flutter_plugin_plus/managers/ar_anchor_manager.dart';
import 'package:ar_flutter_plugin_plus/models/ar_node.dart';
import 'package:ar_flutter_plugin_plus/models/ar_anchor.dart';
import 'package:ar_flutter_plugin_plus/models/ar_hittest_result.dart';
import 'package:ar_flutter_plugin_plus/datatypes/hittest_result_types.dart';
import 'package:ar_flutter_plugin_plus/datatypes/node_types.dart';
import 'package:ar_flutter_plugin_plus/datatypes/config_planedetection.dart';
import 'package:vector_math/vector_math_64.dart' as vector;
import '/components/network_image_with_loader.dart';
import 'dart:async';

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
                        color: Colors.black.withValues(alpha: 0.15),
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
                              .withValues(
                                  alpha: index == _currentPage ? 1 : 0.2),
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
    // Launch custom AR scene
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CustomARScene(
          modelUrl: widget.arModelUrl!,
          productName: widget.productName ?? 'Product',
        ),
      ),
    );
  }
}

class CustomARScene extends StatefulWidget {
  final String modelUrl;
  final String productName;

  const CustomARScene({
    super.key,
    required this.modelUrl,
    required this.productName,
  });

  @override
  State<CustomARScene> createState() => _CustomARSceneState();
}

class _CustomARSceneState extends State<CustomARScene> {
  ARSessionManager? arSessionManager;
  ARObjectManager? arObjectManager;
  ARAnchorManager? arAnchorManager;
  ARNode? productNode;
  ARPlaneAnchor? currentAnchor;

  bool isPlaced = false;
  bool isLoading = true;
  String statusMessage = 'Move your device to detect surfaces...';
  int loadAttempts = 0;

  @override
  void dispose() {
    arSessionManager?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          ARView(
            onARViewCreated: onARViewCreated,
            planeDetectionConfig: PlaneDetectionConfig.horizontalAndVertical,
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 0,
            right: 0,
            child: _buildStatusBar(),
          ),
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: _buildControls(),
          ),
          if (isLoading)
            Container(
              color: Colors.black45,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(color: Colors.white),
                    const SizedBox(height: 16),
                    const Text(
                      'Loading 3D model...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          isLoading = false;
                          statusMessage =
                              'Load cancelled. Tap surface to retry.';
                        });
                      },
                      child: const Text(
                        'Cancel',
                        style: TextStyle(color: Colors.white70),
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

  void onARViewCreated(
    ARSessionManager arSessionManager,
    ARObjectManager arObjectManager,
    ARAnchorManager arAnchorManager,
    ARLocationManager arLocationManager,
  ) {
    this.arSessionManager = arSessionManager;
    this.arObjectManager = arObjectManager;
    this.arAnchorManager = arAnchorManager;

    this.arSessionManager!.onInitialize(
          showFeaturePoints: false,
          showPlanes: true,
          showWorldOrigin: false,
          handlePans: true,
          handleRotation: true,
        );

    this.arObjectManager!.onInitialize();

    this.arSessionManager!.onPlaneOrPointTap = (hits) {
      if (!isPlaced && !isLoading) {
        onPlaneTap(hits);
      }
    };

    // Set up gesture callbacks
    this.arObjectManager!.onPanStart = onPanStarted;
    this.arObjectManager!.onPanChange = onPanChanged;
    this.arObjectManager!.onPanEnd = onPanEnded;
    this.arObjectManager!.onRotationStart = onRotationStarted;
    this.arObjectManager!.onRotationChange = onRotationChanged;
    this.arObjectManager!.onRotationEnd = onRotationEnded;

    setState(() {
      isLoading = false;
      statusMessage = 'Tap on a surface to place ${widget.productName}';
    });
  }

  Future<void> onPlaneTap(List<ARHitTestResult> hitTestResults) async {
    if (hitTestResults.isEmpty) return;
    if (isLoading) return;
    if (isPlaced) return;

    final singleHitTestResult = hitTestResults.firstWhere(
      (hitTestResult) => hitTestResult.type == ARHitTestResultType.plane,
      orElse: () => hitTestResults.first,
    );

    setState(() {
      isLoading = true;
      loadAttempts++;
      statusMessage = 'Loading 3D model (attempt $loadAttempts)...';
    });

    try {
      // Create node with initial rotation using Vector4
      // Format: Vector4(axisX, axisY, axisZ, angleInRadians)
      final newNode = ARNode(
        type: NodeType.webGLB,
        uri: widget.modelUrl,
        scale: vector.Vector3(0.2, 0.2, 0.2),
        position: vector.Vector3(0.0, 0.0, 0.0),
        rotation:
            vector.Vector4(0.0, 1.0, 0.0, 0.0), // Y-axis rotation, 0 degrees
      );

      // Create anchor with the transformation matrix
      var newAnchor = ARPlaneAnchor(
        transformation: singleHitTestResult.worldTransform,
      );

      bool? didAddAnchor = await arAnchorManager?.addAnchor(newAnchor);

      if (didAddAnchor == true) {
        bool? didAddNode = await arObjectManager
            ?.addNode(newNode, planeAnchor: newAnchor)
            .timeout(
          const Duration(seconds: 15),
          onTimeout: () {
            return false;
          },
        );

        if (didAddNode == true) {
          productNode = newNode;
          currentAnchor = newAnchor;

          // Keep gestures enabled after placing the object
          await arSessionManager?.onInitialize(
            showFeaturePoints: false,
            showPlanes: false,
            showWorldOrigin: false,
            handlePans: true,
            handleRotation: true,
          );

          setState(() {
            isPlaced = true;
            isLoading = false;
            statusMessage =
                'Use gestures to move or rotate ${widget.productName}';
          });
        } else {
          throw Exception('Failed to add node');
        }
      } else {
        throw Exception('Failed to create anchor');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        statusMessage = 'Model failed to load';
      });

      if (mounted) {
        _showErrorDialog(e.toString());
      }
    }
  }

  void _showErrorDialog(String error) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('3D Model Error'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'The 3D model could not be loaded. This usually happens when:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              const Text('• Textures are not in ARGB8/RGBA format'),
              const Text('• Model file is corrupted'),
              const Text('• File size is too large'),
              const Text('• Network connection issue'),
              const SizedBox(height: 12),
              const Text(
                'Solutions:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text('1. Re-export GLB with embedded RGBA textures'),
              const Text('2. Reduce model complexity'),
              const Text('3. Check server CORS headers'),
              const SizedBox(height: 12),
              Text(
                'Error: $error',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.red,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                loadAttempts = 0;
                statusMessage = 'Tap to try again';
              });
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close, color: Colors.white),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.productName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  statusMessage,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isPlaced
                  ? Colors.green.withValues(alpha: 0.3)
                  : Colors.white24,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              isPlaced
                  ? 'PLACED'
                  : widget.modelUrl.split('.').last.toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControls() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: isPlaced ? () => _resetObject() : null,
              icon: const Icon(Icons.refresh, size: 20),
              label: const Text('Reset'),
              style: ElevatedButton.styleFrom(
                backgroundColor: isPlaced ? Colors.white24 : Colors.white12,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                disabledBackgroundColor: Colors.white12,
                disabledForegroundColor: Colors.white38,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: isPlaced ? () => _takeScreenshot() : null,
              icon: const Icon(Icons.camera_alt, size: 20),
              label: const Text('Capture'),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    isPlaced ? Theme.of(context).primaryColor : Colors.white12,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                disabledBackgroundColor: Colors.white12,
                disabledForegroundColor: Colors.white38,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _resetObject() async {
    if (productNode != null) {
      await arObjectManager?.removeNode(productNode!);
      await Future.delayed(const Duration(milliseconds: 100));

      if (currentAnchor != null) {
        try {
          await arAnchorManager?.removeAnchor(currentAnchor!);
        } catch (e) {
          debugPrint('Anchor removal error (expected): $e');
        }
      }

      await arSessionManager?.onInitialize(
        showFeaturePoints: false,
        showPlanes: true,
        showWorldOrigin: false,
        handlePans: true,
        handleRotation: true,
      );

      setState(() {
        productNode = null;
        currentAnchor = null;
        isPlaced = false;
        statusMessage = 'Tap on a surface to place ${widget.productName}';
      });
    }
  }

  void _takeScreenshot() async {
    try {
      final screenshot = await arSessionManager?.snapshot();
      if (screenshot != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Screenshot captured!'),
              ],
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to capture screenshot'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Gesture callback methods
  void onPanStarted(String nodeName) {
    debugPrint("Started panning node: $nodeName");
    setState(() {
      statusMessage = 'Moving ${widget.productName}...';
    });
  }

  void onPanChanged(String nodeName) {
    debugPrint("Continued panning node: $nodeName");
  }

  void onPanEnded(String nodeName, vector.Matrix4 newTransform) {
    debugPrint("Ended panning node: $nodeName");
    setState(() {
      statusMessage = 'Use gestures to move or rotate ${widget.productName}';
    });

    // Update the node's transform if you want to keep it in sync
    if (productNode != null && productNode!.name == nodeName) {
      productNode!.transform = newTransform;
    }
  }

  void onRotationStarted(String nodeName) {
    debugPrint("Started rotating node: $nodeName");
    setState(() {
      statusMessage = 'Rotating ${widget.productName}...';
    });
  }

  void onRotationChanged(String nodeName) {
    debugPrint("Continued rotating node: $nodeName");
  }

  void onRotationEnded(String nodeName, vector.Matrix4 newTransform) {
    debugPrint("Ended rotating node: $nodeName");
    setState(() {
      statusMessage = 'Use gestures to move or rotate ${widget.productName}';
    });

    // Update the node's transform if you want to keep it in sync
    if (productNode != null && productNode!.name == nodeName) {
      productNode!.transform = newTransform;
    }
  }
}
