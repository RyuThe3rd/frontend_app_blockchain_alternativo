import 'dart:collection';
import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:cbor/simple.dart' as cbor_lib;
import 'package:app_pfc_blockchain/Domain/entidade/DocumentoDeExtratoBancario.dart';
import 'package:pointycastle/digests/sha256.dart';
import 'package:web3dart/web3dart.dart';

import '../Services/clienteApiBlockchain.dart';

/// Formato binário comum a todos os novos extractos:
/// [versaoProtocolo, tipoPayload, versaoEsquema, compressao,
///  payloadBytes, assinatura65Bytes]
///
/// Tipo A: [1, 'A', 1, 'none', CBOR, assinatura]
/// Tipo B: [1, 'B', 1, 'zlib', ZLIB(CBOR), assinatura]
///
/// Não existe compatibilidade com o QR JSON legado neste repositório.
class DocumentoRepo {
  static const int _maxPayloadBytes = 512 * 1024;

  /// Mantém a assinatura do método utilizada pelo DocumentoProvider.
  Future<DocumentoDeExtratoBancario> processarQrCode({
    required Uint8List CBORDoQrCode,
    required String idDoBanco,
  }) async {
    try {
      // 1. Abrir envelope e obter o CBOR original, independentemente do tipo.
      final envelope = _abrirEnvelope(CBORDoQrCode);

      // 2. Apenas a interpretação dos campos depende de A ou B.
      final Map<String, dynamic> payload;
      switch (envelope.tipoPayload) {
        case 'A':
          payload = descodificarTipoA(envelope.payloadCbor);
          break;
        case 'B':
          payload = descodificarTipoB(envelope.payloadCbor);
          break;
        default:
          throw const FormatException('Tipo de extracto não suportado.');
      }

      // 3. Conferir os metadados do envelope com os dados assinados.
      if (payload['versaoProtocolo'] != envelope.versaoProtocolo ||
          payload['tipoPayload'] != envelope.tipoPayload ||
          payload['versaoEsquemaPayload'] != envelope.versaoEsquemaPayload) {
        throw const FormatException(
          'Os metadados do envelope não correspondem ao payload autenticado.',
        );
      }

      // 4. SHA-256 dos bytes CBOR ORIGINAIS, nunca do envelope ou
      //    de uma nova serialização do payload.
      final hashBytes = SHA256Digest().process(envelope.payloadCbor);
      final documentHashHex = '0x${bytesToHex(hashBytes)}';

      // 5. Uma única verificação para A e B.
      return await _verificarAutenticidade(
        payload: payload,
        documentHashHex: documentHashHex,
        documentHashBytes: hashBytes,
        assinaturaBytes: envelope.assinatura,
        idDoBanco: idDoBanco,
      );
    } on DocumentoException {
      rethrow;
    } on FormatException {
      throw DocumentoException(
        'O código QR não contém um extracto CBOR válido ou utiliza '
            'um formato não suportado.',
      );
    } on RangeError {
      throw DocumentoException(
        'O código QR está incompleto ou tem uma estrutura inválida.',
      );
    } on TypeError {
      throw DocumentoException(
        'Os campos do código QR têm tipos de dados inválidos.',
      );
    } catch (e, st) {
      // Não imprimir bytes do QR, informações bancárias ou chaves.
      print('Falha ao verificar o extracto: ${e.runtimeType}');
      print(st);
      throw DocumentoException(
        'Não foi possível verificar o extracto neste momento. '
            'Verifique a ligação à Internet e tente novamente.',
      );
    }
  }

