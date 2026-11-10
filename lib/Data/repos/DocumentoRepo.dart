import 'dart:collection'; // Necessário para SplayTreeMap
import 'dart:convert';
import 'dart:typed_data';

import 'package:app_pfc_blockchain/Domain/entidade/DocumentoDeExtratoBancario.dart';
import 'package:pointycastle/digests/sha256.dart';
//import 'package:web3dart/crypto.dart';
import 'package:web3dart/web3dart.dart';
import '../Services/clienteApiBlockchain.dart';

class DocumentoRepo {
  Future<DocumentoDeExtratoBancario> processarQrCode({
    required String textoDoQrCode,
    required String idDoBanco,
  }) async {
    try {
      // Reconstruir o payload e o hash do documento (sem assinaturaBanco).
      final payloadOriginal =
      Map<String, dynamic>.from(jsonDecode(textoDoQrCode) as Map);
      final assinaturaHex = payloadOriginal.remove('assinaturaBanco') as String;
      final sortedPayload = SplayTreeMap<String, dynamic>.from(payloadOriginal);
      final jsonCanonico = jsonEncode(sortedPayload);
      final hashBytes = SHA256Digest().process(
        Uint8List.fromList(utf8.encode(jsonCanonico)),
      );
      final documentHashHex = '0x${bytesToHex(hashBytes)}';

      // Mensagens destinadas ao utilizador, sem detalhes técnicos.
      DocumentoDeExtratoBancario recusar(
          String mensagem, {
            String titulo = 'Extrato inválido.',
          }) {
        return DocumentoDeExtratoBancario(sortedPayload)
          ..isDocumentoVeridico = false
          ..mensagemDeErro = titulo
          ..mensagemDeErro2 = mensagem;
      }

      // Uma chamada REST: a API consulta StatementRegistry e BankRegistry
      // numa so eth_call, atraves de verifyStatementWithStatus.
      final registoBlockchain =
      await ClienteApiBlockchain().getStatementRecord(documentHashHex);
      final existe = registoBlockchain['exists'] == true;
      if (!existe) {
        return recusar(
          'Não encontrámos um registo que confirme a existência deste extracto. '
              'Solicite ao banco emissor que confirme a sua autenticidade.',
        );
      }

      // Nunca usar a chave operacional actual para verificar extractos historicos.
      final chaveEsperadaHex = registoBlockchain['chaveOperacional'] as String;
      final bankIdRegisto = registoBlockchain['bankId'].toString();
      if (bankIdRegisto != idDoBanco.trim()) {
        return recusar(
          'O banco selecionado não corresponde ao banco associado a este extracto. '
              'Confirme se a informação abaixo bate com o papel físico.',
        );
      }

      // A API informa a validade temporal e incidentes, mas nao confirma
      // a assinatura ECDSA contida no QR. Fazemos isso localmente.
      final assinaturaBytes = hexToBytes(assinaturaHex);
      bool assinaturaValida = false;
      if (assinaturaBytes.length == 65) {
        final r = BigInt.parse(
            bytesToHex(assinaturaBytes.sublist(0, 32)), radix: 16);
        final s = BigInt.parse(
            bytesToHex(assinaturaBytes.sublist(32, 64)), radix: 16);
        int v = assinaturaBytes[64];
        if (v < 27) v += 27;
        final msgSig = MsgSignature(r, s, v);

        // Compatibilidade temporaria com as variantes do assinador actual.
        // No protocolo definitivo deve existir UM unico esquema de assinatura.
        final candidatos = <Uint8List>[
          hashBytes,
          keccak256(Uint8List.fromList([
            ...utf8.encode('\x19Ethereum Signed Message:\n32'),
            ...hashBytes,
          ])),
          keccak256(Uint8List.fromList([
            ...utf8.encode(
                '\x19Ethereum Signed Message:\n${documentHashHex.length}'),
            ...utf8.encode(documentHashHex),
          ])),
        ];

        for (final digesto in candidatos) {
          try {
            final pubKey = ecRecover(digesto, msgSig);
            final addrHex = '0x${bytesToHex(publicKeyToAddress(pubKey))}';
            if (addrHex.toLowerCase() == chaveEsperadaHex.toLowerCase()) {
              assinaturaValida = true;
              break;
            }
          } catch (_) {
            // O digesto alternativo nao corresponde ao formato da assinatura.
          }
        }
      }

      if (!assinaturaValida) {
        return recusar(
          'Não foi possível confirmar a assinatura digital deste extracto. '
              'O documento pode ter sido alterado ou não ter sido emitido pelo banco indicado.',
          titulo: 'Extrato inválido.',
        );
      }

      if (registoBlockchain['historicalKeyValid'] != true) {
        return recusar(
          'A chave utilizada não estava autorizada quando este extracto foi registado. '
              'Peça uma confirmação ao banco emissor.',
          titulo: 'Extrato inválido.',
        );
      }

      if (registoBlockchain['affectedByCompromise'] == true) {
        // Um incidente não demonstra, por si só, que o extracto seja falso.
        // A interface apresenta este resultado como aviso, não como erro.
        return DocumentoDeExtratoBancario(sortedPayload)
          ..isDocumentoVeridico = false
          ..autenticidadeEmRevisao = true
          ..mensagemDeErro = 'Autenticidade em revisão'
          ..mensagemDeErro2 =
              'Foi comunicado um incidente de segurança relacionado com o processo de geração'
              'utilizado neste extracto. Não é possível confirmar a sua autenticidade '
              'neste momento. Solicite uma confirmação ao banco emissor.';
      }

      if (registoBlockchain['status'] != 'ANCHOR_VALID') {
        return recusar(
          'Não foi possível concluir todas as verificações necessárias. '
              'Tente novamente mais tarde ou contacte o banco emissor.',
          titulo: 'Extrato inválido.',
        );
      }

      // A verificacao criptografica nao compara automaticamente
      // o conteudo visivel no papel com os dados autenticados no QR.
      return DocumentoDeExtratoBancario(sortedPayload)
        ..isDocumentoVeridico = true;

    } catch (e, st) {
      print('ERRO em processarQrCode: $e');
      print(st);
      if (e is DocumentoException) rethrow;
      if (e is FormatException) {
        throw DocumentoException(
          'O código QR não contém dados de verificação válidos. '
              'Confirme que está a ler o código do extracto e tente novamente.',
        );
      }
      throw DocumentoException(
        'Não foi possível verificar o extracto neste momento. '
            'Verifique a ligação à Internet e tente novamente.',
      );
    }
  }
}

/// Converte String Hexadecimal para Uint8List
Uint8List hexToBytes(String hexString) {
  var clean = hexString.startsWith('0x') ? hexString.substring(2) : hexString;
  if (clean.length.isOdd) clean = '0$clean';
  return Uint8List.fromList(List.generate(
    clean.length ~/ 2,
        (i) => int.parse(clean.substring(i * 2, i * 2 + 2), radix: 16),
  ));
}

/// Converte Uint8List para String Hexadecimal
String bytesToHex(List<int> bytes) =>
    bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

class DocumentoException implements Exception {
  final String? message;
  DocumentoException(this.message);

  @override
  String toString() => message ?? super.toString();
}