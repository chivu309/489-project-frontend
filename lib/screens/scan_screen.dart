import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:image/image.dart' as img;
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

class SkinScanScreen extends StatefulWidget {
  final List<CameraDescription> cameras;
  const SkinScanScreen({super.key, required this.cameras});

  @override
  State<SkinScanScreen> createState() => _SkinScanScreenState();
}

class _SkinScanScreenState extends State<SkinScanScreen> {
  CameraController? _controller;

  Future<void>? _initializeControllerFuture;

  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      performanceMode: FaceDetectorMode.fast,
      enableLandmarks: false,
    ),
  );

  bool _isFaceWellPositioned = false;

  bool _isDetecting = false;

  int _currentStep = 0;

  final List<String?> _capturedPaths = [null, null, null];

  final List<String> _stepInstructions = [
    'Look straight ahead',
    'Turn slightly to your left',
    'Turn slightly to your right',
  ];

  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  void _initCamera() async {
    final status = await Permission.camera.request();
    if (!status.isGranted) {
      debugPrint('Camera permission denied');
      return;
    }

    final frontCamera = widget.cameras.firstWhere(
          (cam) => cam.lensDirection == CameraLensDirection.front,
      orElse: () => widget.cameras.first,
    );

    _controller = CameraController(
      frontCamera,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.nv21,
    );

    try {
      _initializeControllerFuture = _controller!.initialize();
      await _initializeControllerFuture;
    } catch (e) {
      debugPrint('Camera init error: $e');
      return;
    }

    if (!mounted) {
      await _controller?.dispose();
      return;
    }

    _controller!.startImageStream(_processCameraImage);

    setState(() {});
  }

  void _processCameraImage(CameraImage image) async {
    if (_isDetecting) return;
    _isDetecting = true;

    try {
      final inputImage = _convertCameraImage(image);
      if (inputImage == null) {
        _isDetecting = false;
        return;
      }

      final faces = await _faceDetector.processImage(inputImage);

      if (!mounted) return;

      if (faces.isEmpty) {
        setState(() => _isFaceWellPositioned = false);
      } else {
        final face = faces.first;
        final box = face.boundingBox;

        final previewSize = _controller!.value.previewSize!;
        final frameWidth = previewSize.height;
        final frameHeight = previewSize.width;

        final faceCenterX = box.left + box.width / 2;
        final faceCenterY = box.top + box.height / 2;

        final isCentered =
            (faceCenterX - frameWidth / 2).abs() < frameWidth * 0.15 &&
                (faceCenterY - frameHeight / 2).abs() < frameHeight * 0.15;

        final isGoodSize = box.width > frameWidth * 0.35 && box.width < frameWidth * 0.85;

        setState(() => _isFaceWellPositioned = isCentered && isGoodSize);
      }
    } catch (e) {
      debugPrint('Face detection error: $e');
    }

    _isDetecting = false;
  }

  InputImage? _convertCameraImage(CameraImage image) {
    final camera = widget.cameras.firstWhere(
          (cam) => cam.lensDirection == CameraLensDirection.front,
      orElse: () => widget.cameras.first,
    );

    final rotation = InputImageRotationValue.fromRawValue(camera.sensorOrientation) ??
        InputImageRotation.rotation0deg;

    final format = InputImageFormatValue.fromRawValue(image.format.raw);
    if (format == null) return null;

    final plane = image.planes.first;

    return InputImage.fromBytes(
      bytes: plane.bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: plane.bytesPerRow,
      ),
    );
  }

  Future<void> _takePhoto() async {
    try {
      await _initializeControllerFuture;

      await _controller!.stopImageStream();

      final XFile rawImage = await _controller!.takePicture();

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

      setState(() {
        _capturedPaths[_currentStep] = savedImage.path;
      });

      if (_currentStep < 2) {
        setState(() {
          _currentStep++;
          _isFaceWellPositioned = false;
        });
        await _controller!.startImageStream(_processCameraImage);
      } else {
        if (mounted && !_isNavigating) {
          _isNavigating = true;
          Navigator.pop(context, _capturedPaths.whereType<String>().toList());
        }
      }
    } catch (e) {
      debugPrint('Error taking photo: $e');
    }
  }

  void _retakeStep(int index) {
    setState(() {
      _currentStep = index;
      _capturedPaths[index] = null;
      _isFaceWellPositioned = false;
    });
    _controller?.startImageStream(_processCameraImage);
  }

  @override
  void dispose() {
    _controller?.stopImageStream();
    _controller?.dispose();
    _faceDetector.close();
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
              ClipRect(
                child: OverflowBox(
                  alignment: Alignment.center,
                  child: FittedBox(
                    fit: BoxFit.cover,
                    child: SizedBox(
                      width: _controller!.value.previewSize!.height,
                      height: _controller!.value.previewSize!.width,
                      child: CameraPreview(_controller!),
                    ),
                  ),
                ),
              ),

              Center(
                child: SizedBox(
                  width: 260,
                  height: 320,
                  child: CustomPaint(
                    painter: FaceGuidePainter(isWellPositioned: _isFaceWellPositioned),
                  ),
                ),
              ),

              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 40),
                  child: GestureDetector(
                    onTap: _isFaceWellPositioned ? _takePhoto : null,
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _isFaceWellPositioned ? Colors.greenAccent : Colors.white38,
                          width: 4,
                        ),
                      ),
                      child: Container(
                        margin: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _isFaceWellPositioned ? Colors.white : Colors.white38,
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
                  onPressed: () {
                    debugPrint('Close button tapped, _isNavigating=$_isNavigating');
                    if (_isNavigating) return;
                    _isNavigating = true;
                    Navigator.pop(context);
                    Future.microtask(() {
                      if (mounted) _isNavigating = false;
                    });
                  },
                ),
              ),

              Positioned(
                top: 100,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _stepInstructions[_currentStep],
                      style: const TextStyle(color: Colors.white, fontSize: 15),
                    ),
                  ),
                ),
              ),

              Positioned(
                bottom: 140,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(3, (index) {
                    final path = _capturedPaths[index];
                    final isCurrent = index == _currentStep;

                    return GestureDetector(
                      onTap: path != null ? () => _retakeStep(index) : null,
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isCurrent ? Colors.greenAccent : Colors.white38,
                            width: 2,
                          ),
                          color: Colors.black26,
                          image: path != null
                              ? DecorationImage(
                            image: FileImage(File(path)),
                            fit: BoxFit.cover,
                          )
                              : null,
                        ),
                        child: path == null
                            ? Icon(
                          Icons.face_outlined,
                          color: isCurrent ? Colors.greenAccent : Colors.white38,
                          size: 28,
                        )
                            : null,
                      ),
                    );
                  }),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class FaceGuidePainter extends CustomPainter {
  final bool isWellPositioned;
  FaceGuidePainter({required this.isWellPositioned});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = isWellPositioned ? Colors.greenAccent : Colors.white70
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    final facePath = Path();
    final w = size.width;
    final h = size.height;
    facePath.moveTo(w * 0.5, 0);

    // Right side of face
    facePath.cubicTo(
      w * 0.92, h * 0.04,
      w * 0.98, h * 0.55,
      w * 0.68, h * 0.88,
    );

    // Rounded chin
    facePath.cubicTo(
      w * 0.62, h * 0.96,
      w * 0.56, h,
      w * 0.50, h,
    );

    facePath.cubicTo(
      w * 0.44, h,
      w * 0.38, h * 0.96,
      w * 0.32, h * 0.88,
    );

    // Left side of face
    facePath.cubicTo(
      w * 0.02, h * 0.55,
      w * 0.08, h * 0.04,
      w * 0.5, 0,
    );

    facePath.close();

    canvas.drawPath(facePath, paint);

    const bracketLen = 24.0;
    final bracketPaint = Paint()
      ..color = isWellPositioned ? Colors.greenAccent : Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    void drawCorner(Offset origin, double dx, double dy) {
      canvas.drawLine(origin, origin + Offset(dx * bracketLen, 0), bracketPaint);
      canvas.drawLine(origin, origin + Offset(0, dy * bracketLen), bracketPaint);
    }

    drawCorner(const Offset(-20, -40), 1, 1);
    drawCorner(Offset(w + 20, -40), -1, 1);
    drawCorner(Offset(-20, h + 40), 1, -1);
    drawCorner(Offset(w + 20, h + 40), -1, -1);
  }

  @override
  bool shouldRepaint(FaceGuidePainter oldDelegate) =>
      oldDelegate.isWellPositioned != isWellPositioned;
}