  /// Validação de estrutura, tipo, versão, algoritmo e assinatura do envelope.
  _EnvelopeCbor _abrirEnvelope(Uint8List qrBytes) {
    final dynamic envelope;
    try {
      envelope = cbor_lib.cbor.decode(qrBytes);
    } catch (_) {
      throw const FormatException('O QR não contém um envelope CBOR válido.');
    }

    if (envelope is! List) {
      throw const FormatException('O envelope CBOR não é um array.');
    }

    // Mantemos a leitura posicional sem exigir exactamente seis elementos,
    // tal como na implementação anterior.
    final versaoProtocolo = envelope[0];
    final tipoPayload = envelope[1];
    final versaoEsquema = envelope[2];
    final algoritmo = envelope[3];
    final payloadBinario = envelope[4];
    final assinaturaBinaria = envelope[5];

    if (versaoProtocolo != 1 || versaoEsquema != 1) {
      throw const FormatException('Versão do protocolo ou esquema inválida.');
    }
    if (tipoPayload != 'A' && tipoPayload != 'B') {
      throw const FormatException('Tipo de payload não suportado.');
    }

    // Convenção para a versão 1: A não comprimido, B comprimido por ZLIB.
    if ((tipoPayload == 'A' && algoritmo != 'none') ||
        (tipoPayload == 'B' && algoritmo != 'zlib')) {
      throw const FormatException('Compressão incompatível com o tipo do payload.');
    }

    if (payloadBinario is! List<int> || assinaturaBinaria is! List<int>) {
      throw const FormatException('O envelope não contém bytes binários válidos.');
    }

    final bytesTransportados = Uint8List.fromList(payloadBinario);
    final assinatura = Uint8List.fromList(assinaturaBinaria);
    if (bytesTransportados.isEmpty || assinatura.length != 65) {
      throw const FormatException('Payload vazio ou assinatura ECDSA inválida.');
    }

    if (bytesTransportados.length > _maxPayloadBytes) {
      throw const FormatException('Payload excede o limite de tamanho.');
    }

    final Uint8List payloadCbor;
    if (algoritmo == 'zlib') {
      try {
        payloadCbor = Uint8List.fromList(
          ZLibDecoder().decodeBytes(
            bytesTransportados,
            verify: true,
            maxOutputSize: _maxPayloadBytes,
          ),
        );
      } catch (_) {
        throw const FormatException('Não foi possível descomprimir o CBOR.');
      }
    } else {
      payloadCbor = bytesTransportados;
    }

    if (payloadCbor.isEmpty || payloadCbor.length > _maxPayloadBytes) {
      throw const FormatException('Payload CBOR vazio ou demasiado grande.');
    }

    return _EnvelopeCbor(
      versaoProtocolo: versaoProtocolo as int,
      tipoPayload: tipoPayload as String,
      versaoEsquemaPayload: versaoEsquema as int,
      payloadCbor: payloadCbor,
      assinatura: assinatura,
    );
  }

  /// Fluxo criptográfico e de autorização partilhado pelos dois tipos.
  Future<DocumentoDeExtratoBancario> _verificarAutenticidade({
    required Map<String, dynamic> payload,
    required String documentHashHex,
    required Uint8List documentHashBytes,
    required Uint8List assinaturaBytes,
    required String idDoBanco,
  }) async {
    final dados = SplayTreeMap<String, dynamic>.from(payload);

    DocumentoDeExtratoBancario recusar(
        String mensagem, {
          String titulo = 'Extrato inválido.',
        }) {
      return DocumentoDeExtratoBancario(dados)
        ..isDocumentoVeridico = false
        ..mensagemDeErro = titulo
        ..mensagemDeErro2 = mensagem;
    }

    // Consulta a blockchain apenas uma vez para obter o estado histórico.
    final registoBlockchain = await ClienteApiBlockchain()
        .getStatementRecord(documentHashHex);

    if (registoBlockchain['exists'] != true) {
      return recusar(
        'Não encontrámos um registo que confirme a existência deste extracto. '
            'Solicite ao banco emissor que confirme a sua autenticidade.',
      );
    }

    final bankIdRegisto = registoBlockchain['bankId']?.toString();
    if (bankIdRegisto != idDoBanco.trim()) {
      return recusar(
        'O banco seleccionado não corresponde ao banco associado ao extracto. '
            'Confirme as informações com o documento físico.',
      );
    }

    // É a chave histórica associada à ancoragem, não a chave actual.
    final chaveEsperada = registoBlockchain['chaveOperacional'];
    if (chaveEsperada is! String ||
        !_assinaturaEcdsaValida(
          documentHashBytes,
          assinaturaBytes,
          chaveEsperada,
        )) {
      return recusar(
        'Não foi possível confirmar a assinatura digital deste extracto. '
            'O documento pode ter sido alterado ou não ter sido emitido pelo banco indicado.',
      );
    }

    if (registoBlockchain['historicalKeyValid'] != true) {
      return recusar(
        'A chave utilizada não estava autorizada quando o extracto foi '
            'registado. Solicite confirmação ao banco emissor.',
      );
    }

    if (registoBlockchain['affectedByCompromise'] == true) {
      return DocumentoDeExtratoBancario(dados)
        ..isDocumentoVeridico = false
        ..autenticidadeEmRevisao = true
        ..mensagemDeErro = 'Autenticidade em revisão'
        ..mensagemDeErro2 =
            'Foi comunicado um incidente de segurança relacionado com '
            'a emissão deste extracto. Solicite uma confirmação ao banco.';
    }

    if (registoBlockchain['status'] != 'ANCHOR_VALID') {
      return recusar(
        'Não foi possível concluir todas as verificações necessárias. '
            'Tente novamente mais tarde ou contacte o banco emissor.',
      );
    }

    // A autenticidade do payload não substitui a comparação com o papel.
    return DocumentoDeExtratoBancario(dados)
      ..isDocumentoVeridico = true;
  }

