// ignore_for_file: avoid_print
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:sqlite3/sqlite3.dart';

void main() async {
  final path = r"c:\Users\sealep\StudioProjects\ingles_1000-main\3_NEY_VASCONCELLOS_-_1000_Frases_mais_comuns_em_Ingls.apkg";
  
  print('Lendo arquivo...');
  final bytes = await File(path).readAsBytes();
  print('Tamanho: ${bytes.length} bytes');
  
  print('Decodificando ZIP...');
  final archive = ZipDecoder().decodeBytes(bytes);
  
  final anki2 = archive.findFile('collection.anki2');
  final anki21b = archive.findFile('collection.anki21b');
  
  print('collection.anki2 existe? ${anki2 != null} - Tamanho: ${anki2?.size ?? 0}');
  print('collection.anki21b existe? ${anki21b != null} - Tamanho: ${anki21b?.size ?? 0}');
  
  if (anki2 != null && anki2.size > 0) {
    print('\nTestando collection.anki2...');
    await File('collection_test.anki2').writeAsBytes(anki2.content);
    try {
      final db = sqlite3.open('collection_test.anki2');
      
      final tables = db.select("SELECT name FROM sqlite_master WHERE type='table'");
      print('Tables: ${tables.map((row) => row["name"]).toList()}');
      
      if (tables.any((row) => row["name"] == 'notes')) {
        final notes = db.select('SELECT count(*) FROM notes');
        print('Notes count: ${notes.first.values.first}');
      }
      
      if (tables.any((row) => row["name"] == 'cards')) {
        final cards = db.select('SELECT count(*) FROM cards');
        print('Cards count: ${cards.first.values.first}');
      }
      db.close();
    } catch (e) {
      print('Error lendo banco: $e');
    }
  }
}
