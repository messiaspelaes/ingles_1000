/*
 * Copyright (c) 2025
 * 
 * This program is free software; you can redistribute it and/or modify it under
 * the terms of the GNU General Public License as published by the Free Software
 * Foundation; either version 3 of the License, or (at your option) any later
 * version.
 * 
 * Adaptado de AnkiDroid (GPL v3) - https://github.com/ankidroid/Anki-Android
 */

import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'dart:io';
import '../models/deck.dart';
import '../models/note.dart';
import '../models/card.dart';
import '../models/review_log.dart';
import 'dart:convert';

/// Serviço de banco de dados local SQLite
/// Substitui o SupabaseService para funcionamento 100% offline
class DatabaseService {
  static const String _databaseName = 'ingles1000.db';
  static const int _databaseVersion = 1;
  
  static Database? _database;
  
  /// Obtém a instância do banco de dados
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// Inicializa o banco de dados
  Future<Database> _initDatabase() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final dbPath = path.join(documentsDirectory.path, _databaseName);
    
    return await openDatabase(
      dbPath,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  /// Cria as tabelas na primeira execução
  Future<void> _onCreate(Database db, int version) async {
    // Tabela de Decks
    await db.execute('''
      CREATE TABLE decks (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Tabela de Notes
    await db.execute('''
      CREATE TABLE notes (
        id TEXT PRIMARY KEY,
        deck_id TEXT NOT NULL,
        fields TEXT NOT NULL,
        tags TEXT,
        model_name TEXT NOT NULL DEFAULT 'Basic',
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        anki_guid TEXT,
        anki_note_id INTEGER,
        FOREIGN KEY (deck_id) REFERENCES decks(id) ON DELETE CASCADE
      )
    ''');

    // Tabela de Cards
    await db.execute('''
      CREATE TABLE cards (
        id TEXT PRIMARY KEY,
        note_id TEXT NOT NULL,
        deck_id TEXT NOT NULL,
        queue_type TEXT NOT NULL DEFAULT 'NEW',
        fsrs_difficulty REAL DEFAULT 0.3,
        fsrs_stability REAL DEFAULT 0.0,
        fsrs_retrievability REAL DEFAULT 1.0,
        due_date TEXT NOT NULL,
        interval_days INTEGER DEFAULT 0,
        ease_factor REAL DEFAULT 2.5,
        reviews_count INTEGER DEFAULT 0,
        lapses_count INTEGER DEFAULT 0,
        last_review_at TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        anki_card_id INTEGER,
        anki_due INTEGER,
        FOREIGN KEY (note_id) REFERENCES notes(id) ON DELETE CASCADE,
        FOREIGN KEY (deck_id) REFERENCES decks(id) ON DELETE CASCADE
      )
    ''');

    // Tabela de Review Logs
    await db.execute('''
      CREATE TABLE review_logs (
        id TEXT PRIMARY KEY,
        card_id TEXT NOT NULL,
        rating INTEGER NOT NULL,
        interval_before INTEGER,
        interval_after INTEGER,
        time_taken_ms INTEGER DEFAULT 0,
        fsrs_difficulty_before REAL,
        fsrs_stability_before REAL,
        fsrs_difficulty_after REAL,
        fsrs_stability_after REAL,
        reviewed_at TEXT NOT NULL,
        FOREIGN KEY (card_id) REFERENCES cards(id) ON DELETE CASCADE
      )
    ''');

    // Tabela de Mídia
    await db.execute('''
      CREATE TABLE media_files (
        id TEXT PRIMARY KEY,
        deck_id TEXT NOT NULL,
        filename TEXT NOT NULL,
        file_path TEXT NOT NULL,
        file_size INTEGER,
        mime_type TEXT,
        anki_filename TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (deck_id) REFERENCES decks(id) ON DELETE CASCADE
      )
    ''');

    // Índices para performance
    await db.execute('CREATE INDEX idx_cards_deck ON cards(deck_id)');
    await db.execute('CREATE INDEX idx_cards_due_date ON cards(due_date)');
    await db.execute('CREATE INDEX idx_cards_queue_type ON cards(queue_type, due_date)');
    await db.execute('CREATE INDEX idx_notes_deck ON notes(deck_id)');
    await db.execute('CREATE INDEX idx_review_logs_card ON review_logs(card_id)');
  }

  /// Atualiza o banco em versões futuras
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Implementar migrações futuras aqui
  }

  // ============================================================================
  // DECKS
  // ============================================================================

  /// Obtém todos os decks
  Future<List<Deck>> getAllDecks() async {
    final db = await database;
    final maps = await db.query('decks', orderBy: 'name ASC');
    return maps.map((map) => Deck.fromMap(map)).toList();
  }

  /// Obtém um deck por ID
  Future<Deck?> getDeckById(String id) async {
    final db = await database;
    final maps = await db.query(
      'decks',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return Deck.fromMap(maps.first);
  }

  /// Cria um novo deck
  Future<String> createDeck(String name, {String? description}) async {
    final db = await database;
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final now = DateTime.now().toIso8601String();

    await db.insert('decks', {
      'id': id,
      'name': name,
      'description': description,
      'created_at': now,
      'updated_at': now,
    });

    return id;
  }

  /// Atualiza um deck
  Future<void> updateDeck(Deck deck) async {
    final db = await database;
    await db.update(
      'decks',
      {
        ...deck.toMap(),
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [deck.id],
    );
  }

  /// Deleta um deck
  Future<void> deleteDeck(String id) async {
    final db = await database;
    await db.delete('decks', where: 'id = ?', whereArgs: [id]);
  }

  // ============================================================================
  // NOTES
  // ============================================================================

  /// Obtém todas as notas de um deck
  Future<List<Note>> getNotesByDeckId(String deckId) async {
    final db = await database;
    final maps = await db.query(
      'notes',
      where: 'deck_id = ?',
      whereArgs: [deckId],
    );
    return maps.map((map) => _noteFromMap(map)).toList();
  }

  /// Obtém uma nota por ID
  Future<Note?> getNoteById(String id) async {
    final db = await database;
    final maps = await db.query(
      'notes',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return _noteFromMap(maps.first);
  }

  /// Salva uma nota (insert ou update)
  Future<void> saveNote(Note note) async {
    final db = await database;
    await db.insert(
      'notes',
      _noteToMap(note),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Deleta uma nota
  Future<void> deleteNote(String id) async {
    final db = await database;
    await db.delete('notes', where: 'id = ?', whereArgs: [id]);
  }

  // ============================================================================
  // CARDS
  // ============================================================================

  /// Obtém cards que estão vencidos (due) para revisão
  Future<List<Card>> getDueCards({String? deckId}) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    
    String whereClause = 'due_date <= ? AND queue_type != ?';
    List<dynamic> whereArgs = [now, 'NEW'];
    
    if (deckId != null) {
      whereClause += ' AND deck_id = ?';
      whereArgs.add(deckId);
    }

    final maps = await db.query(
      'cards',
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'due_date ASC',
      limit: 50,
    );

    return maps.map((map) => _cardFromMap(map)).toList();
  }

  /// Obtém um card por ID
  Future<Card?> getCardById(String id) async {
    final db = await database;
    final maps = await db.query(
      'cards',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return _cardFromMap(maps.first);
  }

  /// Obtém cards por note ID
  Future<List<Card>> getCardsByNoteId(String noteId) async {
    final db = await database;
    final maps = await db.query(
      'cards',
      where: 'note_id = ?',
      whereArgs: [noteId],
    );
    return maps.map((map) => _cardFromMap(map)).toList();
  }

  /// Salva um card (insert ou update)
  Future<void> saveCard(Card card) async {
    final db = await database;
    await db.insert(
      'cards',
      _cardToMap(card),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Deleta um card
  Future<void> deleteCard(String id) async {
    final db = await database;
    await db.delete('cards', where: 'id = ?', whereArgs: [id]);
  }

  // ============================================================================
  // REVIEW LOGS
  // ============================================================================

  /// Salva um log de revisão
  Future<void> saveReviewLog(ReviewLog reviewLog) async {
    final db = await database;
    await db.insert('review_logs', _reviewLogToMap(reviewLog));
  }

  /// Obtém logs de revisão por card ID
  Future<List<ReviewLog>> getReviewLogsByCardId(String cardId) async {
    final db = await database;
    final maps = await db.query(
      'review_logs',
      where: 'card_id = ?',
      whereArgs: [cardId],
      orderBy: 'reviewed_at DESC',
    );
    return maps.map((map) => _reviewLogFromMap(map)).toList();
  }

  // ============================================================================
  // HELPER METHODS - Conversão de dados
  // ============================================================================

  /// Converte Map do SQLite para Note
  Note _noteFromMap(Map<String, dynamic> map) {
    return Note(
      id: map['id'] as String,
      deckId: map['deck_id'] as String,
      userId: '', // Não usado offline
      fields: List<String>.from(jsonDecode(map['fields'] as String)),
      tags: map['tags'] != null
          ? List<String>.from(jsonDecode(map['tags'] as String))
          : [],
      modelName: map['model_name'] as String? ?? 'Basic',
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      ankiGuid: map['anki_guid'] as String?,
      ankiNoteId: map['anki_note_id'] as int?,
    );
  }

  /// Converte Note para Map do SQLite
  Map<String, dynamic> _noteToMap(Note note) {
    return {
      'id': note.id,
      'deck_id': note.deckId,
      'fields': jsonEncode(note.fields),
      'tags': jsonEncode(note.tags),
      'model_name': note.modelName,
      'created_at': note.createdAt.toIso8601String(),
      'updated_at': note.updatedAt.toIso8601String(),
      'anki_guid': note.ankiGuid,
      'anki_note_id': note.ankiNoteId,
    };
  }

  /// Converte Map do SQLite para Card
  Card _cardFromMap(Map<String, dynamic> map) {
    return Card(
      id: map['id'] as String,
      noteId: map['note_id'] as String,
      deckId: map['deck_id'] as String,
      userId: '', // Não usado offline
      queueType: CardQueueType.values.firstWhere(
        (e) => e.value == map['queue_type'],
        orElse: () => CardQueueType.newCard,
      ),
      fsrsDifficulty: (map['fsrs_difficulty'] as num?)?.toDouble() ?? 0.3,
      fsrsStability: (map['fsrs_stability'] as num?)?.toDouble() ?? 0.0,
      fsrsRetrievability: (map['fsrs_retrievability'] as num?)?.toDouble() ?? 1.0,
      dueDate: DateTime.parse(map['due_date'] as String),
      intervalDays: map['interval_days'] as int? ?? 0,
      easeFactor: (map['ease_factor'] as num?)?.toDouble() ?? 2.5,
      reviewsCount: map['reviews_count'] as int? ?? 0,
      lapsesCount: map['lapses_count'] as int? ?? 0,
      lastReviewAt: map['last_review_at'] != null
          ? DateTime.parse(map['last_review_at'] as String)
          : null,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      ankiCardId: map['anki_card_id'] as int?,
      ankiDue: map['anki_due'] as int?,
    );
  }

  /// Converte Card para Map do SQLite
  Map<String, dynamic> _cardToMap(Card card) {
    return {
      'id': card.id,
      'note_id': card.noteId,
      'deck_id': card.deckId,
      'queue_type': card.queueType.value,
      'fsrs_difficulty': card.fsrsDifficulty,
      'fsrs_stability': card.fsrsStability,
      'fsrs_retrievability': card.fsrsRetrievability,
      'due_date': card.dueDate.toIso8601String(),
      'interval_days': card.intervalDays,
      'ease_factor': card.easeFactor,
      'reviews_count': card.reviewsCount,
      'lapses_count': card.lapsesCount,
      'last_review_at': card.lastReviewAt?.toIso8601String(),
      'created_at': card.createdAt.toIso8601String(),
      'updated_at': card.updatedAt.toIso8601String(),
      'anki_card_id': card.ankiCardId,
      'anki_due': card.ankiDue,
    };
  }

  /// Converte Map do SQLite para ReviewLog
  ReviewLog _reviewLogFromMap(Map<String, dynamic> map) {
    return ReviewLog(
      id: map['id'] as String,
      cardId: map['card_id'] as String,
      userId: '', // Não usado offline
      rating: CardRating.fromValue(map['rating'] as int),
      intervalBefore: map['interval_before'] as int?,
      intervalAfter: map['interval_after'] as int?,
      timeTakenMs: map['time_taken_ms'] as int? ?? 0,
      fsrsDifficultyBefore: (map['fsrs_difficulty_before'] as num?)?.toDouble(),
      fsrsStabilityBefore: (map['fsrs_stability_before'] as num?)?.toDouble(),
      fsrsDifficultyAfter: (map['fsrs_difficulty_after'] as num?)?.toDouble(),
      fsrsStabilityAfter: (map['fsrs_stability_after'] as num?)?.toDouble(),
      reviewedAt: DateTime.parse(map['reviewed_at'] as String),
    );
  }

  /// Converte ReviewLog para Map do SQLite
  Map<String, dynamic> _reviewLogToMap(ReviewLog reviewLog) {
    return {
      'id': reviewLog.id,
      'card_id': reviewLog.cardId,
      'rating': reviewLog.rating.value,
      'interval_before': reviewLog.intervalBefore,
      'interval_after': reviewLog.intervalAfter,
      'time_taken_ms': reviewLog.timeTakenMs,
      'fsrs_difficulty_before': reviewLog.fsrsDifficultyBefore,
      'fsrs_stability_before': reviewLog.fsrsStabilityBefore,
      'fsrs_difficulty_after': reviewLog.fsrsDifficultyAfter,
      'fsrs_stability_after': reviewLog.fsrsStabilityAfter,
      'reviewed_at': reviewLog.reviewedAt.toIso8601String(),
    };
  }

  // ============================================================================
  // STATISTICS
  // ============================================================================

  /// Obtém o total de cards no banco
  Future<int> getTotalCardsCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM cards');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Obtém o total de cards revisados hoje
  Future<int> getReviewedTodayCount() async {
    final db = await database;
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day).toIso8601String();
    
    final result = await db.rawQuery('''
      SELECT COUNT(*) as count 
      FROM cards 
      WHERE last_review_at IS NOT NULL 
      AND last_review_at >= ?
    ''', [todayStart]);
    
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Fecha o banco de dados
  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }
}

