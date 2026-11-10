
import '../../Domain/contratos/BancoRepoContract.dart';
import '../Services/clienteApiBlockchain.dart';

class BancoRepo implements BancoRepoContract {

  late List<Map<String, dynamic>> listaDeBancos = [];

  void atualizarInternamenteListaDeBancos() async {
    listaDeBancos = await ClienteApiBlockchain().getDeListaDeBancos();
  }

  @override
  String getChavePublicaDoBanco({String? banco, String? id}) {
    // TODO: implement getChavePublicaDoBanco
    throw UnimplementedError();
  }

  @override
  List<Map<String, dynamic>> getDeListaDeBancos() {
    return listaDeBancos;
  }



}

class BancoRepoException implements Exception {

  String? mensagem;

  BancoRepoException(this.mensagem);
  @override
  String toString() {
    // TODO: implement toString
    return mensagem ?? super.toString();
  }
}