import 'package:app_pfc_blockchain/Presentation/Providers/BancoProvider.dart';
import 'package:app_pfc_blockchain/Presentation/Providers/DocumentoProvider.dart';
import 'package:app_pfc_blockchain/Presentation/Telas/TelaDeCapturaDoQrCode.dart';
import 'package:app_pfc_blockchain/Presentation/Telas/TelaDeEscolhaDeEntidade.dart';
import 'package:app_pfc_blockchain/Presentation/Telas/TelaDeResultados.dart';
import 'package:app_pfc_blockchain/Presentation/Telas/TelaInicial.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import 'Data/repos/BancoRepo.dart';
import 'Data/repos/DocumentoRepo.dart';



void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final bancoRepo = BancoRepo();
  final documentoRepo = DocumentoRepo();

  if (kIsWeb) {
    MobileScannerPlatform.instance.setWebBarcodeReader(
      WebBarcodeReader.zxingWasm,
    );
  }

  bancoRepo.atualizarInternamenteListaDeBancos();

  runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (context) => BancoProvider(bancoRepo)),
          ChangeNotifierProxyProvider<BancoProvider, DocumentoProvider>(
            create: (context) => DocumentoProvider(documentoRepo),
              update: (context, BancoProvider, DocumentoProvider){
                    DocumentoProvider?.bancoSelecionado = BancoProvider.bancoCorrente;
            return DocumentoProvider!;
          })
        ],
        child: const MyApp(),
      )
  );

}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: .fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const TelaInicial(),

      routes: {
        '/TelaDeEscolhaDeEntidade': (context) => const TelaDeEscolhaDeEntidade(),
        '/TelaDeQrCode': (context) => const TelaDeCapturaDoQrCode(),
        '/TelaDeResultados': (context) => const TelaDeResultados(),
      },
    );
  }
}

