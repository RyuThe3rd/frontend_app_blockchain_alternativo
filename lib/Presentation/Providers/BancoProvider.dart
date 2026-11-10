
import 'package:app_pfc_blockchain/Domain/contratos/BancoRepoContract.dart';
import 'package:flutter/material.dart';

class BancoProvider extends ChangeNotifier {
  final BancoRepoContract bancoRepo;
  Map<String, dynamic>? bancoCorrente;
  List<Map<String, dynamic>> bancos = [];
  bool isLoading = true;

  BancoProvider(this.bancoRepo) {
    _init();
  }

  Future<void> _init() async {
    try {
      bancos = await bancoRepo.getDeListaDeBancos();
    } catch (e) {
      debugPrint("Erro ao buscar bancos: $e");
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void atulizarListaDeBancos(){
    bancos = bancoRepo.getDeListaDeBancos();
    notifyListeners();
  }

  void setBancoCorrente(Map<String, dynamic> valor) {

    bancoCorrente = valor;
    /*
    if (bancos.length == 2)
      bancoCorrente["name"] = valor.split("-")[1];
    else
      bancoCorrente[""] = valor;
    */
    notifyListeners();
  }

  void notify() {

    print("Notified\n bancoCorrente: $bancoCorrente");
    notifyListeners();
  }
}
