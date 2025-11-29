/*
 * Copyright (c) 2025
 * 
 * This program is free software; you can redistribute it and/or modify it under
 * the terms of the GNU General Public License as published by the Free Software
 * Foundation; either version 3 of the License, or (at your option) any later
 * version.
 * 
 * Adaptado de AnkiDroid (GPL v3) - https://github.com/ankidroid/Anki-Android
 * Baseado em libanki/src/main/java/com/ichi2/anki/libanki/BackendImportExport.kt
 * e AnkiDroid/src/main/java/com/ichi2/utils/ImportUtils.kt
 */

import 'dart:io';
import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import '../models/card.dart';
import '../models/note.dart';

/// Serviço para importar arquivos .apkg do Anki
/// Adaptado do código do AnkiDroid
class ApkgService {
  /// Importa um arquivo .apkg e retorna os dados extraídos
  /// 
  /// Um arquivo .apkg é um ZIP contendo:
  /// - collection.anki2: banco SQLite com cards, notas, scheduling
  /// - media/: imagens, áudios e outros arquivos
  /// - media.json: mapeamento de arquivos de mídia
  Future<ApkgImportResult> importApkg(String apkgPath) async {
    try {
      // 1. Ler arquivo ZIP
      final file = File(apkgPath);
      final bytes = await file.readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);

      // 2. Extrair collection.anki2 (banco SQLite)
      final dbEntry = archive.findFile('collection.anki2');
      if (dbEntry == null) {
        throw Exception('Arquivo collection.anki2 não encontrado no .apkg');
      }

      // 3. Salvar temporariamente e abrir SQLite
      final tempDir = await getTemporaryDirectory();
      final tempDbPath = '${tempDir.path}/anki_temp.db';
      await File(tempDbPath).writeAsBytes(dbEntry.content);

      final db = await openDatabase(tempDbPath, readOnly: true);

      // 4. Ler dados do banco
      final notes = await _readNotes(db);
      final cards = await _readCards(db);
      final mediaFiles = await _readMedia(archive);

      // 5. Limpar arquivo temporário
      await db.close();
      await File(tempDbPath).delete();

      return ApkgImportResult(
        notes: notes,
        cards: cards,
        mediaFiles: mediaFiles,
      );
    } catch (e) {
      throw Exception('Erro ao importar .apkg: $e');
    }
  }

  /// Lê notas do banco SQLite do Anki
  /// Adaptado de AnkiDroid Collection.importAnkiPackage()
  Future<List<AnkiNote>> _readNotes(Database db) async {
    final notesList = <AnkiNote>[];

    // Tabela 'notes' do Anki
    final notes = await db.rawQuery('''
      SELECT id, guid, mid, flds, tags, sfld, csum, flags, data
      FROM notes
    ''');

    for (final row in notes) {
      // flds é uma string separada por \x1f (caractere de controle)
      final flds = row['flds'] as String;
      final fields = flds.split('\x1f');

      // tags é uma string separada por espaços
      final tagsStr = row['tags'] as String? ?? '';
      final tags = tagsStr.split(' ').where((t) => t.isNotEmpty).toList();

      notesList.add(AnkiNote(
        id: row['id'] as int,
        guid: row['guid'] as String,
        modelId: row['mid'] as int,
        fields: fields,
        tags: tags,
      ));
    }

    return notesList;
  }

  /// Lê cards do banco SQLite do Anki
  /// Adaptado de AnkiDroid Collection.importAnkiPackage()
  Future<List<AnkiCard>> _readCards(Database db) async {
    final cardsList = <AnkiCard>[];

    // Tabela 'cards' do Anki
    final cards = await db.rawQuery('''
      SELECT id, nid, did, ord, mod, usn, type, queue, due, ivl, factor, 
             reps, lapses, left, odue, odid, flags, data
      FROM cards
    ''');

    for (final row in cards) {
      cardsList.add(AnkiCard(
        id: row['id'] as int,
        noteId: row['nid'] as int,
        deckId: row['did'] as int,
        type: row['type'] as int,
        queue: row['queue'] as int,
        due: row['due'] as int,
        interval: row['ivl'] as int? ?? 0,
        easeFactor: (row['factor'] as int? ?? 2500) / 1000.0,
        reviewsCount: row['reps'] as int? ?? 0,
        lapsesCount: row['lapses'] as int? ?? 0,
      ));
    }

    return cardsList;
  }

  /// Lê arquivos de mídia do ZIP
  Future<Map<String, Uint8List>> _readMedia(Archive archive) async {
    final mediaFiles = <String, Uint8List>{};

    // Ler media.json para mapeamento
    final mediaJsonEntry = archive.findFile('media');
    if (mediaJsonEntry != null) {
      // media.json contém mapeamento de nomes de arquivos
      // Por enquanto, extraímos todos os arquivos da pasta media/
      for (final file in archive.files) {
        if (file.name.startsWith('media/') && !file.isFile) {
          continue;
        }
        if (file.name.startsWith('media/')) {
          final filename = file.name.replaceFirst('media/', '');
          mediaFiles[filename] = Uint8List.fromList(file.content);
        }
      }
    }

    return mediaFiles;
  }
}

/// Resultado da importação .apkg
class ApkgImportResult {
  final List<AnkiNote> notes;
  final List<AnkiCard> cards;
  final Map<String, Uint8List> mediaFiles;

  ApkgImportResult({
    required this.notes,
    required this.cards,
    required this.mediaFiles,
  });
}

/// Nota do Anki (formato interno)
class AnkiNote {
  final int id;
  final String guid;
  final int modelId;
  final List<String> fields;
  final List<String> tags;

  AnkiNote({
    required this.id,
    required this.guid,
    required this.modelId,
    required this.fields,
    required this.tags,
  });
}

/// Card do Anki (formato interno)
class AnkiCard {
  final int id;
  final int noteId;
  final int deckId;
  final int type;      // CardType
  final int queue;     // QueueType
  final int due;       // Due date (dias desde epoch ou timestamp)
  final int interval;
  final double easeFactor;
  final int reviewsCount;
  final int lapsesCount;

  AnkiCard({
    required this.id,
    required this.noteId,
    required this.deckId,
    required this.type,
    required this.queue,
    required this.due,
    required this.interval,
    required this.easeFactor,
    required this.reviewsCount,
    required this.lapsesCount,
  });
}

