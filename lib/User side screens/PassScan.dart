import 'dart:typed_data';

import 'package:aapkaparking/User%20side%20screens/AfterPassScan.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class Passcan extends StatefulWidget {
  const Passcan({super.key});

  @override
  State<Passcan> createState() => _QrscannerState();
}

class _QrscannerState extends State<Passcan>
    with SingleTickerProviderStateMixin {
  MobileScannerController cameraController = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    returnImage: true,
  );

  bool isTorchOn = false;
  bool isFrontCamera = false;

  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0, end: 1).animate(_animationController);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan your QR Code'),
        
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: cameraController,
            onDetect: (capture) {
              final List<Barcode> barcodes = capture.barcodes;
              final Uint8List? image = capture.image;
              for (final barcode in barcodes) {
                print('Barcode found: ${barcode.rawValue}');
                if (barcode.rawValue != null) {
                  // Navigate to AfterScan screen with the barcode value
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AfterPassScan(
                        vehicleNumber: barcode.rawValue!,
                      ),
                    ),
                  );
                  break; // Stop after the first barcode is processed
                }
              }
            },
          ),
          Center(
            child: Stack(
              children: [
                Container(
                  width: 250,
                  height: 250,
                  decoration: BoxDecoration(
                    border: Border.all(
                        color: const Color.fromARGB(255, 249, 4, 4),
                        width: 2.0),
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: AnimatedBuilder(
                    animation: _animation,
                    builder: (context, child) {
                      return Stack(
                        children: [
                          Positioned(
                            top: _animation.value * 250,
                            left: 0,
                            right: 0,
                            child: Container(
                              height: 2,
                              color: Colors.blue,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: 600,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: 300,
                height: 70,
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 252, 252, 252),
                  borderRadius: BorderRadius.circular(12.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          isTorchOn = !isTorchOn;
                          cameraController.toggleTorch();
                        });
                      },
                      child: CircleAvatar(
                        backgroundColor: Colors.yellow,
                        radius: 25,
                        child: Icon(
                          isTorchOn ? Icons.flash_on : Icons.flash_off,
                          color: isTorchOn ? Colors.red : Colors.black,
                          size: 35,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          isFrontCamera = !isFrontCamera;
                          cameraController.switchCamera();
                        });
                      },
                      child: const CircleAvatar(
                        backgroundColor: Colors.yellow,
                        radius: 25,
                        child: Icon(
                          Icons.cameraswitch,
                          color: Colors.black,
                          size: 35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