  /// Equivalente Dart do Sign.signPrefixedMessage(hashBytes, ...)
  /// usado pelo CryptoService no backend Java.
  bool _assinaturaEcdsaValida(
      Uint8List documentHashBytes,
      Uint8List assinatura,
      String enderecoEsperado,
      ) {
    if (documentHashBytes.length != 32 || assinatura.length != 65) {
      return false;
    }

    try {
      final r = BigInt.parse(
        bytesToHex(assinatura.sublist(0, 32)), radix: 16,
      );
      final s = BigInt.parse(
        bytesToHex(assinatura.sublist(32, 64)), radix: 16,
      );

      var v = assinatura[64];
      if (v == 0 || v == 1) v += 27;
      if (v != 27 && v != 28) return false;

      final assinaturaWeb3 = MsgSignature(r, s, v);
      final digestEthereum = keccak256(Uint8List.fromList([
        ...utf8.encode('\x19Ethereum Signed Message:\n32'),
        ...documentHashBytes,
      ]));

      final chavePublica = ecRecover(digestEthereum, assinaturaWeb3);
      final enderecoRecuperado =
          '0x${bytesToHex(publicKeyToAddress(chavePublica))}';

      return enderecoRecuperado.toLowerCase() ==
          enderecoEsperado.toLowerCase();
    } catch (_) {
      return false;
    }
  }
}

class _EnvelopeCbor {
  final int versaoProtocolo;
  final String tipoPayload;
  final int versaoEsquemaPayload;
  final Uint8List payloadCbor;
  final Uint8List assinatura;

  const _EnvelopeCbor({
    required this.versaoProtocolo,
    required this.tipoPayload,
    required this.versaoEsquemaPayload,
    required this.payloadCbor,
    required this.assinatura,
  });
}

/// Campos idênticos nos payloads A e B (índices 0..4).
Map<String, dynamic> descodificarCamposComuns(List<dynamic> campos) {
  if (campos[0] != 1 || campos[2] != 1 ||
      (campos[1] != 'A' && campos[1] != 'B') ||
      campos[3] is! String || campos[4] is! String ||
      (campos[3] as String).trim().isEmpty ||
      (campos[4] as String).trim().isEmpty) {
    throw const FormatException('Campos comuns do extracto inválidos.');
  }

  return {
    'versaoProtocolo': campos[0],
    'tipoPayload': campos[1],
    'versaoEsquemaPayload': campos[2],
    'banco': campos[3],
    'titular': campos[4],
  };
}

