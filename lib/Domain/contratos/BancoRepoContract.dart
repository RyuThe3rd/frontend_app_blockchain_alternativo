import "package:http/http.dart" as http;

abstract interface class BancoRepoContract {

  List<Map<String, dynamic>> getDeListaDeBancos();
  String getChavePublicaDoBanco({String? banco, String? id});

  void atualizarInternamenteListaDeBancos() {}


}