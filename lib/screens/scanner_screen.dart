import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';

import '../providers/visitor_provider.dart';
import '../services/visitor_api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/async_state_view.dart';
import 'visitor_details_screen.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key, required this.isActive});

  final bool isActive;

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  final _controller = MobileScannerController(autoStart: false);
  bool _isProcessing = false;
  String? _scanError;

  @override
  void initState() {
    super.initState();
    if (widget.isActive) _scheduleCameraSync();
  }

  @override
  void didUpdateWidget(covariant ScannerScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isActive != widget.isActive) _scheduleCameraSync();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Scan visitor pass',
                  style: Theme.of(context).textTheme.headlineMedium
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                Text(
                  'Point the camera at the visitor QR code.',
                  style: TextStyle(color: Colors.blueGrey.shade600),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: Stack(
                  fit: StackFit.expand,
                  alignment: Alignment.center,
                  children: [
                    MobileScanner(
                      controller: _controller,
                      onDetect: _onDetect,
                      errorBuilder: (context, error) => AsyncStateView(
                        title: 'Camera unavailable',
                        message: _cameraErrorMessage(error),
                        icon: Icons.no_photography_outlined,
                      ),
                    ),
                    IgnorePointer(
                      child: Center(
                        child: Container(
                          width: 240,
                          height: 240,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.white, width: 3),
                            borderRadius: BorderRadius.circular(22),
                          ),
                        ),
                      ),
                    ),
                    if (_isProcessing)
                      ColoredBox(
                        color: Colors.black54,
                        child: const Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        ),
                      ),
                    if (_scanError != null)
                      Positioned(
                        left: 16,
                        right: 16,
                        bottom: 20,
                        child: Material(
                          color: Colors.red.shade700,
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.all(13),
                            child: Text(
                              _scanError!,
                              style: const TextStyle(color: Colors.white),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: TextButton.icon(
              onPressed: () async {
                await _controller.toggleTorch();
              },
              icon: const Icon(Icons.flash_on_outlined),
              label: const Text('Toggle flashlight'),
              style: TextButton.styleFrom(foregroundColor: AppTheme.blue),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;
    final id = capture.barcodes
        .map((barcode) => barcode.rawValue?.trim())
        .whereType<String>()
        .where((value) => value.isNotEmpty)
        .firstOrNull;
    if (id == null) return;

    setState(() {
      _isProcessing = true;
      _scanError = null;
    });
    final provider = context.read<VisitorProvider>();
    try {
      await _controller.stop();
      final visitor = await provider.getVisitorById(id);
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => VisitorDetailsScreen(visitor: visitor),
        ),
      );
      if (mounted) await _controller.start();
    } on VisitorApiException catch (error) {
      if (!mounted) return;
      setState(() => _scanError = error.message);
      await Future<void>.delayed(const Duration(seconds: 3));
      if (mounted) {
        setState(() => _scanError = null);
        if (widget.isActive) await _controller.start();
      }
    } on Exception catch (error) {
      if (!mounted) return;
      setState(() => _scanError = 'Could not find this visitor: $error');
      await Future<void>.delayed(const Duration(seconds: 3));
      if (mounted) {
        setState(() => _scanError = null);
        if (widget.isActive) await _controller.start();
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  String _cameraErrorMessage(MobileScannerException error) {
    return switch (error.errorCode) {
      MobileScannerErrorCode.permissionDenied => 'Camera permission is required. Allow camera access in your device settings and reopen the scanner.',
      _ => error.errorDetails?.message ?? 'Check camera access and try again.',
    };
  }

  void _scheduleCameraSync() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_syncCamera());
    });
  }

  Future<void> _syncCamera() async {
    try {
      if (widget.isActive) {
        await _controller.start();
      } else {
        await _controller.stop();
      }
    } on MobileScannerException catch (error) {
      if (mounted) setState(() => _scanError = _cameraErrorMessage(error));
    }
  }
}
