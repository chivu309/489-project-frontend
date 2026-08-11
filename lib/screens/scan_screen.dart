import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'photo_preview.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image/image.dart' as img;



class SkinScanScreen extends StatefulWidget {
  final List<CameraDescription> cameras;
  const SkinScanScreen({super.key, required this.cameras});

  @override
  State<SkinScanScreen> createState() => _SkinScanScreenState();
}

class _SkinScanScreenState extends State<SkinScanScreen> {
  CameraController? _controller;
  Future<void>? _initializeControllerFuture;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    final status = await Permission.camera.request();

    if (!status.isGranted) {
      debugPrint('Camera permission denied');
      return; // don't attempt to initialize without permission
    }

    final frontCamera = widget.cameras.firstWhere(
          (cam) => cam.lensDirection == CameraLensDirection.front,
      orElse: () => widget.cameras.first,
    );

    _controller = CameraController(
      frontCamera,
      ResolutionPreset.high,
      enableAudio: false,
    );

    try {
      _initializeControllerFuture = _controller!.initialize();
      await _initializeControllerFuture;
    } catch (e) {
      debugPrint('Camera init error: $e');
      return;
    }

    if (!mounted) {
      // widget was disposed while we were awaiting — clean up safely
      await _controller?.dispose();
      return;
    }

    setState(() {});
  }

  Future<void> _takePhoto() async {
    try {
      await _initializeControllerFuture;
      final XFile rawImage = await _controller!.takePicture();

      // Read and flip the image horizontally (front camera mirror fix)
      final bytes = await File(rawImage.path).readAsBytes();
      final decodedImage = img.decodeImage(bytes);

      if (decodedImage == null) {
        debugPrint('Failed to decode image');
        return;
      }

      final flippedImage = img.flipHorizontal(decodedImage);
      final flippedBytes = img.encodeJpg(flippedImage);

      final Directory tempDir = await getTemporaryDirectory();
      final String fileName = 'skin_scan_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final String savedPath = '${tempDir.path}/$fileName';

      final File savedImage = await File(savedPath).writeAsBytes(flippedBytes);

      if (!mounted) return;

      final confirmed = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (_) => PhotoPreviewScreen(imagePath: savedImage.path),
        ),
      );

      if (confirmed == true && mounted) {
        Navigator.pop(context, savedImage.path);
      }
    } catch (e) {
      debugPrint('Error taking photo: $e');
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          return Stack(
            fit: StackFit.expand,
            children: [
              CameraPreview(_controller!),
              Center(
                child: Container(
                  width: 260,
                  height: 320,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white70, width: 2),
                    borderRadius: BorderRadius.circular(140),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 40),
                  child: GestureDetector(
                    onTap: _takePhoto,
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 4),
                      ),
                      child: Container(
                        margin: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 48,
                left: 16,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 30),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}