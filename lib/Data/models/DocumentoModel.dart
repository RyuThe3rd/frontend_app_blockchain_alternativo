
import '../../Domain/entidade/DocumentoDeExtratoBancario.dart';

class DocumentoModel extends DocumentoDeExtratoBancario{

  DocumentoModel(super.dados);

  factory DocumentoModel.fromMap(Map<String,dynamic> map){

    return DocumentoModel(map);
  }
}