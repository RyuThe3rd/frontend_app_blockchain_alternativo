
//tela que tem um texto em branco com algo do tipo:
// "Bem vindo ao aplicativo do Protocolo De Integridade Documental.
// Este é um protótipo de autenticação de extratos bancários de maneira eficiente via QR Code.
//"
// depois tem um botão retangular com o título: Verificar Extrato Bancario
//que on tap, faz pushNameda para '/TelaDeEscolhaDeEntidade'

import 'package:flutter/material.dart';

class TelaInicial extends StatelessWidget {
  const TelaInicial({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green[700],// quero um gradiente de green 400 à 700
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.blue[700]!,
              Colors.green[700]!,
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (false) ...[const Icon(
                Icons.verified_user_outlined,
                size: 100,
                color: Colors.white,
              )],
              const SizedBox(height: 172),
              const Text(
                "Bem vindo ao aplicativo do Protocolo de Integridade Documental.",
                style: TextStyle(
                  //fontFamily: 'Times New Roman',

                  fontStyle: FontStyle.italic,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white, //Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 26),
              const Text(
                "Este é um protótipo de autenticação de extratos bancários de maneira eficiente via QR Code.",
                style: TextStyle(

                  fontSize: 16,
                  color: Colors.white, //Colors.black54,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 3,
                ),
                onPressed: () {
                  Navigator.pushNamed(context, '/TelaDeEscolhaDeEntidade');
                },
                child: const Text(
                  "Verificar Extrato Bancário",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
