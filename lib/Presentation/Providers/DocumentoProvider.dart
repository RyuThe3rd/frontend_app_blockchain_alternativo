
import 'dart:typed_data';

import 'package:app_pfc_blockchain/Domain/entidade/DocumentoDeExtratoBancario.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:mobile_scanner/src/objects/barcode.dart';

import '../../Data/repos/DocumentoRepo.dart';

class DocumentoProvider extends ChangeNotifier{

  bool isLoading = false;
  bool? isDocumentoVeridico = null;
  DocumentoDeExtratoBancario? resposta = DocumentoDeExtratoBancario({});

  Map<String, dynamic>? bancoSelecionado;
  DocumentoRepo documentoRepo;

  DocumentoProvider(this.documentoRepo);

  Future<void> lerQrCode(Barcode? barcode) async {
    isLoading = true;
    notifyListeners();

    try {
      final banco = bancoSelecionado;

      if (banco == null || barcode == null) {
        throw DocumentoException(
          'Banco ou código QR não disponível.',
        );
      }

      final decoded = barcode.rawDecodedBytes;

      if (decoded is! DecodedBarcodeBytes ||
          decoded.bytes.isEmpty) {
        throw DocumentoException(
          'Não foi possível recuperar os bytes do QR Code.',
        );
      }

      resposta = await documentoRepo.processarQrCode(
        CBORDoQrCode: decoded.bytes,
        idDoBanco: banco['bankId'].toString(),
      );

      isDocumentoVeridico = resposta?.isDocumentoVeridico;

    } catch (e, st) {
      debugPrint('Erro na verificação: $e');
      debugPrintStack(stackTrace: st);

      resposta = DocumentoDeExtratoBancario({})
        ..isDocumentoVeridico = false
        ..mensagemDeErro = 'Não foi possível verificar o extracto'
        ..mensagemDeErro2 = "Direcione este extracto a institiução titular relevante.";

      isDocumentoVeridico = false;

    } finally {
      isLoading = false;
      notifyListeners();
    }
  }


}

