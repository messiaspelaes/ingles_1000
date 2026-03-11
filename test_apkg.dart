import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'lib/services/apkg_service.dart';

void main() async {
  // Inicialize ffi para usar o sqflite no desktop/script
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  final service = ApkgService();
  final path =
      r"c:\Users\sealep\StudioProjects\ingles_1000-main\3_NEY_VASCONCELLOS_-_1000_Frases_mais_comuns_em_Ingls.apkg";

  try {
    print('Iniciando importação do arquivo: $path');
    final result = await service.importApkg(path);
    print('Sucesso!');
    print('Notas: ${result.notes.length}');
    print('Cards: ${result.cards.length}');
    print('Media files: ${result.mediaFiles.length}');
  } catch (e) {
    print('Erro: $e');
  }
}
