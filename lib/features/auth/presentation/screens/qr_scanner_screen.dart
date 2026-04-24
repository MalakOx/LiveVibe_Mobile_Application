import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/extensions/context_extensions.dart';

/// Extract session code from QR data
/// Expected format: https://livepulse.app/join?code=SESSIONCODE or just the code
String? extractSessionCode(String qrData) {
  try {
    if (qrData.contains('code=')) {
      final uri = Uri.parse(qrData);
      final code = uri.queryParameters['code'];
      if (code != null && code.length >= 4) {
        return code.toUpperCase();
      }
    }
    final trimmed = qrData.trim().toUpperCase();
    if (RegExp(r'^[A-Z0-9]{4,}$').hasMatch(trimmed)) {
      return trimmed;
    }
  } catch (e) {
    debugPrint('Error parsing QR data: $e');
  }
  return null;
}

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  late MobileScannerController controller;
  bool _hasScanned = false;

  @override
  void initState() {
    super.initState();
    controller = MobileScannerController(
      formats: const [BarcodeFormat.qrCode],
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void _handleQRDetected(BarcodeCapture capture) {
    if (_hasScanned) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final barcode = barcodes.first;
    final qrData = barcode.rawValue;

    if (qrData == null) return;

    _hasScanned = true;

    final sessionCode = extractSessionCode(qrData);

    if (sessionCode == null) {
      _showError('Invalid QR code. Please scan a valid LivePulse session QR.');
      _hasScanned = false;
      return;
    }

    // Navigate to name entry with extracted code
    if (mounted) {
      context.pop(); // Close scanner and go back
      context.push('/participant/name/$sessionCode');
    }
  }

  void _showError(String message) {
    context.showErrorSnackBar(message);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Scan QR Code',
          style: TextStyle(
            fontFamily: 'Outfit',
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: controller,
            onDetect: _handleQRDetected,
            errorBuilder: (context, error, child) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      size: 80,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Camera permission required',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          ),
                    ),
                    const SizedBox(height: 30),
                    ElevatedButton(
                      onPressed: () => context.pop(),
                      child: const Text('Go Back'),
                    ),
                  ],
                ),
              );
            },
          ),
          // Overlay with scanning frame
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(
                  color: AppColors.secondary,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Point at QR Code',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white,
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
}
