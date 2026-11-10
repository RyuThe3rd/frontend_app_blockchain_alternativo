import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../Domain/contratos/ClienteApiBlockchainContract.dart';

class ClienteApiBlockchain implements ClienteApiBlockchainContract{
 String apiUrl = 'https://api-blockchain-pfc-1021823144662.africa-south1.run.app' ;


 Future<String> getChavePublicaDoBanco(String idDoBanco) async {

   try {

     String endpoint = "/api/v1/banks/${idDoBanco}/operational-key";

     http.Response chavePublica = await http.get(Uri.parse("$apiUrl/$endpoint"));

     final mapa = jsonDecode(chavePublica.body);

     if(!mapa.containsKey('operationalKey')){

       throw ClienteApiBlockchainException("Chave pública não encontrada.\nAqui está o mapa atual:\n $mapa");
     }

     print("Mapa com chave operacional\n"
         " $mapa");
     return mapa['operationalKey'];

   } catch(e){

     throw ClienteApiBlockchainException(e.toString());
   }
 }

  Future<bool> extratoConstaNoBlockchain(String hashDoPayload) async {

    try {

      String endpoint = "api/v1/documents/verify/${hashDoPayload}";

      http.Response chavePublica = await http.get(Uri.parse("$apiUrl/$endpoint"));

      final mapa = jsonDecode(chavePublica.body);

      /*
      if(!mapa.containsKey('operationalKey')){

        throw ClienteApiBlockchainException("Chave pública não encontrada.\nAqui está o mapa atual:\n $mapa");
      }


       */
      print("Mapa \n"
          " $mapa");
      return mapa["exists"];

    } catch(e){

      throw ClienteApiBlockchainException(e.toString());
    }
  }

  Future<List<Map<String, dynamic>>> getDeListaDeBancos() async {

    try {

      String endpoint = "/api/v1/banks";

      http.Response chavePublica = await http.get(Uri.parse("$apiUrl/$endpoint"));

      final mapa = jsonDecode(chavePublica.body);

      final mapaProcessado = mapa.map((item){

        return Map<String, dynamic>.from(item as Map);
      }).toList().cast<Map<String, dynamic>>();

      assert(mapaProcessado is List<Map<String, dynamic>>, "mapa não é List<Map<String, dynamic>>, é ${mapaProcessado.runtimeType}");

      assert(mapaProcessado.isNotEmpty, "lista esta vazia");

      return mapaProcessado;


    } catch(e){

      throw ClienteApiBlockchainException(e.toString());
    }

  }

 Future<Map<String, dynamic>> getStatementRecord(String documentHashHex) async {
   try {
     // Assumindo que o teu Controller de Documentos tem este endpoint
     String endpoint = "/api/v1/documents/verify/$documentHashHex";
     http.Response response = await http.get(Uri.parse("$apiUrl$endpoint"));

     if (response.statusCode != 200) {
       throw ClienteApiBlockchainException("Erro ao verificar documento: ${response.statusCode}");
     }

     return jsonDecode(response.body) as Map<String, dynamic>;
   } catch (e) {
     throw ClienteApiBlockchainException(e.toString());
   }
 }

 Future<Map<String, dynamic>> getStatusDoBanco(String idDoBanco) async {
   try {
     // O endpoint que criaste no Controller de Bancos
     String endpoint = "/api/v1/banks/$idDoBanco/status";
     http.Response response = await http.get(Uri.parse("$apiUrl$endpoint"));

     if (response.statusCode != 200) {
       throw ClienteApiBlockchainException("Erro ao buscar status do banco: ${response.statusCode}");
     }

     return jsonDecode(response.body) as Map<String, dynamic>;
   } catch (e) {
     throw ClienteApiBlockchainException(e.toString());
   }
 }

 Future<bool> validateHistoricalKey(String chaveEsperadaHex, dynamic timestampDoRegisto) async {
   try {
     // O endpoint que criaste no Controller de Bancos
     String endpoint = "/api/v1/banks/validate-historical?key=$chaveEsperadaHex&timestamp=${timestampDoRegisto.toString()}";
     http.Response response = await http.get(Uri.parse("$apiUrl$endpoint"));

     if (response.statusCode != 200) {
       throw ClienteApiBlockchainException("Erro ao validar chave histórica: ${response.statusCode}");
     }

     final mapa = jsonDecode(response.body);
     return mapa['isValid'] == true;
   } catch (e) {
     throw ClienteApiBlockchainException(e.toString());
   }
 }



}

class ClienteApiBlockchainException implements Exception {
  String? message;

  ClienteApiBlockchainException(this.message);

  @override
  String toString() {
    // TODO: implement toString
    return message ?? super.toString() ;
  }
}

class ClienteApiBlockchainMock implements ClienteApiBlockchainContract{
  String apiUrl = 'https://api-blockchain-pfc-1021823144662.africa-south1.run.app' ;


  Future<String> getChavePublicaDoBanco(String idDoBanco) async {

      try {
        
        String endpoint = "${idDoBanco}/operational-key";
  
        http.Response chavePublica = await http.get(Uri.parse("$apiUrl/$endpoint"));
  
        final mapa = jsonDecode(chavePublica.body);
  
        if(mapa.containsKey('operationalKey')){
          
          throw ClienteApiBlockchainException("Chave pública não encontrada.\nAqui está o mapa atual:\n $mapa");
        }
        return mapa['operationalKey'];
      
      } catch(e){
        
        throw ClienteApiBlockchainException(e.toString());
      }
    }

  static Future<bool> extratoConstaNoBlockchain(String hashDoPayload) async {

    if(hashDoPayload == 'acac426e8cf891cb8e8aba2bf8094d00933a06d37eceaa6cf9177016e14e75bc'){
      return true;
    }

    return false;
  }


}