/// Novo Tipo A (CBOR):
/// [1 (versão do protocolo), 'A', 1(versão do schema),
/// banco, titular, contaHash, periodo,
///  parteInteiraDoSaldoFinal, parteDeCentavosDoSaldoFinal,
///  issuedAt, transactionsHashOuNull]
///
/// O antigo Tipo A JSON não é suportado nesta PWA.
Map<String, dynamic> descodificarTipoA(Uint8List cborBytes) {
  final campos = _descodificarArrayCbor(cborBytes, 11);
  final comuns = descodificarCamposComuns(campos);
  if (campos[1] != 'A' ||
      campos[5] is! String ||
      campos[6] is! String ||
      campos[7] is! int ||
      campos[8] is! int ||
      (campos[8] as int) < 0 || (campos[8] as int) > 99 ||
      campos[9] is! String ||
      (campos[10] != null && campos[10] is! String)) {
    throw const FormatException('Estrutura do extracto Tipo A inválida.');
  }

  return {
    ...comuns,
    'contaHash': campos[5],
    'periodo': campos[6],
    'parteInteiraDoSaldoFinal': campos[7],
    'parteDeCentavosDoSaldoFinal': campos[8],
    'issuedAt': campos[9],
    'transactionsHash': campos[10],
  };
}

/// Tipo B (CBOR + ZLIB):
/// [1, 'B', 1, banco, titular, saldoInteiro, saldoCentavos,
///  issuedAt, periodo, [[data, inteiro, centavos, 'C'|'D', descricao], ...]]
Map<String, dynamic> descodificarTipoB(Uint8List cborBytes) {
  final campos = _descodificarArrayCbor(cborBytes, 10);
  final comuns = descodificarCamposComuns(campos);

  if (campos[1] != 'B' ||
      campos[5] is! int ||
      campos[6] is! int ||
      (campos[6] as int) < 0 || (campos[6] as int) > 99 ||
      campos[7] is! String ||
      campos[8] is! String ||
      campos[9] is! List) {
    throw const FormatException('Estrutura do extracto Tipo B inválida.');
  }

  final movimentos = <Map<String, dynamic>>[];
  for (final dynamic item in campos[9] as List) {
    if (item is! List || item.length != 5 ||
        item[0] is! String ||
        item[1] is! int ||
        (item[1] as int) < 0 ||
        item[2] is! int ||
        (item[2] as int) < 0 || (item[2] as int) > 99 ||
        (item[3] != 'C' && item[3] != 'D') ||
        item[4] is! String) {
      throw const FormatException('Movimento bancário CBOR inválido.');
    }

    movimentos.add({
      'data': item[0],
      'parteInteiraDoValor': item[1],
      'parteDeCentavosDoValor': item[2],
      'tipoMovimento': item[3],
      'descricao': item[4],
    });
  }

  return {
    ...comuns,
    'parteInteiraDoSaldoFinal': campos[5],
    'parteDeCentavosDoSaldoFinal': campos[6],
    'issuedAt': campos[7],
    'periodo': campos[8],
    'transactions': movimentos,
  };
}

List<dynamic> _descodificarArrayCbor(Uint8List bytes, int tamanho) {
  final dynamic decoded;
  try {
    decoded = cbor_lib.cbor.decode(bytes);
  } catch (_) {
    throw const FormatException('O payload não contém CBOR válido.');
  }
  if (decoded is! List || decoded.length != tamanho) {
    throw const FormatException('Estrutura posicional do payload inválida.');
  }
  return decoded;
}

/// Mantidos para compatibilidade com outras partes do projecto.
Uint8List descomprimir(Uint8List bytesComprimidos) {
  return Uint8List.fromList(ZLibDecoder().decodeBytes(
    bytesComprimidos,
    verify: true,
    maxOutputSize: 512 * 1024,
  ));
}

Uint8List hexToBytes(String hexString) {
  var clean = hexString.startsWith('0x')
      ? hexString.substring(2)
      : hexString;
  if (clean.length.isOdd) clean = '0$clean';
  return Uint8List.fromList(List.generate(
    clean.length ~/ 2,
        (i) => int.parse(clean.substring(i * 2, i * 2 + 2), radix: 16),
  ));
}

String bytesToHex(List<int> bytes) =>
    bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

class DocumentoException implements Exception {
  final String? message;
  DocumentoException(this.message);

  @override
  String toString() => message ?? super.toString();
}
