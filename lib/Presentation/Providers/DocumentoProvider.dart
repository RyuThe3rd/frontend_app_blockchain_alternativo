
import 'package:app_pfc_blockchain/Domain/entidade/DocumentoDeExtratoBancario.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/src/objects/barcode.dart';

import '../../Data/repos/DocumentoRepo.dart';

class DocumentoProvider extends ChangeNotifier{

  bool isLoading = false;
  bool? isDocumentoVeridico = null;
  DocumentoDeExtratoBancario? resposta = DocumentoDeExtratoBancario({});

  Map<String, dynamic>? bancoSelecionado;
  DocumentoRepo documentoRepo;

  DocumentoProvider(this.documentoRepo);

  void lerQrCode(Barcode? barcode) async {
    print("Mapa");
    print(bancoSelecionado);
    print("");
    print(barcode?.displayValue);

    isLoading = true;
    notifyListeners();
    if(bancoSelecionado == null){
       return;
    }

    if (barcode?.displayValue == null) {
      isLoading = false;
      isDocumentoVeridico = false;
      resposta?.mensagemDeErro = "QrCode invalido";
      resposta?.mensagemDeErro2 = "Não foi possível ler o QR Code";
      notifyListeners();
      return;
    }
    // _processarQrCode(barcode);

    String texto = """{"banco":"BCI","titular":"Rui Manuel de Noronha Matomate","contaHash":"a8f3b21c4e9d00112233445566778899aabbccddeeff00112233445566778899a8f2","periodo":"2026-01-01 a 2026-06-30","saldoFinal":"500000.00 MZN","issuedAt":"2026-08-30T18:00:00Z","assinaturaBanco":"d10acdb3215172793827fd4ebb42e08466713500db1f12e1bb6d650d80596c0e96f8b8238db899bae6c5de1e3fb1fa6ed97b8197f0f494c46ef9c6059877ac0b"}""";
    resposta = await documentoRepo.processarQrCode(
    textoDoQrCode: barcode!.displayValue!,
     // textoDoQrCode: texto,
        idDoBanco: bancoSelecionado!["bankId"].toString());

    print("Resposta do processarQrCode: ${resposta?.dados}");
    isDocumentoVeridico = resposta?.isDocumentoVeridico;
    isLoading = false;
    notifyListeners();

  }


}

