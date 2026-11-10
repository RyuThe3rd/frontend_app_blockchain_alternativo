import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';

import '../Providers/BancoProvider.dart';
import '../Providers/DocumentoProvider.dart';



class TelaDeCapturaDoQrCode extends StatefulWidget {
  /// Constructor for simple Mobile Scanner example
  const TelaDeCapturaDoQrCode({super.key});

  @override
  State<TelaDeCapturaDoQrCode> createState() => _TelaDeCapturaDoQrCodeState();
}

class _TelaDeCapturaDoQrCodeState extends State<TelaDeCapturaDoQrCode> {
  Barcode? _barcode;
  bool notScanned = true;

  Widget _barcodePreview(Barcode? value) {
    if (value == null) {
      return const Text(
        'Escaneie o QR Code do Extrato',
        textAlign: TextAlign.center,
        overflow: TextOverflow.fade,
        style: TextStyle(color: Colors.white,
        fontWeight: FontWeight.bold,
        fontSize: 20
        ),
      );
    }

    return Text(
      "Escaneado..." ?? 'No display value.',
      overflow: TextOverflow.fade,
      textAlign: TextAlign.center,
      style: const TextStyle(
          fontSize: 20,
          color: Colors.white),
    );
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    notScanned = true;
  }

  void _handleBarcode2(BarcodeCapture barcodes) {
    if (mounted && notScanned) {
      setState(() {
        _barcode = barcodes.barcodes.firstOrNull;
        context.read<DocumentoProvider>().lerQrCode(_barcode);
      });
      _barcode = null;
      Navigator.pushNamed(context, '/TelaDeResultados');
      notScanned = false;
    }
  }

  void _handleBarcode3(BarcodeCapture capture) {
    if (!mounted || !notScanned || capture.barcodes.isEmpty) return;

    final barcode = capture.barcodes.first;
    final decoded = barcode.rawDecodedBytes;

    final expected = Uint8List.fromList([
      0xA1, 0x65, 0x73, 0x61, 0x6C,
      0x64, 0x6F, 0x18, 0x64,
    ]);

    final Uint8List? bytes =
    decoded is DecodedBarcodeBytes ? decoded.bytes : null;

    final bool iguais =
        bytes != null && listEquals(bytes, expected);

    notScanned = false;

    Navigator.pop(context);
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Teste de QR binário'),
        content: SelectableText(
          'String: ${barcode.rawValue}\n'
              'Tipo: ${decoded.runtimeType}\n'
              'Bytes recebidos: ${bytes?.length ?? "indisponíveis"}\n'
              'CBOR recuperado correctamente? $iguais',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              setState(() => notScanned = true);
            },
            child: const Text('Testar novamente'),
          ),
        ],
      ),
    );
  }

  void _handleBarcode(BarcodeCapture barcodes) {
    if (!mounted || !notScanned) return;

    // 1. Ignora capturas sem nenhum barcode
    if (barcodes.barcodes.isEmpty) return;

    final barcode = barcodes.barcodes.first;
    final valor = barcode.displayValue;

    // 2. Ignora barcodes sem valor legível
    if (valor == null || valor.trim().isEmpty) return;

    // 3. Marca ANTES de qualquer coisa assíncrona pra não disparar de novo
    notScanned = false;

    setState(() {
      _barcode = barcode;
    });

    context.read<BancoProvider>().notify();
    context.read<DocumentoProvider>().lerQrCode(barcode);
    Navigator.pushNamed(context, '/TelaDeResultados');
  }

  @override
  Widget build(BuildContext context) {
    double bottom = MediaQuery.of(context).padding.bottom;
    return Scaffold(
      appBar: AppBar(title: const Text('Escaneie o QR Code do Extrato',
      textAlign: TextAlign.center,
      ),
      backgroundColor: Colors.blue[700],
        titleTextStyle: TextStyle(

          fontSize: 22,
        fontWeight: FontWeight.bold,
        color: Colors.white
        ),
      ),
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          MobileScanner(onDetect: _handleBarcode),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              alignment: Alignment.bottomCenter,
              width: MediaQuery.of(context).size.width,
              height: 100,
              color: const Color.fromRGBO(0, 0, 0, 0.4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Column(
                    children: [
                      Expanded(
                          flex: 1,
                          child: Center(child: _barcodePreview(_barcode))),
                      SizedBox(height: bottom),
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

class MobileScannerAdvanced extends StatefulWidget {
  /// Constructor for simple Mobile Scanner example
  const MobileScannerAdvanced({super.key});

  @override
  State<MobileScannerAdvanced> createState() => _MobileScannerAdvancedState();
}

class _MobileScannerAdvancedState extends State<MobileScannerAdvanced> {
  Barcode? _barcode;

  Widget _barcodePreview(Barcode? value) {
    if (value == null) {
      return const Text(
        'Scan something!',
        overflow: TextOverflow.fade,
        style: TextStyle(color: Colors.white),
      );
    }

    return Text(
      value.displayValue ?? 'No display value.',
      overflow: TextOverflow.fade,
      style: const TextStyle(color: Colors.white),
    );
  }

  void _handleBarcode(BarcodeCapture barcodes) {
    if (mounted) {
      setState(() {
        _barcode = barcodes.barcodes.firstOrNull;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Simple Mobile Scanner')),
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          MobileScanner(onDetect: _handleBarcode),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              alignment: Alignment.bottomCenter,
              height: 100,
              color: const Color.fromRGBO(0, 0, 0, 0.4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(child: Center(child: _barcodePreview(_barcode))),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}