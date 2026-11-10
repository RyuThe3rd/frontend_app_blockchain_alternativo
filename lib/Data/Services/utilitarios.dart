import 'dart:convert';

import 'package:basic_utils/basic_utils.dart';
import 'package:cryptography/cryptography.dart';

EcPublicKey parsearChavePublica(String base64Key) {
  // 1. Decodifica Base64 → DER bytes
  final derBytes = base64Decode(base64Key);

  // 2. basic_utils parseia o ASN.1 e devolve o ECPublicKey (pointycastle)
  final ecPub = CryptoUtils.ecPublicKeyFromDerBytes(derBytes);

  // 3. Extrai X e Y como BigInt
  final xBigInt = ecPub.Q!.x!.toBigInteger()!;
  final yBigInt = ecPub.Q!.y!.toBigInteger()!;

  // 4. Converte BigInt → List<int> (32 bytes para P-256)
  final xBytes = bigIntToBytes32(xBigInt);
  final yBytes = bigIntToBytes32(yBigInt);

  // 5. Monta com List<int>
  return EcPublicKey(
    x: xBytes,
    y: yBytes,
    type: KeyPairType.p256,
  );
}

List<int> bigIntToBytes32(BigInt n) {
  final hex = n.toRadixString(16).padLeft(64, '0'); // 32 bytes = 64 hex chars
  return List.generate(
    32,
        (i) => int.parse(hex.substring(i * 2, i * 2 + 2), radix: 16),
  );
}