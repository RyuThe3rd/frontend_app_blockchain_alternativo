import 'package:flutter/material.dart';

/// Apresenta os movimentos bancários já descodificados do QR Tipo B.
/// Não efectua nova leitura nem modifica os dados autenticados.
class TelaHistoricoDeTransacoes extends StatelessWidget {
  final List<Map<String, dynamic>> transacoes;
  final String banco;
  final String titular;
  final String periodo;
  final bool autenticado;
  final bool emRevisao;

  const TelaHistoricoDeTransacoes({
    super.key,
    required this.transacoes,
    required this.banco,
    required this.titular,
    required this.periodo,
    required this.autenticado,
    required this.emRevisao,
  });

  /// O valor continua representado por dois inteiros, sem double.
  String _formatarValor(Map<String, dynamic> movimento) {
    final inteiro = movimento['parteInteiraDoValor'];
    final centavos = movimento['parteDeCentavosDoValor'];
    if (inteiro is! int || centavos is! int) return 'Valor indisponível';

    final sinal = movimento['tipoMovimento'] == 'C' ? '+' : '−';
    return '$sinal$inteiro,${centavos.toString().padLeft(2, '0')} MT';
  }

  Widget _buildMovimento(BuildContext context, Map<String, dynamic> tx) {
    final credito = tx['tipoMovimento'] == 'C';
    final cor = credito ? Colors.green.shade700 : Colors.red.shade700;
    final descricao = tx['descricao']?.toString() ?? 'Movimento sem descrição';
    final data = tx['data']?.toString() ?? 'Data indisponível';

    return Card(
      margin: EdgeInsets.zero,
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: cor.withOpacity(0.10),
              child: Icon(
                credito ? Icons.south_west_rounded : Icons.north_east_rounded,
                color: cor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    descricao,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$data  •  ${credito ? 'Crédito' : 'Débito'}',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _formatarValor(tx),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: cor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final estado = emRevisao
        ? 'Autenticidade em revisão'
        : autenticado
        ? 'Extracto verificado'
        : 'Extracto não verificado';
    final corEstado = emRevisao
        ? Colors.orange.shade800
        : autenticado
        ? Colors.green.shade700
        : Colors.red.shade700;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Histórico de Transações'),
        centerTitle: true,
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  banco.isEmpty ? 'Extracto Tipo B' : banco,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (titular.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(titular),
                ],
                if (periodo.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text('Período: $periodo'),
                ],
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: corEstado.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: corEstado.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        autenticado && !emRevisao
                            ? Icons.verified_outlined
                            : Icons.info_outline_rounded,
                        color: corEstado,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '$estado. Os movimentos apresentados pertencem ao '
                              'conteúdo do QR Code; não são consultados em tempo real.',
                          style: TextStyle(color: corEstado, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Movimentos (${transacoes.length})',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: transacoes.isEmpty
                ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Não existem movimentos para apresentar neste extracto.',
                  textAlign: TextAlign.center,
                ),
              ),
            )
                : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              itemCount: transacoes.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) =>
                  _buildMovimento(context, transacoes[index]),
            ),
          ),
        ],
      ),
    );
  }
}
