
class DocumentoDeExtratoBancario{
  Map<String, dynamic> dados;
  bool? isDocumentoVeridico = null;
  bool autenticidadeEmRevisao = false;
  String? banco;
  String? mensagemDeErro = "Documento invalido!";
  String? mensagemDeErro2 = "Um dos campos abaixo não contém informação verídica:";
  String? mensagemDeSucesso = "Documento verificado com sucesso!";
  String mensagemDeSucesso2 = "Verifique se a informação abaixo é a mesma que consta no documento de extrato.";

  DocumentoDeExtratoBancario(this.dados);
}

/*Dados provavelmente terá esta informação neste formato JSON:

{
"banco": "BCI",
"titular": "Rui Manuel de Noronha Matomate",
"contaHash": "a8f3b21c4e9d...8f2",
"periodo": "2026-01-01 a 2026-06-30",
"saldoFinal": "500000.00 MZN",
"issuedAt": "2026-08-30T18:00:00Z",
"assinaturaBanco": "3f8b9a1c7d..."
}

 */

