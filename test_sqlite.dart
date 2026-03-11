import 'dart:io';
import 'package:archive/archive.dart';
import 'package:sqlite3/sqlite3.dart';

void main() async {
  final path = r"C:\Users\sealep\StudioProjects\ingles_1000-main\(3) NEY VASCONCELLOS - 1.000 Frases mais comuns em Inglês-20260310220334.apkg";
  
  print('Extracting DBs...');
  final bytes = await File(path).readAsBytes();
  final archive = ZipDecoder().decodeBytes(bytes);
  
  final anki2 = archive.findFile('collection.anki2');
  if (anki2 != null) {
    await File('collection.anki2').writeAsBytes(anki2.content);
    print('Extracted collection.anki2');
  }

  print('Testing collection.anki2...');
  try {
    final db = sqlite3.open('collection.anki2');
    
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
    db.dispose();
  } catch (e) {
    print('Error: $e');
  }
}
