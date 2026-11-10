import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../Providers/DocumentoProvider.dart';
import '../../Domain/entidade/DocumentoDeExtratoBancario.dart';

class TelaDeResultados extends StatefulWidget {
  const TelaDeResultados({super.key});

  @override
  State<TelaDeResultados> createState() => TelaDeResultadosState();
}

class TelaDeResultadosState extends State<TelaDeResultados> {

  Widget loading() {
    return const Expanded(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              "A verificar ancoragem na Blockchain...",
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemInfo(String label, String? valor, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.blueAccent, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  valor ?? "N/A",
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget cardResultado(DocumentoDeExtratoBancario? doc) {
    if (doc == null) {
      return const Center(child: Text("Nenhum resultado encontrado."));
    }

    bool isVeridico = doc.isDocumentoVeridico ?? false;
    final emRevisao = doc.autenticidadeEmRevisao;



    final dados = doc.dados;
    final tempo = DateTime.tryParse(dados['issuedAt']);
    if(tempo is DateTime) {
      final dataFormatada = dados['issuedAt'].split('T')[0];
      final horaFormatada = dados['issuedAt'].split('T')[1].replaceAll('Z', '');//"${tempo.hour}:${tempo.minute}:${tempo.second}";

      if(dados['issuedAt'].contains('Z') && dados['issuedAt'].contains('T')){
        dados['issuedAt'] = "$dataFormatada às $horaFormatada";
      }

    }




    //final corStatus = isVeridico ? Colors.green : Colors.red;
    final corStatus = emRevisao
        ? Colors.orange.shade800
        : (isVeridico ? Colors.green : Colors.red);
   // final iconoStatus = isVeridico ? Icons.check_circle : Icons.cancel;
    final iconoStatus = emRevisao
        ? Icons.warning_amber_rounded
        : (isVeridico ? Icons.check_circle : Icons.cancel);

    final titulo = isVeridico ? doc.mensagemDeSucesso : doc.mensagemDeErro;
    final subtitulo = isVeridico ? doc.mensagemDeSucesso2 : doc.mensagemDeErro2;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Banner de Status (Sucesso / Erro)
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: corStatus.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: corStatus, width: 2),
            ),
            child: Column(
              children: [
                Icon(iconoStatus, color: corStatus, size: 48),
                const SizedBox(height: 8),
                Text(
                  titulo ?? "",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: corStatus,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitulo ?? "",
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Card com os Dados do Extrato
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Informações do Extrato",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueAccent,
                    ),
                  ),
                  const Divider(height: 24),
                  _buildItemInfo("- Banco Emissor:", dados['banco'], Icons.account_balance),
                  _buildItemInfo("- Nome do Titular:", dados['titular'], Icons.person),
                  _buildItemInfo("- Saldo Final:", dados['saldoFinal'], Icons.attach_money),
                  _buildItemInfo("- Data de Emissão:", dados['issuedAt'], Icons.calendar_today),
                  _buildItemInfo("- Período de Transações:", dados['periodo'], Icons.date_range),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Botão para Voltar / Nova Leitura
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () {
              Navigator.popUntil(context, ModalRoute.withName('/'));
            },
            icon: const Icon(Icons.refresh),
            label: const Text(
              "Validar Novo Documento",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DocumentoProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Resultado do Documento"),
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: Column(
        children: [
          if (provider.isLoading)
            loading()
          else
            Expanded(child: cardResultado(provider.resposta)),
        ],
      ),
    );
  }
}