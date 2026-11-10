import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../Providers/BancoProvider.dart';

class TelaDeEscolhaDeEntidade extends StatefulWidget {
  const TelaDeEscolhaDeEntidade({super.key});

  @override
  State<TelaDeEscolhaDeEntidade> createState() => TelaDeEscolhaDeEntidadeState();
}

class TelaDeEscolhaDeEntidadeState extends State<TelaDeEscolhaDeEntidade> {
  final TextEditingController _searchController = TextEditingController();
  String _filtro = "";

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _filtro = _searchController.text.toLowerCase();
      });
    });
    context.read<BancoProvider>().bancoRepo.atualizarInternamenteListaDeBancos();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BancoProvider>().atulizarListaDeBancos();
    });

  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bancoProvider = context.watch<BancoProvider>();
    final listaDeBancos = bancoProvider.bancos;

    final listaFiltrada = listaDeBancos.where((e) {
      return e["name"].toLowerCase().contains(_filtro);
    }).toList();

    return Scaffold(
      appBar: AppBar(

        backgroundColor: Colors.blue[700],
        //backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        title: const Text('Escolha um banco'),
        titleTextStyle: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
        centerTitle: true,
        elevation: 2,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Campo de Pesquisa
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Pesquise uma Entidade ou Banco',
                prefixIcon: const Icon(Icons.search, color: Colors.blueAccent),
                suffixIcon: _filtro.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                  },
                )
                    : null,
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 14,
                  horizontal: 16,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.blueAccent),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.blueAccent, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Lista ou Estado de Carregamento/Vazio
            Expanded(
              child: bancoProvider.isLoading
                  ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 12),
                    Text(
                      "A carregar entidades parceiras...",
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              )
                  : listaFiltrada.isEmpty
                  ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.search_off,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "Nenhum banco encontrado",
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              )
                  : ListView.builder(
                itemCount: listaFiltrada.length,
                itemBuilder: (context, index) {
                  final banco = listaFiltrada[index];
                  return Card(
                    elevation: 1.5,
                    margin: const EdgeInsets.symmetric(vertical: 6.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: Colors.blueAccent,
                        foregroundColor: Colors.white,
                        child: Icon(Icons.account_balance, size: 20),
                      ),
                      title: Text(
                        banco["name"],
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      trailing: const Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: Colors.grey,
                      ),
                      onTap: () {
                        context
                            .read<BancoProvider>()
                            .setBancoCorrente(banco);
                        Navigator.pushNamed(context, '/TelaDeQrCode');
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}